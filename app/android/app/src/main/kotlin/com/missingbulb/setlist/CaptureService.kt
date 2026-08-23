package com.missingbulb.setlist

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * Keeps capture alive while the app is backgrounded and the screen is locked
 * (requirement 6.5).
 *
 * Android cuts microphone access to a backgrounded app unless a foreground
 * service of type `microphone` is running, so this exists for the platform's
 * sake rather than the product's — it holds no recorder of its own.
 *
 * Its persistent notification is not incidental: it is a recording indicator
 * the user cannot dismiss, which is half of what requirement 8.2 asks for and
 * what App Review's equivalent expects of a recording app.
 */
class CaptureService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Recording",
                    // Low: the comedian is on stage, and the set being recorded
                    // is not something to make a sound about.
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
        }

        val notification: Notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Recording your set")
            .setContentText("Set list is recording. Everything stays on your device.")
            .setSmallIcon(android.R.drawable.presence_audio_online)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // Sticky would restart the service without the recorder that gave it a
        // reason to exist, so a killed service stays stopped and the app finds
        // out through the recorder's own state.
        return START_NOT_STICKY
    }

    companion object {
        private const val CHANNEL_ID = "capture"
        private const val NOTIFICATION_ID = 1
    }
}
