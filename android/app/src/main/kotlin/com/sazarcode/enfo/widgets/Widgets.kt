package com.sazarcode.enfo.widgets

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context

/** Every widget Enfo offers. The names match `WidgetKind` in Dart. */
object Widgets {
    class Entry(val kind: String, val cls: Class<out EnfoWidget>, val create: () -> EnfoWidget)

    val all: List<Entry> = listOf(
        Entry("clock", ClockWidget::class.java) { ClockWidget() },
        Entry("analog", AnalogWidget::class.java) { AnalogWidget() },
        Entry("pomodoro", PomodoroWidget::class.java) { PomodoroWidget() },
        Entry("timer", TimerWidget::class.java) { TimerWidget() },
        Entry("stopwatch", StopwatchWidget::class.java) { StopwatchWidget() },
        Entry("alarm", AlarmWidget::class.java) { AlarmWidget() },
        Entry("world", WorldWidget::class.java) { WorldWidget() },
        Entry("music", MusicWidget::class.java) { MusicWidget() },
        Entry("focus", FocusWidget::class.java) { FocusWidget() },
    )

    fun ids(ctx: Context, entry: Entry): IntArray =
        AppWidgetManager.getInstance(ctx).getAppWidgetIds(ComponentName(ctx, entry.cls))

    fun has(ctx: Context, kind: String): Boolean =
        all.any { it.kind == kind && ids(ctx, it).isNotEmpty() }

    fun find(kind: String): Entry? = all.firstOrNull { it.kind == kind }

    /** Redraws every placed widget from the latest snapshot. */
    fun refreshAll(ctx: Context) {
        val mgr = AppWidgetManager.getInstance(ctx)
        for (entry in all) {
            val ids = ids(ctx, entry)
            if (ids.isNotEmpty()) entry.create().onUpdate(ctx, mgr, ids)
        }
        Ticker.plan(ctx)
    }
}
