import 'package:speech_rehab/services/microphone_access.dart';
import 'dart:async';
import 'dart:math' as math;
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
  final ValueNotifier<int> waveformRevision = ValueNotifier(0);
  final List<double> waveform = [];
  final Stopwatch _waveformClock = Stopwatch();
  int waveformDurationMs = 0;
  Timer? _meterTimer;
  int _meterGeneration = 0;
  bool _readingMeter = false;

  void _startMeter() {
    _stopMeter();
    waveform.clear();
    waveformDurationMs = 0;
    _waveformClock.reset();
    _waveformClock.start();
    waveformRevision.value++;
    final generation = _meterGeneration;
    _meterTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (_readingMeter || !_isRecording) return;
      _readingMeter = true;
      try {
        final db = _useIosNative
            ? await _iosRecorderChannel.invokeMethod<double>('amplitude')
            : (await _recorder.getAmplitude()).current;
        if (generation != _meterGeneration || !_isRecording) return;
        if (db != null && db.isFinite) {
          waveform.add(math.pow(10, db.clamp(-160, 0) / 20).toDouble());
          waveformDurationMs = _waveformClock.elapsedMilliseconds;
          waveformRevision.value++;
        }
      } catch (_) {
        // Metering is optional: a failed visual update must not stop audio.
      } finally {
        _readingMeter = false;
      }
    });
  }

  void _stopMeter() {
    _meterGeneration++;
    _meterTimer?.cancel();
    _meterTimer = null;
    _waveformClock.stop();
  }

  Future<bool> hasPermission() => MicrophoneAccess.ensure(_requestPermission);

  Future<bool> _requestPermission() async {
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
        _startMeter();
        debugPrint('Recording started: $filePath');
        return;
      }

      const config =
          RecordConfig(); // Default config: AAC LC, 44.1kHz, 128kbps, mono

      await _recorder.start(config, path: filePath);
      _isRecording = true;
      _startMeter();
      debugPrint('Recording started: $filePath');
    } catch (e) {
      _isRecording = false;
      debugPrint('Error starting recording: $e');
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    _stopMeter();
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
    _stopMeter();
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
