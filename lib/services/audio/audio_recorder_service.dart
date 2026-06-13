import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  return AudioRecorderService();
});

class AudioRecorderService {
  static const MethodChannel _iosRecorderChannel = MethodChannel(
    'speech_rehab/audio_recorder',
  );

  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() async {
    if (Platform.isIOS) {
      return await _iosRecorderChannel.invokeMethod<bool>('hasPermission') ??
          false;
    }

    return await _recorder.hasPermission();
  }

  Future<void> startRecording(String fileName) async {
    try {
      if (!await hasPermission()) {
        debugPrint('Recording permission was not granted.');
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(path.join(directory.path, 'recordings'));
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final filePath = path.join(recordingsDir.path, '$fileName.m4a');

      if (Platform.isIOS) {
        await _iosRecorderChannel.invokeMethod<void>('start', {
          'path': filePath,
        });
        debugPrint('Recording started: $filePath');
        return;
      }

      const config =
          RecordConfig(); // Default config: AAC LC, 44.1kHz, 128kbps, mono

      await _recorder.start(config, path: filePath);
      debugPrint('Recording started: $filePath');
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (Platform.isIOS) {
        final path = await _iosRecorderChannel.invokeMethod<String>('stop');
        debugPrint('Recording stopped. File saved at: $path');
        return path;
      }

      final path = await _recorder.stop();
      debugPrint('Recording stopped. File saved at: $path');
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    if (Platform.isIOS) {
      await _iosRecorderChannel.invokeMethod<void>('dispose');
      return;
    }

    await _recorder.dispose();
  }

  bool isRecording() {
    // Record version 5.0+ uses an async check or stream,
    // but we can track state in the provider if needed.
    // For now, keeping it simple.
    return false; // This is a limitation of the current service design, state should be managed.
  }
}
