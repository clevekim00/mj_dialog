import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/services/app_language_service.dart';

void main() {
  test(
    'system locale resolves Korean exactly and otherwise falls back to US English',
    () {
      expect(
        resolveSupportedLocale(
          AppLanguagePreference.system,
          const Locale('ko', 'KR'),
        ),
        const Locale('ko', 'KR'),
      );
      expect(
        resolveSupportedLocale(
          AppLanguagePreference.system,
          const Locale('fr', 'FR'),
        ),
        const Locale('en', 'US'),
      );
    },
  );

  test(
    'explicit language overrides the system locale and is persisted',
    () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appLanguageProvider);
      await _waitForInitialization(container);

      await container
          .read(appLanguageProvider.notifier)
          .setPreference(AppLanguagePreference.englishUs);

      expect(container.read(appLanguageProvider).languageTag, 'en-US');
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(AppLanguageController.preferenceKey),
        'en-US',
      );
    },
  );

  test(
    'legacy Korean installation is migrated without changing its language',
    () async {
      SharedPreferences.setMockInitialValues({'rehab_profile': '{}'});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appLanguageProvider);
      await _waitForInitialization(container);

      final state = container.read(appLanguageProvider);
      expect(state.preference, AppLanguagePreference.korean);
      expect(state.languageTag, 'ko-KR');
    },
  );
}

Future<void> _waitForInitialization(ProviderContainer container) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (container.read(appLanguageProvider).initialized) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('Language provider did not initialize.');
}
