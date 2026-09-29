package com.sazarcode.enfo.widgets

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** The link between the Flutter app and the widgets (see `widget_bridge.dart`). */
object WidgetChannel {
    private const val NAME = "com.sazarcode.enfo/widgets"

    private var channel: MethodChannel? = null

    /** A tap that reached us before Dart was ready to hear it. */
    private var pending: Map<String, String>? = null

    fun attach(ctx: Context, messenger: BinaryMessenger) {
        val app = ctx.applicationContext
        val ch = MethodChannel(messenger, NAME)
        ch.setMethodCallHandler { call, result -> handle(app, call, result) }
        channel = ch
    }

    /** The intent that started the activity (cold start). */
    fun stash(intent: Intent?) {
        pending = Launch.parse(intent) ?: pending
        Launch.consume(intent)
    }

    /** A tap while the app is already running: tell Dart right away. */
    fun deliver(intent: Intent?) {
        val launch = Launch.parse(intent) ?: return
        Launch.consume(intent)
        pending = launch
        channel?.invokeMethod("launch", launch, object : MethodChannel.Result {
            override fun success(result: Any?) {
                if (pending === launch) pending = null
            }

            override fun error(code: String, message: String?, details: Any?) {}
            override fun notImplemented() {}
        })
    }

    /** Ask Dart (if it is running) to push a fresh snapshot and pictures. */
    fun resync() {
        channel?.invokeMethod("resync", null)
    }

    private fun handle(ctx: Context, call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "framesDir" -> result.success(File(ctx.filesDir, "widget_frames").absolutePath)
            "systemSeed" -> result.success(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    ctx.getColor(android.R.color.system_accent1_500).toLong() and 0xFFFFFFFFL
                } else {
                    null
                },
            )
            "activeKinds" -> result.success(
                Widgets.all.filter { Widgets.ids(ctx, it).isNotEmpty() }.map { it.kind },
            )
            "sync" -> {
                val json = call.arguments as? String
                if (json == null) {
                    result.error("bad_args", "sync expects a JSON string", null)
                } else {
                    SnapStore.save(ctx, json)
                    Widgets.refreshAll(ctx)
                    result.success(null)
                }
            }
            "canPin" -> result.success(
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                    AppWidgetManager.getInstance(ctx).isRequestPinAppWidgetSupported,
            )
            "pin" -> {
                val entry = Widgets.find(call.arguments as? String ?: "")
                if (entry == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                    result.success(false)
                } else {
                    result.success(
                        AppWidgetManager.getInstance(ctx)
                            .requestPinAppWidget(ComponentName(ctx, entry.cls), null, null),
                    )
                }
            }
            "takeLaunch" -> {
                val launch = pending
                pending = null
                result.success(launch)
            }
            else -> result.notImplemented()
        }
    }
}
