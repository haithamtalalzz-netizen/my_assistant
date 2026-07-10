package com.hhub.my_assistant

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class MyAssistantWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.my_assistant_widget).apply {
                setTextViewText(
                    R.id.widget_prayer,
                    widgetData.getString("line_prayer", "افتح التطبيق لتحديث البيانات") ?: ""
                )
                setTextViewText(
                    R.id.widget_appts,
                    widgetData.getString("line_appts", "") ?: ""
                )
                setTextViewText(
                    R.id.widget_water,
                    widgetData.getString("line_water", "") ?: ""
                )
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                )
                setOnClickPendingIntent(
                    R.id.widget_water_add,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        Uri.parse("myassistant://water/add")
                    )
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
