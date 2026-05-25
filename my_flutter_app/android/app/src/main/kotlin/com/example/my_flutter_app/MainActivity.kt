package com.example.my_flutter_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.os.Build
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "sip_keep_alive"
	private val incomingChannelId = "sip_incoming_call_channel"
	private val incomingNotificationId = 2402

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
			setShowWhenLocked(true)
			setTurnScreenOn(true)
		} else {
			window.addFlags(
				WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
					WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
					WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
			)
		}
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"start" -> {
						val intent = Intent(this, SipKeepAliveService::class.java)
						if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
							startForegroundService(intent)
						} else {
							startService(intent)
						}
						result.success(null)
					}
					"stop" -> {
						stopService(Intent(this, SipKeepAliveService::class.java))
						result.success(null)
					}
					"bringToFront" -> {
						val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
							?: Intent(this, MainActivity::class.java)

						launchIntent.addFlags(
							Intent.FLAG_ACTIVITY_NEW_TASK or
								Intent.FLAG_ACTIVITY_SINGLE_TOP or
								Intent.FLAG_ACTIVITY_CLEAR_TOP or
								Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
						)
						startActivity(launchIntent)
						result.success(null)
					}
					"showIncomingCallNotification" -> {
						val caller = call.arguments as? String ?: "Unknown"
						showIncomingCallNotification(caller)
						result.success(null)
					}
					"cancelIncomingCallNotification" -> {
						cancelIncomingCallNotification()
						result.success(null)
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun createIncomingCallChannel() {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

		val manager = getSystemService(NotificationManager::class.java)
		val channel = NotificationChannel(
			incomingChannelId,
			"Incoming SIP calls",
			NotificationManager.IMPORTANCE_HIGH,
		).apply {
			description = "Alerts for incoming SIP calls"
			lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
		}
		manager.createNotificationChannel(channel)
	}

	private fun showIncomingCallNotification(caller: String) {
		createIncomingCallChannel()

		val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
			?: Intent(this, MainActivity::class.java)
		launchIntent.addFlags(
			Intent.FLAG_ACTIVITY_NEW_TASK or
				Intent.FLAG_ACTIVITY_SINGLE_TOP or
				Intent.FLAG_ACTIVITY_CLEAR_TOP or
				Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
		)

		val activityPendingIntent = PendingIntent.getActivity(
			this,
			3001,
			launchIntent,
			PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
		)

		val notificationBuilder = NotificationCompat.Builder(this, incomingChannelId)
			.setSmallIcon(android.R.drawable.sym_call_incoming)
			.setContentTitle("Incoming call")
			.setContentText("Call from $caller")
			.setCategory(NotificationCompat.CATEGORY_CALL)
			.setPriority(NotificationCompat.PRIORITY_MAX)
			.setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
			.setOngoing(true)
			.setAutoCancel(false)
			.setContentIntent(activityPendingIntent)

		val manager = getSystemService(NotificationManager::class.java)
		val canUseFullScreen = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
			manager.canUseFullScreenIntent()
		} else {
			true
		}

		if (canUseFullScreen) {
			notificationBuilder.setFullScreenIntent(activityPendingIntent, true)
		} else {
			val settingsIntent = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
				data = android.net.Uri.parse("package:$packageName")
				addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			}
			startActivity(settingsIntent)
		}

		val notification = notificationBuilder.build()

		manager.notify(incomingNotificationId, notification)
	}

	private fun cancelIncomingCallNotification() {
		val manager = getSystemService(NotificationManager::class.java)
		manager.cancel(incomingNotificationId)
	}
}
