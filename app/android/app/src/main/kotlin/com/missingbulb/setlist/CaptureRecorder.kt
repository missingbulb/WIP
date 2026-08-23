package com.missingbulb.setlist

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.math.max
import kotlin.math.min

/**
 * The Android half of the recording seam.
 *
 * `MediaRecorder` rather than `AudioRecord` (decision D10): nothing analyses
 * while capture runs, so no part of the app needs raw PCM, and the high-level
 * recorder already writes AAC and reports an amplitude. Audio never crosses
 * into Dart — only the path to write, the seconds captured, a level, and the
 * interruption transitions.
 *
 * Unlike iOS there is no interruption callback to subscribe to: under the
 * shared-microphone policy a privileged app may take the input while this
 * recorder keeps running and records silence (risk R9). What that means for
 * requirement 6.6 is unresolved, and is the first thing to settle on a device.
 */
class CaptureRecorder : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private var appContext: Context? = null
    private var recorder: MediaRecorder? = null
    private var events: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())
    private var startedAtMillis = 0L
    private var capturedBeforeThisPart = 0.0

    private val meter = object : Runnable {
        override fun run() {
            val active = recorder ?: return
            events?.success(
                mapOf(
                    "type" to "level",
                    // getMaxAmplitude is 0..32767 and resets on each read, so
                    // this is the loudest sample since the previous tick.
                    "level" to min(1.0, max(0.0, active.maxAmplitude / 32767.0)),
                    "captured" to captured(),
                ),
            )
            handler.postDelayed(this, METER_INTERVAL_MILLIS)
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        MethodChannel(binding.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler(this)
        EventChannel(binding.binaryMessenger, EVENT_CHANNEL).setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stop()
        appContext = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("no-path", "start needs a path", null)
                    return
                }
                runCatching { start(path) }
                    .onSuccess { result.success(null) }
                    .onFailure { result.error("start-failed", it.message, null) }
            }
            "stop" -> {
                stop()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        events = sink
    }

    override fun onCancel(arguments: Any?) {
        events = null
    }

    private fun start(path: String) {
        val file = File(path)
        file.parentFile?.mkdirs()

        val context = appContext
        val active = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && context != null) {
            MediaRecorder(context)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
        active.setAudioSource(MediaRecorder.AudioSource.MIC)
        active.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        active.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        active.setAudioChannels(1)
        active.setAudioSamplingRate(44_100)
        active.setAudioEncodingBitRate(128_000)
        active.setOutputFile(path)
        active.prepare()
        active.start()

        recorder = active
        startedAtMillis = System.currentTimeMillis()
        handler.post(meter)
    }

    private fun stop() {
        handler.removeCallbacks(meter)
        recorder?.let { active ->
            runCatching { active.stop() }
            active.release()
            // The clock counts recorded audio across every part of the show, so
            // what this part captured is carried forward rather than reset.
            capturedBeforeThisPart = captured()
        }
        recorder = null
    }

    private fun captured(): Double =
        if (recorder == null) {
            capturedBeforeThisPart
        } else {
            capturedBeforeThisPart + (System.currentTimeMillis() - startedAtMillis) / 1000.0
        }

    companion object {
        const val METHOD_CHANNEL = "com.missingbulb.setlist/capture"
        const val EVENT_CHANNEL = "com.missingbulb.setlist/capture-events"
        private const val METER_INTERVAL_MILLIS = 100L
    }
}
