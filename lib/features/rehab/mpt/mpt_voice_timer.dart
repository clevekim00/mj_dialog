import '../../voice_analysis/model/voice_analysis_models.dart';

enum MptVoicePhase { calibrating, waiting, phonating, ended, invalid }

/// Acoustic timing estimate, not vowel recognition or a clinical classifier.
/// All boundaries use PCM timestamps; UI/IO delays never enter the duration.
class MptVoiceTimer {
  static const version = 'adaptive-voice-v1';
  static const calibrationMs = 1536;
  static const onsetHoldMs = 192;
  static const offsetHoldMs = 640;
  MptVoicePhase phase = MptVoicePhase.calibrating;
  final List<double> _noise = [];
  int _calibrationVoiced = 0, _lastMs = 0, _candidateMs = -1;
  int onsetMs = 0, endMs = 0;
  double thresholdDbfs = -45;
  String? failure;
  bool hadGap = false;
  int get durationMs => endMs > onsetMs ? endMs - onsetMs : 0;

  void add(VoiceAnalysisFrame frame) {
    if (phase == MptVoicePhase.ended || phase == MptVoicePhase.invalid) return;
    final ms = frame.timestamp.inMilliseconds;
    if (ms <= _lastMs) return;
    if (_lastMs != 0 && ms - _lastMs > 250) {
      failure = 'input_error';
      phase = MptVoicePhase.invalid;
      return;
    }
    _lastMs = ms;
    final width = frame.sampleDuration.inMilliseconds.clamp(1, 128);
    if (phase == MptVoicePhase.calibrating) {
      _noise.add(frame.dbfs);
      if (frame.hasReliablePitch) _calibrationVoiced++;
      if (ms >= calibrationMs) {
        _noise.sort();
        final noise = _noise[_noise.length ~/ 2];
        thresholdDbfs = (noise + 10).clamp(-55, -20);
        if (noise > -30 || _calibrationVoiced > _noise.length ~/ 3) {
          failure = 'noisy_environment';
          phase = MptVoicePhase.invalid;
        } else {
          phase = MptVoicePhase.waiting;
        }
      }
      return;
    }
    if (phase == MptVoicePhase.waiting) {
      // Reject brief taps and breath noise at onset.
      if (frame.dbfs >= thresholdDbfs && frame.hasReliablePitch) {
        if (_candidateMs < 0) _candidateMs = ms - width;
        if (ms - _candidateMs >= onsetHoldMs) {
          onsetMs = _candidateMs;
          endMs = ms;
          phase = MptVoicePhase.phonating;
        }
      } else {
        _candidateMs = -1;
      }
      if (phase == MptVoicePhase.waiting && ms >= calibrationMs + 20000) {
        failure = 'no_voice';
        phase = MptVoicePhase.invalid;
      }
      return;
    }
    // Lower release threshold tolerates soft tails and irregular voicing.
    final voiced =
        frame.dbfs >= thresholdDbfs - 4 &&
        (frame.hasReliablePitch || frame.dbfs >= thresholdDbfs + 6);
    if (voiced) {
      if (ms - endMs > 192) hadGap = true;
      endMs = ms;
    } else if (ms - endMs >= offsetHoldMs) {
      phase = MptVoicePhase.ended;
    }
  }
}
