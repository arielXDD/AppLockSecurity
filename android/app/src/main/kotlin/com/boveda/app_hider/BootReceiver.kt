package com.boveda.app_hider

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON") {
            return
        }
        val prefs = context.getSharedPreferences("boveda_prefs", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("access_notification", true)) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                MainActivity.CHANNEL_ID,
                "Sistema Android",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Estado de optimizacion del sistema"
                setShowBadge(false)
            }
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        val tapIntent = Intent(context, StealthNotificationReceiver::class.java).apply {
            this.action = StealthNotificationReceiver.ACTION_TAP
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            10,
            tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(context, MainActivity.CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_calculator)
            .setContentTitle("Sistema Android")
            .setContentText("Optimizando servicios...")
            .setOngoing(true)
            .setSilent(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        NotificationManagerCompat.from(context).notify(MainActivity.STEALTH_NOTIFICATION_ID, notification)
    }
}
