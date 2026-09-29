package com.sazarcode.enfo.widgets

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import com.sazarcode.enfo.MainActivity

/** Taps: open Enfo on a mode, optionally asking it to do something first. */
object Launch {
    const val ACTION = "com.sazarcode.enfo.WIDGET_LAUNCH"
    const val EXTRA_MODE = "widget_mode"
    const val EXTRA_ACTION = "widget_action"

    fun open(ctx: Context, mode: String, action: String? = null): PendingIntent {
        val intent = Intent(ctx, MainActivity::class.java)
            .setAction(ACTION)
            // Pending intents match on action/categories, not extras, so the
            // target is a category to keep each button distinct. (Not a data
            // URI: Flutter would take that for a deep link and route to it.)
            .addCategory("$ACTION.$mode.${action ?: ""}")
            .putExtra(EXTRA_MODE, mode)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (action != null) intent.putExtra(EXTRA_ACTION, action)
        return PendingIntent.getActivity(
            ctx,
            "$mode|$action".hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** What a launch intent asks for, or null if it is not one of ours. */
    fun parse(intent: Intent?): Map<String, String>? {
        if (intent == null || intent.action != ACTION) return null
        val mode = intent.getStringExtra(EXTRA_MODE) ?: return null
        val action = intent.getStringExtra(EXTRA_ACTION)
        return if (action == null) mapOf("mode" to mode) else mapOf("mode" to mode, "action" to action)
    }

    /** Consumes the request so a recreated activity does not replay it. */
    fun consume(intent: Intent?) {
        intent?.removeExtra(EXTRA_MODE)
        intent?.removeExtra(EXTRA_ACTION)
    }
}
