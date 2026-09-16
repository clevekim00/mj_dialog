import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';
import 'package:speech_rehab/services/audio_analysis/voice_analysis_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('voice_repo_test_');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => directory.delete(recursive: true));

  test('saves, loads, replaces and deletes sessions', () async {
    final repository = VoiceAnalysisRepository(
      recordingsDirectory: () async => directory,
    );
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
  test('공유 녹음은 마지막 참조가 삭제될 때 제거한다', () async {
    final repository = VoiceAnalysisRepository(
      recordingsDirectory: () async => directory,
    );
    final file = File('${directory.path}/sample.wav');
    await file.writeAsBytes([1, 2, 3]);
    VoiceAnalysisSession session(String id) => VoiceAnalysisSession(
      id: id,
      taskType: VoiceAnalysisTaskType.pitch,
      startedAt: DateTime.now(),
      durationSeconds: 1,
      metrics: const VoiceAnalysisMetrics(),
      analysisVersion: '1',
      audioPath: file.path,
    );
    await repository.save(session('first'));
    await repository.save(session('second'));
    await repository.delete('first');
    expect(await file.exists(), isTrue);
    await repository.delete('second');
    expect(await file.exists(), isFalse);
    expect(await repository.load(), isEmpty);
  });

  test('다른 기능이 소유한 파일은 삭제하지 않는다', () async {
    final external = await Directory.systemTemp.createTemp('other_feature_');
    addTearDown(() => external.delete(recursive: true));
    final file = await File('${external.path}/external.wav').writeAsBytes([1]);
    final repository = VoiceAnalysisRepository(
      recordingsDirectory: () async => directory,
    );
    await repository.save(
      VoiceAnalysisSession(
        id: 'external',
        taskType: VoiceAnalysisTaskType.pitch,
        startedAt: DateTime.now(),
        durationSeconds: 1,
        metrics: const VoiceAnalysisMetrics(),
        analysisVersion: '1',
        audioPath: file.path,
      ),
    );
    await repository.delete('external');
    expect(await file.exists(), isTrue);
  });
}
