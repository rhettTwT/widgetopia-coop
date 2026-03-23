package com.example.flutter_application_1

import android.appwidget.AppWidgetManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import com.souvik.widgets.R

class HabitWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.habit_widget).apply {
                val completed = widgetData.getInt("habit_completed", 0)
                val total = widgetData.getInt("habit_total", 0)
                
                setTextViewText(R.id.habit_text, "Completed: $completed / $total")
                
                if (total > 0) {
                    val progress = (completed.toFloat() / total.toFloat() * 100).toInt()
                    setProgressBar(R.id.habit_progress, 100, progress, false)
                } else {
                    setProgressBar(R.id.habit_progress, 100, 0, false)
                }

                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    data = Uri.parse("widgetopia://habit")
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 3, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
