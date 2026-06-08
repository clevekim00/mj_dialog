import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:speech_rehab/services/practice_history_service.dart';

final practiceContentServiceProvider = Provider(
  (ref) => PracticeContentService(),
);

final customPracticeContentServiceProvider = Provider(
  (ref) => CustomPracticeContentService(),
);

enum PracticeContentSource { builtIn, custom }

extension PracticeContentSourceValue on PracticeContentSource {
  String get storageValue {
    return switch (this) {
      PracticeContentSource.builtIn => 'builtIn',
      PracticeContentSource.custom => 'custom',
    };
  }

  static PracticeContentSource fromStorageValue(String? value) {
    return switch (value) {
      'custom' => PracticeContentSource.custom,
      _ => PracticeContentSource.builtIn,
    };
  }
}

class PracticeContentItem {
  const PracticeContentItem({
    required this.id,
    required this.mode,
    required this.text,
    required this.category,
    required this.difficulty,
    this.targetSounds = const [],
    this.source = PracticeContentSource.builtIn,
    this.movementScore = 1,
    this.baseWeight = 10,
    this.isExercisePattern = false,
  });

  final String id;
  final PracticeMode mode;
  final String text;
  final String category;
  final int difficulty;
  final List<String> targetSounds;
  final PracticeContentSource source;
  final int movementScore;
  final int baseWeight;
  final bool isExercisePattern;
}

class PracticeContentService {
  static const List<PracticeContentItem> _items = [
    PracticeContentItem(
      id: 'word_water',
      mode: PracticeMode.wordGame,
      text: '물',
      category: '일상',
      difficulty: 1,
      targetSounds: ['ㅁ', 'ㄹ'],
      movementScore: 2,
      baseWeight: 14,
    ),
    PracticeContentItem(
      id: 'word_medicine',
      mode: PracticeMode.wordGame,
      text: '약',
      category: '병원',
      difficulty: 1,
      targetSounds: ['ㅇ'],
      movementScore: 1,
      baseWeight: 12,
    ),
    PracticeContentItem(
      id: 'word_hospital',
      mode: PracticeMode.wordGame,
      text: '병원',
      category: '병원',
      difficulty: 1,
      targetSounds: ['ㅂ', 'ㅇ'],
      movementScore: 2,
      baseWeight: 12,
    ),
    PracticeContentItem(
      id: 'word_restroom',
      mode: PracticeMode.wordGame,
      text: '화장실',
      category: '일상',
      difficulty: 2,
      targetSounds: ['ㅎ', 'ㅈ', 'ㅅ'],
      movementScore: 3,
      baseWeight: 10,
    ),
    PracticeContentItem(
      id: 'word_help',
      mode: PracticeMode.wordGame,
      text: '도와주세요',
      category: '가족',
      difficulty: 2,
      targetSounds: ['ㄷ', 'ㅈ'],
      movementScore: 3,
      baseWeight: 10,
    ),
    PracticeContentItem(
      id: 'word_slowly',
      mode: PracticeMode.wordGame,
      text: '천천히',
      category: '전화',
      difficulty: 2,
      targetSounds: ['ㅊ', 'ㅎ'],
      movementScore: 3,
      baseWeight: 10,
    ),
    PracticeContentItem(
      id: 'word_puh_tuh_kuh',
      mode: PracticeMode.wordGame,
      text: '퍼터커',
      category: '혀 운동',
      difficulty: 3,
      targetSounds: ['ㅍ', 'ㅌ', 'ㅋ'],
      movementScore: 5,
      baseWeight: 7,
      isExercisePattern: true,
    ),
    PracticeContentItem(
      id: 'word_pa_ta_ka',
      mode: PracticeMode.wordGame,
      text: '파타카',
      category: '혀 운동',
      difficulty: 3,
      targetSounds: ['ㅍ', 'ㅌ', 'ㅋ'],
      movementScore: 5,
      baseWeight: 7,
      isExercisePattern: true,
    ),
    PracticeContentItem(
      id: 'word_pi_ti_ki',
      mode: PracticeMode.wordGame,
      text: '피티키',
      category: '혀 운동',
      difficulty: 3,
      targetSounds: ['ㅍ', 'ㅌ', 'ㅋ'],
      movementScore: 5,
      baseWeight: 6,
      isExercisePattern: true,
    ),
    PracticeContentItem(
      id: 'word_buh_duh_guh',
      mode: PracticeMode.wordGame,
      text: '버더거',
      category: '혀 운동',
      difficulty: 3,
      targetSounds: ['ㅂ', 'ㄷ', 'ㄱ'],
      movementScore: 5,
      baseWeight: 6,
      isExercisePattern: true,
    ),
    PracticeContentItem(
      id: 'word_ta_ra_ka',
      mode: PracticeMode.wordGame,
      text: '타라카',
      category: '혀 운동',
      difficulty: 3,
      targetSounds: ['ㅌ', 'ㄹ', 'ㅋ'],
      movementScore: 5,
      baseWeight: 6,
      isExercisePattern: true,
    ),
    PracticeContentItem(
      id: 'word_do_to_ri',
      mode: PracticeMode.wordGame,
      text: '도토리',
      category: '움직임 단어',
      difficulty: 2,
      targetSounds: ['ㄷ', 'ㅌ', 'ㄹ'],
      movementScore: 4,
      baseWeight: 8,
    ),
    PracticeContentItem(
      id: 'word_tak_gu',
      mode: PracticeMode.wordGame,
      text: '탁구',
      category: '움직임 단어',
      difficulty: 2,
      targetSounds: ['ㅌ', 'ㄱ'],
      movementScore: 4,
      baseWeight: 8,
    ),
    PracticeContentItem(
      id: 'word_chi_gwa',
      mode: PracticeMode.wordGame,
      text: '치과',
      category: '움직임 단어',
      difficulty: 2,
      targetSounds: ['ㅊ', 'ㄱ'],
      movementScore: 4,
      baseWeight: 8,
    ),
    PracticeContentItem(
      id: 'word_gi_cha',
      mode: PracticeMode.wordGame,
      text: '기차',
      category: '움직임 단어',
      difficulty: 2,
      targetSounds: ['ㄱ', 'ㅊ'],
      movementScore: 4,
      baseWeight: 8,
    ),
    PracticeContentItem(
      id: 'short_water',
      mode: PracticeMode.shortSentence,
      text: '물을 마시고 싶어요.',
      category: '일상',
      difficulty: 1,
      targetSounds: ['ㅁ', 'ㅅ'],
    ),
    PracticeContentItem(
      id: 'short_rest',
      mode: PracticeMode.shortSentence,
      text: '조금 쉬고 싶어요.',
      category: '감정',
      difficulty: 1,
      targetSounds: ['ㅈ', 'ㅅ'],
    ),
    PracticeContentItem(
      id: 'short_restroom',
      mode: PracticeMode.shortSentence,
      text: '화장실에 가고 싶어요.',
      category: '일상',
      difficulty: 1,
      targetSounds: ['ㅎ', 'ㅅ'],
    ),
    PracticeContentItem(
      id: 'short_dizzy',
      mode: PracticeMode.shortSentence,
      text: '어지러워요. 도와주세요.',
      category: '병원',
      difficulty: 2,
      targetSounds: ['ㄹ', 'ㄷ', 'ㅈ'],
    ),
    PracticeContentItem(
      id: 'short_repeat',
      mode: PracticeMode.shortSentence,
      text: '천천히 다시 말해 주세요.',
      category: '전화',
      difficulty: 2,
      targetSounds: ['ㅊ', 'ㄷ', 'ㅈ'],
    ),
    PracticeContentItem(
      id: 'short_slow',
      mode: PracticeMode.shortSentence,
      text: '제가 천천히 말해 볼게요.',
      category: '전화',
      difficulty: 2,
      targetSounds: ['ㅈ', 'ㅊ', 'ㅂ'],
    ),
    PracticeContentItem(
      id: 'long_today',
      mode: PracticeMode.longSentence,
      text:
          '아침에 창문을 열자 차가운 공기가 방 안으로 천천히 들어왔습니다. 민수는 물 한 잔을 마시고 식탁 앞에 앉아 오늘 해야 할 일을 작은 수첩에 적었습니다. 첫 번째는 병원에 전화해서 진료 시간을 확인하는 일이었고, 두 번째는 가족에게 몸 상태를 차분하게 설명하는 일이었습니다. 민수는 급하게 말하면 숨이 가빠진다는 것을 알고 있었기 때문에, 문장을 한 번에 다 말하려고 하지 않았습니다. 대신 의미가 끊기는 곳마다 잠깐 쉬고, 입 모양을 또렷하게 만들며 한 문장씩 읽어 내려갔습니다. 처음에는 목소리가 작게 떨렸지만, 두 번 세 번 반복하자 말의 끝이 조금씩 분명해졌습니다. 그는 오늘의 연습이 아주 큰 변화는 아니어도 내일 다시 말할 힘을 만들어 준다고 생각했습니다.',
      category: '단편 읽기',
      difficulty: 3,
      targetSounds: ['ㅊ', 'ㄹ', 'ㅂ'],
    ),
    PracticeContentItem(
      id: 'long_medicine',
      mode: PracticeMode.longSentence,
      text:
          '영희는 병원에 가기 전날 밤, 식탁 위에 약 봉투와 작은 달력을 나란히 놓았습니다. 약을 먹은 시간을 잊지 않기 위해 달력 한쪽에 동그라미를 치고, 불편했던 증상을 천천히 적었습니다. 아침에는 가족에게 “어제 저녁에는 기침이 조금 줄었고, 물을 마실 때 목이 덜 아팠어요”라고 말해 보기로 했습니다. 말이 중간에 막히면 다시 처음부터 시작하지 않고, 숨을 고른 뒤 멈춘 단어 다음부터 이어서 말하기로 마음먹었습니다. 병원에 도착하면 의사 선생님께 필요한 내용을 빠뜨리지 않고 전하고 싶었습니다. 그래서 영희는 거울 앞에서 입을 편안히 벌리고, 한 문장씩 소리 내어 읽었습니다. 짧은 연습이었지만 마음이 조금 놓였습니다.',
      category: '단편 읽기',
      difficulty: 3,
      targetSounds: ['ㅂ', 'ㄱ', 'ㅎ'],
    ),
    PracticeContentItem(
      id: 'long_habit',
      mode: PracticeMode.longSentence,
      text:
          '동네 도서관에는 오후마다 조용한 햇빛이 길게 들어왔습니다. 준호는 가장 안쪽 책상에 앉아 좋아하는 짧은 이야기를 펼쳤습니다. 예전에는 긴 문장을 보면 마음이 먼저 급해졌고, 단어가 이어질수록 발음이 흐려졌습니다. 하지만 오늘은 다른 방법을 써 보기로 했습니다. 마침표가 나오기 전에도 뜻이 잠깐 쉬는 곳에서는 눈으로 표시를 하고, 그 지점에서 숨을 고르며 읽었습니다. “천천히 읽어도 괜찮다”는 말을 속으로 반복하자 어깨에 들어간 힘이 조금 빠졌습니다. 준호는 한 단락을 다 읽은 뒤 자신이 놓친 소리를 다시 확인했습니다. 완벽하지는 않았지만, 끝까지 읽었다는 사실이 다음 연습을 시작하게 하는 작은 용기가 되었습니다.',
      category: '단편 읽기',
      difficulty: 3,
      targetSounds: ['ㄲ', 'ㄹ', 'ㅂ'],
    ),
    PracticeContentItem(
      id: 'long_phone',
      mode: PracticeMode.longSentence,
      text:
          '전화벨이 울리자 수진은 잠시 숨을 고르고 통화 버튼을 눌렀습니다. 예전 같으면 상대방이 기다릴까 봐 서둘러 말했지만, 오늘은 천천히 말하기로 했습니다. 먼저 자신의 이름을 또렷하게 말하고, 필요한 내용을 한 가지씩 나누어 전했습니다. “오늘 오후 약속 시간을 확인하려고 전화했습니다. 가능하다면 세 시보다 조금 늦게 도착할 것 같습니다.” 문장이 길어질 때는 중간에 짧게 쉬었고, 마지막 단어를 흐리지 않으려고 입을 조금 더 분명히 움직였습니다. 상대방은 괜찮다고 답했고, 수진은 감사하다는 말을 천천히 덧붙였습니다. 전화를 끊은 뒤 그는 작은 성공을 기록했습니다. 짧은 통화였지만, 일상에서 다시 말할 수 있다는 자신감을 느꼈습니다.',
      category: '단편 읽기',
      difficulty: 3,
      targetSounds: ['ㅈ', 'ㅊ', 'ㄸ'],
    ),
  ];

  List<PracticeContentItem> getItems(PracticeMode mode) {
    return _items.where((item) => item.mode == mode).toList();
  }

  PracticeContentItem? getFirstItem(PracticeMode mode) {
    final items = getItems(mode);
    return items.isEmpty ? null : items.first;
  }

  PracticeContentItem? getById(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  List<PracticeContentItem> getFailedWordReviewItems(
    List<PracticeSession> history,
  ) {
    final wordSessions =
        history
            .where(
              (session) =>
                  session.mode == PracticeMode.wordGame.storageValue &&
                  session.contentId != null,
            )
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final sessionsByContentId = <String, List<PracticeSession>>{};
    for (final session in wordSessions) {
      sessionsByContentId
          .putIfAbsent(session.contentId!, () => [])
          .add(session);
    }

    final reviewItems = <PracticeContentItem>[];
    for (final entry in sessionsByContentId.entries) {
      final sessions = entry.value;
      final hasFailure = sessions.any((session) => session.score < 70);
      if (!hasFailure) {
        continue;
      }

      final recentTwo = sessions.take(2).toList();
      final hasRecovered =
          recentTwo.length == 2 &&
          recentTwo.every((session) => session.score >= 80);
      if (hasRecovered) {
        continue;
      }

      final item = getById(entry.key);
      if (item != null && item.mode == PracticeMode.wordGame) {
        reviewItems.add(item);
      }
    }

    return reviewItems;
  }

  PracticeContentItem pickWeightedWord({
    required List<PracticeContentItem> items,
    required List<PracticeSession> history,
    required int difficultyLevel,
    String? currentContentId,
    String? focusedConsonant,
    String? focusedVowel,
    Random? random,
  }) {
    var wordItems = items
        .where((item) => item.mode == PracticeMode.wordGame)
        .toList();
    if (wordItems.isEmpty) {
      throw StateError('No word practice items available.');
    }

    final focusedItems = _focusedWordItems(
      wordItems,
      focusedConsonant,
      focusedVowel,
    );
    if (focusedItems.isNotEmpty) {
      wordItems = focusedItems;
    }

    final rng = random ?? Random();
    final weightedItems = wordItems
        .map(
          (item) => MapEntry(
            item,
            _wordWeight(
              item: item,
              history: history,
              difficultyLevel: difficultyLevel,
              currentContentId: currentContentId,
              focusedConsonant: focusedConsonant,
              focusedVowel: focusedVowel,
            ),
          ),
        )
        .where((entry) => entry.value > 0)
        .toList();

    final totalWeight = weightedItems.fold<int>(
      0,
      (sum, entry) => sum + entry.value,
    );
    var ticket = rng.nextInt(totalWeight);
    for (final entry in weightedItems) {
      ticket -= entry.value;
      if (ticket < 0) {
        return entry.key;
      }
    }

    return weightedItems.last.key;
  }

  Map<String, int> getDifficultSoundCounts(List<PracticeSession> history) {
    final counts = <String, int>{};
    for (final session in history) {
      if (session.mode != PracticeMode.wordGame.storageValue ||
          session.score >= 70 ||
          session.contentId == null) {
        continue;
      }

      final item = getById(session.contentId!);
      if (item == null) {
        continue;
      }

      for (final sound in item.targetSounds) {
        counts[sound] = (counts[sound] ?? 0) + 1;
      }
    }
    return counts;
  }

  int _wordWeight({
    required PracticeContentItem item,
    required List<PracticeSession> history,
    required int difficultyLevel,
    String? currentContentId,
    String? focusedConsonant,
    String? focusedVowel,
  }) {
    final clampedLevel = difficultyLevel.clamp(1, 3);
    var weight = item.baseWeight;

    if (item.isExercisePattern) {
      weight += switch (clampedLevel) {
        1 => -4,
        2 => 5,
        _ => 12,
      };
    } else if (item.movementScore >= 4) {
      weight += switch (clampedLevel) {
        1 => -1,
        2 => 4,
        _ => 8,
      };
    } else {
      weight += switch (clampedLevel) {
        1 => 6,
        2 => 1,
        _ => -2,
      };
    }

    final itemHistory =
        history.where((session) => session.contentId == item.id).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (itemHistory.any((session) => session.score < 70)) {
      weight += 8;
    }

    final recentTwo = itemHistory.take(2).toList();
    if (recentTwo.length == 2 &&
        recentTwo.every((session) => session.score >= 85)) {
      weight -= 5;
    }

    if (item.id == currentContentId && itemHistory.length > 1) {
      weight -= 4;
    }

    final matchesConsonant =
        focusedConsonant != null &&
        _matchesFocusedConsonant(item, focusedConsonant);
    final matchesVowel =
        focusedVowel != null && _containsHangulVowel(item.text, focusedVowel);
    if (matchesConsonant) {
      weight += 60;
    }
    if (matchesVowel) {
      weight += 24;
    }
    if ((focusedConsonant != null || focusedVowel != null) &&
        !matchesConsonant &&
        !matchesVowel) {
      weight -= 6;
    }

    return max(weight, 1);
  }

  bool _matchesFocusedConsonant(
    PracticeContentItem item,
    String focusedConsonant,
  ) {
    return item.targetSounds.any(
          (sound) => _isSameConsonantFamily(sound, focusedConsonant),
        ) ||
        _containsHangulConsonant(item.text, focusedConsonant);
  }

  List<PracticeContentItem> _focusedWordItems(
    List<PracticeContentItem> items,
    String? focusedConsonant,
    String? focusedVowel,
  ) {
    if (focusedConsonant == null && focusedVowel == null) {
      return const [];
    }

    return items.where((item) {
      final matchesConsonant =
          focusedConsonant == null ||
          _matchesFocusedConsonant(item, focusedConsonant);
      final matchesVowel =
          focusedVowel == null || _containsHangulVowel(item.text, focusedVowel);
      return matchesConsonant && matchesVowel;
    }).toList();
  }

  bool _containsHangulConsonant(String text, String consonant) {
    return _decomposeHangul(text).any(
      (sound) =>
          _isSameConsonantFamily(sound.initial, consonant) ||
          (sound.finalConsonant != null &&
              _isSameConsonantFamily(sound.finalConsonant!, consonant)),
    );
  }

  bool _containsHangulVowel(String text, String vowel) {
    return _decomposeHangul(
      text,
    ).any((sound) => _isSameVowelFamily(sound.vowel, vowel));
  }

  bool _isSameConsonantFamily(String sound, String focusedConsonant) {
    return sound == focusedConsonant || sound.contains(focusedConsonant);
  }

  bool _isSameVowelFamily(String sound, String focusedVowel) {
    const compoundVowels = {
      'ㅘ': {'ㅗ', 'ㅏ'},
      'ㅙ': {'ㅗ', 'ㅐ'},
      'ㅚ': {'ㅗ', 'ㅣ'},
      'ㅝ': {'ㅜ', 'ㅓ'},
      'ㅞ': {'ㅜ', 'ㅔ'},
      'ㅟ': {'ㅜ', 'ㅣ'},
      'ㅢ': {'ㅡ', 'ㅣ'},
    };
    return sound == focusedVowel ||
        (compoundVowels[sound]?.contains(focusedVowel) ?? false);
  }

  List<({String initial, String vowel, String? finalConsonant})>
  _decomposeHangul(String text) {
    const initials = [
      'ㄱ',
      'ㄲ',
      'ㄴ',
      'ㄷ',
      'ㄸ',
      'ㄹ',
      'ㅁ',
      'ㅂ',
      'ㅃ',
      'ㅅ',
      'ㅆ',
      'ㅇ',
      'ㅈ',
      'ㅉ',
      'ㅊ',
      'ㅋ',
      'ㅌ',
      'ㅍ',
      'ㅎ',
    ];
    const vowels = [
      'ㅏ',
      'ㅐ',
      'ㅑ',
      'ㅒ',
      'ㅓ',
      'ㅔ',
      'ㅕ',
      'ㅖ',
      'ㅗ',
      'ㅘ',
      'ㅙ',
      'ㅚ',
      'ㅛ',
      'ㅜ',
      'ㅝ',
      'ㅞ',
      'ㅟ',
      'ㅠ',
      'ㅡ',
      'ㅢ',
      'ㅣ',
    ];
    const finals = [
      null,
      'ㄱ',
      'ㄲ',
      'ㄳ',
      'ㄴ',
      'ㄵ',
      'ㄶ',
      'ㄷ',
      'ㄹ',
      'ㄺ',
      'ㄻ',
      'ㄼ',
      'ㄽ',
      'ㄾ',
      'ㄿ',
      'ㅀ',
      'ㅁ',
      'ㅂ',
      'ㅄ',
      'ㅅ',
      'ㅆ',
      'ㅇ',
      'ㅈ',
      'ㅊ',
      'ㅋ',
      'ㅌ',
      'ㅍ',
      'ㅎ',
    ];

    final sounds = <({String initial, String vowel, String? finalConsonant})>[];
    for (final codeUnit in text.runes) {
      if (codeUnit < 0xAC00 || codeUnit > 0xD7A3) {
        continue;
      }
      final syllableIndex = codeUnit - 0xAC00;
      final initialIndex = syllableIndex ~/ 588;
      final vowelIndex = (syllableIndex % 588) ~/ 28;
      final finalIndex = syllableIndex % 28;
      sounds.add((
        initial: initials[initialIndex],
        vowel: vowels[vowelIndex],
        finalConsonant: finals[finalIndex],
      ));
    }
    return sounds;
  }
}

class CustomPracticeContentService {
  static const String _storageKey = 'custom_long_sentence_items';
  static const int minStoryLength = 300;
  static const int maxStoryLength = 1600;

  Future<List<PracticeContentItem>> loadLongSentences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => _fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<PracticeContentItem> addLongSentence({
    required String text,
    required String category,
  }) async {
    final sentence = _normalizeText(text);
    final item = PracticeContentItem(
      id: 'custom_long_${DateTime.now().microsecondsSinceEpoch}',
      mode: PracticeMode.longSentence,
      text: sentence,
      category: category.trim().isEmpty ? '내 문장' : category.trim(),
      difficulty: estimateDifficulty(sentence),
      source: PracticeContentSource.custom,
    );

    final items = await loadLongSentences();
    items.insert(0, item);
    await _save(items);
    return item;
  }

  Future<void> updateLongSentence({
    required String id,
    required String text,
    required String category,
  }) async {
    final sentence = _normalizeText(text);
    final items = await loadLongSentences();
    final index = items.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    items[index] = PracticeContentItem(
      id: id,
      mode: PracticeMode.longSentence,
      text: sentence,
      category: category.trim().isEmpty ? '내 문장' : category.trim(),
      difficulty: estimateDifficulty(sentence),
      source: PracticeContentSource.custom,
    );
    await _save(items);
  }

  Future<void> deleteLongSentence(String id) async {
    final items = await loadLongSentences();
    items.removeWhere((item) => item.id == id);
    await _save(items);
  }

  static int estimateDifficulty(String text) {
    final length = _normalizeText(text).replaceAll(' ', '').length;
    if (length <= 400) {
      return 1;
    }
    if (length <= 800) {
      return 2;
    }
    return 3;
  }

  Future<void> _save(List<PracticeContentItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(items.map(_toJson).toList()));
  }

  Map<String, dynamic> _toJson(PracticeContentItem item) => {
    'id': item.id,
    'text': item.text,
    'category': item.category,
    'difficulty': item.difficulty,
    'source': item.source.storageValue,
  };

  PracticeContentItem _fromJson(Map<String, dynamic> json) {
    final text = _normalizeText(json['text'] as String? ?? '');
    return PracticeContentItem(
      id: json['id'] as String? ?? 'custom_long_legacy',
      mode: PracticeMode.longSentence,
      text: text,
      category: json['category'] as String? ?? '내 문장',
      difficulty: json['difficulty'] as int? ?? estimateDifficulty(text),
      source: PracticeContentSourceValue.fromStorageValue(
        json['source'] as String?,
      ),
    );
  }

  static String _normalizeText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
