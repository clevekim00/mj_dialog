import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';

class ConsonantTrainingHistoryService {
  ConsonantTrainingHistoryService({SharedPreferences? preferences})
    : _preferences = preferences;

  static const _storageKey = 'consonant_training_attempts_v1';
  SharedPreferences? _preferences;

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

  Future<void> add(ConsonantTrainingAttempt attempt) async {
    final attempts = [attempt, ...await load()].take(500).toList();
    await (await _prefs).setString(
      _storageKey,
      jsonEncode(attempts.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> clear() async => (await _prefs).remove(_storageKey);

  ConsonantBaseline? baselineFor(
    List<ConsonantTrainingAttempt> attempts,
    String targetId,
  ) {
    final valid = attempts
        .where(
          (item) => item.targetId == targetId && item.analysis.hasReliableScore,
        )
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
