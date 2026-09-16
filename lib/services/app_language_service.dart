import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguagePreference { system, korean, englishUs }

extension AppLanguagePreferenceValue on AppLanguagePreference {
  String get storageValue => switch (this) {
    AppLanguagePreference.system => 'system',
    AppLanguagePreference.korean => 'ko-KR',
    AppLanguagePreference.englishUs => 'en-US',
  };

  static AppLanguagePreference parse(String? value) => switch (value) {
    'ko-KR' => AppLanguagePreference.korean,
    'en-US' => AppLanguagePreference.englishUs,
    _ => AppLanguagePreference.system,
  };
}

class AppLanguageState {
  const AppLanguageState({
    required this.preference,
    required this.resolvedLocale,
    this.initialized = false,
  });

  final AppLanguagePreference preference;
  final Locale resolvedLocale;
  final bool initialized;

  String get languageTag => switch (resolvedLocale.languageCode) {
    'ko' => 'ko-KR',
    _ => 'en-US',
  };
}

Locale resolveSupportedLocale(
  AppLanguagePreference preference,
  Locale systemLocale,
) {
  return switch (preference) {
    AppLanguagePreference.korean => const Locale('ko', 'KR'),
    AppLanguagePreference.englishUs => const Locale('en', 'US'),
    AppLanguagePreference.system when systemLocale.languageCode == 'ko' =>
      const Locale('ko', 'KR'),
    AppLanguagePreference.system => const Locale('en', 'US'),
  };
}

final appLanguageProvider =
    NotifierProvider<AppLanguageController, AppLanguageState>(
      AppLanguageController.new,
    );

class AppLanguageController extends Notifier<AppLanguageState> {
  static const preferenceKey = 'app_language_preference_v1';
  static const migrationKey = 'app_language_migration_v1';
  static const legacyProfileKey = 'rehab_profile';

  Locale get _systemLocale => PlatformDispatcher.instance.locale;

  @override
  AppLanguageState build() {
    final initial = AppLanguageState(
      preference: AppLanguagePreference.system,
      resolvedLocale: resolveSupportedLocale(
        AppLanguagePreference.system,
        _systemLocale,
      ),
    );
    unawaited(_restore());
    return initial;
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    var selected = AppLanguagePreferenceValue.parse(
      preferences.getString(preferenceKey),
    );
    if (!preferences.getBool(migrationKey).isTrue &&
        preferences.containsKey(legacyProfileKey) &&
        !preferences.containsKey(preferenceKey)) {
      selected = AppLanguagePreference.korean;
      await preferences.setString(preferenceKey, selected.storageValue);
    }
    await preferences.setBool(migrationKey, true);
    state = AppLanguageState(
      preference: selected,
      resolvedLocale: resolveSupportedLocale(selected, _systemLocale),
      initialized: true,
    );
  }

  Future<void> setPreference(AppLanguagePreference preference) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(preferenceKey, preference.storageValue);
    state = AppLanguageState(
      preference: preference,
      resolvedLocale: resolveSupportedLocale(preference, _systemLocale),
      initialized: true,
    );
  }
}

extension on bool? {
  bool get isTrue => this == true;
}
