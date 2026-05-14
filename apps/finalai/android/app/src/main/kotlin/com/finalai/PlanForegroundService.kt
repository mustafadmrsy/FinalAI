package com.finalai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class PlanForegroundService : Service() {

    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        private const val CHANNEL_ID = "finalai_plan_fg"
        private const val NOTIFICATION_ID = 9001

        fun start(context: Context, title: String, body: String) {
            val intent = Intent(context, PlanForegroundService::class.java).apply {
                putExtra("title", title)
                putExtra("body", body)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, PlanForegroundService::class.java))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra("title") ?: "Plan hazırlanıyor..."
        val body = intent?.getStringExtra("body") ?: "AI ders planınız oluşturuluyor"

        val notification = buildNotification(title, body)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // Acquire wake lock to prevent CPU sleep
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "finalai:plan_generation").apply {
            acquire(10 * 60 * 1000L) // 10 minutes max
        }

        return START_STICKY
    }

    override fun onDestroy() {
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "AI Plan Oluşturma",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "AI ders planı arka planda oluşturuluyor"
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(title: String, body: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
