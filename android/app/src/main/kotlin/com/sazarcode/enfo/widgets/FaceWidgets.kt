package com.sazarcode.enfo.widgets

import android.content.Context
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import com.sazarcode.enfo.R

/**
 * A countdown drawn as a picture of the user's chosen clock style (one of the
 * 63), with an exact live readout next to it. Narrow widgets show the picture
 * with a small readout under it; wide ones add a side panel with the
 * readout and the play/pause button.
 */
abstract class FaceWidget(
    private val layoutId: Int,
    private val key: String,
    private val mode: String,
    private val toggleAction: String,
) : EnfoWidget(layoutId) {

    /** The line above the readout while the countdown is idle or running. */
    protected abstract fun idleLabel(snap: Snap, countdown: Countdown): String

    /** Extra parts of a specific widget (the timer's presets). */
    protected open fun decorate(
        ctx: Context,
        v: RemoteViews,
        snap: Snap?,
        state: Countdown.State,
        size: WidgetSize,
        look: Look,
    ) {
    }

    override fun build(ctx: Context, snap: Snap?, size: WidgetSize, now: Long, look: Look): RemoteViews {
        val v = RemoteViews(ctx.packageName, layoutId)
        val countdown = Countdown.of(snap, key)
        val state = countdown?.state(now) ?: Countdown.State.IDLE
        val wide = size.widthDp >= 230

        look.tint(v, R.id.w_bg, Role.SURFACE)
        look.text(v, R.id.w_label, Role.VARIANT)
        look.text(v, R.id.w_caption, Role.VARIANT)
        look.text(v, R.id.w_chrono, Role.ON_SURFACE)
        look.tint(v, R.id.w_action_bg, Role.PRIMARY)
        look.tint(v, R.id.w_action_icon, Role.ON_PRIMARY)

        // The picture for this instant. Until the app has rendered any, the
        // layout's placeholder ring stays.
        Frames.pick(countdown?.json, now)?.let {
            v.setImageViewBitmap(R.id.w_face_l, it.light)
            v.setImageViewBitmap(R.id.w_face_d, it.dark)
        }

        if (countdown != null) {
            chronometer(v, R.id.w_chrono, countdown, state, now)
            chronometer(v, R.id.w_caption, countdown, state, now)
        }
        v.setViewVisibility(R.id.w_side, if (wide) View.VISIBLE else View.GONE)
        v.setViewVisibility(R.id.w_caption, if (wide) View.GONE else View.VISIBLE)

        val label = when {
            snap == null || countdown == null -> ctx.getString(R.string.widget_open)
            state == Countdown.State.DONE -> snap.label("timerDone")
            state == Countdown.State.PAUSED -> snap.label("paused")
            else -> idleLabel(snap, countdown)
        }
        v.setTextViewText(R.id.w_label, label)

        v.setImageViewResource(
            R.id.w_action_icon,
            if (state == Countdown.State.RUNNING) R.drawable.w_ic_pause else R.drawable.w_ic_play,
        )
        v.setOnClickPendingIntent(R.id.w_action, Launch.open(ctx, mode, toggleAction))
        v.setOnClickPendingIntent(R.id.w_root, Launch.open(ctx, mode))

        decorate(ctx, v, snap, state, size, look)
        return v
    }

    /** A live countdown while running, a frozen readout otherwise. */
    private fun chronometer(v: RemoteViews, id: Int, c: Countdown, state: Countdown.State, now: Long) {
        // Chronometer bases are on the elapsed-realtime clock, not wall time.
        val base = SystemClock.elapsedRealtime() + c.stillMs(now)
        v.setChronometerCountDown(id, true)
        v.setChronometer(id, base, null, state == Countdown.State.RUNNING)
    }
}

class PomodoroWidget : FaceWidget(R.layout.w_pomodoro, "pomodoro", "pomodoro", "pomodoro_toggle") {
    override fun idleLabel(snap: Snap, countdown: Countdown): String =
        snap.label(if (countdown.rest) "relax" else "focus")
}

class TimerWidget : FaceWidget(R.layout.w_timer, "timer", "timer", "timer_toggle") {
    override fun idleLabel(snap: Snap, countdown: Countdown): String = snap.label("timer")

    private val chips = intArrayOf(R.id.w_chip1, R.id.w_chip2, R.id.w_chip3, R.id.w_chip4)
    private val chipBgs = intArrayOf(R.id.w_chip1_bg, R.id.w_chip2_bg, R.id.w_chip3_bg, R.id.w_chip4_bg)
    private val chipTexts = intArrayOf(R.id.w_chip1_text, R.id.w_chip2_text, R.id.w_chip3_text, R.id.w_chip4_text)

    override fun decorate(
        ctx: Context,
        v: RemoteViews,
        snap: Snap?,
        state: Countdown.State,
        size: WidgetSize,
        look: Look,
    ) {
        // Presets are for starting: only while idle, and only with room.
        val show = state == Countdown.State.IDLE && size.widthDp >= 230 && size.heightDp >= 100
        val presets = snap?.obj("timer")?.optJSONArray("presets")
        if (!show || presets == null || presets.length() == 0) {
            v.setViewVisibility(R.id.w_chips, View.GONE)
            return
        }
        v.setViewVisibility(R.id.w_chips, View.VISIBLE)
        val room = if (size.widthDp < 300) 3 else 4
        for (i in chips.indices) {
            if (i >= presets.length() || i >= room) {
                v.setViewVisibility(chips[i], View.GONE)
                continue
            }
            val seconds = presets.getInt(i)
            v.setViewVisibility(chips[i], View.VISIBLE)
            v.setTextViewText(chipTexts[i], chipLabel(seconds))
            look.tint(v, chipBgs[i], Role.TILE)
            look.text(v, chipTexts[i], Role.ON_SURFACE)
            v.setOnClickPendingIntent(chips[i], Launch.open(ctx, "timer", "timer_start:$seconds"))
        }
    }

    private fun chipLabel(seconds: Int): String = when {
        seconds < 60 -> "${seconds}s"
        seconds % 3600 == 0 -> "${seconds / 3600}h"
        seconds % 60 == 0 && seconds < 3600 -> "${seconds / 60}m"
        seconds < 3600 -> "${seconds / 60}:${(seconds % 60).toString().padStart(2, '0')}"
        else -> "${seconds / 3600}h${(seconds % 3600) / 60}m"
    }
}
