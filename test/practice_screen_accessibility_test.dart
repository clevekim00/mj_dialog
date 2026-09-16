import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:speech_rehab/features/practice/provider/practice_provider.dart';
import 'package:speech_rehab/features/practice/view/practice_screen.dart';

class _RecordingNotifier extends PracticeNotifier {
  int stopCount = 0;
  @override
  PracticeProgress build() =>
      PracticeProgress(state: PracticeState.recording, targetText: '편안하게 말해요');
  @override
  Future<void> stopRecording() async {
    stopCount++;
    state = state.copyWith(state: PracticeState.completed);
  }
}

void main() {
  testWidgets(
    'leaving during recording saves before closing and disables other routes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final notifier = _RecordingNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [practiceProvider.overrideWith(() => notifier)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PracticeScreen()),
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IconButton>(find.byWidgetPredicate((widget) => widget is IconButton && widget.tooltip == '녹음 보관함')).onPressed,
        isNull,
      );
      expect(
        tester.widget<IconButton>(find.byWidgetPredicate((widget) => widget is IconButton && widget.tooltip == '연습 기록')).onPressed,
        isNull,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('녹음을 마치고 나갈까요?'), findsOneWidget);
      expect(notifier.stopCount, 0);
      await tester.tap(find.text('녹음 마치고 나가기'));
      await tester.pumpAndSettle();
      expect(notifier.stopCount, 1);
      expect(find.byType(PracticeScreen), findsNothing);
      expect(find.text('열기'), findsOneWidget);
    },
  );

  testWidgets(
    'reading target and fixed recording controls remain usable with large text',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
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
            home: const PracticeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PracticeScreen)),
      );
      await container
          .read(practiceProvider.notifier)
          .setMode(PracticeMode.longSentence);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final record = find.byKey(const Key('practice-record'));
      expect(record.hitTestable(), findsOneWidget);
      expect(tester.getSize(record).height, greaterThanOrEqualTo(56));
      final before = tester.getTopLeft(record);
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(record), before);
      expect(record.hitTestable(), findsOneWidget);
      await tester.tap(record);
      await tester.pumpAndSettle();
      expect(find.text('시작 전 피로도'), findsOneWidget);
      expect(container.read(practiceProvider).state, PracticeState.idle);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('돌아가기'));
      await tester.pumpAndSettle();
      expect(container.read(practiceProvider).state, PracticeState.idle);
    },
  );
}
