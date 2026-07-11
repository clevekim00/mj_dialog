import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:speech_rehab/services/api/ai_service.dart';

void main() {
  test('word game evaluation uses local exact-match scoring', () async {
    const service = AiService();

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
    expect(mismatched.pronunciationScore, lessThan(70));
    expect(mismatched.pronunciationFeedback, contains('손씻기'));
  });
}
