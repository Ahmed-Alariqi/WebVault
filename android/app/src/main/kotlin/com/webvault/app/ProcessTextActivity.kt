package com.webvault.app

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.Toast

/**
 * Handles the PROCESS_TEXT intent — appears in the text selection context menu
 * when a user selects text in any app and long-presses (Copy/Paste/Share/WebVault).
 *
 * Saves the selected text to the pending-share queue (same as ShareReceiverActivity).
 * Saves the selected text to the pending-share queue and opens the app to the Share Hub UI.
 */
class ProcessTextActivity : Activity() {

    companion object {
        private const val TAG = "ProcessText"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Intent.ACTION_PROCESS_TEXT == intent.action) {
            val selectedText = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
            } else {
                null
            }

            if (!selectedText.isNullOrBlank()) {
                Log.d(TAG, "Received selected text: $selectedText")
                ShareReceiverActivity.enqueueShare(this, selectedText, "Selected text")
                
                val launchIntent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse("webvault-floating://app/share-hub")).apply {
                    setClass(this@ProcessTextActivity, FloatingAssistantActivity::class.java)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                startActivity(launchIntent)
            } else {
                Log.w(TAG, "Received empty/blank selected text")
            }
        } else {
            Log.w(TAG, "Unexpected action: ${intent.action}")
        }

        finish()
    }
}
