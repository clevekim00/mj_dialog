import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/tongue_exercise/model/tongue_exercise_step.dart';

final tongueExerciseHistoryServiceProvider = Provider(
  (ref) => TongueExerciseHistoryService(),
);

class TongueExerciseHistoryService {
  static const String _storageKey = 'tongue_exercise_history';

  Future<void> saveSession(TongueExerciseSession session) async {
    final sessions = await loadSessions();
    sessions.insert(0, session);

    final prefs = await SharedPreferences.getInstance();
    final jsonList = sessions.map((session) => session.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<List<TongueExerciseSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map(
            (json) =>
                TongueExerciseSession.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
