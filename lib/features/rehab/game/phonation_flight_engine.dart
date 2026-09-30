import 'dart:math' as math;
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';

/// Game feedback only, NOT maximum phonation time or a clinical assessment.
/// Every non-detected frame breaks a run; separated breaths are never added
/// together and called one continuous phonation.
class PhonationFlightEngine {
  static const version = 'flight-feedback-v1';
  static const calibrationMs = 800;
  final List<double> _noise = [], _baseline = [];
  double noiseDbfs = -80;
  double? basePitchHz;
  double height = .5;
  int _lastEndUs = 0, elapsedMs = 0, voicedMs = 0, longestMs = 0, currentMs = 0;
  bool detecting = false, clipping = false;
  bool get calibrating => elapsedMs <= calibrationMs;
  bool get hasPitchBaseline => basePitchHz != null;
  void add(VoiceAnalysisFrame frame) {
    final end = frame.timestamp.inMicroseconds;
    if (end <= _lastEndUs) return;
    final gap =
        _lastEndUs > 0 &&
        end - _lastEndUs > frame.sampleDuration.inMicroseconds + 1000;
    _lastEndUs = end;
    elapsedMs = end ~/ 1000;
    clipping = frame.clipping;
    if (calibrating) {
      _noise.add(frame.dbfs);
      noiseDbfs = _median(_noise);
      return;
    }
    detecting =
        !clipping &&
        frame.hasReliablePitch &&
        frame.dbfs > math.max(-55, noiseDbfs + 10);
    if (gap) currentMs = 0;
    if (!detecting) {
      currentMs = 0;
      return;
    }
    final ms = frame.sampleDuration.inMilliseconds;
    currentMs += ms;
    voicedMs += ms;
    longestMs = math.max(longestMs, currentMs);
    if (basePitchHz == null) {
      _baseline.add(frame.pitchHz!);
      if (_baseline.length >= 8) basePitchHz = _median(_baseline);
    }
    if (basePitchHz != null) {
      final semitones = 12 * math.log(frame.pitchHz! / basePitchHz!) / math.ln2;
      // Only a small, smoothed movement within a broad obstacle-free corridor.
      final target = .5 - semitones.clamp(-4, 4) / 4 * .18;
      height += (target - height) * .15;
    }
  }

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    return sorted[sorted.length ~/ 2];
  }
}
