import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/practice/view/practice_mode_selection_screen.dart';
import 'package:speech_rehab/features/rehab/services/rehab_session_repository.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'home offers one saved plan, with no score driven recommendation',
    (tester) async {
      await RehabSessionRepository().savePlan('hospital', 2);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PracticeModeSelectionScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('오늘 연습 시작'), findsOneWidget);
      expect(find.text('병원에서 부탁하기'), findsOneWidget);
      expect(find.text('3개 과제 · 과제마다 2번 녹음'), findsOneWidget);
      expect(find.text('단어 게임'), findsNothing);
      expect(find.text('자유 대화'), findsNothing);
      await tester.tap(find.text('오늘 연습 시작'));
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '연습 시작'),
      );
      expect(button.onPressed, isNull);
      await tester.scrollUntilVisible(
        find.text('2 / 5'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('2 / 5'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '연습 시작'))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
