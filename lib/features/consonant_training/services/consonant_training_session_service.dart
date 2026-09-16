import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';
import 'package:synchronized/synchronized.dart';

/// A small, finite recording practice plan. Progress never implies accuracy.
class ConsonantTrainingProgress {
  const ConsonantTrainingProgress({
    required this.targetId,
    required this.grapheme,
    required this.position,
    required this.level,
    required this.itemIndex,
    required this.repetitions,
    required this.completedAttempts,
    required this.completed,
    required this.updatedAt,
    this.language = 'ko-KR',
    this.contentId,
  });

  final String targetId;
  final String grapheme;
  final PhonemePosition position;
  final ConsonantTrainingLevel level;
  final int itemIndex;
  final int repetitions;
  final int completedAttempts;
  final bool completed;
  final DateTime updatedAt;
  final String language;
  final String? contentId;

  Map<String, dynamic> toJson() => {
    'targetId': targetId,
    'grapheme': grapheme,
    'position': position.name,
    'level': level.name,
    'itemIndex': itemIndex,
    'repetitions': repetitions,
    'completedAttempts': completedAttempts,
    'completed': completed,
    'updatedAt': updatedAt.toIso8601String(),
    'language': language,
    'contentId': contentId,
  };

  factory ConsonantTrainingProgress.fromJson(Map<String, dynamic> json) {
    final repetitions = (json['repetitions'] as int? ?? 3).clamp(1, 10);
    final count = (json['completedAttempts'] as int? ?? 0).clamp(
      0,
      repetitions,
    );
    return ConsonantTrainingProgress(
      targetId: json['targetId'] as String,
      grapheme: json['grapheme'] as String,
      position: PhonemePositionLabel.fromValue(json['position'] as String?),
      level: ConsonantTrainingLevelLabel.fromValue(json['level'] as String?),
      itemIndex: (json['itemIndex'] as int? ?? 0).clamp(0, 100000),
      repetitions: repetitions,
      completedAttempts: count,
      completed: json['completed'] == true || count >= repetitions,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      language: json['language'] as String? ?? 'ko-KR',
      contentId: json['contentId'] as String?,
    );
  }
}

class ConsonantTrainingSessionService {
  ConsonantTrainingSessionService({SharedPreferences? preferences})
    : _preferences = preferences;

  SharedPreferences? _preferences;
  static final _lock = Lock();
  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();
  String _key(String language) => 'consonant_training_progress_v1_$language';

  Future<ConsonantTrainingProgress?> load({String language = 'ko-KR'}) async {
    final raw = (await _prefs).getString(_key(language));
    if (raw == null) return null;
    try {
      final progress = ConsonantTrainingProgress.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return progress.language == language ? progress : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ConsonantTrainingProgress progress) =>
      _lock.synchronized(() async {
        final saved = await (await _prefs).setString(
          _key(progress.language),
          jsonEncode(progress.toJson()),
        );
        if (!saved) throw StateError('자음 연습 정보를 저장하지 못했습니다.');
      });
}
