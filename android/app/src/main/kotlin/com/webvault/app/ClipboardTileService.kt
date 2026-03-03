package com.webvault.app

import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log

/**
 * Quick Settings tile that opens the main app directly to the Clipboard page
 * using a standard deep link.
 */
class ClipboardTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        val tile = qsTile ?: return
        tile.state = Tile.STATE_INACTIVE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = "Tap to open"
        }
        tile.updateTile()
    }

    override fun onClick() {
        super.onClick()
        Log.d("ClipboardTile", "QS tile clicked — launching app to Clipboard")

        // Create an intent to open the app via deep link
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("webvault://app/clipboard")).apply {
            setClass(this@ClipboardTileService, MainActivity::class.java)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                // API 34+: startActivityAndCollapse requires PendingIntent
                val pendingIntent = PendingIntent.getActivity(
                    this, 0, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                startActivityAndCollapse(pendingIntent)
            } else {
                // API < 34: use the Intent overload directly
                @Suppress("DEPRECATION")
                startActivityAndCollapse(intent)
            }
        } catch (e: Exception) {
            Log.e("ClipboardTile", "Failed to launch app from tile: ${e.message}")
            try {
                startActivity(intent)
            } catch (e2: Exception) {
                Log.e("ClipboardTile", "Fallback also failed: ${e2.message}")
            }
        }
    }
}
