package com.souvik.widgets

import android.appwidget.AppWidgetManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

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
                val streak = widgetData.getInt("habit_streak", 0)
                val namesStr = widgetData.getString("habit_names", null)
                val emojisStr = widgetData.getString("habit_emojis", null)
                val doneStr = widgetData.getString("habit_done", null)

                // Badge
                setTextViewText(R.id.habit_badge, "$completed/$total")

                // Streak
                val streakText = if (streak == 1) "🔥 1 day streak" else "🔥 $streak day streak"
                setTextViewText(R.id.habit_streak, streakText)

                // Progress
                if (total > 0) {
                    val progress = (completed.toFloat() / total.toFloat() * 100).toInt()
                    setProgressBar(R.id.habit_progress, 100, progress, false)
                } else {
                    setProgressBar(R.id.habit_progress, 100, 0, false)
                }

                // Parse habit lists
                val names = namesStr?.split("|||")?.filter { it.isNotEmpty() } ?: emptyList()
                val emojis = emojisStr?.split("|||")?.filter { it.isNotEmpty() } ?: emptyList()
                val done = doneStr?.split("|||")?.map { it == "1" } ?: emptyList()

                val rowIds = intArrayOf(R.id.habit_row_1, R.id.habit_row_2, R.id.habit_row_3)
                val nameIds = intArrayOf(R.id.habit_name_1, R.id.habit_name_2, R.id.habit_name_3)
                val emojiIds = intArrayOf(R.id.habit_emoji_1, R.id.habit_emoji_2, R.id.habit_emoji_3)
                val statusIds = intArrayOf(R.id.habit_status_1, R.id.habit_status_2, R.id.habit_status_3)

                val displayCount = minOf(names.size, 3)
                for (i in 0 until 3) {
                    if (i < displayCount) {
                        setViewVisibility(rowIds[i], View.VISIBLE)
                        setTextViewText(nameIds[i], names[i])
                        setTextViewText(emojiIds[i], if (i < emojis.size) emojis[i] else "🎯")
                        val isDone = if (i < done.size) done[i] else false
                        setTextViewText(statusIds[i], if (isDone) "✓" else "○")
                    } else {
                        setViewVisibility(rowIds[i], View.GONE)
                    }
                }

                // More indicator
                if (names.size > 3) {
                    setViewVisibility(R.id.habit_more, View.VISIBLE)
                    setTextViewText(R.id.habit_more, "+${names.size - 3} more")
                } else {
                    setViewVisibility(R.id.habit_more, View.GONE)
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
