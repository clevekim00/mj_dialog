import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/main.dart';

void main() {
  testWidgets('renders the rehab onboarding shell', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MyApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('말하기 재활을 안전하게 시작해요'), findsOneWidget);
      expect(find.text('안전 안내'), findsOneWidget);
      expect(find.text('오늘의 주 목표'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
