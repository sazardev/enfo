package com.sazarcode.enfo.widgets

import android.content.Context
import android.view.View
import android.widget.RemoteViews
import com.sazarcode.enfo.R

/** Today's focus time, pomodoros and streak. */
class FocusWidget : EnfoWidget(R.layout.w_focus) {
    override fun build(ctx: Context, snap: Snap?, size: WidgetSize, now: Long, look: Look): RemoteViews {
        val v = RemoteViews(ctx.packageName, R.layout.w_focus)
        look.tint(v, R.id.w_bg, Role.SURFACE)
        look.text(v, R.id.w_label, Role.VARIANT)
        look.text(v, R.id.w_value, Role.ON_SURFACE)
        look.text(v, R.id.w_detail, Role.VARIANT)
        look.text(v, R.id.w_streak, Role.PRIMARY)

        val focus = snap?.obj("focus")
        v.setTextViewText(
            R.id.w_label,
            snap?.label("focus") ?: ctx.getString(R.string.widget_focus_label),
        )
        v.setTextViewText(R.id.w_value, focus?.optString("today", "0m") ?: "0m")
        v.setTextViewText(R.id.w_detail, focus?.optString("detail", "") ?: "")

        val streak = focus?.optString("streak", "") ?: ""
        v.setViewVisibility(R.id.w_streak, if (streak.isEmpty()) View.GONE else View.VISIBLE)
        v.setTextViewText(R.id.w_streak, streak)

        v.setOnClickPendingIntent(R.id.w_root, Launch.open(ctx, "pomodoro"))
        return v
    }
}
