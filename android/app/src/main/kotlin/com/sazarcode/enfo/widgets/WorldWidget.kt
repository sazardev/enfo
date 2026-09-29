package com.sazarcode.enfo.widgets

import android.content.Context
import android.view.View
import android.widget.RemoteViews
import com.sazarcode.enfo.R
import java.util.Calendar
import java.util.TimeZone
import kotlin.math.abs

/** The time here and in the user's cities. Each row's clock is a TextClock in that time zone. */
class WorldWidget : EnfoWidget(R.layout.w_world) {

    private class Row(val row: Int, val name: Int, val sub: Int, val time: Int)

    private val rows = listOf(
        Row(R.id.w_r1, R.id.w_r1_name, R.id.w_r1_sub, R.id.w_r1_time),
        Row(R.id.w_r2, R.id.w_r2_name, R.id.w_r2_sub, R.id.w_r2_time),
        Row(R.id.w_r3, R.id.w_r3_name, R.id.w_r3_sub, R.id.w_r3_time),
        Row(R.id.w_r4, R.id.w_r4_name, R.id.w_r4_sub, R.id.w_r4_time),
        Row(R.id.w_r5, R.id.w_r5_name, R.id.w_r5_sub, R.id.w_r5_time),
    )

    override fun build(ctx: Context, snap: Snap?, size: WidgetSize, now: Long, look: Look): RemoteViews {
        val v = RemoteViews(ctx.packageName, R.layout.w_world)
        look.tint(v, R.id.w_bg, Role.SURFACE)

        val cities = snap?.array("world")
        val total = 1 + (cities?.length() ?: 0)
        // About 44 dp a row, minus the padding.
        val fit = ((size.heightDp - 24) / 44).coerceIn(1, rows.size)
        val shown = minOf(total, fit)

        val h24 = snap?.h24
        val local = TimeZone.getDefault()
        for ((i, r) in rows.withIndex()) {
            if (i >= shown) {
                v.setViewVisibility(r.row, View.GONE)
                continue
            }
            v.setViewVisibility(r.row, View.VISIBLE)
            look.text(v, r.name, Role.ON_SURFACE)
            look.text(v, r.sub, Role.VARIANT)
            look.text(v, r.time, Role.ON_SURFACE)

            if (h24 != null) {
                val pattern = if (h24) "HH:mm" else "h:mm a"
                v.setCharSequence(r.time, "setFormat12Hour", pattern)
                v.setCharSequence(r.time, "setFormat24Hour", pattern)
            }

            if (i == 0) {
                v.setTextViewText(r.name, snap?.label("local", "Local") ?: "")
                v.setTextViewText(r.sub, local.id.substringAfterLast('/').replace('_', ' '))
                continue
            }
            val city = cities?.optJSONObject(i - 1) ?: continue
            val zone = city.optString("zone")
            v.setString(r.time, "setTimeZone", zone)
            v.setTextViewText(r.name, city.optString("name"))
            v.setTextViewText(r.sub, offsetLabel(snap, TimeZone.getTimeZone(zone), local, now))
        }

        v.setOnClickPendingIntent(R.id.w_root, Launch.open(ctx, "world"))
        return v
    }

    /** "Tomorrow · +8h": how that city relates to here, computed now so it stays true. */
    private fun offsetLabel(snap: Snap?, zone: TimeZone, local: TimeZone, now: Long): String {
        val there = Calendar.getInstance(zone).apply { timeInMillis = now }
        val here = Calendar.getInstance(local).apply { timeInMillis = now }
        val dayDiff = (there.get(Calendar.YEAR) * 400 + there.get(Calendar.DAY_OF_YEAR)) -
            (here.get(Calendar.YEAR) * 400 + here.get(Calendar.DAY_OF_YEAR))
        val day = when {
            dayDiff > 0 -> snap?.label("tomorrow", "Tomorrow") ?: ""
            dayDiff < 0 -> snap?.label("yesterday", "Yesterday") ?: ""
            else -> ""
        }
        val minutes = (zone.getOffset(now) - local.getOffset(now)) / 60000
        val diff = when {
            minutes == 0 -> ""
            minutes % 60 == 0 -> "${if (minutes > 0) "+" else "-"}${abs(minutes) / 60}h"
            else -> "${if (minutes > 0) "+" else "-"}${abs(minutes) / 60}:${(abs(minutes) % 60).toString().padStart(2, '0')}"
        }
        return listOf(day, diff).filter { it.isNotEmpty() }.joinToString(" · ")
    }
}
