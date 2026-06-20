import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:speech_rehab/services/practice_history_service.dart';

void main() {
  group('PracticeHistoryService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves and loads structured practice mode fields', () async {
      final service = PracticeHistoryService();
      final session = PracticeSession(
        id: 'session-1',
        targetText: '물',
        spokenText: '물',
        audioFilePath: '/tmp/sample.m4a',
        videoFilePath: '/tmp/sample-mouth.mp4',
        score: 95,
        feedback: '또렷하게 말했습니다.',
        timestamp: DateTime(2026, 6, 1, 9),
        mode: PracticeMode.wordGame.storageValue,
        contentId: 'word_water',
        category: '일상',
        difficulty: 1,
        retryCount: 0,
        streakCount: 2,
        previousBestScore: 90,
        contentSource: 'custom',
        movementScore: 5,
        isExercisePattern: true,
      );

      await service.savePractice(session);
      final loaded = await service.loadPractices();

      expect(loaded, hasLength(1));
      expect(loaded.first.mode, 'wordGame');
      expect(loaded.first.videoFilePath, '/tmp/sample-mouth.mp4');
      expect(loaded.first.contentId, 'word_water');
      expect(loaded.first.category, '일상');
      expect(loaded.first.streakCount, 2);
      expect(loaded.first.previousBestScore, 90);
      expect(loaded.first.contentSource, 'custom');
      expect(loaded.first.movementScore, 5);
      expect(loaded.first.isExercisePattern, isTrue);
    });

    test('loads old practice sessions with default mode metadata', () {
      final oldJson = {
        'id': 'old-session',
        'targetText': '물을 마시고 싶어요.',
        'spokenText': '물을 마시고 싶어요.',
        'audioFilePath': '/tmp/old.m4a',
        'score': 80,
        'feedback': '천천히 읽어보세요.',
        'timestamp': DateTime(2026, 6, 1).toIso8601String(),
      };

      final session = PracticeSession.fromJson(oldJson);

      expect(session.mode, 'shortSentence');
      expect(session.category, '일반');
      expect(session.difficulty, 1);
      expect(session.retryCount, 0);
      expect(session.streakCount, 0);
      expect(session.contentSource, 'builtIn');
      expect(session.movementScore, 1);
      expect(session.isExercisePattern, isFalse);
      expect(session.videoFilePath, isNull);
    });
  });
}
