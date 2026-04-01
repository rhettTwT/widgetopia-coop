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

class HabitHeatmapWidgetProvider : HomeWidgetProvider() {

    companion object {
        // GitHub-style green palette
        private val HEAT_COLORS = intArrayOf(
            Color.parseColor("#161B22"), // Level 0 - empty
            Color.parseColor("#0E4429"), // Level 1 - light
            Color.parseColor("#006D32"), // Level 2 - medium
            Color.parseColor("#26A641"), // Level 3 - bright
            Color.parseColor("#39D353")  // Level 4 - vivid
        )

        // Cell ID mapping: cell_row_col
        // We build this at runtime to avoid 49 hardcoded constants
        private fun getCellId(context: Context, row: Int, col: Int): Int {
            val name = "cell_${row}_${col}"
            return context.resources.getIdentifier(name, "id", context.packageName)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.habit_heatmap_widget).apply {

                // Read heatmap data: 49 comma-separated heat levels (0-4)
                val heatmapStr = widgetData.getString("heatmap_data", null)
                val heatLevels = if (heatmapStr != null) {
                    heatmapStr.split(",").map { it.trim().toIntOrNull() ?: 0 }
                } else {
                    List(49) { 0 }
                }

                // Read stats
                val streak = widgetData.getInt("habit_streak", 0)
                val totalHabits = widgetData.getInt("habit_total_count", 0)
                val completedToday = widgetData.getInt("habit_completed_today", 0)

                // Update header
                val streakText = if (streak == 1) "🔥 1 day streak" else "🔥 $streak day streak"
                setTextViewText(R.id.streak_badge, streakText)

                // Update stats
                val totalText = if (totalHabits == 1) "1 habit" else "$totalHabits habits"
                setTextViewText(R.id.stat_total, totalText)
                setTextViewText(R.id.stat_today, "$completedToday done today")

                // Color the 49 grid cells
                // Data is stored column-major: index = col * 7 + row
                // (column = week, row = day of week)
                for (row in 0..6) {
                    for (col in 0..6) {
                        val dataIndex = col * 7 + row
                        val level = if (dataIndex < heatLevels.size) {
                            heatLevels[dataIndex].coerceIn(0, 4)
                        } else {
                            0
                        }
                        val cellId = getCellId(context, row, col)
                        if (cellId != 0) {
                            setInt(cellId, "setColorFilter", HEAT_COLORS[level])
                        }
                    }
                }

                // Tap intent: open habit tracker screen
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    data = Uri.parse("widgetopia://habit")
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 6, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
