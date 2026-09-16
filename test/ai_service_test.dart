import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:speech_rehab/services/api/ai_service.dart';

void main() {
  const service = AiService();

  test(
    'word matching is named text matching and a mismatch is not a pronunciation claim',
    () async {
      final matched = await service.evaluatePracticeByMode(
        mode: PracticeMode.wordGame,
        targetText: '숨쉬기',
        spokenText: '숨쉬기',
        durationSeconds: 2,
      );
      final mismatched = await service.evaluatePracticeByMode(
        mode: PracticeMode.wordGame,
        targetText: '숨쉬기',
        spokenText: '손씻기',
        durationSeconds: 2,
      );
      expect(matched.pronunciationScore, 100);
      expect(matched.scoreLabel, '텍스트 일치도');
      expect(matched.evaluationVersion, AiService.textMatchVersion);
      expect(mismatched.pronunciationScore, 0);
      expect(mismatched.pronunciationFeedback, contains('음성 인식 오류'));
    },
  );

  test(
    'every practice mode preserves unavailable recognition as no score',
    () async {
      for (final mode in PracticeMode.values) {
        final result = await service.evaluatePracticeByMode(
          mode: mode,
          targetText: '물',
          spokenText: '  ',
          durationSeconds: 5,
        );
        expect(result.pronunciationScore, isNull, reason: mode.name);
        expect(result.evaluationMethod, 'unavailable');
        expect(result.hasComparableScore, isFalse);
      }
    },
  );

  test('free speech has no fixed score even with a transcript', () async {
    final result = await service.getFreeReadingFeedback('오늘 산책했어요.');
    expect(result.pronunciationScore, isNull);
    expect(result.evaluationMethod, 'notAssessed');
  });

  test(
    'sentence comparison uses actual edits rather than transcript length',
    () async {
      final exact = await service.getReadingFeedback('물을 마셔요.', '물을  마셔요');
      final different = await service.getReadingFeedback('물을 마셔요', '가나다라마');
      expect(exact.pronunciationScore, 100);
      expect(different.pronunciationScore, 0);
    },
  );

  test(
    'unimplemented audio evaluation reports unavailable without fake analysis',
    () async {
      final result = await service.evaluateAudio(
        '/tmp/does-not-exist.m4a',
        '물',
      );
      expect(result.pronunciationScore, isNull);
      expect(result.evaluationMethod, 'unavailable');
    },
  );

  test(
    'iOS conversation fallback never assigns an articulation score',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final result = await service.getResponseAndFeedback('말하기 어려워요');
      expect(result.pronunciationScore, isNull);
      expect(result.pronunciationFeedback, isNot(contains('혀')));
      expect(result.evaluationMethod, 'notAssessed');
    },
  );
}
