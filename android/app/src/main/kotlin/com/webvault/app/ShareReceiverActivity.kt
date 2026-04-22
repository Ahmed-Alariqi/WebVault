package com.webvault.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import org.json.JSONArray
import org.json.JSONObject

/**
 * Invisible Activity that receives shared text from any app via the Android
 * Share Sheet ("Share → WebVault Clipboard").
 *
 * Saves the shared text to a pending-share queue in SharedPreferences.
 * Saves the shared text to a pending-share queue in SharedPreferences,
 * then opens the main app to the Share Hub UI.
 */
class ShareReceiverActivity : Activity() {

    companion object {
        private const val TAG = "ShareReceiver"
        const val PREFS_NAME = "share_pending"
        const val KEY_PENDING_QUEUE = "pending_queue"

        /**
         * Enqueues a shared text item into the persistent pending queue.
         * Supports multiple items being queued before the app opens.
         */
        fun enqueueShare(context: Context, text: String, label: String) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existingJson = prefs.getString(KEY_PENDING_QUEUE, "[]")
            val queue = try { JSONArray(existingJson) } catch (e: Exception) { JSONArray() }

            val item = JSONObject().apply {
                put("text", text)
                put("label", label)
                put("timestamp", System.currentTimeMillis())
            }
            queue.put(item)

            prefs.edit().putString(KEY_PENDING_QUEUE, queue.toString()).commit()
            Log.d(TAG, "Enqueued share item. Queue size: ${queue.length()}")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND == action && "text/plain" == type) {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
            val sharedSubject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
                ?: intent.getStringExtra(Intent.EXTRA_TITLE)
                ?: "Shared item"

            if (!sharedText.isNullOrBlank()) {
                Log.d(TAG, "Received shared text: label=$sharedSubject")
                enqueueShare(this, sharedText, sharedSubject)
                
                // Launch the app to the Share Hub deep link
                val launchIntent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse("webvault-floating://app/share-hub")).apply {
                    setClass(this@ShareReceiverActivity, FloatingAssistantActivity::class.java)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                startActivity(launchIntent)
            } else {
                Log.w(TAG, "Received empty/blank shared text")
            }
        } else {
            Log.w(TAG, "Unexpected action=$action or type=$type")
        }

        finish()
    }
}
