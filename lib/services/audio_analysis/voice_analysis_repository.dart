import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';

class VoiceAnalysisRepository {
  static const storageKey = 'voice_analysis_sessions_v1';

  Future<List<VoiceAnalysisSession>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return [];
    try {
      final values = jsonDecode(raw) as List<dynamic>;
      return values
          .map(
            (value) =>
                VoiceAnalysisSession.fromJson(value as Map<String, dynamic>),
          )
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> save(VoiceAnalysisSession session) async {
    final sessions = await load();
    sessions.removeWhere((value) => value.id == session.id);
    sessions.insert(0, session);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(sessions.map((value) => value.toJson()).toList()),
    );
  }

  Future<void> delete(String id) async {
    final sessions = await load()
      ..removeWhere((value) => value.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(sessions.map((value) => value.toJson()).toList()),
    );
  }
}
