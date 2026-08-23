package com.missingbulb.setlist

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Registered by hand rather than by the generated registrant: the
        // recorder is part of this app, not a published plugin.
        flutterEngine.plugins.add(CaptureRecorder())
    }
}
