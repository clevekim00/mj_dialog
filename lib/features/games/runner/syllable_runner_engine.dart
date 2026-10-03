import 'dart:math' as math;

enum RunnerAction { jump, duck }

const runnerConsonants = [
  'ㄱ',
  'ㄲ',
  'ㄴ',
  'ㄷ',
  'ㄸ',
  'ㄹ',
  'ㅁ',
  'ㅂ',
  'ㅃ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅉ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];
String runnerSyllable(String consonant, RunnerAction action) {
  final index = runnerConsonants.indexOf(consonant);
  if (index < 0) throw ArgumentError.value(consonant);
  return String.fromCharCode(
    0xac00 + index * 588 + (action == RunnerAction.jump ? 0 : 4) * 28,
  );
}

/// One syllable per recognition window. No substring matching of longer words.
RunnerAction? runnerCommand(String text, String consonant) {
  final clean = text.replaceAll(RegExp(r'[\s.,!?。，！？]'), '');
  for (final action in RunnerAction.values) {
    if (clean == runnerSyllable(consonant, action)) return action;
  }
  return null;
}

enum RunnerMode { comfortable, challenge }

class SyllableRunnerEngine {
  SyllableRunnerEngine({this.mode = RunnerMode.comfortable, this.stage = 0});
  final RunnerMode mode;
  int stage;
  static const stageGoals = [12, 16, 20];
  int get goal => stageGoals[stage];
  int retries = 2;
  bool failed = false;
  double approach = 0, motion = 0, distance = 0, freeMotion = 0;
  int cleared = 0, voiceStars = 0, buttonStars = 0, skipped = 0;
  RunnerAction? action;
  bool resolving = false;
  double _startX = .42;
  double _deadline = 0;
  bool get finished => cleared >= goal;
  bool get campaignFinished => finished && stage == stageGoals.length - 1;
  bool get waiting => approach >= 1 && !resolving && !failed;
  bool get actionActive => action != null;
  RunnerAction get requiredAction =>
      (cleared + stage).isEven ? RunnerAction.jump : RunnerAction.duck;
  double get obstacleX => resolving
      ? _startX + (-.23 - _startX) * motion
      : 1.15 - approach * .73 - _deadline / 3 * .17;
  double get jumpHeight =>
      action == RunnerAction.jump ? math.sin(freeMotion * math.pi) * .43 : 0;

  // Away from the obstacle, both commands animate freely. At the approach
  // zone the matching command clears it; a wrong command still animates.
  bool command(RunnerAction next, {required bool voice}) {
    if (finished || failed || actionActive) return false;
    action = next;
    freeMotion = 0;
    if (voice) {
      voiceStars++;
    } else {
      buttonStars++;
    }
    if (!resolving && approach >= .75 && next == requiredAction) {
      _startX = obstacleX;
      resolving = true;
      motion = 0;
    }
    return true;
  }

  void skip() {
    if (finished || failed || resolving || mode == RunnerMode.challenge) return;
    _startX = obstacleX;
    skipped++;
    resolving = true;
    motion = 0;
  }

  bool retry() {
    if (!failed || retries == 0) return false;
    retries--;
    _resetCourse();
    return true;
  }

  bool nextStage() {
    if (!finished || campaignFinished) return false;
    stage++;
    retries = 2;
    _resetCourse();
    return true;
  }

  void _resetCourse() {
    approach = motion = distance = freeMotion = _deadline = 0;
    cleared = voiceStars = buttonStars = skipped = 0;
    action = null;
    resolving = failed = false;
  }

  void tick(double seconds) {
    if (finished || failed) return;
    final dt = seconds.clamp(0.0, .1);
    if (actionActive) {
      freeMotion = (freeMotion + dt / 1.5).clamp(0, 1);
      if (freeMotion >= 1) action = null;
    }
    if (resolving) {
      motion = (motion + dt / 1.5).clamp(0, 1);
      distance += dt;
      if (motion >= 1) {
        cleared++;
        approach = motion = _deadline = 0;
        resolving = false;
      }
    } else {
      approach = (approach + dt / (6 - stage * .5)).clamp(0, 1);
      if (!waiting || mode == RunnerMode.challenge) distance += dt;
      if (waiting && mode == RunnerMode.challenge) {
        _deadline += dt;
        if (_deadline >= 3) failed = true;
      }
    }
  }
}
