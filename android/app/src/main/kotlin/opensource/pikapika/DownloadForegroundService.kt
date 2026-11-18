package opensource.pikapika

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

class DownloadForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null || intent.action == ACTION_CANCEL) {
            stopSelf()
            return START_NOT_STICKY
        }
        val title = intent.getStringExtra(EXTRA_TITLE) ?: ""
        val body = intent.getStringExtra(EXTRA_BODY) ?: ""
        val notification = buildNotification(this, title, body)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        running = true
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        running = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    companion object {
        const val ACTION_SHOW = "opensource.pikapika.DOWNLOAD_NOTICE_SHOW"
        const val ACTION_CANCEL = "opensource.pikapika.DOWNLOAD_NOTICE_CANCEL"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        private const val CHANNEL_ID = "download_persistent"
        const val NOTIFICATION_ID = 0x504B

        @Volatile
        var running = false

        fun update(context: Context, title: String, body: String) {
            val manager = context.getSystemService(NotificationManager::class.java)
            ensureChannel(manager)
            manager.notify(NOTIFICATION_ID, buildNotification(context, title, body))
        }

        private fun ensureChannel(manager: NotificationManager) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                return
            }
            val channel = NotificationChannel(
                CHANNEL_ID,
                "下载",
                NotificationManager.IMPORTANCE_LOW,
            )
            channel.setShowBadge(false)
            channel.setSound(null, null)
            manager.createNotificationChannel(channel)
        }

        private fun buildNotification(context: Context, title: String, body: String): Notification {
            val manager = context.getSystemService(NotificationManager::class.java)
            ensureChannel(manager)
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            launch.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pending = PendingIntent.getActivity(context, 0, launch, pendingFlags)
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }
            builder
                .setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(R.drawable.ic_stat_download)
                .setOngoing(true)
                .setContentIntent(pending)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                builder.setOnlyAlertOnce(true)
            }
            return builder.build()
        }
    }
}
