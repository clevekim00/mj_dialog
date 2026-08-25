import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/voice_analysis/view/voice_analysis_screens.dart';

void main() {
  testWidgets('shows all voice analysis tools as individual menu items', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: VoiceAnalysisMenuScreen()));

    expect(find.text('실시간 목소리 높이'), findsOneWidget);
    expect(find.text('목표음 따라 내기'), findsOneWidget);
    expect(find.text('목소리 크기'), findsOneWidget);
    expect(find.text('발성 음파 분석'), findsOneWidget);
    expect(find.text('한국어 발음 균형 문장'), findsOneWidget);
    expect(find.text('10초 즉시 녹음'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('마이크·소음 점검'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('발성 분석 결과'), findsOneWidget);
    expect(find.text('나의 기준 음성'), findsOneWidget);
    expect(find.text('발성 분석 기록'), findsOneWidget);
    expect(find.text('마이크·소음 점검'), findsOneWidget);
  });
}
