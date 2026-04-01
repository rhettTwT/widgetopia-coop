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

class MoodWidgetProvider : HomeWidgetProvider() {

    companion object {
        private val DEFAULT_DOT_COLOR = Color.parseColor("#E0D6F0")
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.mood_widget).apply {
                val moodEmoji = widgetData.getString("mood_emoji", "🤔") ?: "🤔"
                val moodLabel = widgetData.getString("mood_label", "How are you?") ?: "How are you?"
                val moodDescription = widgetData.getString("mood_description", "Tap to check in") ?: "Tap to check in"
                val checkinCount = widgetData.getInt("mood_checkin_count", 0)
                val weekColorsStr = widgetData.getString("mood_week_colors", null)

                setTextViewText(R.id.mood_emoji, moodEmoji)
                setTextViewText(R.id.mood_label, moodLabel)
                setTextViewText(R.id.mood_description, moodDescription)

                // Check-in badge
                val badgeText = if (checkinCount == 1) "1 check-in" else "$checkinCount check-ins"
                setTextViewText(R.id.mood_checkin_badge, badgeText)

                // Week dots — 7 colors for Mon through Sun
                val dotIds = intArrayOf(
                    R.id.mood_dot_0, R.id.mood_dot_1, R.id.mood_dot_2,
                    R.id.mood_dot_3, R.id.mood_dot_4, R.id.mood_dot_5, R.id.mood_dot_6
                )
                val weekColors = weekColorsStr?.split(",")?.map { hex ->
                    try {
                        Color.parseColor(hex.trim())
                    } catch (e: Exception) {
                        DEFAULT_DOT_COLOR
                    }
                } ?: List(7) { DEFAULT_DOT_COLOR }

                for (i in 0..6) {
                    val color = if (i < weekColors.size) weekColors[i] else DEFAULT_DOT_COLOR
                    setInt(dotIds[i], "setColorFilter", color)
                }

                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    data = Uri.parse("widgetopia://mood")
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 4, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
