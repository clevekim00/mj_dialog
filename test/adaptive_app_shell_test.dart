import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/navigation/view/adaptive_app_shell.dart';
import 'package:speech_rehab/l10n/app_localizations.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('uses bottom navigation on compact windows', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: _LocalizedTestApp()));
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('더보기'), findsOneWidget);
  });

  testWidgets('uses navigation rail and opens records on wide windows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: _LocalizedTestApp()));
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('기록').first);
    await tester.pumpAndSettle();

    expect(find.text('훈련 달력 · 이력'), findsOneWidget);
    expect(find.text('음성 분석 기록'), findsOneWidget);
  });
}

class _LocalizedTestApp extends StatelessWidget {
  const _LocalizedTestApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    locale: Locale('ko', 'KR'),
    supportedLocales: [Locale('ko', 'KR'), Locale('en', 'US')],
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: AdaptiveAppShell(),
  );
}
