package com.example.mentors_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.mentors_app/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel 초기화
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "createNotificationChannel") {
                    createNotificationChannel()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    // 알림 채널 생성 로직
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "default_channel"
            val channelName = "Default Notifications"
            val channelDescription = "Default Notification Channel for Mentors App"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager?.createNotificationChannel(channel)
        }
    }
}
