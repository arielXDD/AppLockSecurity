package com.boveda.app_hider

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.Toast

/**
 * Device Admin Receiver para la Bóveda.
 *
 * Funcionalidad crítica:
 * - onDisableRequested: cuando alguien intenta quitar el permiso de Device Admin,
 *   se restauran automáticamente TODAS las apps ocultas y se borran los datos
 *   sensibles antes de permitir la desinstalación (plan de autodestrucción).
 */
class BovedaDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        Toast.makeText(
            context,
            "Bóveda: Protección activada ✓",
            Toast.LENGTH_SHORT
        ).show()
    }

    override fun onDisabled(context: Context, intent: Intent) {
        Toast.makeText(
            context,
            "Bóveda: Protección desactivada",
            Toast.LENGTH_SHORT
        ).show()
    }

    /**
     * PLAN DE AUTODESTRUCCIÓN:
     * Se ejecuta justo ANTES de que el usuario pueda quitar el permiso.
     * 1. Restaura todas las apps ocultas (para no dejarlas inutilizables)
     * 2. Borra todos los datos de la bóveda
     */
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        clearHiddenApps(context)
        // Borrar datos sensibles
        nukeVaultData(context)

        return "Se restaurarán todas las aplicaciones ocultas y se borrarán los datos de la bóveda."
    }

    private fun clearHiddenApps(context: Context) {
        prefs(context).edit().putString("hidden_apps", "").apply()
    }

    private fun nukeVaultData(context: Context) {
        try {
            // Borrar SharedPreferences
            prefs(context).edit().clear().apply()
            // Borrar FlutterSecureStorage (encrypted shared prefs)
            context.getSharedPreferences(
                "FlutterSecureStorage",
                Context.MODE_PRIVATE
            ).edit().clear().apply()
            // Resetear setup
            context.getSharedPreferences(
                "${context.packageName}_preferences",
                Context.MODE_PRIVATE
            ).edit().clear().apply()
        } catch (_: Exception) {}
    }

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences("boveda_prefs", Context.MODE_PRIVATE)
}
