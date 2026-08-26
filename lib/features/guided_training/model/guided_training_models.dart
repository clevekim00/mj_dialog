enum GuidedTrainingCategory { tongue, lip, alternating, breathing }

extension GuidedTrainingCategoryLabel on GuidedTrainingCategory {
  String get label => switch (this) {
    GuidedTrainingCategory.tongue => '혀 운동',
    GuidedTrainingCategory.lip => '입술 운동',
    GuidedTrainingCategory.alternating => '교호 운동',
    GuidedTrainingCategory.breathing => '호흡 훈련',
  };

  String get description => switch (this) {
    GuidedTrainingCategory.tongue => '혀의 방향과 움직임을 천천히 연습해요.',
    GuidedTrainingCategory.lip => '입술 모양과 표정을 또렷하게 바꿔요.',
    GuidedTrainingCategory.alternating => '음절을 일정한 박자로 반복해요.',
    GuidedTrainingCategory.breathing => '호흡과 지속 발성을 편안하게 연습해요.',
  };
}

enum GuidedTrainingSafetyTier { general, caution, clinicianOnly }

extension GuidedTrainingSafetyLabel on GuidedTrainingSafetyTier {
  String get label => switch (this) {
    GuidedTrainingSafetyTier.general => '일반',
    GuidedTrainingSafetyTier.caution => '주의',
    GuidedTrainingSafetyTier.clinicianOnly => '전문가 확인',
  };
}

enum GuidedTrainingVisualMode { faceCloseUp, oralCutaway, upperBody, phoneme }

class GuidedTrainingExercise {
  const GuidedTrainingExercise({
    required this.id,
    required this.category,
    required this.sourceOrder,
    required this.title,
    required this.instruction,
    required this.shortCaption,
    required this.visualMode,
    this.videoAsset,
    this.defaultRepeatCount = 20,
    this.loopDuration = const Duration(seconds: 5),
    this.safetyTier = GuidedTrainingSafetyTier.general,
    this.safetyMessage,
  });

  final String id;
  final GuidedTrainingCategory category;
  final int sourceOrder;
  final String title;
  final String instruction;
  final String shortCaption;
  final GuidedTrainingVisualMode visualMode;
  final String? videoAsset;
  final int defaultRepeatCount;
  final Duration loopDuration;
  final GuidedTrainingSafetyTier safetyTier;
  final String? safetyMessage;

  bool get hasVideo => videoAsset != null;
}

class GuidedTrainingExerciseResult {
  const GuidedTrainingExerciseResult({
    required this.exerciseId,
    required this.targetLoops,
    required this.completedLoops,
    required this.playbackSpeed,
    required this.skipped,
    required this.videoFailed,
  });

  final String exerciseId;
  final int targetLoops;
  final int completedLoops;
  final double playbackSpeed;
  final bool skipped;
  final bool videoFailed;

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'targetLoops': targetLoops,
    'completedLoops': completedLoops,
    'playbackSpeed': playbackSpeed,
    'skipped': skipped,
    'videoFailed': videoFailed,
  };

  factory GuidedTrainingExerciseResult.fromJson(Map<String, dynamic> json) {
    return GuidedTrainingExerciseResult(
      exerciseId: json['exerciseId'] as String? ?? '',
      targetLoops: json['targetLoops'] as int? ?? 0,
      completedLoops: json['completedLoops'] as int? ?? 0,
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1,
      skipped: json['skipped'] as bool? ?? false,
      videoFailed: json['videoFailed'] as bool? ?? false,
    );
  }
}

class GuidedTrainingSession {
  const GuidedTrainingSession({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.routineName,
    required this.fatigueBefore,
    required this.fatigueAfter,
    required this.results,
    this.schemaVersion = 1,
    this.contentVersion = '2026.08',
  });

  final String id;
  final DateTime startedAt;
  final DateTime completedAt;
  final String routineName;
  final int fatigueBefore;
  final int? fatigueAfter;
  final List<GuidedTrainingExerciseResult> results;
  final int schemaVersion;
  final String contentVersion;

  bool get completed =>
      results.isNotEmpty && results.any((result) => result.completedLoops > 0);

  int get completedExerciseCount => results
      .where((result) => !result.skipped && result.completedLoops > 0)
      .length;

  int get durationSeconds => completedAt.difference(startedAt).inSeconds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'routineName': routineName,
    'fatigueBefore': fatigueBefore,
    'fatigueAfter': fatigueAfter,
    'results': results.map((result) => result.toJson()).toList(),
    'schemaVersion': schemaVersion,
    'contentVersion': contentVersion,
  };

  factory GuidedTrainingSession.fromJson(Map<String, dynamic> json) {
    return GuidedTrainingSession(
      id: json['id'] as String? ?? '',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      routineName: json['routineName'] as String? ?? '구강·호흡 훈련',
      fatigueBefore: json['fatigueBefore'] as int? ?? 1,
      fatigueAfter: json['fatigueAfter'] as int?,
      results: (json['results'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GuidedTrainingExerciseResult.fromJson)
          .toList(),
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      contentVersion: json['contentVersion'] as String? ?? '2026.08',
    );
  }
}
