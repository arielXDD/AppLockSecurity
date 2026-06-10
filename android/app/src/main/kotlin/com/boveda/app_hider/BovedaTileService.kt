package com.boveda.app_hider

import android.app.PendingIntent
import android.content.Context
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.content.Intent
import android.net.Uri
import android.os.Build

class BovedaTileService : TileService() {
    override fun onStartListening() {
        qsTile?.apply {
            label = "Ahorro de datos"
            state = Tile.STATE_INACTIVE
            updateTile()
        }
    }

    override fun onClick() {
        val enabled = getSharedPreferences("boveda_prefs", Context.MODE_PRIVATE)
            .getBoolean("access_quick_tile", true)
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            updateTile()
        }
        if (!enabled) return
        
        // Lanza el deep link boveda://open
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("boveda://open")).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        if (Build.VERSION.SDK_INT >= 34) {
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
