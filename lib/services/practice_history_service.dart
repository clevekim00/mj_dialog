import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PracticeSession {
  final String id;
  final String targetText;
  final String spokenText;
  final String audioFilePath;
  final int score;
  final String feedback;
  final List<Map<String, dynamic>>? phonemeAccuracy;
  final String? intonationFeedback;
  final DateTime timestamp;

  PracticeSession({
    required this.id,
    required this.targetText,
    required this.spokenText,
    required this.audioFilePath,
    required this.score,
    required this.feedback,
    this.phonemeAccuracy,
    this.intonationFeedback,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetText': targetText,
        'spokenText': spokenText,
        'audioFilePath': audioFilePath,
        'score': score,
        'feedback': feedback,
        'phonemeAccuracy': phonemeAccuracy,
        'intonationFeedback': intonationFeedback,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PracticeSession.fromJson(Map<String, dynamic> json) => PracticeSession(
        id: json['id'] as String,
        targetText: json['targetText'] as String,
        spokenText: json['spokenText'] as String,
        audioFilePath: json['audioFilePath'] as String,
        score: json['score'] as int,
        feedback: json['feedback'] as String,
        phonemeAccuracy: (json['phonemeAccuracy'] as List?)?.cast<Map<String, dynamic>>(),
        intonationFeedback: json['intonationFeedback'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class PracticeHistoryService {
  static const String _storageKey = 'practice_history';

  Future<void> savePractice(PracticeSession session) async {
    final sessions = await loadPractices();
    sessions.insert(0, session);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<List<PracticeSession>> loadPractices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((j) => PracticeSession.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deletePractice(String id) async {
    final sessions = await loadPractices();
    sessions.removeWhere((s) => s.id == id);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
