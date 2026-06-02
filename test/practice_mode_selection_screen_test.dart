import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/practice/view/practice_mode_selection_screen.dart';

void main() {
  testWidgets('shows all structured practice mode choices', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: PracticeModeSelectionScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('연습 선택'), findsOneWidget);
    expect(find.text('단어 게임'), findsOneWidget);
    expect(find.text('짧은 문장 읽기'), findsOneWidget);
    expect(find.text('긴 문장 읽기'), findsOneWidget);
    expect(find.text('자유 대화'), findsOneWidget);
  });
}
