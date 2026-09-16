import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/chat/view/widgets/animated_orb.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:speech_rehab/features/practice/provider/practice_provider.dart';
import 'package:speech_rehab/features/practice/view/word_game_screen.dart';
import 'package:speech_rehab/services/api/ai_service.dart';
import 'package:speech_rehab/services/audio/audio_player_service.dart';
import 'package:speech_rehab/services/audio/audio_recorder_service.dart';
import 'package:speech_rehab/services/audio/stt_service.dart';
import 'package:speech_rehab/services/practice_history_service.dart';

class _FakeAudioRecorderService extends AudioRecorderService {
  bool started = false;
  bool stopped = false;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> startRecording(String fileName) async {
    started = true;
  }

  @override
  Future<String?> stopRecording() async {
    stopped = true;
    return '/tmp/word_game_orb_test.m4a';
  }
}

class _ControlledAudioRecorderService extends _FakeAudioRecorderService {
  final permissionGate = Completer<bool>();
  final startGate = Completer<void>();
  int startCalls = 0;
  int stopCalls = 0;
  bool recording = false;
  @override
  Future<bool> hasPermission() => permissionGate.future;
  @override
  Future<void> startRecording(String fileName) async {
    startCalls++;
    await startGate.future;
    recording = true;
  }

  @override
  Future<String?> stopRecording() async {
    stopCalls++;
    recording = false;
    return '/tmp/serialized-start-stop.m4a';
  }
}

class _FailingAudioRecorderService extends _FakeAudioRecorderService {
  @override
  Future<void> startRecording(String fileName) async =>
      throw StateError('device unavailable');
}

class _FakeSttService extends SttService {
  @override
  Future<bool> startListening({required SttResultCallback onResult}) async {
    return false;
  }

  @override
  Future<void> stopListening() async {}
}

class _FakeTranscriptSttService extends SttService {
  _FakeTranscriptSttService(this.transcript);

  final String transcript;

  @override
  Future<bool> startListening({required SttResultCallback onResult}) async {
    await onResult(transcript, true);
    return true;
  }

  @override
  Future<void> stopListening() async {}
}

class _FakeAudioPlayerService extends AudioPlayerService {
  @override
  void onPlaybackComplete(VoidCallback callback) {}

  @override
  Future<void> stop() async {}
}

class _FakeAiService extends AiService {
  const _FakeAiService();

  @override
  Future<AiResponse> evaluatePracticeByMode({
    required PracticeMode mode,
    required String targetText,
    required String spokenText,
    required int durationSeconds,
  }) async {
    return const AiResponse(
      replyText: '테스트 판정 완료',
      pronunciationScore: 92,
      evaluationMethod: 'textMatch',
      evaluationVersion: AiService.textMatchVersion,
      pronunciationFeedback: '좋습니다.',
    );
  }
}

class _TranscriptScoringAiService extends AiService {
  const _TranscriptScoringAiService();

  @override
  Future<AiResponse> evaluatePracticeByMode({
    required PracticeMode mode,
    required String targetText,
    required String spokenText,
    required int durationSeconds,
  }) async {
    final score = spokenText.trim().isEmpty
        ? 0
        : spokenText.trim() == targetText.trim()
        ? 100
        : 40;
    return AiResponse(
      replyText: '테스트 판정 완료',
      pronunciationScore: score,
      evaluationMethod: 'textMatch',
      evaluationVersion: AiService.textMatchVersion,
      pronunciationFeedback: score >= 70 ? '좋습니다.' : '다시 말해 주세요.',
    );
  }
}

void main() {
  testWidgets(
    'recording blocks navigation; background stops audio and pauses game',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final recorder = _FakeAudioRecorderService();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioRecorderServiceProvider.overrideWithValue(recorder),
            sttServiceProvider.overrideWithValue(_FakeSttService()),
            audioPlayerServiceProvider.overrideWithValue(
              _FakeAudioPlayerService(),
            ),
          ],
          child: MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(body: Text('홈')),
          ),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const WordGameScreen()),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WordGameScreen)),
      );
      final notifier = container.read(practiceProvider.notifier);
      await notifier.setMode(PracticeMode.wordGame);
      notifier.setWordGameTimed(true);
      notifier.startFallingWordGame();
      await notifier.startRecording();
      await tester.pump();
      expect(recorder.started, isTrue);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.library_music),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.bar_chart),
            )
            .onPressed,
        isNull,
      );
      await navigator.currentState!.maybePop();
      await tester.pump();
      expect(find.byType(WordGameScreen), findsOneWidget);
      expect(find.text('녹음을 끝낸 뒤 나갈 수 있어요.'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(recorder.stopped, isTrue);
      expect(
        container.read(practiceProvider).wordGameStatus,
        WordGameStatus.paused,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      notifier.resumeWordGame();
      await tester.pump();
      await navigator.currentState!.maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(WordGameScreen), findsNothing);
      expect(
        container.read(practiceProvider).wordGameStatus,
        WordGameStatus.paused,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'stop waits for pending permission and start; duplicate start and mode changes cannot race it',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final recorder = _ControlledAudioRecorderService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioRecorderServiceProvider.overrideWithValue(recorder),
            sttServiceProvider.overrideWithValue(_FakeSttService()),
            audioPlayerServiceProvider.overrideWithValue(
              _FakeAudioPlayerService(),
            ),
          ],
          child: const MaterialApp(home: WordGameScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WordGameScreen)),
      );
      final notifier = container.read(practiceProvider.notifier);
      await notifier.setMode(PracticeMode.shortSentence);
      final started = notifier.startRecording();
      final duplicateStart = notifier.startRecording();
      expect(container.read(practiceProvider).state, PracticeState.recording);
      final stopped = notifier.stopRecording();
      final duplicateStop = notifier.stopRecording();
      expect(container.read(practiceProvider).state, PracticeState.analyzing);
      await notifier.setMode(PracticeMode.freeSpeech);
      expect(container.read(practiceProvider).mode, PracticeMode.shortSentence);
      recorder.permissionGate.complete(true);
      await tester.pump();
      expect(recorder.startCalls, 1);
      expect(recorder.stopCalls, 0);
      recorder.startGate.complete();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await Future.wait([started, duplicateStart, stopped, duplicateStop]);
      expect(recorder.startCalls, 1);
      expect(recorder.stopCalls, 1);
      expect(recorder.recording, isFalse);
      expect(container.read(practiceProvider).state, PracticeState.completed);
      expect(container.read(practiceProvider).history.single.score, isNull);
    },
  );

  testWidgets(
    'recorder start failure leaves an error and no fabricated attempt',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioRecorderServiceProvider.overrideWithValue(
              _FailingAudioRecorderService(),
            ),
            sttServiceProvider.overrideWithValue(_FakeSttService()),
            audioPlayerServiceProvider.overrideWithValue(
              _FakeAudioPlayerService(),
            ),
          ],
          child: const MaterialApp(home: WordGameScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WordGameScreen)),
      );
      final notifier = container.read(practiceProvider.notifier);
      await notifier.setMode(PracticeMode.shortSentence);
      await notifier.startRecording();
      expect(container.read(practiceProvider).state, PracticeState.error);
      expect(
        container.read(practiceProvider).feedback?.pronunciationScore,
        isNull,
      );
      expect(container.read(practiceProvider).history, isEmpty);
    },
  );

  testWidgets(
    'untimed is default and pausing preserves words; timed expiration is not a practice attempt',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: WordGameScreen())),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WordGameScreen)),
      );
      final notifier = container.read(practiceProvider.notifier);
      await notifier.setMode(PracticeMode.wordGame);
      notifier.startFallingWordGame();
      final word = container.read(practiceProvider).fallingWords.single;
      expect(container.read(practiceProvider).wordGameTimed, isFalse);
      await tester.pump(const Duration(seconds: 40));
      expect(
        container.read(practiceProvider).fallingWords.single.progress,
        word.progress,
      );
      notifier.pauseWordGame();
      expect(
        container.read(practiceProvider).wordGameStatus,
        WordGameStatus.paused,
      );
      notifier.resumeWordGame();
      expect(container.read(practiceProvider).fallingWords.single.id, word.id);
      notifier.resetFallingWordGame();
      notifier.setWordGameTimed(true);
      notifier.startFallingWordGame();
      for (var tick = 0; tick < 35; tick++) {
        await tester.pump(const Duration(milliseconds: 650));
      }
      expect(
        container.read(practiceProvider).wordGameStatus,
        WordGameStatus.gameOver,
      );
      expect(container.read(practiceProvider).history, isEmpty);
      expect(await PracticeHistoryService().loadPractices(), isEmpty);
    },
  );

  testWidgets(
    'free speech STT failure never fabricates transcript and ending fatigue updates the attempt',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioRecorderServiceProvider.overrideWithValue(
              _FakeAudioRecorderService(),
            ),
            sttServiceProvider.overrideWithValue(_FakeSttService()),
            aiServiceProvider.overrideWithValue(const _FakeAiService()),
            audioPlayerServiceProvider.overrideWithValue(
              _FakeAudioPlayerService(),
            ),
          ],
          child: const MaterialApp(home: WordGameScreen()),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WordGameScreen)),
      );
      final notifier = container.read(practiceProvider.notifier);
      await notifier.setMode(PracticeMode.freeSpeech);
      await notifier.startRecording();
      await tester.pump(const Duration(seconds: 1));
      final stopped = notifier.stopRecording();
      await tester.pump(const Duration(seconds: 2));
      await stopped;
      final saved = container.read(practiceProvider).history.single;
      expect(saved.spokenText, isEmpty);
      expect(saved.score, isNull);
      expect(saved.evaluationMethod, 'unavailable');
      expect(saved.fatigueAfter, isNull);
      await notifier.saveFatigueAfter(4);
      expect(
        (await PracticeHistoryService().loadPractices()).single.fatigueAfter,
        4,
      );
    },
  );

  testWidgets('uses falling words instead of a separate record button', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: WordGameScreen())),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WordGameScreen)),
    );
    await container
        .read(practiceProvider.notifier)
        .setMode(PracticeMode.wordGame);
    await tester.pumpAndSettle();

    container.read(practiceProvider.notifier).startFallingWordGame();
    await tester.pump();

    expect(find.text('녹음 시작'), findsNothing);
    expect(find.text('판정하기'), findsNothing);

    expect(
      container.read(practiceProvider).wordGameStatus,
      WordGameStatus.running,
    );
  });

  testWidgets('tapping the orb starts recording in word game', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recorder = _FakeAudioRecorderService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioRecorderServiceProvider.overrideWithValue(recorder),
          sttServiceProvider.overrideWithValue(_FakeSttService()),
          aiServiceProvider.overrideWithValue(const _FakeAiService()),
          audioPlayerServiceProvider.overrideWithValue(
            _FakeAudioPlayerService(),
          ),
        ],
        child: const MaterialApp(home: WordGameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WordGameScreen)),
    );
    await container
        .read(practiceProvider.notifier)
        .setMode(PracticeMode.wordGame);
    container.read(practiceProvider.notifier).startFallingWordGame();
    await tester.pump();

    expect(
      container.read(practiceProvider).wordGameStatus,
      WordGameStatus.running,
    );
    await tester.scrollUntilVisible(
      find.byType(AnimatedOrb),
      240,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('word-game-microphone')));
    await tester.pump();

    expect(recorder.started, isTrue);
    expect(container.read(practiceProvider).state, PracticeState.recording);
  });

  testWidgets('shows recognized speech above the orb', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioRecorderServiceProvider.overrideWithValue(
            _FakeAudioRecorderService(),
          ),
          sttServiceProvider.overrideWithValue(_FakeTranscriptSttService('물')),
          aiServiceProvider.overrideWithValue(const _FakeAiService()),
          audioPlayerServiceProvider.overrideWithValue(
            _FakeAudioPlayerService(),
          ),
        ],
        child: const MaterialApp(home: WordGameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WordGameScreen)),
    );
    await container
        .read(practiceProvider.notifier)
        .setMode(PracticeMode.wordGame);
    container.read(practiceProvider.notifier).startFallingWordGame();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byType(AnimatedOrb),
      240,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();

    expect(find.text('인식된 글'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('word-game-microphone')));
    await tester.pump();

    expect(find.text('인식된 글'), findsOneWidget);
    expect(find.text('물'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('orb keeps a stable desktop click target while recording', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recorder = _FakeAudioRecorderService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioRecorderServiceProvider.overrideWithValue(recorder),
          sttServiceProvider.overrideWithValue(_FakeSttService()),
          aiServiceProvider.overrideWithValue(const _FakeAiService()),
          audioPlayerServiceProvider.overrideWithValue(
            _FakeAudioPlayerService(),
          ),
        ],
        child: const MaterialApp(home: WordGameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WordGameScreen)),
    );
    await container
        .read(practiceProvider.notifier)
        .setMode(PracticeMode.wordGame);
    container.read(practiceProvider.notifier).startFallingWordGame();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byType(AnimatedOrb),
      240,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();

    final orbCenter = tester.getCenter(
      find.byKey(const ValueKey('word-game-microphone')),
    );
    await tester.tapAt(orbCenter);
    await tester.pump();
    expect(container.read(practiceProvider).state, PracticeState.recording);

    await tester.tapAt(orbCenter.translate(84, 0));
    await tester.pump();

    expect(container.read(practiceProvider).state, PracticeState.analyzing);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('second orb tap immediately enters analyzing state', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recorder = _FakeAudioRecorderService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioRecorderServiceProvider.overrideWithValue(recorder),
          sttServiceProvider.overrideWithValue(_FakeSttService()),
          aiServiceProvider.overrideWithValue(const _FakeAiService()),
          audioPlayerServiceProvider.overrideWithValue(
            _FakeAudioPlayerService(),
          ),
        ],
        child: const MaterialApp(home: WordGameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WordGameScreen)),
    );
    await container
        .read(practiceProvider.notifier)
        .setMode(PracticeMode.wordGame);
    container.read(practiceProvider.notifier).startFallingWordGame();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byType(AnimatedOrb),
      240,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('word-game-microphone')));
    await tester.pump();
    expect(container.read(practiceProvider).state, PracticeState.recording);

    await tester.tap(find.byKey(const ValueKey('word-game-microphone')));
    await tester.pump();

    expect(recorder.stopped, isFalse);
    expect(container.read(practiceProvider).state, PracticeState.analyzing);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('falling words pause while recording', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioRecorderServiceProvider.overrideWithValue(
            _FakeAudioRecorderService(),
          ),
          sttServiceProvider.overrideWithValue(_FakeSttService()),
          aiServiceProvider.overrideWithValue(const _FakeAiService()),
          audioPlayerServiceProvider.overrideWithValue(
            _FakeAudioPlayerService(),
          ),
        ],
        child: const MaterialApp(home: WordGameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WordGameScreen)),
    );
    await container
        .read(practiceProvider.notifier)
        .setMode(PracticeMode.wordGame);
    container.read(practiceProvider.notifier).startFallingWordGame();
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byType(AnimatedOrb),
      240,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('word-game-microphone')));
    await tester.pump();

    expect(find.text('판정하기'), findsOneWidget);

    final before = container
        .read(practiceProvider)
        .fallingWords
        .map((word) => word.progress)
        .toList();

    await tester.pump(const Duration(seconds: 2));

    final after = container
        .read(practiceProvider)
        .fallingWords
        .map((word) => word.progress)
        .toList();

    expect(after, before);
  });

  testWidgets('empty transcription does not clear a word as correct', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioRecorderServiceProvider.overrideWithValue(
            _FakeAudioRecorderService(),
          ),
          sttServiceProvider.overrideWithValue(_FakeSttService()),
          aiServiceProvider.overrideWithValue(
            const _TranscriptScoringAiService(),
          ),
          audioPlayerServiceProvider.overrideWithValue(
            _FakeAudioPlayerService(),
          ),
        ],
        child: const MaterialApp(home: WordGameScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WordGameScreen)),
    );
    await container
        .read(practiceProvider.notifier)
        .setMode(PracticeMode.wordGame);
    container.read(practiceProvider.notifier).startFallingWordGame();
    await tester.pump();

    final initialWords = container.read(practiceProvider).fallingWords.length;
    expect(initialWords, greaterThan(0));

    await tester.scrollUntilVisible(
      find.byType(AnimatedOrb),
      240,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('word-game-microphone')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('word-game-microphone')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final practice = container.read(practiceProvider);
    expect(practice.spokenText, isEmpty);
    expect(practice.feedback?.pronunciationScore, isNull);
    expect(practice.history.single.score, isNull);
    expect(practice.wordGameHits, 0);
    expect(practice.wordGameMisses, 0);
    expect(practice.fallingWords.length, initialWords);
  });

  testWidgets(
    'different recognized word does not clear target even with high AI score',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioRecorderServiceProvider.overrideWithValue(
              _FakeAudioRecorderService(),
            ),
            sttServiceProvider.overrideWithValue(
              _FakeTranscriptSttService('다른단어'),
            ),
            aiServiceProvider.overrideWithValue(const _FakeAiService()),
            audioPlayerServiceProvider.overrideWithValue(
              _FakeAudioPlayerService(),
            ),
          ],
          child: const MaterialApp(home: WordGameScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(WordGameScreen)),
      );
      await container
          .read(practiceProvider.notifier)
          .setMode(PracticeMode.wordGame);
      container.read(practiceProvider.notifier).startFallingWordGame();
      await tester.pump();

      final initialWords = container.read(practiceProvider).fallingWords.length;
      expect(initialWords, greaterThan(0));

      await tester.scrollUntilVisible(
        find.byType(AnimatedOrb),
        240,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('word-game-microphone')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word-game-microphone')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final practice = container.read(practiceProvider);
      expect(practice.spokenText, '다른단어');
      expect(practice.feedback?.pronunciationScore, lessThan(70));
      expect(practice.wordGameHits, 0);
      expect(practice.wordGameMisses, 1);
      expect(practice.fallingWords.length, initialWords);
    },
  );

  testWidgets(
    'shows unavailable speech recognition instead of no recognition',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioRecorderServiceProvider.overrideWithValue(
              _FakeAudioRecorderService(),
            ),
            sttServiceProvider.overrideWithValue(_FakeSttService()),
            aiServiceProvider.overrideWithValue(
              const _TranscriptScoringAiService(),
            ),
            audioPlayerServiceProvider.overrideWithValue(
              _FakeAudioPlayerService(),
            ),
          ],
          child: const MaterialApp(home: WordGameScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(WordGameScreen)),
      );
      await container
          .read(practiceProvider.notifier)
          .setMode(PracticeMode.wordGame);
      container.read(practiceProvider.notifier).startFallingWordGame();
      await tester.pump();

      await tester.scrollUntilVisible(
        find.byType(AnimatedOrb),
        240,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('word-game-microphone')));
      await tester.pump();

      expect(find.text('실시간 인식 권한 필요'), findsOneWidget);
      expect(find.text('인식 없음'), findsNothing);
    },
  );

  testWidgets('starts review mode from failed word history', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final failedSession = PracticeSession(
      id: 'failed_word_water',
      targetText: '물',
      spokenText: '불',
      audioFilePath: '/tmp/failed_word_water.m4a',
      score: 52,
      evaluationMethod: 'textMatch',
      evaluationVersion: AiService.textMatchVersion,
      feedback: '복습이 필요합니다.',
      timestamp: DateTime(2026, 6, 9, 10),
      mode: PracticeMode.wordGame.storageValue,
      contentId: 'word_water',
      category: '일상',
      difficulty: 1,
      contentSource: 'builtIn',
      movementScore: 2,
    );
    SharedPreferences.setMockInitialValues({
      'practice_history': jsonEncode([failedSession.toJson()]),
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: WordGameScreen())),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WordGameScreen)),
    );
    await container
        .read(practiceProvider.notifier)
        .setMode(PracticeMode.wordGame);
    await tester.pumpAndSettle();

    expect(find.text('다시 볼 단어 1개 복습'), findsOneWidget);
    expect(find.text('인식 차이 1회 · 일치도 52%'), findsOneWidget);
    expect(find.text('녹음 듣기'), findsOneWidget);

    final started = container
        .read(practiceProvider.notifier)
        .startFailedWordReview();
    await tester.pump();

    final practice = container.read(practiceProvider);
    expect(started, isTrue);
    expect(practice.isReviewMode, isTrue);
    expect(practice.targetText, '물');
  });
}
