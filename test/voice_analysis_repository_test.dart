import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';
import 'package:speech_rehab/services/audio_analysis/voice_analysis_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves, loads, replaces and deletes sessions', () async {
    final repository = VoiceAnalysisRepository();
    VoiceAnalysisSession session(double pitch) => VoiceAnalysisSession(
      id: 'same-id',
      taskType: VoiceAnalysisTaskType.pitch,
      startedAt: DateTime(2026, 8, 24),
      durationSeconds: 5,
      metrics: VoiceAnalysisMetrics(medianPitchHz: pitch),
      analysisVersion: '1',
    );

    await repository.save(session(180));
    await repository.save(session(190));
    final loaded = await repository.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.metrics.medianPitchHz, 190);

    await repository.delete('same-id');
    expect(await repository.load(), isEmpty);
  });
}
