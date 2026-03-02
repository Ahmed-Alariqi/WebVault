package com.webvault.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {

    private val OVERLAY_CHANNEL = "com.webvault.app/overlay"

    // Broadcast receiver for text shared from other apps
    private val shareReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val text = intent?.getStringExtra("text") ?: return
            val label = intent.getStringExtra("label") ?: "Shared item"
            Log.d("MainActivity", "Share received: label=$label, text=$text")
            // Notify Flutter via MethodChannel
            flutterEngine?.dartExecutor?.let {
                MethodChannel(it.binaryMessenger, OVERLAY_CHANNEL)
                    .invokeMethod("shareReceived", mapOf("label" to label, "text" to text))
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        // Register broadcast receiver for text sharing
        val filter = IntentFilter("com.webvault.app.SHARE_RECEIVED")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(shareReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(shareReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(shareReceiver)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isOverlayActive" -> result.success(ClipboardTileService.isOverlayActive)
                    else -> result.notImplemented()
                }
            }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "webvault_push",
                "WebVault Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Push notifications from WebVault"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
