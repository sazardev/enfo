package com.sazarcode.enfo.widgets

import android.content.Context
import android.os.Build
import android.widget.RemoteViews

/**
 * Colors for one update. On Android 12+ with Material You on, the layouts
 * already point at the system palette through `@color/w_*` (and the launcher
 * re-tints them by itself when the wallpaper or theme changes), so nothing
 * needs to be done here. Otherwise the palette Enfo pushed is applied on top
 * of the layouts' defaults.
 */
class Look(ctx: Context, snap: Snap?) {
    private val palette: Palette? =
        if (snap != null && (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || !snap.dynamic)) {
            snap.palette(Snap.isNight(ctx))
        } else {
            null
        }

    /** A shape or vector drawn in a single role color. */
    fun tint(views: RemoteViews, id: Int, role: Role) {
        palette?.let { views.setInt(id, "setColorFilter", it.of(role)) }
    }

    fun text(views: RemoteViews, id: Int, role: Role) {
        palette?.let { views.setTextColor(id, it.of(role)) }
    }
}
