import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';

void main() {
  test('voice analysis session JSON round trips', () {
    final original = VoiceAnalysisSession(
      id: 'session-1',
      taskType: VoiceAnalysisTaskType.spectrogram,
      startedAt: DateTime.utc(2026, 8, 24, 3),
      durationSeconds: 10,
      metrics: const VoiceAnalysisMetrics(
        medianPitchHz: 181.2,
        voicedFrameRatio: 0.8,
        medianDbfs: -24,
        analysisConfidence: 0.9,
      ),
      analysisVersion: '1.0.0',
      audioPath: '/tmp/test.wav',
      isReference: true,
    );

    final restored = VoiceAnalysisSession.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.taskType, VoiceAnalysisTaskType.spectrogram);
    expect(restored.metrics.medianPitchHz, 181.2);
    expect(restored.isReference, isTrue);
    expect(restored.startedAt, original.startedAt);
  });
}
