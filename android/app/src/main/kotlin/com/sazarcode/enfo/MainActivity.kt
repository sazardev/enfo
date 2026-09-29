package com.sazarcode.enfo

import android.content.Intent
import com.sazarcode.enfo.widgets.WidgetChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WidgetChannel.attach(this, flutterEngine.dartExecutor.binaryMessenger)
        // Started by a tap on a home-screen widget?
        WidgetChannel.stash(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        WidgetChannel.deliver(intent)
    }
}
