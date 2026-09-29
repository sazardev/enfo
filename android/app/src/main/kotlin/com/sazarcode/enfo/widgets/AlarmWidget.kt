package com.sazarcode.enfo.widgets

import android.content.Context
import android.view.View
import android.widget.RemoteViews
import com.sazarcode.enfo.R
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/** Your next alarms. The app pushes several upcoming rings, so it stays right after one passes. */
class AlarmWidget : EnfoWidget(R.layout.w_alarm) {

    class Occurrence(val at: Long, val time: String, val repeat: String, val label: String)

    override fun build(ctx: Context, snap: Snap?, size: WidgetSize, now: Long, look: Look): RemoteViews {
        val v = RemoteViews(ctx.packageName, R.layout.w_alarm)
        look.tint(v, R.id.w_bg, Role.SURFACE)
        look.tint(v, R.id.w_icon, Role.PRIMARY)
        look.text(v, R.id.w_label, Role.VARIANT)
        look.text(v, R.id.w_time, Role.ON_SURFACE)
        look.text(v, R.id.w_sub, Role.VARIANT)
        look.text(v, R.id.w_more1, Role.ON_SURFACE)
        look.text(v, R.id.w_more2, Role.ON_SURFACE)

        v.setTextViewText(
            R.id.w_label,
            snap?.label("alarm") ?: ctx.getString(R.string.widget_open),
        )
        val next = upcoming(snap, now)
        val first = next.firstOrNull()
        if (snap == null || first == null) {
            v.setTextViewText(R.id.w_time, "—")
            v.setTextViewText(R.id.w_sub, snap?.label("noAlarms") ?: "")
            v.setViewVisibility(R.id.w_more, View.GONE)
        } else {
            v.setTextViewText(R.id.w_time, first.time)
            v.setTextViewText(R.id.w_sub, describe(snap, first, now))
            val roomy = size.heightDp >= 130
            v.setViewVisibility(R.id.w_more, if (roomy && next.size > 1) View.VISIBLE else View.GONE)
            for ((i, id) in intArrayOf(R.id.w_more1, R.id.w_more2).withIndex()) {
                val other = next.getOrNull(i + 1)
                v.setViewVisibility(id, if (other == null) View.GONE else View.VISIBLE)
                if (other != null) v.setTextViewText(id, "${other.time} · ${dayLabel(snap, other.at, now)}")
            }
        }
        v.setViewVisibility(R.id.w_label, if (size.heightDp < 70) View.GONE else View.VISIBLE)
        v.setOnClickPendingIntent(R.id.w_root, Launch.open(ctx, "alarm"))
        return v
    }

    private fun describe(snap: Snap, o: Occurrence, now: Long): String =
        listOf(dayLabel(snap, o.at, now), o.repeat, o.label).filter { it.isNotBlank() }.joinToString(" · ")

    companion object {
        /** The rings still ahead of [now], soonest first. */
        fun upcoming(snap: Snap?, now: Long): List<Occurrence> {
            val array = snap?.array("alarms") ?: return emptyList()
            val all = ArrayList<Occurrence>()
            for (i in 0 until array.length()) {
                val o = array.optJSONObject(i) ?: continue
                val at = o.optLong("at", 0)
                if (at <= now) continue
                all.add(Occurrence(at, o.optString("time"), o.optString("repeat"), o.optString("label")))
            }
            return all.sortedBy { it.at }
        }

        /** "Today", "Tomorrow", or the weekday: worked out now, so it never goes stale. */
        fun dayLabel(snap: Snap, at: Long, now: Long): String {
            val today = Calendar.getInstance().apply { timeInMillis = now }
            val day = Calendar.getInstance().apply { timeInMillis = at }
            val diff = dayNumber(day) - dayNumber(today)
            return when {
                diff <= 0 -> snap.label("today", "Today")
                diff == 1 -> snap.label("tomorrow", "Tomorrow")
                else -> SimpleDateFormat("EEE", Locale(snap.lang)).format(Date(at))
            }
        }

        private fun dayNumber(c: Calendar): Int = c.get(Calendar.YEAR) * 400 + c.get(Calendar.DAY_OF_YEAR)
    }
}
