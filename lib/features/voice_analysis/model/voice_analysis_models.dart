import 'dart:math' as math;

enum VoiceAnalysisTaskType {
  pitch,
  targetTone,
  volume,
  spectrogram,
  balancedSentence,
  quickRecording,
}

class VoiceAnalysisFrame {
  const VoiceAnalysisFrame({
    required this.timestamp,
    required this.waveform,
    required this.spectrum,
    required this.dbfs,
    required this.peak,
    required this.noiseFloorDbfs,
    required this.clipping,
    this.pitchHz,
    this.pitchConfidence = 0,
  });

  final Duration timestamp;
  final List<double> waveform;
  final List<double> spectrum;
  final double dbfs;
  final double peak;
  final double noiseFloorDbfs;
  final bool clipping;
  final double? pitchHz;
  final double pitchConfidence;

  bool get hasReliablePitch =>
      pitchHz != null && pitchConfidence >= 0.55 && pitchHz! >= 60;
}

class VoiceAnalysisMetrics {
  const VoiceAnalysisMetrics({
    this.medianPitchHz,
    this.meanPitchHz,
    this.minPitchHz,
    this.maxPitchHz,
    this.pitchVariability = 0,
    this.voicedFrameRatio = 0,
    this.medianDbfs = -80,
    this.volumeVariability = 0,
    this.noiseFloorDbfs = -80,
    this.clippingRatio = 0,
    this.phonationDurationMs = 0,
    this.analysisConfidence = 0,
  });

  final double? medianPitchHz;
  final double? meanPitchHz;
  final double? minPitchHz;
  final double? maxPitchHz;
  final double pitchVariability;
  final double voicedFrameRatio;
  final double medianDbfs;
  final double volumeVariability;
  final double noiseFloorDbfs;
  final double clippingRatio;
  final int phonationDurationMs;
  final double analysisConfidence;

  Map<String, dynamic> toJson() => {
    'medianPitchHz': medianPitchHz,
    'meanPitchHz': meanPitchHz,
    'minPitchHz': minPitchHz,
    'maxPitchHz': maxPitchHz,
    'pitchVariability': pitchVariability,
    'voicedFrameRatio': voicedFrameRatio,
    'medianDbfs': medianDbfs,
    'volumeVariability': volumeVariability,
    'noiseFloorDbfs': noiseFloorDbfs,
    'clippingRatio': clippingRatio,
    'phonationDurationMs': phonationDurationMs,
    'analysisConfidence': analysisConfidence,
  };

  factory VoiceAnalysisMetrics.fromJson(Map<String, dynamic> json) {
    double? nullableDouble(Object? value) =>
        value is num ? value.toDouble() : null;
    double value(Object? raw, double fallback) =>
        raw is num ? raw.toDouble() : fallback;

    return VoiceAnalysisMetrics(
      medianPitchHz: nullableDouble(json['medianPitchHz']),
      meanPitchHz: nullableDouble(json['meanPitchHz']),
      minPitchHz: nullableDouble(json['minPitchHz']),
      maxPitchHz: nullableDouble(json['maxPitchHz']),
      pitchVariability: value(json['pitchVariability'], 0),
      voicedFrameRatio: value(json['voicedFrameRatio'], 0),
      medianDbfs: value(json['medianDbfs'], -80),
      volumeVariability: value(json['volumeVariability'], 0),
      noiseFloorDbfs: value(json['noiseFloorDbfs'], -80),
      clippingRatio: value(json['clippingRatio'], 0),
      phonationDurationMs: json['phonationDurationMs'] as int? ?? 0,
      analysisConfidence: value(json['analysisConfidence'], 0),
    );
  }

  static VoiceAnalysisMetrics fromFrames(List<VoiceAnalysisFrame> frames) {
    if (frames.isEmpty) return const VoiceAnalysisMetrics();
    final pitches = frames
        .where((frame) => frame.hasReliablePitch)
        .map((frame) => frame.pitchHz!)
        .toList();
    final volumes = frames.map((frame) => frame.dbfs).toList();
    final confidences = frames.map((frame) => frame.pitchConfidence).toList();
    final noiseFloors = frames.map((frame) => frame.noiseFloorDbfs).toList();

    return VoiceAnalysisMetrics(
      medianPitchHz: pitches.isEmpty ? null : _median(pitches),
      meanPitchHz: pitches.isEmpty ? null : _mean(pitches),
      minPitchHz: pitches.isEmpty ? null : pitches.reduce(math.min),
      maxPitchHz: pitches.isEmpty ? null : pitches.reduce(math.max),
      pitchVariability: pitches.isEmpty ? 0 : _standardDeviation(pitches),
      voicedFrameRatio: pitches.length / frames.length,
      medianDbfs: _median(volumes),
      volumeVariability: _standardDeviation(volumes),
      noiseFloorDbfs: _median(noiseFloors),
      clippingRatio:
          frames.where((frame) => frame.clipping).length / frames.length,
      phonationDurationMs: frames.last.timestamp.inMilliseconds,
      analysisConfidence: _mean(confidences).clamp(0, 1),
    );
  }

  static double _mean(List<double> values) =>
      values.reduce((a, b) => a + b) / values.length;

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static double _standardDeviation(List<double> values) {
    if (values.length < 2) return 0;
    final mean = _mean(values);
    final variance =
        values
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
    return math.sqrt(variance);
  }
}

class VoiceAnalysisSession {
  const VoiceAnalysisSession({
    required this.id,
    required this.taskType,
    required this.startedAt,
    required this.durationSeconds,
    required this.metrics,
    required this.analysisVersion,
    this.promptId,
    this.audioPath,
    this.routineSessionId,
    this.isReference = false,
  });

  final String id;
  final VoiceAnalysisTaskType taskType;
  final DateTime startedAt;
  final int durationSeconds;
  final VoiceAnalysisMetrics metrics;
  final String analysisVersion;
  final String? promptId;
  final String? audioPath;
  final String? routineSessionId;
  final bool isReference;

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskType': taskType.name,
    'startedAt': startedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'metrics': metrics.toJson(),
    'analysisVersion': analysisVersion,
    'promptId': promptId,
    'audioPath': audioPath,
    'routineSessionId': routineSessionId,
    'isReference': isReference,
  };

  factory VoiceAnalysisSession.fromJson(Map<String, dynamic> json) {
    return VoiceAnalysisSession(
      id: json['id'] as String,
      taskType: VoiceAnalysisTaskType.values.firstWhere(
        (value) => value.name == json['taskType'],
        orElse: () => VoiceAnalysisTaskType.pitch,
      ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      metrics: VoiceAnalysisMetrics.fromJson(
        json['metrics'] as Map<String, dynamic>? ?? const {},
      ),
      analysisVersion: json['analysisVersion'] as String? ?? '1',
      promptId: json['promptId'] as String?,
      audioPath: json['audioPath'] as String?,
      routineSessionId: json['routineSessionId'] as String?,
      isReference: json['isReference'] as bool? ?? false,
    );
  }
}
