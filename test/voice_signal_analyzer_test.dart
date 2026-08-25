import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';
import 'package:speech_rehab/services/audio_analysis/voice_signal_analyzer.dart';

void main() {
  const analyzer = VoiceSignalAnalyzer(sampleRate: 16000);

  Uint8List sineWave(double frequency, {double amplitude = 0.5}) {
    const sampleCount = 4096;
    final bytes = ByteData(sampleCount * 2);
    for (var index = 0; index < sampleCount; index++) {
      final sample = math.sin(2 * math.pi * frequency * index / 16000);
      bytes.setInt16(
        index * 2,
        (sample * amplitude * 32767).round(),
        Endian.little,
      );
    }
    return bytes.buffer.asUint8List();
  }

  test('estimates adult voice-range sine pitch', () {
    final frame = analyzer.analyzePcm16(
      sineWave(200),
      timestamp: const Duration(seconds: 1),
    );

    expect(frame.pitchHz, isNotNull);
    expect(frame.pitchHz!, closeTo(200, 4));
    expect(frame.pitchConfidence, greaterThan(0.8));
    expect(frame.dbfs, closeTo(-9, 1));
    expect(frame.clipping, isFalse);
  });

  test('does not report pitch for silence', () {
    final frame = analyzer.analyzePcm16(
      Uint8List(4096),
      timestamp: Duration.zero,
    );

    expect(frame.pitchHz, isNull);
    expect(frame.dbfs, -80);
    expect(frame.hasReliablePitch, isFalse);
  });

  test('detects clipping', () {
    final frame = analyzer.analyzePcm16(
      sineWave(150, amplitude: 1),
      timestamp: Duration.zero,
    );
    expect(frame.clipping, isTrue);
  });

  test('aggregates robust session metrics', () {
    final frames = [
      analyzer.analyzePcm16(
        sineWave(180),
        timestamp: const Duration(milliseconds: 100),
      ),
      analyzer.analyzePcm16(
        sineWave(182),
        timestamp: const Duration(milliseconds: 200),
      ),
      analyzer.analyzePcm16(
        sineWave(178),
        timestamp: const Duration(milliseconds: 300),
      ),
    ];
    final metrics = VoiceAnalysisMetrics.fromFrames(frames);

    expect(metrics.medianPitchHz, closeTo(180, 5));
    expect(metrics.voicedFrameRatio, 1);
    expect(metrics.phonationDurationMs, 300);
    expect(metrics.analysisConfidence, greaterThan(0.8));
  });
}
