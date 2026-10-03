import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_rehab/services/audio/stt_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/games/runner/syllable_runner_engine.dart';
import 'package:speech_rehab/features/games/runner/syllable_runner_screen.dart';

class RunnerFakeSpeech extends SttService {
  bool initialized = false;
  SttResultCallback? callback;
  @override
  Future<bool> init() async {
    initialized = true;
    return true;
  }

  @override
  Future<bool> startListening({
    required SttResultCallback onResult,
    List<String> contextualStrings = const [],
  }) async {
    callback = onResult;
    return true;
  }

  @override
  Future<void> stopListening() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  test('all consonants compose a/eo syllables', () {
    expect(runnerSyllable('ㄱ', RunnerAction.jump), '가');
    expect(runnerSyllable('ㄱ', RunnerAction.duck), '거');
    expect(runnerSyllable('ㅇ', RunnerAction.jump), '아');
    expect(runnerSyllable('ㅎ', RunnerAction.duck), '허');
    expect(
      runnerConsonants.map((c) => runnerSyllable(c, RunnerAction.jump)).toSet(),
      hasLength(19),
    );
  });
  test('commands accept only the selected syllable', () {
    expect(runnerCommand(' 가! ', 'ㄱ'), RunnerAction.jump);
    expect(runnerCommand('거', 'ㄱ'), RunnerAction.duck);
    expect(runnerCommand('가방', 'ㄱ'), isNull);
    expect(runnerCommand('가 거', 'ㄱ'), isNull);
    expect(runnerCommand('나', 'ㄱ'), isNull);
  });
  test('obstacles wait and cannot double-count partial recognition', () {
    final game = SyllableRunnerEngine();
    for (var i = 0; i < 200; i++) {
      game.tick(.1);
    }
    expect(game.waiting, isTrue);
    expect(game.cleared, 0);

    expect(game.command(RunnerAction.jump, voice: true), isTrue);
    expect(game.command(RunnerAction.jump, voice: true), isFalse);
    for (var i = 0; i < 16; i++) {
      game.tick(.1);
    }
    expect(game.cleared, 1);
    expect(game.voiceStars, 1);
    expect(game.requiredAction, RunnerAction.duck);
  });
  test('finish distinguishes voice, button, and skip', () {
    final game = SyllableRunnerEngine();
    for (var n = 0; n < game.goal; n++) {
      for (var i = 0; i < 65; i++) {
        game.tick(.1);
      }
      if (n == 0) {
        game.skip();
      } else {
        game.command(game.requiredAction, voice: n.isEven);
      }
      for (var i = 0; i < 16; i++) {
        game.tick(.1);
      }
    }
    expect(game.finished, isTrue);
    expect(game.skipped, 1);
    expect(game.voiceStars, 5);
    expect(game.buttonStars, 6);
    expect(game.command(RunnerAction.jump, voice: true), isFalse);
  });
  test('free actions animate without clearing a distant obstacle', () {
    final game = SyllableRunnerEngine();
    expect(game.command(RunnerAction.duck, voice: false), isTrue);
    expect(game.action, RunnerAction.duck);
    expect(game.resolving, isFalse);
    for (var i = 0; i < 16; i++) {
      game.tick(.1);
    }
    expect(game.cleared, 0);
    expect(game.action, isNull);
    expect(game.command(RunnerAction.jump, voice: false), isTrue);
    game.tick(.1);
    expect(game.jumpHeight, greaterThan(0));
  });
  test('challenge stops on collision and permits exactly two retries', () {
    final game = SyllableRunnerEngine(mode: RunnerMode.challenge);
    for (var attempt = 0; attempt < 3; attempt++) {
      for (var i = 0; i < 100; i++) {
        game.tick(.1);
      }
      expect(game.failed, isTrue);
      expect(game.command(RunnerAction.jump, voice: false), isFalse);
      expect(game.retry(), attempt < 2);
    }
    expect(game.retries, 0);
  });
  test('stages lengthen and finish after the third course', () {
    final game = SyllableRunnerEngine();
    for (var stage = 0; stage < 3; stage++) {
      expect(game.goal, [12, 16, 20][stage]);
      for (var n = 0; n < game.goal; n++) {
        game.skip();
        for (var i = 0; i < 16; i++) {
          game.tick(.1);
        }
      }
      expect(game.finished, isTrue);
      expect(game.nextStage(), stage < 2);
    }
    expect(game.campaignFinished, isTrue);
  });
  testWidgets('cat selection changes without starting the microphone', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SyllableRunnerScreen()));
    await tester.tap(find.text('모찌 · 흰 코숏 · 암컷'));
    await tester.pump();
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '모찌 · 흰 코숏 · 암컷'),
    );
    expect(chip.selected, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'macOS voice startup uses speech plugin and accepts voice commands',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final speech = RunnerFakeSpeech();
      await tester.pumpWidget(
        MaterialApp(home: SyllableRunnerScreen(speech: speech)),
      );
      await tester.tap(find.text('목소리로 시작 / 이어 하기'));
      await tester.pump();
      expect(speech.initialized, isTrue);
      expect(find.text('잠시 쉬기'), findsOneWidget);
      await speech.callback!('가', false);
      await tester.pump();
      expect(find.textContaining('목소리 동작 1'), findsOneWidget);
      final oldCallback = speech.callback!;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await oldCallback(
        '가',
        true,
      ); // A late result cannot trigger another action.
      await speech.callback!('거', false);
      await tester.pump();
      expect(find.textContaining('목소리 동작 2'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );
  testWidgets('consonant grid changes both controls', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SyllableRunnerScreen()));
    await tester.tap(find.text('자음 선택 · ㄱ  (가 / 거)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ㅁ'));
    await tester.pumpAndSettle();
    expect(find.text('마 · 점프'), findsOneWidget);
    expect(find.text('머 · 숙이기'), findsOneWidget);
    expect(find.text('자음 선택 · ㅁ  (마 / 머)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('button play works without microphone and pauses', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SyllableRunnerScreen()));
    final start = find.text('버튼으로 시작 / 이어 하기');
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    // Tick incrementally; a large background time jump deliberately cannot skip obstacles.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('버튼 동작 1'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.textContaining('버튼 동작 2'), findsOneWidget);
    await tester.tap(find.text('잠시 쉬기'));
    await tester.pump();
    expect(find.text('버튼으로 시작 / 이어 하기'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
