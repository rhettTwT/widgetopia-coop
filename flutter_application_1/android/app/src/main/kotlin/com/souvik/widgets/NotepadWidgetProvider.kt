package com.souvik.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class NotepadWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.notepad_widget).apply {
                val title = widgetData.getString("notepad_title", "My Notes") ?: "My Notes"
                val content = widgetData.getString("notepad_content", "Tap to add a note...") ?: "Tap to add a note..."
                val noteType = widgetData.getString("notepad_type", "TEXT") ?: "TEXT"
                val updated = widgetData.getString("notepad_updated", "") ?: ""
                val noteCount = widgetData.getInt("notepad_count", 0)

                setTextViewText(R.id.notepad_title, title)
                setTextViewText(R.id.notepad_type_badge, noteType.uppercase())
                setTextViewText(R.id.notepad_updated, updated)

                if (noteCount > 0) {
                    setTextViewText(R.id.notepad_count, "$noteCount notes")
                } else {
                    setTextViewText(R.id.notepad_count, "")
                }

                // Format content — for checklist, items come as "☑ item|||☐ item"
                if (noteType.equals("LIST", ignoreCase = true)) {
                    val items = content.split("|||").take(5)
                    setTextViewText(R.id.notepad_content, items.joinToString("\n"))
                } else {
                    setTextViewText(R.id.notepad_content, content)
                }

                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    data = Uri.parse("widgetopia://notepad")
                }
                val pendingIntent = PendingIntent.getActivity(
                    context, 5, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
