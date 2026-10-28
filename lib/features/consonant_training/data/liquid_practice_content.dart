import '../model/consonant_training_models.dart';

/// Written targets and practice conditions, never an acoustic assessment.
enum LiquidExercise { repetition, medial, coda, linked, sentence, custom }

extension LiquidExerciseLabel on LiquidExercise {
  String get label => switch (this) {
    LiquidExercise.repetition => '같은 음절 반복',
    LiquidExercise.medial => '단어 속 ㄹ',
    LiquidExercise.coda => '받침 ㄹ',
    LiquidExercise.linked => '이어지는 ㄹ',
    LiquidExercise.sentence => '생활 문장',
    LiquidExercise.custom => '내 연습',
  };
}

class LiquidPracticeContent {
  static const version = 'ko-liquid-v1';

  // ASCII asset keys avoid macOS NFD vs iOS/Flutter NFC filename mismatches.
  static String referenceAsset(String text) =>
      'assets/pronunciation/liquid_examples/liquid_${text.runes.map((r) => r.toRadixString(16)).join('_')}.wav';
  static const vowels = ['라', '러', '로', '루', '르', '리'];
  static const examples = {
    LiquidExercise.medial: ['아라', '어러', '오로', '다리', '소리', '오리', '기다려요'],
    LiquidExercise.coda: ['알', '얼', '올', '울', '을', '일', '달', '물', '길'],
    LiquidExercise.linked: ['빨리', '멀리', '달라', '올라', '몰라요'],
    LiquidExercise.sentence: ['소리가 들려요.', '물을 마실래요.', '빨리 말하지 않을게요.'],
  };

  static ConsonantTrainingTarget target(LiquidExercise exercise) =>
      ConsonantTrainingTarget(
        id: 'liquid_${exercise.name}',
        grapheme: 'ㄹ',
        phone: exercise == LiquidExercise.coda ? 'lf' : 'r',
        position: exercise == LiquidExercise.coda
            ? PhonemePosition.coda
            : PhonemePosition.onset,
        description: exercise.label,
      );

  static PronunciationContentItem item(
    LiquidExercise exercise,
    String text, {
    int repetitions = 5,
  }) {
    final value = text.trim();
    final repeated = exercise == LiquidExercise.repetition;
    return PronunciationContentItem(
      id: 'liquid_${exercise.name}_${Uri.encodeComponent(value)}_${repeated ? repetitions : 1}_v1',
      targetId: target(exercise).id,
      level: repeated || exercise == LiquidExercise.coda
          ? ConsonantTrainingLevel.syllable
          : exercise == LiquidExercise.sentence ||
                exercise == LiquidExercise.custom
          ? ConsonantTrainingLevel.sentence
          : ConsonantTrainingLevel.word,
      text: repeated ? List.filled(repetitions, value).join(' ') : value,
      pronunciation: const [],
      difficulty: 1,
      category: exercise.label,
      targetOccurrenceCount: repeated ? repetitions : 1,
      reviewStatus: 'practice_only',
    );
  }
}
