package com.webvault.app

import android.app.PendingIntent
import android.content.ClipboardManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log

/**
 * Quick Settings tile that opens the main app directly to the AI Assistant page.
 * Reads the clipboard so the assistant can automatically process any copied link or text.
 */
class AiAssistantTileService : TileService() {

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
        Log.d("AiTile", "QS AI tile clicked — launching app to Assistant")

        // 1. Read clipboard content
        var clipText = ""
        try {
            val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
            clipText = clipboard.primaryClip?.getItemAt(0)?.text?.toString() ?: ""
        } catch (e: Exception) {
            Log.e("AiTile", "Failed to read clipboard: ${e.message}")
        }

        // 2. Open app via deep link
        val uriStr = if (clipText.isNotBlank()) {
            "webvault-floating://app/external-ai-assistant?text=${Uri.encode(clipText)}"
        } else {
            "webvault-floating://app/external-ai-assistant"
        }

        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uriStr)).apply {
            setClass(this@AiAssistantTileService, FloatingAssistantActivity::class.java)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                val pendingIntent = PendingIntent.getActivity(
                    this, 1, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                startActivityAndCollapse(pendingIntent)
            } else {
                @Suppress("DEPRECATION")
                startActivityAndCollapse(intent)
            }
        } catch (e: Exception) {
            Log.e("AiTile", "Failed to launch app from tile: ${e.message}")
            try {
                startActivity(intent)
            } catch (e2: Exception) {
                Log.e("AiTile", "Fallback also failed: ${e2.message}")
            }
        }
    }
}
