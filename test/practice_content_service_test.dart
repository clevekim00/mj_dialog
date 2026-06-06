import 'dart:math';

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
      expect(word.movementScore, greaterThanOrEqualTo(1));
      expect(word.baseWeight, greaterThan(0));
    });

    test('contains high movement exercise pattern words', () {
      final service = PracticeContentService();
      final words = service.getItems(PracticeMode.wordGame);

      expect(words.map((item) => item.text), contains('퍼터커'));
      expect(words.map((item) => item.text), contains('파타카'));
      expect(
        words.where((item) => item.isExercisePattern),
        hasLength(greaterThanOrEqualTo(4)),
      );
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

    test('picks a weighted word from available word items', () {
      final service = PracticeContentService();
      final items = service.getItems(PracticeMode.wordGame);

      final picked = service.pickWeightedWord(
        items: items,
        history: const [],
        difficultyLevel: 3,
      );

      expect(items.map((item) => item.id), contains(picked.id));
    });

    test('filters focused consonant words before applying vowel boost', () {
      final service = PracticeContentService();
      final items = service
          .getItems(PracticeMode.wordGame)
          .where(
            (item) => item.id == 'word_medicine' || item.id == 'word_ta_ra_ka',
          )
          .toList();

      for (var i = 0; i < 80; i += 1) {
        final picked = service.pickWeightedWord(
          items: items,
          history: const [],
          difficultyLevel: 2,
          focusedConsonant: 'ㄹ',
          focusedVowel: 'ㅏ',
          random: Random(i),
        );
        expect(picked.id, 'word_ta_ra_ka');
      }
    });

    test('filters focused consonant and vowel together', () {
      final service = PracticeContentService();
      final items = service
          .getItems(PracticeMode.wordGame)
          .where((item) => item.id == 'word_tak_gu' || item.id == 'word_gi_cha')
          .toList();

      for (var i = 0; i < 80; i += 1) {
        final picked = service.pickWeightedWord(
          items: items,
          history: const [],
          difficultyLevel: 2,
          focusedConsonant: 'ㄱ',
          focusedVowel: 'ㅣ',
          random: Random(i),
        );

        expect(picked.id, 'word_gi_cha');
      }
    });

    test('matches compound vowels when a base focused vowel is selected', () {
      final service = PracticeContentService();
      final items = service
          .getItems(PracticeMode.wordGame)
          .where(
            (item) => item.id == 'word_medicine' || item.id == 'word_chi_gwa',
          )
          .toList();

      for (var i = 0; i < 40; i += 1) {
        final picked = service.pickWeightedWord(
          items: items,
          history: const [],
          difficultyLevel: 2,
          focusedConsonant: 'ㄱ',
          focusedVowel: 'ㅏ',
          random: Random(i),
        );

        expect(picked.id, 'word_chi_gwa');
      }
    });

    test(
      'does not substitute nearby consonants for exact focused consonant',
      () {
        final service = PracticeContentService();
        final items = service
            .getItems(PracticeMode.wordGame)
            .where(
              (item) =>
                  item.id == 'word_puh_tuh_kuh' || item.id == 'word_tak_gu',
            )
            .toList();

        for (var i = 0; i < 40; i += 1) {
          final picked = service.pickWeightedWord(
            items: items,
            history: const [],
            difficultyLevel: 3,
            focusedConsonant: 'ㄱ',
            random: Random(i),
          );
          expect(picked.id, 'word_tak_gu');
        }
      },
    );

    test('counts difficult target sounds from failed word sessions', () {
      final service = PracticeContentService();
      final history = [
        _wordSession(
          contentId: 'word_puh_tuh_kuh',
          targetText: '퍼터커',
          score: 50,
          timestamp: DateTime(2026, 6, 2, 9),
        ),
      ];

      final counts = service.getDifficultSoundCounts(history);

      expect(counts['ㅍ'], 1);
      expect(counts['ㅌ'], 1);
      expect(counts['ㅋ'], 1);
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
      expect(
        CustomPracticeContentService.estimateDifficulty(
          List.filled(400, '가').join(),
        ),
        1,
      );
      expect(
        CustomPracticeContentService.estimateDifficulty(
          List.filled(401, '가').join(),
        ),
        2,
      );
      expect(
        CustomPracticeContentService.estimateDifficulty(
          List.filled(801, '가').join(),
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
