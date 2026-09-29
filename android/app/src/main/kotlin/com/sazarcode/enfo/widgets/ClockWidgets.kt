package com.sazarcode.enfo.widgets

import android.content.Context
import android.view.View
import android.widget.RemoteViews
import com.sazarcode.enfo.R

/** The time and date. TextClock keeps ticking by itself, with no updates from us. */
class ClockWidget : EnfoWidget(R.layout.w_clock) {
    override fun build(ctx: Context, snap: Snap?, size: WidgetSize, now: Long, look: Look): RemoteViews {
        val v = RemoteViews(ctx.packageName, R.layout.w_clock)
        look.tint(v, R.id.w_bg, Role.SURFACE)
        look.text(v, R.id.w_time, Role.ON_SURFACE)
        look.text(v, R.id.w_date, Role.VARIANT)

        // 12 / 24 h: the app's setting when it has one, else the system's.
        val h24 = snap?.h24
        if (h24 != null) {
            val pattern = if (h24) "HH:mm" else "h:mm"
            v.setCharSequence(R.id.w_time, "setFormat12Hour", pattern)
            v.setCharSequence(R.id.w_time, "setFormat24Hour", pattern)
        }

        // AM/PM rides along with the date line; with the date off it stands alone.
        val showDate = snap?.showDate ?: true
        val day = "EEE, d MMM"
        val date12 = if (showDate) "$day · a" else "a"
        val date24 = if (showDate) day else ""
        v.setCharSequence(R.id.w_date, "setFormat12Hour", if (h24 == true) date24 else date12)
        v.setCharSequence(R.id.w_date, "setFormat24Hour", if (h24 == false) date12 else date24)
        // A single-row widget has room for the time only.
        v.setViewVisibility(R.id.w_date, if (size.heightDp < 70) View.GONE else View.VISIBLE)

        v.setOnClickPendingIntent(R.id.w_root, Launch.open(ctx, "clock"))
        return v
    }
}

/** A calm analog clock. */
class AnalogWidget : EnfoWidget(R.layout.w_analog) {
    override fun build(ctx: Context, snap: Snap?, size: WidgetSize, now: Long, look: Look): RemoteViews {
        val v = RemoteViews(ctx.packageName, R.layout.w_analog)
        look.tint(v, R.id.w_bg, Role.SURFACE)
        v.setOnClickPendingIntent(R.id.w_root, Launch.open(ctx, "clock"))
        return v
    }
}
