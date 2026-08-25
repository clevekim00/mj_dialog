import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';
import 'package:speech_rehab/services/audio_analysis/audio_input_stream_service.dart';
import 'package:speech_rehab/services/audio_analysis/voice_signal_analyzer.dart';

enum VoiceAnalysisStatus {
  idle,
  requestingPermission,
  listening,
  stopped,
  error,
}

class VoiceAnalysisController extends ChangeNotifier {
  VoiceAnalysisController({
    AudioInputStreamService? input,
    VoiceSignalAnalyzer? analyzer,
    this.sampleRate = 16000,
  }) : _input = input ?? AudioInputStreamService(),
       _analyzer = analyzer ?? const VoiceSignalAnalyzer();

  final AudioInputStreamService _input;
  final VoiceSignalAnalyzer _analyzer;
  final int sampleRate;
  final List<VoiceAnalysisFrame> _frames = [];
  final BytesBuilder _pending = BytesBuilder(copy: false);
  final List<Uint8List> _ringChunks = [];
  StreamSubscription<Uint8List>? _subscription;
  Stopwatch? _watch;
  int _ringBytes = 0;

  VoiceAnalysisStatus status = VoiceAnalysisStatus.idle;
  VoiceAnalysisFrame? latestFrame;
  String? errorMessage;

  List<VoiceAnalysisFrame> get frames => List.unmodifiable(_frames);
  int get maxRingBytes => sampleRate * 2 * 10;

  Future<void> start() async {
    if (status == VoiceAnalysisStatus.listening) return;
    status = VoiceAnalysisStatus.requestingPermission;
    errorMessage = null;
    notifyListeners();
    try {
      if (!await _input.hasPermission()) {
        status = VoiceAnalysisStatus.error;
        errorMessage = '마이크 권한이 필요합니다.';
        notifyListeners();
        return;
      }
      _frames.clear();
      _ringChunks.clear();
      _ringBytes = 0;
      _watch = Stopwatch()..start();
      final stream = await _input.start(sampleRate: sampleRate);
      _subscription = stream.listen(
        _onAudio,
        onError: (Object error) {
          status = VoiceAnalysisStatus.error;
          errorMessage = '마이크 입력을 분석할 수 없습니다.';
          notifyListeners();
        },
      );
      status = VoiceAnalysisStatus.listening;
      notifyListeners();
    } catch (_) {
      status = VoiceAnalysisStatus.error;
      errorMessage = '다른 음성 기능을 종료한 뒤 다시 시도해 주세요.';
      notifyListeners();
    }
  }

  void _onAudio(Uint8List bytes) {
    _appendRing(bytes);
    _pending.add(bytes);
    final all = _pending.takeBytes();
    const frameBytes = 2048;
    var offset = 0;
    while (all.length - offset >= frameBytes) {
      final chunk = Uint8List.sublistView(all, offset, offset + frameBytes);
      final recentNoise = _frames.isEmpty
          ? -80.0
          : _frames
                .take(20)
                .map((frame) => frame.dbfs)
                .reduce((a, b) => a < b ? a : b);
      final frame = _analyzer.analyzePcm16(
        chunk,
        timestamp: _watch?.elapsed ?? Duration.zero,
        noiseFloorDbfs: recentNoise,
      );
      _frames.add(frame);
      latestFrame = frame;
      offset += frameBytes;
    }
    if (offset < all.length) _pending.add(Uint8List.sublistView(all, offset));
    if (_frames.length % 2 == 0) notifyListeners();
  }

  void _appendRing(Uint8List bytes) {
    final copy = Uint8List.fromList(bytes);
    _ringChunks.add(copy);
    _ringBytes += copy.length;
    while (_ringBytes > maxRingBytes && _ringChunks.isNotEmpty) {
      _ringBytes -= _ringChunks.removeAt(0).length;
    }
  }

  Uint8List recentPcm() {
    final builder = BytesBuilder(copy: false);
    for (final chunk in _ringChunks) {
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    if (bytes.length <= maxRingBytes) return bytes;
    return Uint8List.sublistView(bytes, bytes.length - maxRingBytes);
  }

  VoiceAnalysisMetrics get metrics => VoiceAnalysisMetrics.fromFrames(_frames);

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _input.stop();
    _watch?.stop();
    status = VoiceAnalysisStatus.stopped;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _input.dispose();
    super.dispose();
  }
}
