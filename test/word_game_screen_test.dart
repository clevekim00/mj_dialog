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
      pronunciationFeedback: score >= 70 ? '좋습니다.' : '다시 말해 주세요.',
    );
  }
}

void main() {
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

    await tester.tap(find.byType(AnimatedOrb));
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

    expect(find.text('인식된 발음'), findsNothing);

    await tester.tap(find.byType(AnimatedOrb));
    await tester.pump();

    expect(find.text('인식된 발음'), findsOneWidget);
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

    final orbCenter = tester.getCenter(find.byType(AnimatedOrb));
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

    await tester.tap(find.byType(AnimatedOrb));
    await tester.pump();
    expect(container.read(practiceProvider).state, PracticeState.recording);

    await tester.tap(find.byType(AnimatedOrb));
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

    await tester.tap(find.byType(AnimatedOrb));
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

    await tester.tap(find.byType(AnimatedOrb));
    await tester.pump();
    await tester.tap(find.byType(AnimatedOrb));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    final practice = container.read(practiceProvider);
    expect(practice.spokenText, isEmpty);
    expect(practice.wordGameHits, 0);
    expect(practice.wordGameMisses, 1);
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

      await tester.tap(find.byType(AnimatedOrb));
      await tester.pump();
      await tester.tap(find.byType(AnimatedOrb));
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

      await tester.tap(find.byType(AnimatedOrb));
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

    expect(find.text('틀린 단어 1개 복습'), findsOneWidget);
    expect(find.text('실패 1회 · 최근 52점'), findsOneWidget);
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
