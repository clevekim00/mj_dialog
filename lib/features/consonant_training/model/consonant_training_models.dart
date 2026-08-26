enum PhonemePosition { onset, coda }

extension PhonemePositionLabel on PhonemePosition {
  String get label => this == PhonemePosition.onset ? '초성' : '받침';

  String get storageValue => name;

  static PhonemePosition fromValue(String? value) =>
      value == 'coda' ? PhonemePosition.coda : PhonemePosition.onset;
}

enum ConsonantTrainingLevel { syllable, word, sentence }

extension ConsonantTrainingLevelLabel on ConsonantTrainingLevel {
  String get label => switch (this) {
    ConsonantTrainingLevel.syllable => '음절',
    ConsonantTrainingLevel.word => '단어',
    ConsonantTrainingLevel.sentence => '짧은 문장',
  };

  static ConsonantTrainingLevel fromValue(String? value) => switch (value) {
    'syllable' => ConsonantTrainingLevel.syllable,
    'word' => ConsonantTrainingLevel.word,
    _ => ConsonantTrainingLevel.sentence,
  };
}

class ConsonantTrainingTarget {
  const ConsonantTrainingTarget({
    required this.id,
    required this.grapheme,
    required this.phone,
    required this.position,
    required this.description,
    this.isControl = false,
  });

  final String id;
  final String grapheme;
  final String phone;
  final PhonemePosition position;
  final String description;
  final bool isControl;

  factory ConsonantTrainingTarget.fromJson(Map<String, dynamic> json) =>
      ConsonantTrainingTarget(
        id: json['id'] as String,
        grapheme: json['grapheme'] as String,
        phone: json['phone'] as String,
        position: PhonemePositionLabel.fromValue(json['position'] as String?),
        description: json['description'] as String? ?? '',
        isControl: json['isControl'] as bool? ?? false,
      );
}

class PronunciationContentItem {
  const PronunciationContentItem({
    required this.id,
    required this.targetId,
    required this.level,
    required this.text,
    required this.pronunciation,
    required this.difficulty,
    required this.category,
    required this.targetOccurrenceCount,
    this.referenceAudioAsset,
    this.reviewStatus = 'generated_validated',
  });

  final String id;
  final String targetId;
  final ConsonantTrainingLevel level;
  final String text;
  final List<String> pronunciation;
  final int difficulty;
  final String category;
  final int targetOccurrenceCount;
  final String? referenceAudioAsset;
  final String reviewStatus;

  factory PronunciationContentItem.fromJson(Map<String, dynamic> json) =>
      PronunciationContentItem(
        id: json['id'] as String,
        targetId: json['targetId'] as String,
        level: ConsonantTrainingLevelLabel.fromValue(json['level'] as String?),
        text: json['text'] as String,
        pronunciation: (json['pronunciation'] as List<dynamic>? ?? const [])
            .cast<String>(),
        difficulty: json['difficulty'] as int? ?? 1,
        category: json['category'] as String? ?? '일상',
        targetOccurrenceCount: json['targetOccurrenceCount'] as int? ?? 1,
        referenceAudioAsset: json['referenceAudioAsset'] as String?,
        reviewStatus: json['reviewStatus'] as String? ?? 'generated_validated',
      );
}

class PronunciationContentPack {
  const PronunciationContentPack({
    required this.id,
    required this.schemaVersion,
    required this.version,
    required this.targets,
    required this.items,
    required this.source,
  });

  final String id;
  final int schemaVersion;
  final String version;
  final List<ConsonantTrainingTarget> targets;
  final List<PronunciationContentItem> items;
  final String source;

  factory PronunciationContentPack.fromJson(
    Map<String, dynamic> json, {
    String source = 'bundled',
  }) => PronunciationContentPack(
    id: json['id'] as String? ?? 'ko-consonant-core',
    schemaVersion: json['schemaVersion'] as int? ?? 1,
    version: json['version'] as String? ?? '0',
    targets: (json['targets'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ConsonantTrainingTarget.fromJson)
        .toList(growable: false),
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PronunciationContentItem.fromJson)
        .toList(growable: false),
    source: source,
  );

  List<PronunciationContentItem> itemsFor(
    String targetId,
    ConsonantTrainingLevel level,
  ) => items
      .where((item) => item.targetId == targetId && item.level == level)
      .toList(growable: false);
}

enum PronunciationAnalysisStatus {
  queued,
  processing,
  completed,
  unavailable,
  failed,
}

enum PhonemeFeedbackStatus { accurate, caution, retry, unavailable }

class PhoneCandidate {
  const PhoneCandidate({required this.phone, required this.probability});
  final String phone;
  final double probability;

  factory PhoneCandidate.fromJson(Map<String, dynamic> json) => PhoneCandidate(
    phone: json['phone'] as String? ?? '',
    probability: (json['probability'] as num?)?.toDouble() ?? 0,
  );
}

class PhonemeAnalysisResult {
  const PhonemeAnalysisResult({
    required this.expectedPhone,
    required this.observedCandidates,
    required this.position,
    required this.startMs,
    required this.endMs,
    required this.rawGop,
    required this.practiceScore,
    required this.confidence,
    required this.status,
    this.errorType,
  });

  final String expectedPhone;
  final List<PhoneCandidate> observedCandidates;
  final PhonemePosition position;
  final int startMs;
  final int endMs;
  final double rawGop;
  final int practiceScore;
  final double confidence;
  final PhonemeFeedbackStatus status;
  final String? errorType;

  factory PhonemeAnalysisResult.fromJson(Map<String, dynamic> json) =>
      PhonemeAnalysisResult(
        expectedPhone: json['expected'] as String? ?? '',
        observedCandidates:
            (json['observedCandidates'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(PhoneCandidate.fromJson)
                .toList(growable: false),
        position: PhonemePositionLabel.fromValue(json['position'] as String?),
        startMs: json['startMs'] as int? ?? 0,
        endMs: json['endMs'] as int? ?? 0,
        rawGop: (json['gop'] as num?)?.toDouble() ?? 0,
        practiceScore: json['practiceScore'] as int? ?? 0,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        status: switch (json['status']) {
          'accurate' => PhonemeFeedbackStatus.accurate,
          'caution' => PhonemeFeedbackStatus.caution,
          'retry' => PhonemeFeedbackStatus.retry,
          _ => PhonemeFeedbackStatus.unavailable,
        },
        errorType: json['errorType'] as String?,
      );
}

class PronunciationAnalysisResult {
  const PronunciationAnalysisResult({
    required this.jobId,
    required this.status,
    required this.modelVersion,
    required this.contentVersion,
    required this.overallPracticeScore,
    required this.confidence,
    required this.phonemes,
    required this.baselineDelta,
    required this.signalAccepted,
    required this.disclaimer,
    this.message,
  });

  final String jobId;
  final PronunciationAnalysisStatus status;
  final String modelVersion;
  final String contentVersion;
  final int? overallPracticeScore;
  final double confidence;
  final List<PhonemeAnalysisResult> phonemes;
  final double? baselineDelta;
  final bool signalAccepted;
  final String disclaimer;
  final String? message;

  bool get hasReliableScore =>
      status == PronunciationAnalysisStatus.completed &&
      signalAccepted &&
      overallPracticeScore != null &&
      confidence >= 0.55;

  factory PronunciationAnalysisResult.fromJson(Map<String, dynamic> json) {
    final signal = json['signalQuality'] as Map<String, dynamic>?;
    return PronunciationAnalysisResult(
      jobId: json['jobId'] as String? ?? '',
      status: switch (json['status']) {
        'queued' => PronunciationAnalysisStatus.queued,
        'processing' => PronunciationAnalysisStatus.processing,
        'completed' => PronunciationAnalysisStatus.completed,
        'failed' => PronunciationAnalysisStatus.failed,
        _ => PronunciationAnalysisStatus.unavailable,
      },
      modelVersion: json['modelVersion'] as String? ?? 'unknown',
      contentVersion: json['contentVersion'] as String? ?? 'unknown',
      overallPracticeScore: json['overallPracticeScore'] as int?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      phonemes: (json['phonemes'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PhonemeAnalysisResult.fromJson)
          .toList(growable: false),
      baselineDelta: (json['baselineDelta'] as num?)?.toDouble(),
      signalAccepted: signal?['accepted'] as bool? ?? false,
      disclaimer:
          json['disclaimer'] as String? ?? '훈련 참고용 자동 분석이며 임상 진단이 아닙니다.',
      message: json['message'] as String?,
    );
  }

  factory PronunciationAnalysisResult.unavailable(String message) =>
      PronunciationAnalysisResult(
        jobId: '',
        status: PronunciationAnalysisStatus.unavailable,
        modelVersion: 'unavailable',
        contentVersion: 'unknown',
        overallPracticeScore: null,
        confidence: 0,
        phonemes: const [],
        baselineDelta: null,
        signalAccepted: false,
        disclaimer: '훈련 참고용 자동 분석이며 임상 진단이 아닙니다.',
        message: message,
      );
}

class ConsonantTrainingAttempt {
  const ConsonantTrainingAttempt({
    required this.id,
    required this.targetId,
    required this.contentId,
    required this.text,
    required this.level,
    required this.audioFilePath,
    required this.createdAt,
    required this.analysis,
  });

  final String id;
  final String targetId;
  final String contentId;
  final String text;
  final ConsonantTrainingLevel level;
  final String audioFilePath;
  final DateTime createdAt;
  final PronunciationAnalysisResult analysis;

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetId': targetId,
    'contentId': contentId,
    'text': text,
    'level': level.name,
    'audioFilePath': audioFilePath,
    'createdAt': createdAt.toIso8601String(),
    'analysis': {
      'jobId': analysis.jobId,
      'status': analysis.status.name,
      'modelVersion': analysis.modelVersion,
      'contentVersion': analysis.contentVersion,
      'overallPracticeScore': analysis.overallPracticeScore,
      'confidence': analysis.confidence,
      'baselineDelta': analysis.baselineDelta,
      'signalQuality': {'accepted': analysis.signalAccepted},
      'phonemes': analysis.phonemes
          .map(
            (item) => {
              'expected': item.expectedPhone,
              'observedCandidates': item.observedCandidates
                  .map(
                    (candidate) => {
                      'phone': candidate.phone,
                      'probability': candidate.probability,
                    },
                  )
                  .toList(),
              'position': item.position.name,
              'startMs': item.startMs,
              'endMs': item.endMs,
              'gop': item.rawGop,
              'practiceScore': item.practiceScore,
              'confidence': item.confidence,
              'status': item.status.name,
              'errorType': item.errorType,
            },
          )
          .toList(),
      'disclaimer': analysis.disclaimer,
      'message': analysis.message,
    },
  };

  factory ConsonantTrainingAttempt.fromJson(Map<String, dynamic> json) =>
      ConsonantTrainingAttempt(
        id: json['id'] as String,
        targetId: json['targetId'] as String,
        contentId: json['contentId'] as String,
        text: json['text'] as String,
        level: ConsonantTrainingLevelLabel.fromValue(json['level'] as String?),
        audioFilePath: json['audioFilePath'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        analysis: PronunciationAnalysisResult.fromJson(
          json['analysis'] as Map<String, dynamic>? ?? const {},
        ),
      );
}

class ConsonantBaseline {
  const ConsonantBaseline({
    required this.targetId,
    required this.medianScore,
    required this.variability,
    required this.validAttemptCount,
    required this.modelVersion,
  });

  final String targetId;
  final double medianScore;
  final double variability;
  final int validAttemptCount;
  final String modelVersion;
}
