package com.sazarcode.enfo

import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import com.ryanheise.audioservice.AudioServiceActivity
import com.sazarcode.enfo.widgets.WidgetChannel
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WidgetChannel.attach(this, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.sazarcode.enfo/tv"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isTv" -> result.success(isTelevision())
                else -> result.notImplemented()
            }
        }
        // Started by a tap on a home-screen widget?
        WidgetChannel.stash(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        WidgetChannel.deliver(intent)
    }

    /// Android TV and Google TV, including TV devices that do not expose the
    /// Leanback launcher (some operator boxes).
    private fun isTelevision(): Boolean {
        val hasTvFeature =
            packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK) ||
                packageManager.hasSystemFeature(PackageManager.FEATURE_TELEVISION)
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
        val isTvUiMode =
            uiModeManager?.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
        return hasTvFeature || isTvUiMode
    }
}
