import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:speech_rehab/features/sentence_practice/sentence_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/navigation/view/adaptive_app_shell.dart';
import 'package:speech_rehab/l10n/app_localizations.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final language in ['ko', 'en']) {
    testWidgets('360px navigation with 200% text in $language', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const AdaptiveAppShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      await tester.tap(find.byType(NavigationDestination).at(4));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('uses bottom navigation on compact windows', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: _LocalizedTestApp()));
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.text('글자 크기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses navigation rail and opens records on wide windows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sentences = SentenceRepository(
      sqlite3.openInMemory(),
      Directory.systemTemp,
    );
    addTearDown(sentences.db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sentenceRepositoryProvider.overrideWith((ref) async => sentences),
        ],
        child: const _LocalizedTestApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('훈련').first);
    await tester.pumpAndSettle();
    expect(find.text('구강 훈련'), findsOneWidget);

    await tester.tap(find.text('게임').first);
    await tester.pumpAndSettle();
    expect(find.text('단어 말하기 게임'), findsOneWidget);
    expect(find.text('목소리로 천천히 날기'), findsOneWidget);

    await tester.tap(find.text('기록').first);
    await tester.pumpAndSettle();

    expect(find.text('연습 기록'), findsOneWidget);
    await tester.tap(find.text('자음'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '자음')).selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
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
