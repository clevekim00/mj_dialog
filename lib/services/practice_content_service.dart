import 'dart:convert';

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
  });

  final String id;
  final PracticeMode mode;
  final String text;
  final String category;
  final int difficulty;
  final List<String> targetSounds;
  final PracticeContentSource source;
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
    ),
    PracticeContentItem(
      id: 'word_medicine',
      mode: PracticeMode.wordGame,
      text: '약',
      category: '병원',
      difficulty: 1,
      targetSounds: ['ㅇ'],
    ),
    PracticeContentItem(
      id: 'word_hospital',
      mode: PracticeMode.wordGame,
      text: '병원',
      category: '병원',
      difficulty: 1,
      targetSounds: ['ㅂ', 'ㅇ'],
    ),
    PracticeContentItem(
      id: 'word_restroom',
      mode: PracticeMode.wordGame,
      text: '화장실',
      category: '일상',
      difficulty: 2,
      targetSounds: ['ㅎ', 'ㅈ', 'ㅅ'],
    ),
    PracticeContentItem(
      id: 'word_help',
      mode: PracticeMode.wordGame,
      text: '도와주세요',
      category: '가족',
      difficulty: 2,
      targetSounds: ['ㄷ', 'ㅈ'],
    ),
    PracticeContentItem(
      id: 'word_slowly',
      mode: PracticeMode.wordGame,
      text: '천천히',
      category: '전화',
      difficulty: 2,
      targetSounds: ['ㅊ', 'ㅎ'],
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
      text: '오늘은 발음 연습을 천천히 하면서 또렷하게 말해 보겠습니다.',
      category: '호흡 연습',
      difficulty: 3,
      targetSounds: ['ㅊ', 'ㄹ', 'ㅂ'],
    ),
    PracticeContentItem(
      id: 'long_medicine',
      mode: PracticeMode.longSentence,
      text: '병원에 가기 전에 약 먹는 시간을 가족과 함께 확인하겠습니다.',
      category: '병원',
      difficulty: 3,
      targetSounds: ['ㅂ', 'ㄱ', 'ㅎ'],
    ),
    PracticeContentItem(
      id: 'long_habit',
      mode: PracticeMode.longSentence,
      text: '꾸준한 연습만이 올바른 언어 습관을 만드는 비결입니다.',
      category: '어려운 발음',
      difficulty: 3,
      targetSounds: ['ㄲ', 'ㄹ', 'ㅂ'],
    ),
    PracticeContentItem(
      id: 'long_phone',
      mode: PracticeMode.longSentence,
      text: '전화로 말할 때는 숨을 고르고 천천히 또박또박 말하겠습니다.',
      category: '전화',
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
}

class CustomPracticeContentService {
  static const String _storageKey = 'custom_long_sentence_items';

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
    if (length <= 28) {
      return 1;
    }
    if (length <= 56) {
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
