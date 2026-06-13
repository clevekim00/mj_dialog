package com.clevekim00.mjdialog.mj_dialog

import android.media.MediaPlayer
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var mediaPlayer: MediaPlayer? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "speech_rehab/audio_player"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "playFile" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("invalid_args", "Missing audio path.", null)
                    } else {
                        playFile(path, result)
                    }
                }
                "stop" -> {
                    stopPlayback()
                    result.success(null)
                }
                "pause" -> {
                    mediaPlayer?.pause()
                    result.success(null)
                }
                "resume" -> {
                    mediaPlayer?.start()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "speech_rehab/audio_player/events"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun playFile(path: String, result: MethodChannel.Result) {
        try {
            stopPlayback()
            mediaPlayer = MediaPlayer().apply {
                setDataSource(path)
                setOnCompletionListener {
                    eventSink?.success("complete")
                }
                prepare()
                start()
            }
            result.success(null)
        } catch (error: Exception) {
            result.error("playback_failed", "Failed to play audio file.", error.localizedMessage)
        }
    }

    private fun stopPlayback() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
    }

    override fun onDestroy() {
        stopPlayback()
        super.onDestroy()
    }
}
