import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/games/view/game_menu_screen.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:speech_rehab/features/practice/provider/practice_provider.dart';
import 'package:speech_rehab/features/rehab/game/phonation_flight_screen.dart';
import 'package:speech_rehab/features/rehab/services/rehab_record_index.dart';
import 'package:speech_rehab/services/practice_history_service.dart';
import 'package:speech_rehab/l10n/app_localizations.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'word game resets previous mode and timed preference before opening',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(practiceProvider.notifier);
      await notifier.setMode(PracticeMode.longSentence);
      notifier.setWordGameTimed(true);
      var opens = 0;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const GameMenuScreen(),
            routes: {
              '/word_game': (_) {
                opens++;
                return const Scaffold(body: Text('Opened word game'));
              },
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('단어 말하기 게임'));
      await tester.pumpAndSettle();
      expect(opens, 1);
      expect(container.read(practiceProvider).mode, PracticeMode.wordGame);
      expect(container.read(practiceProvider).wordGameTimed, false);
      expect(find.text('Opened word game'), findsOneWidget);
    },
  );
  for (final language in ['ko', 'en']) {
    testWidgets('both games in $language at 360px and 200 percent text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final en = language == 'en';
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
            home: const GameMenuScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final flight = find.text(en ? 'Gentle voice flight' : '목소리로 천천히 날기');
      await tester.scrollUntilVisible(
        flight,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(flight);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(flight);
      await tester.pumpAndSettle();
      expect(find.byType(PhonationFlightScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test(
    'existing word game records use game filter without rewriting storage',
    () async {
      await PracticeHistoryService().savePractice(
        PracticeSession(
          id: 'word',
          targetText: '물',
          spokenText: '물',
          audioFilePath: '/word.wav',
          score: null,
          feedback: '',
          timestamp: DateTime.now(),
          mode: 'wordGame',
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      final before = prefs.getString('practice_history');
      final record = (await RehabRecordIndex().load()).single;
      expect(record.kind, 'game');
      expect(record.id, 'practice:word');
      expect(record.recordings.single.path, '/word.wav');
      expect(prefs.getString('practice_history'), before);
    },
  );
}
