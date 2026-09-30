import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/rehab/audio/practice_capture.dart';
import 'package:speech_rehab/features/rehab/game/phonation_flight_screen.dart';
import 'package:speech_rehab/features/rehab/services/rehab_session_repository.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';

class Capture extends PracticeCapture {
  int starts = 0, stops = 0;
  @override
  Future<void> startRecording(String name) async {
    starts++;
  }

  @override
  Future<String?> stopRecording() async {
    stops++;
    return '/game.wav';
  }

  @override
  int get durationMs => 2048;
  void sound(int n, {bool voice = true}) {
    frame.value = VoiceAnalysisFrame(
      timestamp: Duration(milliseconds: 64 * n),
      sampleDuration: const Duration(milliseconds: 64),
      waveform: const [.2],
      spectrum: const [],
      dbfs: voice ? -20 : -70,
      peak: .2,
      noiseFloorDbfs: -70,
      clipping: false,
      pitchHz: voice ? 200 : null,
      pitchConfidence: voice ? 0.9 : 0,
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'game requires fatigue, stops on background and saves feedback as non-MPT',
    (tester) async {
      final capture = Capture();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [practiceCaptureProvider.overrideWithValue(capture)],
          child: const MaterialApp(home: PhonationFlightScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(capture.starts, 0);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '편안하게 시작'))
            .onPressed,
        isNull,
      );
      await tester.scrollUntilVisible(
        find.text('2 / 5'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('2 / 5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('편안하게 시작'));
      await tester.pumpAndSettle();
      for (var i = 1; i <= 12; i++) {
        capture.sound(i, voice: false);
      }
      for (var i = 13; i <= 32; i++) {
        capture.sound(i);
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(capture.starts, 1);
      expect(capture.stops, 1);
      final saved = (await RehabSessionRepository().load()).single;
      expect(saved.feedback['notMpt'], true);
      expect(saved.feedback['longestDetectedMs'], 1280);
      expect(saved.canResume, false);
      expect(saved.takes, hasLength(1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(tester.takeException(), isNull);
    },
  );
}
