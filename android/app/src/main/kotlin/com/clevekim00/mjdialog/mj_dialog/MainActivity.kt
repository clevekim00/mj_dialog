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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "speech_rehab/sentence_ocr")
            .setMethodCallHandler { call, result ->
                if (call.method != "recognize") { result.notImplemented(); return@setMethodCallHandler }
                val path = call.argument<String>("path")
                if (path == null) { result.error("invalid_args", "Missing image.", null); return@setMethodCallHandler }
                val recognizer = if (call.argument<String>("language") == "ko-KR")
                    com.google.mlkit.vision.text.TextRecognition.getClient(com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions.Builder().build())
                else com.google.mlkit.vision.text.TextRecognition.getClient(com.google.mlkit.vision.text.latin.TextRecognizerOptions.DEFAULT_OPTIONS)
                try {
                    val image = com.google.mlkit.vision.common.InputImage.fromFilePath(this, android.net.Uri.fromFile(java.io.File(path)))
                    recognizer.process(image).addOnSuccessListener { result.success(it.text) }
                        .addOnFailureListener { result.error("ocr_failed", "Could not read image.", null) }
                        .addOnCompleteListener { recognizer.close() }
                } catch (e: Exception) { recognizer.close(); result.error("ocr_failed", "Could not open image.", null) }
            }


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
