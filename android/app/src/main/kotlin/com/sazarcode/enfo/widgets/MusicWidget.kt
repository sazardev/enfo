package com.sazarcode.enfo.widgets

import android.content.Context
import android.widget.RemoteViews
import com.sazarcode.enfo.R

/** The current song with play/pause, previous and next. */
class MusicWidget : EnfoWidget(R.layout.w_music) {
    override fun build(ctx: Context, snap: Snap?, size: WidgetSize, now: Long, look: Look): RemoteViews {
        val v = RemoteViews(ctx.packageName, R.layout.w_music)
        look.tint(v, R.id.w_bg, Role.SURFACE)
        look.text(v, R.id.w_label, Role.VARIANT)
        look.text(v, R.id.w_title, Role.ON_SURFACE)
        look.text(v, R.id.w_artist, Role.VARIANT)
        look.tint(v, R.id.w_toggle_bg, Role.PRIMARY)
        look.tint(v, R.id.w_toggle_icon, Role.ON_PRIMARY)
        look.tint(v, R.id.w_prev_bg, Role.CONTAINER)
        look.tint(v, R.id.w_prev_icon, Role.ON_CONTAINER)
        look.tint(v, R.id.w_next_bg, Role.CONTAINER)
        look.tint(v, R.id.w_next_icon, Role.ON_CONTAINER)

        val music = snap?.obj("music")
        val playing = music?.optBoolean("playing", false) ?: false
        val hasSong = music?.optBoolean("hasSong", false) ?: false
        val title = music?.optString("title", "") ?: ""
        val artist = music?.optString("artist", "") ?: ""

        v.setTextViewText(
            R.id.w_label,
            snap?.label("music") ?: ctx.getString(R.string.widget_music_label),
        )
        v.setTextViewText(
            R.id.w_title,
            if (hasSong) title else ctx.getString(R.string.widget_open),
        )
        v.setTextViewText(R.id.w_artist, if (hasSong) artist else "")
        v.setImageViewResource(
            R.id.w_toggle_icon,
            if (playing) R.drawable.w_ic_pause else R.drawable.w_ic_play,
        )

        v.setOnClickPendingIntent(R.id.w_toggle, Launch.open(ctx, "music", "music_toggle"))
        v.setOnClickPendingIntent(R.id.w_prev, Launch.open(ctx, "music", "music_prev"))
        v.setOnClickPendingIntent(R.id.w_next, Launch.open(ctx, "music", "music_next"))
        v.setOnClickPendingIntent(R.id.w_root, Launch.open(ctx, "music"))
        return v
    }
}
