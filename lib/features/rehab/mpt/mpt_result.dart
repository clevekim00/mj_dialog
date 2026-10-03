/// Sustained /a/ with automatic or observer timing and three reviewed trials.
/// This protocol record is not an automated or clinically validated diagnosis.
class MptTrial {
  const MptTrial({
    required this.id,
    required this.durationMs,
    required this.onsetOffsetMs,
    required this.endOffsetMs,
    this.timingMethod = 'observer-stopwatch',
    this.hadGap = false,
    this.accepted = false,
    this.reason = 'unreviewed',
  });
  final String id, reason, timingMethod;
  final int durationMs, onsetOffsetMs, endOffsetMs;
  final bool accepted, hadGap;
  bool get eligible =>
      durationMs > 0 &&
      endOffsetMs > onsetOffsetMs &&
      (reason == 'unreviewed' || reason == 'confirmed');
  MptTrial reviewed(bool use) => MptTrial(
    id: id,
    durationMs: durationMs,
    onsetOffsetMs: onsetOffsetMs,
    endOffsetMs: endOffsetMs,
    timingMethod: timingMethod,
    hadGap: hadGap,
    accepted: use && eligible,
    reason: use && eligible
        ? 'confirmed'
        : eligible
        ? 'excluded'
        : reason,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'timingMethod': timingMethod,
    'hadGap': hadGap,
    'durationMs': durationMs,
    'onsetOffsetMs': onsetOffsetMs,
    'endOffsetMs': endOffsetMs,
    'accepted': accepted,
    'reason': reason,
  };
  factory MptTrial.fromJson(Map<String, dynamic> j) => MptTrial(
    id: j['id'] as String,
    hadGap: j['hadGap'] as bool? ?? false,
    timingMethod: j['timingMethod'] as String? ?? 'observer-stopwatch',
    durationMs: j['durationMs'] as int,
    onsetOffsetMs: j['onsetOffsetMs'] as int,
    endOffsetMs: j['endOffsetMs'] as int,
    accepted: j['accepted'] as bool,
    reason: j['reason'] as String,
  );
}

class MptResult {
  static const automaticProtocol = 'mpt-auto-reviewed-3-trials-v1';
  static const protocol = 'mpt-observer-3-trials-v1';
  static List<MptTrial> trials(Map<String, dynamic> feedback) =>
      (feedback['trials'] as List? ?? [])
          .map((j) => MptTrial.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
  static int? maximum(List<MptTrial> trials) {
    final valid = trials.where((t) => t.accepted && t.eligible).toList();
    if (valid.length != 3) return null;
    return valid.map((t) => t.durationMs).reduce((a, b) => a > b ? a : b);
  }

  static String reasonLabel(String reason, bool en) => switch (reason) {
    'confirmed' => en ? 'Confirmed' : '확인 완료',
    'unreviewed' => en ? 'Awaiting review' : '확인 대기',
    'interrupted' => en ? 'Interrupted' : '중단됨',
    'input_error' => en ? 'Microphone error' : '마이크 입력 오류',
    'recording_limit' => en ? 'Recording limit reached' : '녹음 한도 도달',
    'no_voice' => en ? 'No voice detected' : '발성 감지 없음',
    'noisy_environment' => en ? 'Calibration needs quiet' : '소음 확인 필요',
    'no_timed_audio' => en ? 'No timed audio' : '측정 녹음 없음',
    _ => en ? 'Excluded' : '제외됨',
  };
  static String summary(Map<String, dynamic> feedback, bool en) {
    final values = trials(feedback);
    final max = maximum(values);
    final count = values.where((t) => t.accepted && t.eligible).length;
    final automatic = feedback['timingMethod'] == 'automatic-acoustic';
    return [
      automatic
          ? (en
                ? 'MPT · automatic estimate · sustained /a/'
                : 'MPT · 자동 감지 추정 · 모음 /아/')
          : (en
                ? 'MPT · observer timer · sustained /a/'
                : 'MPT · 관찰자 타이머 · 모음 /아/'),
      if (max != null)
        en
            ? 'Maximum of 3 trials: ${(max / 1000).toStringAsFixed(1)} s'
            : '3회 중 최장 시간: ${(max / 1000).toStringAsFixed(1)}초'
      else
        en
            ? 'Incomplete: $count/3 confirmed trials. No final MPT.'
            : '미완료: 유효 시도 $count/3회. 최종 MPT 없음.',
      for (var i = 0; i < values.length; i++)
        '${i + 1}. ${(values[i].durationMs / 1000).toStringAsFixed(1)} ${en ? 's' : '초'} · ${values[i].accepted ? (en ? 'Confirmed' : '유효') : (en ? 'Excluded / unreviewed' : '제외 / 미확인')} ${reasonLabel(values[i].reason, en)}${values[i].hadGap ? (en ? ' · brief gap detected' : ' · 짧은 끊김 감지') : ''}',
      automatic
          ? (en
                ? 'Automatic boundaries may be affected by noise or weak voice. Review the recording; not clinically validated.'
                : '소음·약한 목소리로 자동 구간에 오차가 생길 수 있어요. 녹음 확인이 필요하며 임상 검증 전입니다.')
          : en
          ? 'Button timing includes observer reaction error. No normal/abnormal grading; clinical validation is pending.'
          : '버튼 반응 시간 오차가 있습니다. 정상·비정상 판정은 제공하지 않으며 임상 검증 전입니다.',
    ].join('\n');
  }
}
