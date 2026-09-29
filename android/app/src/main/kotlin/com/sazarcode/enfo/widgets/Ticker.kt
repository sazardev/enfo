package com.sazarcode.enfo.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Wakes the widgets at the next moment something on them changes on its own,
 * with the app closed: the next picture of a running countdown, a countdown
 * finishing, an alarm going past. Everything else on a widget (clocks,
 * chronometers) is driven by the launcher itself and needs no wake-up.
 */
object Ticker {
    private const val ACTION = "com.sazarcode.enfo.WIDGET_TICK"

    private fun intent(ctx: Context): PendingIntent = PendingIntent.getBroadcast(
        ctx,
        0,
        Intent(ctx, TickReceiver::class.java).setAction(ACTION),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /** When the next change is due (ms), or null if nothing is pending. */
    fun nextChange(ctx: Context, snap: Snap?, now: Long): Long? {
        if (snap == null) return null
        var next: Long? = null
        fun consider(t: Long?) {
            if (t != null && t > now && (next == null || t < next!!)) next = t
        }
        for (key in listOf("pomodoro", "timer")) {
            if (!Widgets.has(ctx, key)) continue
            val countdown = Countdown.of(snap, key) ?: continue
            consider(Frames.next(countdown.json, now))
            consider(countdown.endsAt)
        }
        if (Widgets.has(ctx, "alarm")) {
            consider(AlarmWidget.upcoming(snap, now).firstOrNull()?.at?.plus(1000))
        }
        return next
    }

    fun plan(ctx: Context) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()
        val at = nextChange(ctx, SnapStore.load(ctx), now)
        val pending = intent(ctx)
        if (at == null) {
            am.cancel(pending)
            return
        }
        // A hair late, so "now" is safely past the instant being waited for.
        val when_ = at + 250
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !am.canScheduleExactAlarms()) {
                am.setAndAllowWhileIdle(AlarmManager.RTC, when_, pending)
            } else {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC, when_, pending)
            }
        } catch (e: SecurityException) {
            am.set(AlarmManager.RTC, when_, pending)
        }
    }
}

class TickReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        Widgets.refreshAll(ctx)
    }
}
