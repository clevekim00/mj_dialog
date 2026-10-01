import 'package:speech_rehab/features/guided_training/data/guided_training_catalog.dart';
import 'package:speech_rehab/features/guided_training/view/guided_training_hub_screen.dart';
import 'package:speech_rehab/services/training/training_availability.dart';
import 'package:speech_rehab/services/training/training_availability_provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/guided_training/model/guided_training_models.dart';
import 'package:speech_rehab/features/guided_training/view/guided_training_player_screen.dart';
import 'package:speech_rehab/services/guided_training/guided_training_history_service.dart';

GuidedTrainingExercise exercise(String id) => GuidedTrainingExercise(
  id: id,
  category: GuidedTrainingCategory.lip,
  sourceOrder: 1,
  title: id,
  instruction: '편안하게 따라 하세요.',
  shortCaption: '천천히',
  visualMode: GuidedTrainingVisualMode.phoneme,
  loopDuration: const Duration(milliseconds: 100),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'training_default_repeat_count': 20,
      'training_tts_enabled': false,
      'training_haptics_enabled': false,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (_) async => 1,
        );
  });

  testWidgets('clinician-guided breathing opens and can start under default policy', (tester) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [trainingAvailabilityProvider.overrideWith((ref) async => const TrainingAvailability())],
      child: const MaterialApp(home: GuidedTrainingCategoryScreen(category: GuidedTrainingCategory.breathing)),
    ));
    await tester.pumpAndSettle();
    final target = find.text(guidedExerciseById('breathing_03_rapid_deep')!.title);
    await tester.scrollUntilVisible(target, 200);
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(find.byType(GuidedTrainingPlayerScreen), findsOneWidget);
    expect(find.text('이 훈련은 의사 또는 언어재활사와 상의한 뒤 실시하세요.'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '2'));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('guided-training-start'))).onPressed, isNotNull);
  });

  testWidgets('closed direct training cannot start', (tester) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trainingAvailabilityProvider.overrideWith(
            (ref) async =>
                const TrainingAvailability(overrides: {'closed': false}),
          ),
        ],
        child: MaterialApp(
          home: GuidedTrainingPlayerScreen(exercises: [exercise('closed')]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '2'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('guided-training-start')),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('관리자가 이 훈련을 일시적으로 닫았어요.'), findsOneWidget);
    expect(await GuidedTrainingHistoryService().loadSessions(), isEmpty);
  });

  testWidgets('routine skips closed first item and records it as skipped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trainingAvailabilityProvider.overrideWith(
            (ref) async =>
                const TrainingAvailability(overrides: {'closed': false}),
          ),
        ],
        child: MaterialApp(
          home: GuidedTrainingPlayerScreen(
            exercises: [exercise('closed'), exercise('open')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '2'));
    await tester.pump();
    await tester.tap(find.text('훈련 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    final saved = (await GuidedTrainingHistoryService().loadSessions()).single;
    expect(saved.exerciseIndex, 1);
    expect(saved.results.single.exerciseId, 'closed');
    expect(saved.results.single.skipped, isTrue);
    expect(saved.results.single.completedLoops, 0);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'late lifecycle pause does not turn a completed session into resumable progress',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final stop = Completer<int>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'),
            (call) async => call.method == 'stop' ? stop.future : 1,
          );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trainingAvailabilityProvider.overrideWith(
              (ref) async => const TrainingAvailability(),
            ),
          ],
          child: MaterialApp(
            home: GuidedTrainingPlayerScreen(exercises: [exercise('one')]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('5회'));
      await tester.tap(find.widgetWithText(ChoiceChip, '2'));
      await tester.pump();
      await tester.tap(find.text('훈련 시작'));
      await tester.pump();
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      await tester.tap(find.text('훈련 완료'));
      await tester.pumpAndSettle();
      stop.complete(1);
      await tester.pumpAndSettle();
      final saved =
          (await GuidedTrainingHistoryService().loadSessions()).single;
      expect(saved.status, GuidedTrainingSessionStatus.completed);
      expect(saved.canResume, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    },
  );

  testWidgets(
    'selected repetitions persist across exercises and completion autosaves',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trainingAvailabilityProvider.overrideWith(
              (ref) async => const TrainingAvailability(),
            ),
          ],
          child: MaterialApp(
            home: GuidedTrainingPlayerScreen(
              exercises: [exercise('one'), exercise('two')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('5회'));
      await tester.tap(find.widgetWithText(ChoiceChip, '2'));
      await tester.pump();
      await tester.tap(find.text('훈련 시작'));
      await tester.pump();
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
      }
      expect(find.text('5 / 5'), findsOneWidget);
      await tester.tap(find.text('다음 운동'));
      await tester.pump();
      await tester.pump();
      expect(find.text('0 / 5'), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump();
      }
      await tester.tap(find.text('훈련 완료'));
      await tester.pumpAndSettle();
      final saved =
          (await GuidedTrainingHistoryService().loadSessions()).single;
      expect(saved.completed, isTrue);
      expect(saved.results.map((result) => result.targetLoops), [5, 5]);
      expect(saved.fatigueAfter, isNull);
      expect(find.text('훈련을 마쳤어요'), findsOneWidget);
    },
  );

  testWidgets('resuming a now-closed exercise skips it and leaves next paused', (tester) async {
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final saved = GuidedTrainingSession(
      id: 'closed-resume', startedAt: DateTime(2026, 10, 1),
      completedAt: DateTime(2026, 10, 1), routineName: '내 루틴',
      fatigueBefore: 2, fatigueAfter: null, results: const [],
      status: GuidedTrainingSessionStatus.stopped,
      exerciseIds: const ['closed', 'open'], currentCompletedLoops: 2,
      currentTargetLoops: 5, repeatCount: 5,
    );
    await GuidedTrainingHistoryService().saveSession(saved);
    await tester.pumpWidget(ProviderScope(
      overrides: [trainingAvailabilityProvider.overrideWith((ref) async => const TrainingAvailability(overrides: {'closed': false}))],
      child: MaterialApp(home: GuidedTrainingPlayerScreen(exercises: [exercise('closed'), exercise('open')])),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이어하기'));
    await tester.pumpAndSettle();
    expect(find.text('계속하기'), findsOneWidget);
    expect(find.text('0 / 5'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('0 / 5'), findsOneWidget);
    final result = (await GuidedTrainingHistoryService().loadSessions()).single;
    expect(result.exerciseIndex, 1);
    expect(result.results.single.skipped, isTrue);
  });

  testWidgets('resume restores partial loops and remains paused', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final saved = GuidedTrainingSession(
      id: 'resume',
      startedAt: DateTime(2026, 9, 15),
      completedAt: DateTime(2026, 9, 15),
      routineName: '이어하기',
      fatigueBefore: 2,
      fatigueAfter: null,
      results: const [],
      status: GuidedTrainingSessionStatus.stopped,
      exerciseIds: const ['one'],
      currentCompletedLoops: 3,
      currentTargetLoops: 5,
      repeatCount: 5,
      activeDurationSeconds: 10,
    );
    await GuidedTrainingHistoryService().saveSession(saved);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trainingAvailabilityProvider.overrideWith(
            (ref) async => const TrainingAvailability(),
          ),
        ],
        child: MaterialApp(
          home: GuidedTrainingPlayerScreen(exercises: [exercise('one')]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('이어하기'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 5'), findsOneWidget);
    expect(find.text('계속하기'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('3 / 5'), findsOneWidget);
  });
}
