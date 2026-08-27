import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('내장 자음 콘텐츠는 초성·받침과 문장 500개를 포함한다', () async {
    final raw = await rootBundle.loadString(
      'assets/pronunciation/content/ko_consonant_core.json',
    );
    final pack = PronunciationContentPack.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    expect(pack.targets, hasLength(25));
    expect(
      pack.targets.where((target) => target.position == PhonemePosition.onset),
      hasLength(18),
    );
    expect(
      pack.targets.where((target) => target.position == PhonemePosition.coda),
      hasLength(7),
    );
    expect(
      pack.items.where((item) => item.level == ConsonantTrainingLevel.sentence),
      hasLength(500),
    );
    for (final target in pack.targets) {
      expect(
        pack.itemsFor(target.id, ConsonantTrainingLevel.sentence),
        hasLength(20),
      );
      expect(
        pack.itemsFor(target.id, ConsonantTrainingLevel.syllable),
        hasLength(6),
      );
      expect(
        pack.itemsFor(target.id, ConsonantTrainingLevel.word),
        hasLength(6),
      );
    }
  });

  test('모든 문장은 대상 자음이 두 번 이상 표시된다', () async {
    final raw = await rootBundle.loadString(
      'assets/pronunciation/content/ko_consonant_core.json',
    );
    final pack = PronunciationContentPack.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    final sentences = pack.items.where(
      (item) => item.level == ConsonantTrainingLevel.sentence,
    );
    expect(sentences.every((item) => item.targetOccurrenceCount >= 2), isTrue);
  });

  test('영어 내장 콘텐츠는 initial, medial, final 목표를 분리한다', () async {
    final raw = await rootBundle.loadString(
      'assets/pronunciation/content/en_us_consonant_core.json',
    );
    final pack = PronunciationContentPack.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );

    expect(pack.language, 'en-US');
    expect(pack.targets, hasLength(12));
    for (final position in PhonemePosition.values) {
      expect(
        pack.targets.where((target) => target.position == position),
        hasLength(4),
      );
    }
    for (final target in pack.targets) {
      expect(
        pack.itemsFor(target.id, ConsonantTrainingLevel.word),
        hasLength(1),
      );
      expect(
        pack.itemsFor(target.id, ConsonantTrainingLevel.sentence),
        hasLength(1),
      );
    }
  });
}
