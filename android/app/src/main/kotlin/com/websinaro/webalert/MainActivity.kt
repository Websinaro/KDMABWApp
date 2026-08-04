package com.websinaro.webalert  // keep whatever your actual package already is

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.webalert/dnd"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasDndAccess" -> {
                    val nm = getSystemService(NotificationManager::class.java)
                    result.success(nm.isNotificationPolicyAccessGranted)
                }
                "openDndSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
                    result.success(null)
                }
                "createSosChannel" -> {
                    createSosChannel()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun createSosChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val nm = getSystemService(NotificationManager::class.java)
        val soundUri = Uri.parse("android.resource://" + packageName + "/raw/sos_alarm")

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val channel = NotificationChannel(
            "sos_alerts",
            "SOS Emergency Alerts",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Emergency alerts from your Safety Circle"
            enableVibration(true)
            setSound(soundUri, audioAttributes)
            // This is the actual DND bypass - only takes effect once the
            // user has granted Notification Policy Access (see hasDndAccess
            // / openDndSettings above). It cannot be set silently.
            if (nm.isNotificationPolicyAccessGranted) {
                setBypassDnd(true)
            }
        }

        nm.createNotificationChannel(channel)
    }
}