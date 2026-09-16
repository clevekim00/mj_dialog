import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:speech_rehab/services/audio_analysis/wav_file_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';

class VoiceAnalysisRepository {
  VoiceAnalysisRepository({Future<Directory> Function()? recordingsDirectory})
    : _recordingsDirectory =
          recordingsDirectory ?? voiceAnalysisRecordingDirectory;
  final Future<Directory> Function() _recordingsDirectory;
  static const storageKey = 'voice_analysis_sessions_v1';
  static Future<void> _pendingMutation = Future<void>.value();

  Future<void> _mutate(Future<void> Function() operation) {
    final result = _pendingMutation.then((_) => operation());
    _pendingMutation = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

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

  Future<void> save(VoiceAnalysisSession session) =>
      _mutate(() => _save(session));

  Future<void> _save(VoiceAnalysisSession session) async {
    final sessions = await load();
    sessions.removeWhere((value) => value.id == session.id);
    sessions.insert(0, session);
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      storageKey,
      jsonEncode(sessions.map((value) => value.toJson()).toList()),
    );
    if (!saved) throw StateError('음성 기록을 저장하지 못했습니다.');
  }

  Future<void> delete(String id) => _mutate(() => _delete(id));

  Future<void> _delete(String id) async {
    final sessions = await load();
    final removed = sessions.where((value) => value.id == id).toList();
    final remaining = sessions.where((value) => value.id != id).toList();
    final directory = path.normalize(
      (await _recordingsDirectory()).absolute.path,
    );
    final remainingPaths = remaining
        .map((value) => value.audioPath)
        .whereType<String>()
        .map((value) => path.normalize(File(value).absolute.path))
        .toSet();
    for (final audioPath
        in removed
            .map((value) => value.audioPath)
            .whereType<String>()
            .toSet()) {
      final normalized = path.normalize(File(audioPath).absolute.path);
      if (remainingPaths.contains(normalized)) continue;
      // Delete only assets owned by this feature. Never unlink arbitrary paths
      // loaded from old/imported metadata or recordings belonging to other flows.
      if (path.dirname(normalized) != directory) continue;
      final file = File(normalized);
      if (await file.exists()) await file.delete();
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      storageKey,
      jsonEncode(remaining.map((value) => value.toJson()).toList()),
    );
    if (!saved) throw StateError('음성 기록 삭제 내용을 저장하지 못했습니다.');
  }
}
