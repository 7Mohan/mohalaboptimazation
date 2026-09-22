package com.mohalab.optimization

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MohaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.moha_widget).apply {
                val profile = widgetData.getString("widget_profile", "Balanced") ?: "Balanced"
                val status = widgetData.getString("widget_status", "SAFE MODE") ?: "SAFE MODE"
                val metrics = widgetData.getString("widget_metrics", "Optimized for daily gaming") ?: "Optimized for daily gaming"

                setTextViewText(R.id.widget_profile, "Profile: $profile")
                setTextViewText(R.id.widget_status, status)
                setTextViewText(R.id.widget_metrics, metrics)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
