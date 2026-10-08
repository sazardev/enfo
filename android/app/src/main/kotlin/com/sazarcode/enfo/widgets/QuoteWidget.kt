package com.sazarcode.enfo.widgets

import android.content.Context
import android.widget.RemoteViews
import com.sazarcode.enfo.R
import org.json.JSONObject

/** The focus quote of the day, decorated in the style chosen in Settings. */
class QuoteWidget : EnfoWidget(R.layout.w_quote) {
    override fun build(
        ctx: Context,
        snap: Snap?,
        size: WidgetSize,
        now: Long,
        look: Look,
    ): RemoteViews {
        val v = RemoteViews(ctx.packageName, R.layout.w_quote)
        look.tint(v, R.id.w_bg, Role.SURFACE)
        look.text(v, R.id.w_mark, Role.PRIMARY)
        look.text(v, R.id.w_label, Role.VARIANT)
        look.text(v, R.id.w_quote, Role.ON_SURFACE)
        look.text(v, R.id.w_day, Role.VARIANT)

        val quote = snap?.obj("quote")
        val entry = today(quote, now)
        v.setTextViewText(
            R.id.w_label,
            snap?.label("quote", ctx.getString(R.string.widget_quote_label))
                ?: ctx.getString(R.string.widget_quote_label),
        )
        val text = entry?.optString("text").orEmpty()
        v.setTextViewText(
            R.id.w_quote,
            text.ifEmpty { ctx.getString(R.string.widget_quote_empty) },
        )
        v.setTextViewText(R.id.w_day, entry?.optString("day").orEmpty())

        // Accent style: fill the card with the container color. The palette in
        // the snapshot already follows Material You when the app is set to it.
        if (quote?.optInt("style", 0) == 1) {
            snap.palette(Snap.isNight(ctx))?.let { p ->
                v.setInt(R.id.w_bg, "setColorFilter", p.container)
                v.setTextColor(R.id.w_mark, p.primary)
                v.setTextColor(R.id.w_label, p.onContainer)
                v.setTextColor(R.id.w_quote, p.onContainer)
                v.setTextColor(R.id.w_day, p.onContainer)
            }
        }

        v.setOnClickPendingIntent(R.id.w_root, Launch.open(ctx, "pomodoro"))
        return v
    }

    companion object {
        /**
         * The entry in force at [now]: the latest one whose midnight already
         * passed, the first one otherwise (a snapshot taken today always has
         * one), or null with no snapshot at all.
         */
        fun today(quote: JSONObject?, now: Long): JSONObject? {
            val days = quote?.optJSONArray("days") ?: return null
            var current: JSONObject? = null
            for (i in 0 until days.length()) {
                val entry = days.optJSONObject(i) ?: continue
                if (entry.optLong("at", 0) <= now) current = entry else break
            }
            return current ?: days.optJSONObject(0)
        }

        /**
         * The next midnight that changes the quote, or null once the window
         * has run out (it only rolls forward when the app is opened).
         */
        fun nextChange(quote: JSONObject?, now: Long): Long? {
            val days = quote?.optJSONArray("days") ?: return null
            for (i in 0 until days.length()) {
                val at = days.optJSONObject(i)?.optLong("at", 0) ?: continue
                if (at > now) return at
            }
            return null
        }
    }
}
