import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  final String sessionGoal;
  final int fatigueBefore;
  final int? fatigueAfter;
  final int durationSeconds;
  final String mode;
  final String? contentId;
  final String category;
  final int difficulty;
  final int retryCount;
  final int streakCount;
  final int? previousBestScore;
  final String contentSource;

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
    this.sessionGoal = '또렷하게 말하기',
    this.fatigueBefore = 1,
    this.fatigueAfter,
    this.durationSeconds = 0,
    this.mode = 'shortSentence',
    this.contentId,
    this.category = '일반',
    this.difficulty = 1,
    this.retryCount = 0,
    this.streakCount = 0,
    this.previousBestScore,
    this.contentSource = 'builtIn',
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
    'sessionGoal': sessionGoal,
    'fatigueBefore': fatigueBefore,
    'fatigueAfter': fatigueAfter,
    'durationSeconds': durationSeconds,
    'mode': mode,
    'contentId': contentId,
    'category': category,
    'difficulty': difficulty,
    'retryCount': retryCount,
    'streakCount': streakCount,
    'previousBestScore': previousBestScore,
    'contentSource': contentSource,
  };

  factory PracticeSession.fromJson(Map<String, dynamic> json) =>
      PracticeSession(
        id: json['id'] as String,
        targetText: json['targetText'] as String,
        spokenText: json['spokenText'] as String,
        audioFilePath: json['audioFilePath'] as String,
        score: json['score'] as int,
        feedback: json['feedback'] as String,
        phonemeAccuracy: (json['phonemeAccuracy'] as List?)
            ?.cast<Map<String, dynamic>>(),
        intonationFeedback: json['intonationFeedback'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        sessionGoal: json['sessionGoal'] as String? ?? '또렷하게 말하기',
        fatigueBefore: json['fatigueBefore'] as int? ?? 1,
        fatigueAfter: json['fatigueAfter'] as int?,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        mode: json['mode'] as String? ?? 'shortSentence',
        contentId: json['contentId'] as String?,
        category: json['category'] as String? ?? '일반',
        difficulty: json['difficulty'] as int? ?? 1,
        retryCount: json['retryCount'] as int? ?? 0,
        streakCount: json['streakCount'] as int? ?? 0,
        previousBestScore: json['previousBestScore'] as int?,
        contentSource: json['contentSource'] as String? ?? 'builtIn',
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
