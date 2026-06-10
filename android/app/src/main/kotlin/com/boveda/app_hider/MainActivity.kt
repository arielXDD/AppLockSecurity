package com.boveda.app_hider

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Bundle
import android.util.Base64
import androidx.biometric.BiometricManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val channel = "com.boveda.app_hider/native"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var adminComponent: ComponentName

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponent = ComponentName(this, BovedaDeviceAdminReceiver::class.java)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> result.success(getInstalledApps())
                "hideApp" -> {
                    val pkg = call.argument<String>("package")
                    if (pkg == null) result.error("INVALID", "Package name required", null)
                    else result.success(hideApp(pkg))
                }
                "showApp" -> {
                    val pkg = call.argument<String>("package")
                    if (pkg == null) result.error("INVALID", "Package name required", null)
                    else result.success(showApp(pkg))
                }
                "showAllApps" -> result.success(showAllApps())
                "isDeviceAdmin" -> result.success(devicePolicyManager.isDeviceOwnerApp(packageName))
                "requestDeviceAdmin" -> {
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                        putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                        putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Activa este permiso para habilitar el ocultamiento avanzado de aplicaciones.")
                    }
                    startActivity(intent)
                    result.success(null)
                }
                "isBiometricAvailable" -> {
                    val biometricManager = BiometricManager.from(this)
                    result.success(biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) == BiometricManager.BIOMETRIC_SUCCESS)
                }
                "setLauncherAlias" -> {
                    val alias = call.argument<String>("alias") ?: "calculator"
                    setLauncherAlias(alias)
                    result.success(null)
                }
                "saveIntruderLog" -> {
                    val path = call.argument<String>("photoPath")
                    if (path != null) saveIntruderLog(path)
                    result.success(null)
                }
                "getIntruderLogs" -> result.success(getIntruderLogs())
                "setDialCode" -> {
                    val code = call.argument<String>("code") ?: "*#*#0000#*#*"
                    prefs().edit().putString("dial_code", code).apply()
                    result.success(null)
                }
                "setAccessMethod" -> {
                    val method = call.argument<String>("method")
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    if (method != null) {
                        prefs().edit().putBoolean("access_$method", enabled).apply()
                    }
                    result.success(null)
                }
                "requestQuickTile" -> result.success(null)
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            PackageManager.MATCH_DISABLED_COMPONENTS
        } else {
            PackageManager.GET_DISABLED_COMPONENTS
        }
        val hiddenSet = (prefs().getString("hidden_apps", "") ?: "").split(",").filter { it.isNotEmpty() }.toSet()
        val excludePackages = setOf(packageName, "android", "com.android.settings", "com.android.systemui")

        return pm.getInstalledApplications(flags)
            .filter { it.flags and ApplicationInfo.FLAG_SYSTEM == 0 && it.packageName !in excludePackages }
            .map { info ->
                mapOf(
                    "packageName" to info.packageName,
                    "appName" to pm.getApplicationLabel(info).toString(),
                    "iconBase64" to try {
                        drawableToBase64(pm.getApplicationIcon(info.packageName))
                    } catch (_: Exception) { null },
                    "isHidden" to (info.packageName in hiddenSet)
                )
            }
            .sortedBy { it["appName"] as? String ?: "" }
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = when (drawable) {
            is BitmapDrawable -> drawable.bitmap
            is AdaptiveIconDrawable -> {
                val bmp = Bitmap.createBitmap(108, 108, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bmp
            }
            else -> {
                val bmp = Bitmap.createBitmap(
                    drawable.intrinsicWidth.takeIf { it > 0 } ?: 108,
                    drawable.intrinsicHeight.takeIf { it > 0 } ?: 108,
                    Bitmap.Config.ARGB_8888
                )
                val canvas = Canvas(bmp)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bmp
            }
        }
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 85, stream)
        return Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP)
    }

    private fun hideApp(targetPackage: String): Boolean {
        return try {
            if (devicePolicyManager.isDeviceOwnerApp(packageName)) {
                devicePolicyManager.setApplicationHidden(adminComponent, targetPackage, true)
                saveHiddenPackage(targetPackage, true)
                true
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun showApp(targetPackage: String): Boolean {
        return try {
            if (devicePolicyManager.isDeviceOwnerApp(packageName)) {
                devicePolicyManager.setApplicationHidden(adminComponent, targetPackage, false)
                saveHiddenPackage(targetPackage, false)
                true
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun showAllApps(): Boolean {
        val hiddenPkgs = prefs().getString("hidden_apps", "") ?: ""
        if (devicePolicyManager.isDeviceOwnerApp(packageName)) {
            hiddenPkgs.split(",").filter { it.isNotEmpty() }.forEach { pkg ->
                devicePolicyManager.setApplicationHidden(adminComponent, pkg, false)
            }
        }
        prefs().edit().putString("hidden_apps", "").apply()
        return true
    }

    private fun saveHiddenPackage(pkg: String, hidden: Boolean) {
        val current = prefs().getString("hidden_apps", "") ?: ""
        val set = current.split(",").filter { it.isNotEmpty() }.toMutableSet()
        if (hidden) set.add(pkg) else set.remove(pkg)
        prefs().edit().putString("hidden_apps", set.joinToString(",")).apply()
    }

    private fun setLauncherAlias(alias: String) {
        val calcAlias = ComponentName(this, "com.boveda.app_hider.FakeCalculatorActivity")
        val vaultAlias = ComponentName(this, "com.boveda.app_hider.VaultLauncherActivity")
        val pm = packageManager

        if (alias == "calculator") {
            pm.setComponentEnabledSetting(calcAlias, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
            pm.setComponentEnabledSetting(vaultAlias, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
        } else {
            pm.setComponentEnabledSetting(calcAlias, PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP)
            pm.setComponentEnabledSetting(vaultAlias, PackageManager.COMPONENT_ENABLED_STATE_ENABLED, PackageManager.DONT_KILL_APP)
        }
    }

    private fun saveIntruderLog(photoPath: String) {
        val logs = prefs().getString("intruder_logs", "[]") ?: "[]"
        val array = JSONArray(logs)
        val obj = JSONObject().apply {
            put("timestamp", System.currentTimeMillis())
            put("photoPath", photoPath)
            put("attemptNumber", array.length() + 1)
        }
        array.put(obj)
        // Mantener solo los últimos 20
        val finalArray = if (array.length() > 20) {
            val newArray = JSONArray()
            for (i in (array.length() - 20) until array.length()) {
                newArray.put(array.get(i))
            }
            newArray
        } else array
        prefs().edit().putString("intruder_logs", finalArray.toString()).apply()
    }

    private fun getIntruderLogs(): List<Map<String, Any>> {
        val logs = prefs().getString("intruder_logs", "[]") ?: "[]"
        val array = JSONArray(logs)
        val result = mutableListOf<Map<String, Any>>()
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            result.add(mapOf(
                "timestamp" to obj.getLong("timestamp"),
                "photoPath" to obj.getString("photoPath"),
                "attemptNumber" to obj.getInt("attemptNumber")
            ))
        }
        return result.reversed()
    }

    private fun prefs(): SharedPreferences = getSharedPreferences("boveda_prefs", Context.MODE_PRIVATE)

    companion object {
        const val CHANNEL_ID = "stealth_channel"
        const val STEALTH_NOTIFICATION_ID = 884
    }
}
