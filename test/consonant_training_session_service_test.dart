import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';
import 'package:speech_rehab/features/consonant_training/services/consonant_training_session_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('재시작 후 선택 자음, 단계, 항목과 실제 녹음 횟수를 복원한다', () async {
    final service = ConsonantTrainingSessionService();
    await service.save(
      ConsonantTrainingProgress(
        targetId: 'coda_n',
        grapheme: 'ㄴ',
        position: PhonemePosition.coda,
        level: ConsonantTrainingLevel.word,
        itemIndex: 4,
        contentId: 'word_5',
        repetitions: 5,
        completedAttempts: 2,
        completed: false,
        updatedAt: DateTime(2026, 9, 15),
      ),
    );
    final restored = await ConsonantTrainingSessionService().load();
    expect(restored!.targetId, 'coda_n');
    expect(restored.level, ConsonantTrainingLevel.word);
    expect(restored.contentId, 'word_5');
    expect(restored.itemIndex, 4);
    expect(restored.completedAttempts, 2);
    expect(restored.completed, isFalse);
    expect(await service.load(language: 'en-US'), isNull);
  });

  test('완료 상태를 보존하고 손상된 진행 정보는 무시한다', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = ConsonantTrainingSessionService(preferences: prefs);
    await service.save(
      ConsonantTrainingProgress(
        targetId: 'onset_g',
        grapheme: 'ㄱ',
        position: PhonemePosition.onset,
        level: ConsonantTrainingLevel.syllable,
        itemIndex: 0,
        repetitions: 3,
        completedAttempts: 3,
        completed: true,
        updatedAt: DateTime(2026),
      ),
    );
    expect((await service.load())!.completed, isTrue);
    await prefs.setString('consonant_training_progress_v1_ko-KR', '{invalid');
    expect(await service.load(), isNull);
  });
}
