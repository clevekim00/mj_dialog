import 'dart:math' as math;
import 'dart:typed_data';
import 'package:speech_rehab/services/audio_analysis/voice_signal_analyzer.dart';
import 'package:speech_rehab/features/rehab/mpt/mpt_voice_timer.dart';
import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';
import 'package:speech_rehab/features/exercise/view/exercise_menu_screen.dart';
import 'package:speech_rehab/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/rehab/audio/practice_capture.dart';
import 'package:speech_rehab/features/rehab/mpt/mpt_result.dart';
import 'package:speech_rehab/features/rehab/model/rehab_session.dart';
import 'package:speech_rehab/features/rehab/mpt/mpt_screen.dart';
import 'package:speech_rehab/features/rehab/services/rehab_record_index.dart';
import 'package:speech_rehab/features/rehab/services/rehab_session_repository.dart';

class MptCapture extends PracticeCapture {
  int ms = 0, starts = 0, stops = 0;
  bool deny = false, failSave = false;
  @override
  int get durationMs => ms;
  @override
  Future<void> startRecording(String name) async {
    expect(name, startsWith('rehab_mpt_'));
    if (deny) throw StateError('denied');
    starts++;
    ms = 0;
    problem.value = null;
    limitReached.value = false;
  }

  @override
  Future<String?> stopRecording() async {
    stops++;
    if (failSave) throw StateError('disk');
    return '/mpt-$starts.wav';
  }
}

class RetryRepo extends RehabSessionRepository {
  bool fail = false;
  @override
  Future<void> save(RehabSession session) async {
    if (fail) throw StateError('storage');
    await super.save(session);
  }
}

MptTrial trial(int ms, {String reason = 'confirmed', bool accepted = true}) =>
    MptTrial(
      id: '$ms',
      durationMs: ms,
      onsetOffsetMs: 500,
      endOffsetMs: 500 + ms,
      reason: reason,
      accepted: accepted,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'only three confirmed single trials produce maximum, not sum or mean',
    () {
      final values = [trial(1200), trial(5000), trial(2300)];
      expect(MptResult.maximum(values), 5000);
      expect(MptResult.maximum(values.take(2).toList()), isNull);
      expect(
        MptResult.maximum([...values, trial(8000, reason: 'interrupted')]),
        5000,
      );
      expect(MptResult.maximum([...values, trial(8000)]), isNull);
      expect(MptResult.maximum([trial(0), trial(1000), trial(2000)]), isNull);
      expect(
        trial(
          8000,
          reason: 'recording_limit',
          accepted: false,
        ).reviewed(true).accepted,
        false,
      );
      expect(MptTrial.fromJson(values.first.toJson()).durationMs, 1200);
    },
  );

  Future<void> tap(WidgetTester tester, String text) async {
    final target = find.text(text);
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> setup(
    WidgetTester tester,
    MptCapture capture, {
    RetryRepo? repo,
    bool automatic = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          practiceCaptureProvider.overrideWithValue(capture),
          if (repo != null) rehabRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: MptScreen()),
      ),
    );
    await tester.pumpAndSettle();
    if (!automatic) await tap(tester, '발성 자동 감지');
    await tap(tester, '2 / 5');
    await tap(
      tester,
      automatic
          ? '충분히 쉬었고, 조용한 곳에서 녹음을 확인할 준비가 됐어요.'
          : '충분히 쉬었고, 조용한 곳에서 측정을 도와줄 사람이 준비됐어요.',
    );
    await tap(tester, '녹음 준비');
  }

  VoiceAnalysisFrame frame(int ms, {bool voice = false, double? level}) =>
      VoiceAnalysisFrame(
        timestamp: Duration(milliseconds: ms),
        sampleDuration: const Duration(milliseconds: 64),
        waveform: const [],
        spectrum: const [],
        dbfs: level ?? (voice ? -24 : -65),
        peak: voice ? .2 : .001,
        noiseFloorDbfs: -65,
        clipping: false,
        pitchHz: voice ? 180 : null,
        pitchConfidence: voice ? .9 : 0,
      );

  test(
    'automatic timing excludes onset confirmation and trailing silence delays',
    () {
      final timer = MptVoiceTimer();
      for (var ms = 64; ms <= 1536; ms += 64) {
        timer.add(frame(ms));
      }
      expect(timer.phase, MptVoicePhase.waiting);
      // A single short tap cannot start the timer.
      timer.add(frame(1600, voice: true));
      timer.add(frame(1664));
      expect(timer.phase, MptVoicePhase.waiting);
      for (var ms = 1728; ms <= 3648; ms += 64) {
        timer.add(frame(ms, voice: true));
      }
      expect(timer.onsetMs, 1664);
      expect(timer.durationMs, 1984);
      for (var ms = 3712; ms <= 4288; ms += 64) {
        timer.add(frame(ms));
      }
      expect(timer.phase, MptVoicePhase.ended);
      expect(timer.durationMs, 1984);
      timer.add(frame(4352, voice: true));
      expect(timer.endMs, 3648);
    },
  );
  test(
    'short gaps are flagged, silence times out, and noisy calibration fails',
    () {
      final timer = MptVoiceTimer();
      for (var ms = 64; ms <= 1536; ms += 64) {
        timer.add(frame(ms));
      }
      for (var ms = 1600; ms <= 2176; ms += 64) {
        timer.add(frame(ms, voice: true));
      }
      for (var ms = 2240; ms <= 2432; ms += 64) {
        timer.add(frame(ms));
      }
      timer.add(frame(2496, voice: true));
      expect(timer.hadGap, isTrue);
      expect(timer.phase, MptVoicePhase.phonating);
      final silent = MptVoiceTimer();
      for (var ms = 64; ms <= 21632; ms += 64) {
        silent.add(frame(ms));
      }
      expect(silent.failure, 'no_voice');
      final noisy = MptVoiceTimer();
      for (var ms = 64; ms <= 1536; ms += 64) {
        noisy.add(frame(ms, level: -22));
      }
      expect(noisy.failure, 'noisy_environment');
    },
  );
  testWidgets(
    'automatic onset and offset save an unconfirmed PCM-timed trial without taps',
    (tester) async {
      final capture = MptCapture();
      await setup(tester, capture, automatic: true);
      expect(find.text('소리 시작 · 타이머 시작'), findsNothing);
      for (var ms = 64; ms <= 1536; ms += 64) {
        capture.ms = ms;
        capture.frame.value = frame(ms);
      }
      for (var ms = 1600; ms <= 3456; ms += 64) {
        capture.ms = ms;
        capture.frame.value = frame(ms, voice: true);
      }
      await tester.pump();
      expect(find.text('1.9 초'), findsOneWidget);
      for (var ms = 3520; ms <= 4096; ms += 64) {
        capture.ms = ms;
        capture.frame.value = frame(ms);
      }
      await tester.pumpAndSettle();
      final saved = (await RehabSessionRepository().load()).single;
      final value = MptResult.trials(saved.feedback).single;
      expect(capture.stops, 1);
      expect(value.durationMs, 1920);
      expect(value.onsetOffsetMs, 1536);
      expect(value.endOffsetMs, 3456);
      expect(value.accepted, isFalse);
      expect(value.timingMethod, 'automatic-acoustic');
      expect(saved.feedback['maximumMs'], isNull);
      expect(saved.feedback['version'], MptResult.automaticProtocol);
      expect(MptResult.summary(saved.feedback, false), contains('자동 감지 추정'));
    },
  );

  test('real PCM analysis drives the automatic timer', () {
    final timer = MptVoiceTimer();
    const analyzer = VoiceSignalAnalyzer();
    for (var n = 0; n < 64; n++) {
      final bytes = ByteData(2048);
      for (var sample = 0; sample < 1024; sample++) {
        final voiced = n >= 24 && n < 54;
        final value = voiced
            ? (4000 * math.sin(2 * math.pi * 180 * (n * 1024 + sample) / 16000))
                  .round()
            : 0;
        bytes.setInt16(sample * 2, value, Endian.little);
      }
      timer.add(
        analyzer.analyzePcm16(
          bytes.buffer.asUint8List(),
          timestamp: Duration(milliseconds: (n + 1) * 64),
          includeSpectrum: false,
        ),
      );
    }
    expect(timer.phase, MptVoicePhase.ended);
    expect(timer.durationMs, 1920);
  });

  Future<void> timed(WidgetTester tester, MptCapture capture) async {
    capture.ms = 500;
    await tap(tester, '소리 시작 · 타이머 시작');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    capture.ms = 2000;
    await tap(tester, '소리 끝 · 타이머 종료');
  }

  testWidgets(
    'three reviewed trials persist as MPT, separate from game and daily practice',
    (tester) async {
      final capture = MptCapture();
      await setup(tester, capture);
      for (var i = 0; i < 3; i++) {
        if (i > 0) {
          await tap(tester, '충분히 쉬었고, 조용한 곳에서 측정을 도와줄 사람이 준비됐어요.');
          await tap(tester, '녹음 준비');
        }
        await timed(tester, capture);
        final unreviewed = (await RehabSessionRepository().load()).single;
        expect(unreviewed.feedback['maximumMs'], isNull);
        await tester.scrollUntilVisible(
          find.text('유효 시도로 저장'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, '유효 시도로 저장'),
              )
              .onPressed,
          isNull,
        );
        await tap(
          tester,
          '한 번의 숨으로 “아”를 냈고, 중간 호흡·기침·방해 소리 없이 끝까지 정확히 시간을 쟀어요. 녹음도 확인했어요.',
        );
        await tap(tester, '유효 시도로 저장');
      }
      final saved = (await RehabSessionRepository().load()).single;
      expect(saved.feedback['validTrialCount'], 3);
      expect(saved.feedback['maximumMs'], greaterThan(0));
      expect(saved.takes.length, 3);
      expect(saved.canResume, false);
      final indexed = (await RehabRecordIndex().load()).single;
      expect(indexed.kind, 'mpt');
      expect(indexed.recordings.every((r) => !r.comparable), true);
      expect(capture.starts, 3);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'background interruption excludes trial and never yields final MPT',
    (tester) async {
      final capture = MptCapture();
      await setup(tester, capture);
      capture.ms = 500;
      await tap(tester, '소리 시작 · 타이머 시작');
      capture.ms = 1500;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      final saved = (await RehabSessionRepository().load()).single;
      expect(MptResult.trials(saved.feedback).single.reason, 'interrupted');
      expect(saved.feedback['maximumMs'], isNull);
      expect(find.text('유효 시도로 저장'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    },
  );
  testWidgets('audio save retry keeps one attempt and original timing', (
    tester,
  ) async {
    final capture = MptCapture();
    await setup(tester, capture);
    capture.failSave = true;
    await timed(tester, capture);
    expect(await RehabSessionRepository().load(), isEmpty);
    capture.failSave = false;
    await tap(tester, '저장 재시도');
    final saved = (await RehabSessionRepository().load()).single;
    expect(saved.takes.length, 1);
    expect(MptResult.trials(saved.feedback).length, 1);
    expect(saved.feedback['maximumMs'], isNull);
  });
  for (final reason in ['limit', 'input']) {
    testWidgets('$reason excludes even a timed recording', (tester) async {
      final capture = MptCapture();
      await setup(tester, capture);
      capture.ms = 500;
      await tap(tester, '소리 시작 · 타이머 시작');
      capture.ms = 3000;
      if (reason == 'limit') {
        capture.limitReached.value = true;
      } else {
        capture.problem.value = 'stalled';
      }
      await tester.pumpAndSettle();
      final saved = (await RehabSessionRepository().load()).single;
      expect(MptResult.trials(saved.feedback).single.eligible, false);
      expect(saved.feedback['maximumMs'], isNull);
      expect(find.text('유효 시도로 저장'), findsNothing);
    });
  }
  testWidgets('permission failure makes no trial', (tester) async {
    final capture = MptCapture()..deny = true;
    await setup(tester, capture);
    expect(capture.starts, 0);
    expect(await RehabSessionRepository().load(), isEmpty);
    expect(find.text('마이크를 시작하지 못했어요. 권한을 확인하고 다시 시도하세요.'), findsOneWidget);
  });
  testWidgets('record persistence failure blocks acceptance until retry', (
    tester,
  ) async {
    final capture = MptCapture();
    final repo = RetryRepo();
    await setup(tester, capture, repo: repo);
    repo.fail = true;
    await timed(tester, capture);
    expect(await repo.load(), isEmpty);
    expect(find.text('유효 시도로 저장'), findsNothing);
    repo.fail = false;
    await tap(tester, '저장 재시도');
    final stored = (await repo.load()).single;
    expect(stored.takes.length, 1);
    expect(MptResult.trials(stored.feedback).single.accepted, false);
    expect(stored.feedback['maximumMs'], isNull);
  });
  for (final lang in ['ko', 'en']) {
    testWidgets('MPT menu opens in $lang on 360px at 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const ExerciseMenuScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(
        tester,
        lang == 'ko' ? '편안하게 소리 내기' : 'Comfortable voice practice',
      );
      await tap(
        tester,
        lang == 'ko' ? '최대발성시간 (MPT)' : 'Maximum phonation time (MPT)',
      );
      expect(find.byType(MptScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
