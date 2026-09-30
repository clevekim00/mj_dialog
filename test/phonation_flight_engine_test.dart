import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/rehab/game/phonation_flight_engine.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';

VoiceAnalysisFrame f(
  int n, {
  double? hz = 200,
  double db = -20,
  bool clipped = false,
}) => VoiceAnalysisFrame(
  timestamp: Duration(milliseconds: n * 64),
  sampleDuration: const Duration(milliseconds: 64),
  waveform: const [],
  spectrum: const [],
  dbfs: db,
  peak: .3,
  noiseFloorDbfs: -70,
  clipping: clipped,
  pitchHz: hz,
  pitchConfidence: hz == null ? 0 : .9,
);
void main() {
  test(
    'separate sounds never become one maximum duration; duplicate frames ignored',
    () {
      final e = PhonationFlightEngine();
      for (var i = 1; i <= 12; i++) {
        e.add(f(i, hz: null, db: -70));
      }
      for (var i = 13; i <= 22; i++) {
        e.add(f(i));
      }
      expect(e.longestMs, 640);
      e.add(f(22));
      expect(e.voicedMs, 640);
      e.add(f(23, hz: null));
      for (var i = 24; i <= 28; i++) {
        e.add(f(i));
      }
      expect(e.longestMs, 640);
      expect(e.voicedMs, 960);
      expect(e.currentMs, 320);
    },
  );
  test(
    'silence, clipping and unreliable pitch do not move bird or count time',
    () {
      final e = PhonationFlightEngine();
      for (var i = 1; i <= 12; i++) {
        e.add(f(i, hz: null, db: -70));
      }
      e.add(f(13, db: -75));
      e.add(f(14, clipped: true));
      e.add(f(15, hz: null));
      expect(e.voicedMs, 0);
      expect(e.height, .5);
      expect(e.basePitchHz, isNull);
    },
  );
  test(
    'sample gaps break a run and pitch changes stay within easy corridor',
    () {
      final e = PhonationFlightEngine();
      for (var i = 1; i <= 12; i++) {
        e.add(f(i, hz: null, db: -70));
      }
      for (var i = 13; i <= 22; i++) {
        e.add(f(i));
      }
      expect(e.basePitchHz, 200);
      e.add(f(30, hz: 400));
      expect(e.currentMs, 64);
      for (var i = 31; i < 60; i++) {
        e.add(f(i, hz: 400));
      }
      expect(e.height, greaterThanOrEqualTo(.32));
      expect(e.height, lessThan(.5));
    },
  );
}
