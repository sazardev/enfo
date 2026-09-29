package com.sazarcode.enfo.widgets

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import org.json.JSONObject

/**
 * Pictures of the user's chosen clock style, rendered by the app (see
 * `widget_frames.dart`), one per instant, in a light and a dark version. The
 * widget shows the one for "now", so a running countdown keeps moving with
 * the app closed.
 */
object Frames {
    class Pick(val light: Bitmap, val dark: Bitmap)

    private fun timeline(countdown: JSONObject?): Pair<JSONObject, List<Long>>? {
        val frames = countdown?.optJSONObject("frames") ?: return null
        val array = frames.optJSONArray("times") ?: return null
        return frames to List(array.length()) { array.getLong(it) }
    }

    /** The picture for [now], or null if there is none (yet). */
    fun pick(countdown: JSONObject?, now: Long): Pick? {
        val (frames, times) = timeline(countdown) ?: return null
        if (times.isEmpty()) return null
        var index = 0
        for (i in times.indices) {
            if (times[i] <= now) index = i else break
        }
        val dir = frames.optString("dir")
        val prefix = frames.optString("prefix")
        val light = BitmapFactory.decodeFile("$dir/${prefix}_l_$index.png") ?: return null
        val dark = BitmapFactory.decodeFile("$dir/${prefix}_d_$index.png") ?: return null
        return Pick(light, dark)
    }

    /** When the picture should change next, if it will. */
    fun next(countdown: JSONObject?, now: Long): Long? =
        timeline(countdown)?.second?.firstOrNull { it > now }
}
