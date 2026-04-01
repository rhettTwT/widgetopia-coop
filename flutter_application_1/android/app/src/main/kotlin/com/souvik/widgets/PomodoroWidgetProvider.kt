package com.souvik.widgets

import android.appwidget.AppWidgetManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PomodoroWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.pomodoro_widget).apply {
                val timerStatus = widgetData.getString("pomodoro_status", "Ready to focus") ?: "Ready to focus"
                val timerTime = widgetData.getString("pomodoro_time", "25:00") ?: "25:00"
                val session = widgetData.getInt("pomodoro_session", 1)
                val totalSessions = widgetData.getInt("pomodoro_total_sessions", 4)

                setTextViewText(R.id.pomodoro_time, timerTime)
                setTextViewText(R.id.pomodoro_status, timerStatus)
                setTextViewText(R.id.pomodoro_session, "Session $session of $totalSessions")

                // Status pill color and text
                val pillText: String
                val pillColor: Int
                when {
                    timerStatus.contains("break", ignoreCase = true) -> {
                        pillText = "BREAK"
                        pillColor = Color.parseColor("#4ECDC4")
                    }
                    timerStatus.contains("focus", ignoreCase = true) ||
                    timerStatus.contains("running", ignoreCase = true) -> {
                        pillText = "FOCUS"
                        pillColor = Color.parseColor("#C05272")
                    }
                    timerStatus.contains("pause", ignoreCase = true) -> {
                        pillText = "PAUSED"
                        pillColor = Color.parseColor("#FFB347")
                    }
                    else -> {
                        pillText = "READY"
                        pillColor = Color.parseColor("#9E9E9E")
                    }
                }
                setTextViewText(R.id.pomodoro_status_pill, pillText)
                setInt(R.id.pomodoro_status_pill, "setBackgroundColor", pillColor)

                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    data = Uri.parse("widgetopia://pomodoro")
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 2, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
