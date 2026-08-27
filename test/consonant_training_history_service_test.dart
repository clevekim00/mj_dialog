import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';
import 'package:speech_rehab/features/consonant_training/services/consonant_training_history_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('훈련 시도를 저장하고 다시 불러온다', () async {
    final preferences = await SharedPreferences.getInstance();
    final service = ConsonantTrainingHistoryService(preferences: preferences);
    final attempt = _attempt(72, id: 'one');

    await service.add(attempt);
    final loaded = await service.load();

    expect(loaded, hasLength(1));
    expect(loaded.single.id, 'one');
    expect(loaded.single.analysis.overallPracticeScore, 72);
  });

  test('신뢰 가능한 3회부터 중앙값 기준선을 계산한다', () async {
    final service = ConsonantTrainingHistoryService(
      preferences: await SharedPreferences.getInstance(),
    );
    expect(
      service.baselineFor([_attempt(60), _attempt(80)], 'onset_g'),
      isNull,
    );

    final baseline = service.baselineFor([
      _attempt(90),
      _attempt(60),
      _attempt(75),
    ], 'onset_g');
    expect(baseline, isNotNull);
    expect(baseline!.medianScore, 75);
    expect(baseline.validAttemptCount, 3);
    expect(baseline.modelVersion, 'test-model');
  });

  test('언어가 다른 점수는 같은 기준선에 섞지 않는다', () async {
    final service = ConsonantTrainingHistoryService(
      preferences: await SharedPreferences.getInstance(),
    );
    final attempts = [
      _attempt(90, language: 'ko-KR'),
      _attempt(80, language: 'ko-KR'),
      _attempt(70, language: 'en-US'),
    ];

    expect(
      service.baselineFor(attempts, 'onset_g', language: 'ko-KR'),
      isNull,
    );
  });
}

ConsonantTrainingAttempt _attempt(
  int score, {
  String id = 'attempt',
  String language = 'ko-KR',
}) {
  return ConsonantTrainingAttempt(
    id: id,
    targetId: 'onset_g',
    contentId: 'item',
    text: '가',
    level: ConsonantTrainingLevel.syllable,
    audioFilePath: '/tmp/audio.m4a',
    createdAt: DateTime(2026),
    analysis: PronunciationAnalysisResult(
      jobId: 'job',
      status: PronunciationAnalysisStatus.completed,
      modelVersion: 'test-model',
      contentVersion: '1.0.0',
      overallPracticeScore: score,
      confidence: 0.9,
      phonemes: const [],
      baselineDelta: null,
      signalAccepted: true,
      disclaimer: 'test',
      language: language,
    ),
  );
}
