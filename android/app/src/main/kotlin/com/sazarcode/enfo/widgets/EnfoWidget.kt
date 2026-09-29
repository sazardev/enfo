package com.sazarcode.enfo.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle
import android.widget.RemoteViews

/** How much room a widget has, in dp. */
class WidgetSize(val widthDp: Int, val heightDp: Int) {
    companion object {
        fun of(options: Bundle?): WidgetSize {
            // Before the launcher reports sizes they read 0: assume a roomy one.
            val w = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0) ?: 0
            val h = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0) ?: 0
            return WidgetSize(if (w > 0) w else 250, if (h > 0) h else 110)
        }
    }
}

/**
 * Base for every Enfo widget. Subclasses only describe how to draw
 * themselves from the latest snapshot; scheduling, sizing and error handling
 * are shared.
 */
abstract class EnfoWidget(private val fallbackLayout: Int) : AppWidgetProvider() {

    protected abstract fun build(
        ctx: Context,
        snap: Snap?,
        size: WidgetSize,
        now: Long,
        look: Look,
    ): RemoteViews

    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) push(ctx, mgr, id)
        Ticker.plan(ctx)
    }

    override fun onAppWidgetOptionsChanged(
        ctx: Context,
        mgr: AppWidgetManager,
        id: Int,
        newOptions: Bundle,
    ) {
        push(ctx, mgr, id)
    }

    /** First instance placed: the app (if running) should render its pictures. */
    override fun onEnabled(ctx: Context) {
        WidgetChannel.resync()
    }

    override fun onDeleted(ctx: Context, ids: IntArray) {
        Ticker.plan(ctx)
    }

    override fun onDisabled(ctx: Context) {
        Ticker.plan(ctx)
    }

    private fun push(ctx: Context, mgr: AppWidgetManager, id: Int) {
        val snap = SnapStore.load(ctx)
        val size = WidgetSize.of(mgr.getAppWidgetOptions(id))
        val views = try {
            build(ctx, snap, size, System.currentTimeMillis(), Look(ctx, snap))
        } catch (e: Exception) {
            // A widget that cannot draw must still show something tappable.
            RemoteViews(ctx.packageName, fallbackLayout)
        }
        mgr.updateAppWidget(id, views)
    }
}
