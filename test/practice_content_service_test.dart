import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:speech_rehab/services/practice_content_service.dart';
import 'package:speech_rehab/services/practice_history_service.dart';

void main() {
  group('PracticeContentService', () {
    test('returns structured content for word, short, and long practice', () {
      final service = PracticeContentService();

      expect(
        service.getItems(PracticeMode.wordGame),
        hasLength(greaterThan(3)),
      );
      expect(
        service.getItems(PracticeMode.shortSentence),
        hasLength(greaterThan(3)),
      );
      expect(
        service.getItems(PracticeMode.longSentence),
        hasLength(greaterThan(2)),
      );
      expect(service.getItems(PracticeMode.freeSpeech), isEmpty);
    });

    test('keeps mode, category, difficulty, and target sound metadata', () {
      final service = PracticeContentService();
      final word = service.getFirstItem(PracticeMode.wordGame);

      expect(word, isNotNull);
      expect(word!.mode, PracticeMode.wordGame);
      expect(word.category, isNotEmpty);
      expect(word.difficulty, greaterThanOrEqualTo(1));
      expect(word.targetSounds, isNotEmpty);
    });

    test('returns failed word review items from low scoring history', () {
      final service = PracticeContentService();
      final history = [
        _wordSession(
          contentId: 'word_water',
          targetText: '물',
          score: 62,
          timestamp: DateTime(2026, 6, 2, 9),
        ),
        _wordSession(
          contentId: 'word_medicine',
          targetText: '약',
          score: 88,
          timestamp: DateTime(2026, 6, 2, 10),
        ),
      ];

      final reviewItems = service.getFailedWordReviewItems(history);

      expect(reviewItems.map((item) => item.id), contains('word_water'));
      expect(
        reviewItems.map((item) => item.id),
        isNot(contains('word_medicine')),
      );
    });

    test('removes failed word from review after two recent successes', () {
      final service = PracticeContentService();
      final history = [
        _wordSession(
          contentId: 'word_water',
          targetText: '물',
          score: 82,
          timestamp: DateTime(2026, 6, 2, 11),
        ),
        _wordSession(
          contentId: 'word_water',
          targetText: '물',
          score: 86,
          timestamp: DateTime(2026, 6, 2, 10),
        ),
        _wordSession(
          contentId: 'word_water',
          targetText: '물',
          score: 55,
          timestamp: DateTime(2026, 6, 2, 9),
        ),
      ];

      final reviewItems = service.getFailedWordReviewItems(history);

      expect(reviewItems.map((item) => item.id), isNot(contains('word_water')));
    });
  });

  group('CustomPracticeContentService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('adds, updates, and deletes custom long sentences', () async {
      final service = CustomPracticeContentService();

      final added = await service.addLongSentence(
        text: '병원에서 오늘 몸 상태를 천천히 설명해 보겠습니다.',
        category: '병원',
      );
      var items = await service.loadLongSentences();

      expect(items, hasLength(1));
      expect(items.first.id, added.id);
      expect(items.first.source, PracticeContentSource.custom);
      expect(items.first.mode, PracticeMode.longSentence);
      expect(items.first.category, '병원');

      await service.updateLongSentence(
        id: added.id,
        text: '전화로 가족에게 필요한 도움을 천천히 설명해 보겠습니다.',
        category: '전화',
      );
      items = await service.loadLongSentences();

      expect(items.first.text, contains('전화로 가족에게'));
      expect(items.first.category, '전화');

      await service.deleteLongSentence(added.id);
      items = await service.loadLongSentences();

      expect(items, isEmpty);
    });

    test('estimates custom long sentence difficulty from text length', () {
      expect(CustomPracticeContentService.estimateDifficulty('짧은 문장입니다.'), 1);
      expect(
        CustomPracticeContentService.estimateDifficulty(
          '오늘은 전화로 가족에게 필요한 내용을 천천히 또박또박 설명해 보겠습니다.',
        ),
        2,
      );
      expect(
        CustomPracticeContentService.estimateDifficulty(
          '병원에 가기 전에 현재 몸 상태와 약을 먹은 시간 그리고 오늘 느낀 불편한 점을 가족에게 차분하게 정리해서 설명하고 필요한 도움을 부탁해 보겠습니다.',
        ),
        3,
      );
    });
  });
}

PracticeSession _wordSession({
  required String contentId,
  required String targetText,
  required int score,
  required DateTime timestamp,
}) {
  return PracticeSession(
    id: '${contentId}_${timestamp.microsecondsSinceEpoch}',
    targetText: targetText,
    spokenText: targetText,
    audioFilePath: '/tmp/$contentId.m4a',
    score: score,
    feedback: '테스트 피드백',
    timestamp: timestamp,
    mode: PracticeMode.wordGame.storageValue,
    contentId: contentId,
    category: '테스트',
  );
}
