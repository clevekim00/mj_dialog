import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PracticeSession {
  final String id;
  final String targetText;
  final String spokenText;
  final String audioFilePath;
  final String? videoFilePath;
  final int? score;
  final String evaluationMethod;
  final String evaluationVersion;

  bool get hasComparableScore =>
      evaluationMethod == 'textMatch' && score != null;
  bool get isRecordedAttempt =>
      audioFilePath.isNotEmpty || spokenText.trim().isNotEmpty;
  String get scoreLabel => switch (evaluationMethod) {
    'textMatch' => '텍스트 일치도',
    'legacy' => '이전 방식 점수',
    'unavailable' => '분석 불가',
    _ => '점수 없음',
  };
  String get scoreDisplay => score == null
      ? scoreLabel
      : '$scoreLabel $score${evaluationMethod == 'textMatch' ? '%' : '점'}';

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
  final int movementScore;
  final bool isExercisePattern;

  PracticeSession({
    required this.id,
    required this.targetText,
    required this.spokenText,
    required this.audioFilePath,
    this.videoFilePath,
    required this.score,
    this.evaluationMethod = 'legacy',
    this.evaluationVersion = 'legacy',
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
    this.movementScore = 1,
    this.isExercisePattern = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetText': targetText,
    'spokenText': spokenText,
    'audioFilePath': audioFilePath,
    'videoFilePath': videoFilePath,
    'score': score,
    'evaluationMethod': evaluationMethod,
    'evaluationVersion': evaluationVersion,
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
    'movementScore': movementScore,
    'isExercisePattern': isExercisePattern,
  };

  factory PracticeSession.fromJson(Map<String, dynamic> json) =>
      PracticeSession(
        id: json['id'] as String,
        targetText: json['targetText'] as String,
        spokenText: json['spokenText'] as String,
        audioFilePath: json['audioFilePath'] as String,
        videoFilePath: json['videoFilePath'] as String?,
        score: (json['score'] as num?)?.toInt(),
        evaluationMethod: json['evaluationMethod'] as String? ?? 'legacy',
        evaluationVersion: json['evaluationVersion'] as String? ?? 'legacy',
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
        movementScore: json['movementScore'] as int? ?? 1,
        isExercisePattern: json['isExercisePattern'] as bool? ?? false,
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

  Future<void> updateFatigueAfter(String id, int value) async {
    if (value < 1 || value > 5) throw ArgumentError.value(value, 'value');
    final sessions = await loadPractices();
    final updated = sessions
        .map(
          (session) => session.id == id
              ? PracticeSession.fromJson({
                  ...session.toJson(),
                  'fatigueAfter': value,
                })
              : session,
        )
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(updated.map((s) => s.toJson()).toList()),
    );
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
