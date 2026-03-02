package com.webvault.app

import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class ClipboardTileService : TileService() {

    companion object {
        var isOverlayActive = false
    }

    override fun onStartListening() {
        super.onStartListening()
        updateTileState()
    }

    override fun onClick() {
        super.onClick()

        if (isOverlayActive) {
            // Send close intent to OverlayService
            val stopIntent = Intent(this, Class.forName(
                "flutter.overlay.window.flutter_overlay_window.OverlayService"
            ))
            stopIntent.putExtra("IsCloseWindow", true)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(stopIntent)
            } else {
                startService(stopIntent)
            }
            isOverlayActive = false
        } else {
            // Launch overlay as a small bubble in bottom-right corner
            val startIntent = Intent(this, Class.forName(
                "flutter.overlay.window.flutter_overlay_window.OverlayService"
            ))
            // Using dp values — OverlayService converts via dpToPx()
            startIntent.putExtra("height", 58)
            startIntent.putExtra("width", 58)
            startIntent.putExtra("enableDrag", true)
            startIntent.putExtra("overlayTitle", "WebVault Clipboard")
            startIntent.putExtra("overlayContent", "Quick clipboard access")
            // flagNotFocusable keeps the bubble non-blocking for other apps
            startIntent.putExtra("flag", "flagNotFocusable")
            // Snap to right edge after drag
            startIntent.putExtra("positionGravity", "auto")
            // Start at bottom-right
            startIntent.putExtra("alignment", "bottomRight")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(startIntent)
            } else {
                startService(startIntent)
            }
            isOverlayActive = true
        }
        updateTileState()
    }

    private fun updateTileState() {
        val tile = qsTile ?: return
        tile.state = if (isOverlayActive) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            tile.subtitle = if (isOverlayActive) "Active" else "Tap to open"
        }
        tile.updateTile()
    }
}
