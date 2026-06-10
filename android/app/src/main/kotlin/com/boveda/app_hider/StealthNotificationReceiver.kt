package com.boveda.app_hider

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class StealthNotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TAP) return

        val prefs = context.getSharedPreferences("boveda_prefs", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("access_notification", true)) return
        val now = System.currentTimeMillis()
        val firstTap = prefs.getLong("stealth_first_tap", 0L)
        val count = if (now - firstTap <= TAP_WINDOW_MS) {
            prefs.getInt("stealth_tap_count", 0) + 1
        } else {
            1
        }

        prefs.edit()
            .putLong("stealth_first_tap", if (count == 1) now else firstTap)
            .putInt("stealth_tap_count", count)
            .apply()

        if (count >= 3) {
            prefs.edit().remove("stealth_first_tap").remove("stealth_tap_count").apply()
            val launchIntent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse("boveda://open")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            context.startActivity(launchIntent)
        }
    }

    companion object {
        const val ACTION_TAP = "com.boveda.app_hider.STEALTH_NOTIFICATION_TAP"
        private const val TAP_WINDOW_MS = 1400L
    }
}
