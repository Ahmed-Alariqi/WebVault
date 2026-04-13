package com.webvault.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity: FlutterFragmentActivity() {

    private val OVERLAY_CHANNEL = "com.webvault.app/overlay"
    private val TAG = "MainActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPendingShares" -> {
                        // Read the pending share queue from SharedPreferences
                        val prefs = getSharedPreferences(
                            ShareReceiverActivity.PREFS_NAME,
                            Context.MODE_PRIVATE
                        )
                        val queueJson = prefs.getString(ShareReceiverActivity.KEY_PENDING_QUEUE, "[]")
                        val queue = try { JSONArray(queueJson) } catch (e: Exception) { JSONArray() }

                        if (queue.length() > 0) {
                            Log.d(TAG, "Found ${queue.length()} pending shares")

                            // Convert to a list of maps for Flutter
                            val items = mutableListOf<Map<String, Any>>()
                            for (i in 0 until queue.length()) {
                                val obj = queue.getJSONObject(i)
                                items.add(mapOf(
                                    "text" to obj.getString("text"),
                                    "label" to obj.getString("label")
                                ))
                            }

                            // Clear the queue after reading
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

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "webvault_notifications",
                "ZaadTech Notifications",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Push notifications from ZaadTech"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
