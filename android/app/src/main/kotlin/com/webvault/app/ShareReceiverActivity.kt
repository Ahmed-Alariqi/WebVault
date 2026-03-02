package com.webvault.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast

/**
 * Invisible Activity that receives shared text from any app via the Android
 * Share Sheet ("Share → WebVault Clipboard").
 *
 * It stores the received text in the Hive database of the main Flutter app.
 * Because this Activity is launched in the same process as the main app,
 * Hive data is fully accessible.
 *
 * android:theme="@android:style/Theme.NoDisplay" makes it invisible to the user.
 */
class ShareReceiverActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val intent = intent
        val type = intent.type

        if (Intent.ACTION_SEND == intent.action && "text/plain" == type) {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
            val sharedSubject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
                ?: intent.getStringExtra(Intent.EXTRA_TITLE)
                ?: "Shared item"

            if (!sharedText.isNullOrBlank()) {
                // Forward the shared text to the main app via a broadcast
                // The main Flutter app will intercept and store it via MainActivity
                val broadcastIntent = Intent("com.webvault.app.SHARE_RECEIVED")
                broadcastIntent.setPackage(packageName)
                broadcastIntent.putExtra("text", sharedText)
                broadcastIntent.putExtra("label", sharedSubject)
                sendBroadcast(broadcastIntent)

                Toast.makeText(this, "✓ Saved to WebVault Clipboard", Toast.LENGTH_SHORT).show()
            }
        }

        finish() // Close immediately — no UI
    }
}
