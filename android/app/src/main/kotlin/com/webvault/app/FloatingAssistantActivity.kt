package com.webvault.app

import android.content.Context
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class FloatingAssistantActivity: FlutterFragmentActivity() {

    private val OVERLAY_CHANNEL = "com.webvault.app/overlay"
    private val TAG = "FloatingActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPendingShares" -> {
                        val prefs = getSharedPreferences(
                            ShareReceiverActivity.PREFS_NAME,
                            Context.MODE_PRIVATE
                        )
                        val queueJson = prefs.getString(ShareReceiverActivity.KEY_PENDING_QUEUE, "[]")
                        val queue = try { JSONArray(queueJson) } catch (e: Exception) { JSONArray() }

                        if (queue.length() > 0) {
                            Log.d(TAG, "FloatingActivity - Found ${queue.length()} pending shares")
                            val items = mutableListOf<Map<String, Any>>()
                            for (i in 0 until queue.length()) {
                                val obj = queue.getJSONObject(i)
                                items.add(mapOf(
                                    "text" to obj.getString("text"),
                                    "label" to obj.getString("label")
                                ))
                            }
                            prefs.edit()
                                .putString(ShareReceiverActivity.KEY_PENDING_QUEUE, "[]")
                                .apply()

                            result.success(items)
                        } else {
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
