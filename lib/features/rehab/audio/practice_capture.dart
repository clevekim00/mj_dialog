import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';
import 'package:speech_rehab/services/audio_analysis/audio_input_stream_service.dart';
import 'package:speech_rehab/services/audio_analysis/voice_signal_analyzer.dart';
import 'package:speech_rehab/services/audio_analysis/wav_file_service.dart';

final practiceCaptureProvider = Provider<PracticeCapture>((ref) {
  final capture = PracticeCapture();
  ref.onDispose(() => unawaited(capture.dispose()));
  return capture;
});

/// A single PCM input drives the display and the complete saved recording.
/// It never opens a second microphone beside the recorder.
class PracticeCapture {
  PracticeCapture({AudioInputStreamService? input, WavFileService? files})
    : _input = input,
      _files = files ?? const WavFileService();
  AudioInputStreamService? _input;
  final WavFileService _files;
  final frame = ValueNotifier<VoiceAnalysisFrame?>(null);
  final problem = ValueNotifier<String?>(null);
  final limitReached = ValueNotifier<bool>(false);
  static const maxSeconds = 120;
  static const sampleRate = 16000;
  static const _frameBytes = 2048;
  final _audio = BytesBuilder(copy: false);
  final _pending = BytesBuilder(copy: false);
  final _analyzer = const VoiceSignalAnalyzer();
  StreamSubscription<Uint8List>? _subscription;
  Timer? _watchdog;
  int _lastWatchBytes = -1;
  Uint8List? _unsaved;
  int _bytes = 0, _samplesAnalyzed = 0;
  bool _running = false, _starting = false, _disposed = false;
  Future<String?>? _stopping;
  String _name = '';
  final List<double> envelope = [];
  bool get hasPendingAudio => _unsaved?.isNotEmpty == true;
  int get durationMs => _bytes * 1000 ~/ (sampleRate * 2);

  Future<void> startRecording(String name) async {
    if (_running || _starting || hasPendingAudio || _stopping != null) {
      throw StateError('Capture is busy or has unsaved audio');
    }
    _starting = true;
    try {
      final input = _input ??= AudioInputStreamService();
      if (!await input.hasPermission()) throw StateError('Microphone denied');
      if (_disposed) throw StateError('Disposed');
      _audio.clear();
      _pending.clear();
      envelope.clear();
      _bytes = 0;
      _samplesAnalyzed = 0;
      _name = name;
      frame.value = null;
      problem.value = null;
      limitReached.value = false;
      final stream = await input.start(sampleRate: sampleRate);
      if (_disposed) {
        await input.stop();
        return;
      }
      _running = true;
      _lastWatchBytes = -1;
      _watchdog = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!_running || _disposed) return;
        if (_bytes == _lastWatchBytes) problem.value = 'stalled';
        _lastWatchBytes = _bytes;
      });
      _subscription = stream.listen(
        _onAudio,
        onError: (Object _) {
          if (!_disposed) problem.value = 'input';
        },
        onDone: () {
          if (_running && !_disposed) problem.value = 'ended';
        },
      );
    } finally {
      _starting = false;
    }
  }

  void _onAudio(Uint8List bytes) {
    if (!_running || _disposed || limitReached.value) return;
    final remaining = maxSeconds * sampleRate * 2 - _bytes;
    final count = bytes.length < remaining ? bytes.length : remaining;
    final copy = Uint8List.fromList(bytes.sublist(0, count));
    _audio.add(copy);
    _pending.add(copy);
    _bytes += copy.length;
    final data = _pending.takeBytes();
    var offset = 0;
    while (data.length - offset >= _frameBytes) {
      _samplesAnalyzed += _frameBytes ~/ 2;
      final next = _analyzer.analyzePcm16(
        Uint8List.sublistView(data, offset, offset + _frameBytes),
        timestamp: Duration(
          microseconds: _samplesAnalyzed * 1000000 ~/ sampleRate,
        ),
        includeSpectrum: false,
      );
      envelope.add(next.peak);
      frame.value = next;
      offset += _frameBytes;
    }
    if (offset < data.length) _pending.add(Uint8List.sublistView(data, offset));
    if (_bytes >= maxSeconds * sampleRate * 2) limitReached.value = true;
  }

  Future<String?> stopRecording() {
    return _stopping ??= _stopAndSave().whenComplete(() => _stopping = null);
  }

  Future<String?> _stopAndSave() async {
    if (_running) {
      _running = false;
      _watchdog?.cancel();
      await _subscription?.cancel();
      _subscription = null;
      try {
        await _input?.stop();
      } finally {
        final bytes = _audio.takeBytes();
        _unsaved = bytes.length.isOdd
            ? Uint8List.sublistView(bytes, 0, bytes.length - 1)
            : bytes;
      }
    }
    final pcm = _unsaved;
    if (pcm == null || pcm.isEmpty) return null;
    final path = await _files.writePcm16(
      pcm,
      fileName: _name,
      sampleRate: sampleRate,
    );
    _unsaved = null;
    return path;
  }

  Future<void> dispose() async {
    _watchdog?.cancel();
    _disposed = true;
    _running = false;
    await _subscription?.cancel();
    await _input?.dispose();
    frame.dispose();
    problem.dispose();
    limitReached.dispose();
  }
}
