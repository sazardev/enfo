package com.sazarcode.enfo.widgets

import android.content.Context
import android.content.res.Configuration
import org.json.JSONArray
import org.json.JSONObject

/**
 * The last state the app pushed (see `widget_snapshot.dart`). This JSON
 * document is the whole contract between Flutter and the widgets: native code
 * never reads Flutter's own preference file.
 */
class Snap(private val json: JSONObject) {
    val lang: String get() = json.optString("lang", "en")

    /** true = force 24 h, false = force 12 h, null = follow the system. */
    val h24: Boolean? = if (json.has("h24") && !json.isNull("h24")) json.optBoolean("h24") else null

    val showDate: Boolean get() = json.optBoolean("showDate", true)

    /** The app chose Material You: use the system colors from resources. */
    val dynamic: Boolean get() = json.optBoolean("dynamic", false)

    /** When the snapshot was taken (wall-clock ms). */
    val at: Long get() = json.optLong("at", 0)

    fun obj(key: String): JSONObject? = json.optJSONObject(key)

    fun array(key: String): JSONArray? = json.optJSONArray(key)

    fun label(key: String, fallback: String = ""): String =
        json.optJSONObject("labels")?.optString(key, fallback) ?: fallback

    fun palette(night: Boolean): Palette? {
        val p = json.optJSONObject("palette")?.optJSONObject(if (night) "dark" else "light")
            ?: return null
        return try {
            Palette(
                surface = p.getLong("surface").toInt(),
                tile = p.getLong("tile").toInt(),
                onSurface = p.getLong("onSurface").toInt(),
                variant = p.getLong("variant").toInt(),
                primary = p.getLong("primary").toInt(),
                onPrimary = p.getLong("onPrimary").toInt(),
                container = p.getLong("container").toInt(),
                onContainer = p.getLong("onContainer").toInt(),
            )
        } catch (e: Exception) {
            null
        }
    }

    companion object {
        fun isNight(ctx: Context): Boolean =
            (ctx.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                Configuration.UI_MODE_NIGHT_YES
    }
}

object SnapStore {
    private const val FILE = "enfo_widgets"
    private const val KEY = "snapshot"

    fun save(ctx: Context, raw: String) {
        ctx.getSharedPreferences(FILE, Context.MODE_PRIVATE).edit().putString(KEY, raw).apply()
    }

    fun load(ctx: Context): Snap? {
        val raw = ctx.getSharedPreferences(FILE, Context.MODE_PRIVATE).getString(KEY, null)
            ?: return null
        return try {
            Snap(JSONObject(raw))
        } catch (e: Exception) {
            null
        }
    }
}

/** Colors the app pushes, used when the system palette is not (or must not be). */
data class Palette(
    val surface: Int,
    val tile: Int,
    val onSurface: Int,
    val variant: Int,
    val primary: Int,
    val onPrimary: Int,
    val container: Int,
    val onContainer: Int,
) {
    fun of(role: Role): Int = when (role) {
        Role.SURFACE -> surface
        Role.TILE -> tile
        Role.ON_SURFACE -> onSurface
        Role.VARIANT -> variant
        Role.PRIMARY -> primary
        Role.ON_PRIMARY -> onPrimary
        Role.CONTAINER -> container
        Role.ON_CONTAINER -> onContainer
    }
}

enum class Role { SURFACE, TILE, ON_SURFACE, VARIANT, PRIMARY, ON_PRIMARY, CONTAINER, ON_CONTAINER }
