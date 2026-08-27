import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/guided_training/model/guided_training_models.dart';

final guidedTrainingHistoryServiceProvider = Provider(
  (ref) => GuidedTrainingHistoryService(),
);

final guidedTrainingSessionsProvider =
    FutureProvider<List<GuidedTrainingSession>>(
      (ref) =>
          ref.watch(guidedTrainingHistoryServiceProvider).loadAllSessions(),
    );

class GuidedTrainingHistoryService {
  static const storageKey = 'guided_training_history_v1';
  static const legacyTongueStorageKey = 'tongue_exercise_history';

  Future<void> saveSession(GuidedTrainingSession session) async {
    final sessions = await loadSessions();
    sessions.insert(0, session);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(sessions.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<GuidedTrainingSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(storageKey);
    if (value == null) return [];
    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(GuidedTrainingSession.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<GuidedTrainingSession>> loadAllSessions() async {
    final current = await loadSessions();
    final legacy = await _loadLegacyTongueSessions();
    return [...current, ...legacy]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  Future<List<GuidedTrainingSession>> _loadLegacyTongueSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(legacyTongueStorageKey);
    if (value == null) return [];
    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      return decoded.whereType<Map<String, dynamic>>().map((json) {
        final startedAt =
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final duration = json['durationSeconds'] as int? ?? 0;
        final completedIds =
            (json['completedStepIds'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toList();
        return GuidedTrainingSession(
          id: 'legacy_${json['id'] ?? startedAt.microsecondsSinceEpoch}',
          startedAt: startedAt,
          completedAt: startedAt.add(Duration(seconds: duration)),
          routineName: '이전 혀운동 기록',
          fatigueBefore: json['fatigueBefore'] as int? ?? 1,
          fatigueAfter: json['fatigueAfter'] as int?,
          contentVersion: 'legacy',
          results: completedIds
              .map(
                (id) => GuidedTrainingExerciseResult(
                  exerciseId: id,
                  targetLoops: 1,
                  completedLoops: 1,
                  playbackSpeed: 1,
                  skipped: false,
                  videoFailed: false,
                ),
              )
              .toList(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearCurrentHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}

extension GuidedTrainingHistoryMetrics on List<GuidedTrainingSession> {
  bool get isTodayCompleted {
    final now = DateTime.now();
    return any(
      (session) =>
          session.completed &&
          session.startedAt.year == now.year &&
          session.startedAt.month == now.month &&
          session.startedAt.day == now.day,
    );
  }

  int get completedDaysInLast7 {
    final now = DateTime.now();
    return where(
          (session) =>
              session.completed && now.difference(session.startedAt).inDays < 7,
        )
        .map(
          (session) => DateTime(
            session.startedAt.year,
            session.startedAt.month,
            session.startedAt.day,
          ),
        )
        .toSet()
        .length;
  }

  int get averageDurationLast7 {
    final now = DateTime.now();
    final recent = where(
      (session) => now.difference(session.startedAt).inDays < 7,
    ).toList();
    if (recent.isEmpty) return 0;
    return recent
            .map((session) => session.durationSeconds)
            .reduce((a, b) => a + b) ~/
        recent.length;
  }
}
