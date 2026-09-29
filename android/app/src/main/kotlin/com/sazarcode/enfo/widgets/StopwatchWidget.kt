package com.sazarcode.enfo.widgets

import android.content.Context
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import com.sazarcode.enfo.R

/** Start, stop and lap. The chronometer counts by itself while it runs. */
class StopwatchWidget : EnfoWidget(R.layout.w_stopwatch) {
    override fun build(ctx: Context, snap: Snap?, size: WidgetSize, now: Long, look: Look): RemoteViews {
        val v = RemoteViews(ctx.packageName, R.layout.w_stopwatch)
        look.tint(v, R.id.w_bg, Role.SURFACE)
        look.text(v, R.id.w_label, Role.VARIANT)
        look.text(v, R.id.w_chrono, Role.ON_SURFACE)
        look.tint(v, R.id.w_toggle_bg, Role.PRIMARY)
        look.tint(v, R.id.w_toggle_icon, Role.ON_PRIMARY)
        look.tint(v, R.id.w_lap_bg, Role.CONTAINER)
        look.tint(v, R.id.w_lap_icon, Role.ON_CONTAINER)

        val state = snap?.obj("stopwatch")
        val running = state?.optBoolean("running", false) ?: false
        var elapsed: Long = state?.optLong("elapsedMs", 0L) ?: 0L
        // The snapshot's elapsed time was true when it was taken.
        if (running && snap != null) elapsed += maxOf(0L, now - snap.at)

        v.setChronometerCountDown(R.id.w_chrono, false)
        v.setChronometer(R.id.w_chrono, SystemClock.elapsedRealtime() - elapsed, null, running)

        v.setTextViewText(
            R.id.w_label,
            snap?.label("stopwatch") ?: ctx.getString(R.string.widget_open),
        )
        v.setViewVisibility(R.id.w_label, if (size.heightDp < 100) View.GONE else View.VISIBLE)
        v.setImageViewResource(
            R.id.w_toggle_icon,
            if (running) R.drawable.w_ic_pause else R.drawable.w_ic_play,
        )
        // A lap only means something while running.
        v.setViewVisibility(R.id.w_lap, if (running) View.VISIBLE else View.GONE)

        v.setOnClickPendingIntent(R.id.w_toggle, Launch.open(ctx, "stopwatch", "stopwatch_toggle"))
        v.setOnClickPendingIntent(R.id.w_lap, Launch.open(ctx, "stopwatch", "stopwatch_lap"))
        v.setOnClickPendingIntent(R.id.w_root, Launch.open(ctx, "stopwatch"))
        return v
    }
}
