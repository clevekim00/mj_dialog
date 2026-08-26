import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/practice/view/practice_mode_selection_screen.dart';

class _VoiceToolsStub extends StatelessWidget {
  const _VoiceToolsStub();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('음성도구 화면'));
}

void main() {
  testWidgets('shows all structured practice mode choices', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: PracticeModeSelectionScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('오늘의 연습'), findsOneWidget);
    expect(find.text('오늘 추천 연습'), findsOneWidget);
    expect(find.text('구강·호흡 준비운동'), findsOneWidget);
    expect(find.text('오늘의 통합 루틴'), findsOneWidget);
    expect(find.text('자음 집중 훈련'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('다른 연습 선택'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('다른 연습 선택'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('단어 게임'),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('단어 게임'), findsOneWidget);
    expect(find.text('짧은 문장 읽기'), findsOneWidget);
    expect(find.text('긴 문장 읽기'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('자유 대화'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('자유 대화'), findsOneWidget);
  });

  testWidgets('opens voice tools from the top menu', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const PracticeModeSelectionScreen(),
          routes: {'/voice_analysis_menu': (_) => const _VoiceToolsStub()},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('음성도구'), findsOneWidget);
    await tester.tap(find.text('음성도구'));
    await tester.pumpAndSettle();

    expect(find.text('음성도구 화면'), findsOneWidget);
  });
}
