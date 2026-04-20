import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  return AudioRecorderService();
});

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording(String fileName) async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final recordingsDir = Directory(path.join(directory.path, 'recordings'));
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }

        final filePath = path.join(recordingsDir.path, '$fileName.m4a');
        
        const config = RecordConfig(); // Default config: AAC LC, 44.1kHz, 128kbps, mono

        await _recorder.start(config, path: filePath);
        debugPrint('Recording started: $filePath');
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      debugPrint('Recording stopped. File saved at: $path');
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }

  bool isRecording() {
    // Record version 5.0+ uses an async check or stream, 
    // but we can track state in the provider if needed.
    // For now, keeping it simple.
    return false; // This is a limitation of the current service design, state should be managed.
  }
}
