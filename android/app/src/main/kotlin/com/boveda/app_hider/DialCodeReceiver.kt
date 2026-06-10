package com.boveda.app_hider

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri

class DialCodeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prefs = prefs(context)
        if (!prefs.getBoolean("access_phone", true)) return

        if (intent.action == "android.provider.Telephony.SECRET_CODE") {
            val host = intent.data?.host ?: return
            if (host == "0000") openVault(context)
            return
        }

        if (intent.action != Intent.ACTION_NEW_OUTGOING_CALL) return

        val dialedNumber = resultData ?: intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER) ?: return
        val secretCode = prefs.getString("dial_code", "*#*#0000#*#*") ?: "*#*#0000#*#*"
        val normalized = dialedNumber.replace("\\s".toRegex(), "").replace("-", "")

        if (normalized == secretCode) {
            resultData = null
            openVault(context)
        }
    }

    private fun openVault(context: Context) {
        val launchIntent = Intent(Intent.ACTION_VIEW, Uri.parse("boveda://open")).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        context.startActivity(launchIntent)
    }

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences("boveda_prefs", Context.MODE_PRIVATE)
}
