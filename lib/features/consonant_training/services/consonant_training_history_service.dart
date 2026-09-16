import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';

class ConsonantTrainingHistoryService {
  ConsonantTrainingHistoryService({SharedPreferences? preferences})
    : _preferences = preferences;

  static const _storageKey = 'consonant_training_attempts_v1';
  SharedPreferences? _preferences;
  static final _lock = Lock();

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();

  Future<List<ConsonantTrainingAttempt>> load() async {
    final raw = (await _prefs).getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(ConsonantTrainingAttempt.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(ConsonantTrainingAttempt attempt) =>
      _lock.synchronized(() async {
        final attempts = [
          attempt,
          ...await load().then(
            (items) => items.where((item) => item.id != attempt.id),
          ),
        ].take(500).toList();
        final saved = await (await _prefs).setString(
          _storageKey,
          jsonEncode(attempts.map((item) => item.toJson()).toList()),
        );
        if (!saved) throw StateError('자음 연습 정보를 저장하지 못했습니다.');
      });

  /// Comparison is restricted to the same text and target in the same language.
  Future<ConsonantTrainingAttempt?> previousFor({
    required String targetId,
    required String contentId,
    required String text,
    required String language,
    String? excludingId,
  }) async {
    for (final item in await load()) {
      if (item.targetId == targetId &&
          item.contentId == contentId &&
          item.text == text &&
          item.language == language &&
          item.id != excludingId &&
          item.audioFilePath.isNotEmpty) {
        return item;
      }
    }
    return null;
  }

  Future<void> clear() async => (await _prefs).remove(_storageKey);

  ConsonantBaseline? baselineFor(
    List<ConsonantTrainingAttempt> attempts,
    String targetId, {
    String? language,
  }) {
    final candidates = attempts
        .where(
          (item) => item.targetId == targetId && item.analysis.hasReliableScore,
        )
        .toList();
    if (candidates.isEmpty) return null;
    final selectedLanguage = language ?? candidates.first.analysis.language;
    final valid = candidates
        .where((item) => item.analysis.language == selectedLanguage)
        .toList();
    if (valid.length < 3) return null;
    final modelVersion = valid.first.analysis.modelVersion;
    final scores =
        valid
            .where((item) => item.analysis.modelVersion == modelVersion)
            .map((item) => item.analysis.overallPracticeScore!.toDouble())
            .toList()
          ..sort();
    if (scores.length < 3) return null;
    final median = scores.length.isOdd
        ? scores[scores.length ~/ 2]
        : (scores[scores.length ~/ 2 - 1] + scores[scores.length ~/ 2]) / 2;
    final variance =
        scores
            .map((score) => pow(score - median, 2).toDouble())
            .reduce((a, b) => a + b) /
        scores.length;
    return ConsonantBaseline(
      targetId: targetId,
      medianScore: median,
      variability: sqrt(variance),
      validAttemptCount: scores.length,
      modelVersion: modelVersion,
    );
  }
}
