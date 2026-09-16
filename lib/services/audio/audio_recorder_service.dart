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
  AudioRecorderService({bool? useIosNative})
    : _useIosNative = useIosNative ?? (!kIsWeb && Platform.isIOS);
  final bool _useIosNative;
  static const MethodChannel _iosRecorderChannel = MethodChannel(
    'speech_rehab/audio_recorder',
  );

  // Native iOS uses the custom channel and must not initialize the separate
  // record plugin merely by constructing this service.
  AudioRecorder? _platformRecorder;
  AudioRecorder get _recorder => _platformRecorder ??= AudioRecorder();
  bool _isRecording = false;

  Future<bool> hasPermission() async {
    if (_useIosNative) {
      return await _iosRecorderChannel.invokeMethod<bool>('hasPermission') ??
          false;
    }

    return await _recorder.hasPermission();
  }

  Future<void> startRecording(String fileName) async {
    try {
      if (!await hasPermission()) {
        throw StateError('마이크 권한이 없어 녹음을 시작하지 못했습니다.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(path.join(directory.path, 'recordings'));
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final filePath = path.join(recordingsDir.path, '$fileName.m4a');

      if (_useIosNative) {
        await _iosRecorderChannel.invokeMethod<void>('start', {
          'path': filePath,
        });
        _isRecording = true;
        debugPrint('Recording started: $filePath');
        return;
      }

      const config =
          RecordConfig(); // Default config: AAC LC, 44.1kHz, 128kbps, mono

      await _recorder.start(config, path: filePath);
      _isRecording = true;
      debugPrint('Recording started: $filePath');
    } catch (e) {
      _isRecording = false;
      debugPrint('Error starting recording: $e');
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (_useIosNative) {
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
    } finally {
      _isRecording = false;
    }
  }

  Future<void> dispose() async {
    _isRecording = false;
    if (_useIosNative) {
      await _iosRecorderChannel.invokeMethod<void>('dispose');
      return;
    }

    await _platformRecorder?.dispose();
    _platformRecorder = null;
  }

  bool isRecording() => _isRecording;
}
