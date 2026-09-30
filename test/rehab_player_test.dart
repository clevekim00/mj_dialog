import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/rehab/model/rehab_session.dart';
import 'package:speech_rehab/features/rehab/services/rehab_session_repository.dart';
import 'package:speech_rehab/features/rehab/view/rehab_player_screen.dart';
import 'package:speech_rehab/features/rehab/audio/practice_capture.dart';
import 'rehab_session_test.dart' show sample;

class Recorder extends PracticeCapture {
  int starts = 0, stops = 0;
  @override
  Future<void> startRecording(String name) async {
    starts++;
  }

  @override
  Future<String?> stopRecording() async {
    stops++;
    return '/test.m4a';
  }
}

class FailingRepository extends RehabSessionRepository {
  bool fail = false;
  @override
  Future<void> save(RehabSession session) async {
    if (fail) throw StateError('disk');
    await super.save(session);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'save failure blocks advancement, retry retains recording once, pause preserves index',
    (tester) async {
      final repo = FailingRepository(), recorder = Recorder();
      await repo.save(sample());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rehabRepositoryProvider.overrideWithValue(repo),
            practiceCaptureProvider.overrideWithValue(recorder),
          ],
          child: MaterialApp(home: RehabPlayerScreen(session: sample())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('녹음 시작'));
      await tester.pumpAndSettle();
      repo.fail = true;
      await tester.tap(find.text('녹음 마치기'));
      await tester.pumpAndSettle();
      expect(recorder.stops, 1);
      expect((await repo.load()).single.takes, isEmpty);
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text('녹음 시작'),
                matching: find.byWidgetPredicate((w) => w is FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
      repo.fail = false;
      await tester.tap(find.text('다시 저장'));
      await tester.pumpAndSettle();
      expect((await repo.load()).single.takes.length, 1);
      await tester.scrollUntilVisible(
        find.text('다음 과제'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음 과제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('쉬기'));
      await tester.pumpAndSettle();
      final saved = (await repo.load()).single;
      expect(saved.status, RehabStatus.paused);
      expect(saved.taskIndex, 1);
      expect(saved.takes.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'ending without a recording never completes tasks, works at 200 percent',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: RehabPlayerScreen(session: sample()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('녹음 시작').hitTestable(), findsOneWidget);
      await tester.tap(find.text('마치기'));
      await tester.pumpAndSettle();
      final saved = (await RehabSessionRepository().load()).single;
      expect(saved.status, RehabStatus.partial);
      expect(saved.completedTasks, 0);
      expect(saved.takes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('backgrounding stops and saves an active recording', (
    tester,
  ) async {
    final recorder = Recorder();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [practiceCaptureProvider.overrideWithValue(recorder)],
        child: MaterialApp(home: RehabPlayerScreen(session: sample())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('녹음 시작'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(recorder.stops, 1);
    final saved = (await RehabSessionRepository().load()).single;
    expect(saved.status, RehabStatus.paused);
    expect(saved.takes.length, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}
