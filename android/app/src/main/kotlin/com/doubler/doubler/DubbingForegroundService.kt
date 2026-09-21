package com.doubler.doubler

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

/**
 * Keeps the process — and therefore the Flutter isolate — alive after the user
 * leaves for YouTube. Android 14 also requires this service to be in the
 * foreground *before* [android.media.projection.MediaProjectionManager.getMediaProjection].
 */
class DubbingForegroundService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            DoublerAudioBridge.onNotificationStop()
            stopHeldForeground()
            stopSelf()
            return START_NOT_STICKY
        }
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "DOUBLER"
        val body = intent?.getStringExtra(EXTRA_BODY) ?: ""
        val stop = intent?.getStringExtra(EXTRA_STOP) ?: "Stop"
        val type = intent?.getIntExtra(EXTRA_TYPE, TYPE_MIC) ?: TYPE_MIC
        val started = startHeldForeground(title, body, stop, type)
        acquireWakeLock()
        // Only the intent that asked to be told (capture setup) consumes the
        // callback. A later type upgrade must not steal it.
        if (intent?.getBooleanExtra(EXTRA_NOTIFY, false) == true) {
            val ready = whenForeground
            whenForeground = null
            ready?.invoke(started)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        releaseWakeLock()
        isForeground = false
        super.onDestroy()
    }

    private fun startHeldForeground(title: String, body: String, stop: String, type: Int): Boolean {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "DOUBLER",
                NotificationManager.IMPORTANCE_LOW,
            )
            channel.setShowBadge(false)
            manager.createNotificationChannel(channel)
        }
        val notification = buildNotification(title, body, stop)
        try {
            val typed = serviceType(type)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && typed != 0) {
                startForeground(NOTIFICATION_ID, notification, typed)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            isForeground = true
            return true
        } catch (error: RuntimeException) {
            android.util.Log.e("DoublerAudio", "startForeground failed", error)
            isForeground = false
            return false
        }
    }

    private fun serviceType(type: Int): Int {
        var flags = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            flags = flags or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            (type == TYPE_PLAYBACK || type == TYPE_OUTPUT_PLAYBACK)
        ) {
            flags = flags or ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
        }
        // Dubbed speech has to keep playing after the activity pauses for YouTube.
        // Added only once an AudioTrack is actually playing — Android 14 rejects
        // mediaPlayback if nothing is playing yet. Never attach mediaProjection
        // here unless the user already consented; that type throws otherwise.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            (type == TYPE_OUTPUT || type == TYPE_OUTPUT_PLAYBACK)
        ) {
            flags = flags or ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
        }
        return flags
    }

    private fun buildNotification(title: String, body: String, stop: String): Notification {
        val launch = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        } ?: Intent(this, MainActivity::class.java)
        val content = PendingIntent.getActivity(
            this,
            0,
            launch,
            pendingFlags(),
        )
        val stopIntent = Intent(this, DubbingForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPending = PendingIntent.getService(
            this,
            1,
            stopIntent,
            pendingFlags(),
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_doubler)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(content)
            .addAction(R.drawable.ic_stat_doubler, stop, stopPending)
            .build()
    }

    private fun stopHeldForeground() {
        isForeground = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) {
            return
        }
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "doubler:live").apply {
            setReferenceCounted(false)
            acquire(4 * 60 * 60 * 1000L)
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    companion object {
        const val ACTION_STOP = "com.doubler.doubler.STOP"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_STOP = "stop"
        const val EXTRA_TYPE = "type"
        const val EXTRA_NOTIFY = "notify"
        const val TYPE_MIC = 1
        const val TYPE_PLAYBACK = 2
        const val TYPE_OUTPUT = 3
        const val TYPE_OUTPUT_PLAYBACK = 4
        const val CHANNEL_ID = "doubler_live"
        const val NOTIFICATION_ID = 4401

        @Volatile
        var isForeground: Boolean = false

        var whenForeground: ((Boolean) -> Unit)? = null

        fun pendingFlags(): Int {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        }
    }
}
