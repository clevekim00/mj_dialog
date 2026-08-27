import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/settings/view/language_settings_screen.dart';
import 'package:speech_rehab/l10n/app_localizations.dart';
import 'package:speech_rehab/services/app_language_service.dart';

void main() {
  testWidgets('사용자가 English (US)를 선택하면 설정에 저장한다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ko', 'KR'),
          supportedLocales: [Locale('ko', 'KR'), Locale('en', 'US')],
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: LanguageSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('English (US)').last);
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(AppLanguageController.preferenceKey),
      'en-US',
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
