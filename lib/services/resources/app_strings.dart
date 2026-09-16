import 'package:speech_rehab/l10n/app_localizations.dart';

/// Runtime-downloaded product strings with generated ARB as the safe fallback.
class AppStrings {
  const AppStrings(this.fallback, [this.overrides = const {}]);

  final AppLocalizations fallback;
  final Map<String, String> overrides;

  String _get(String key, String fallbackValue) =>
      overrides[key]?.trim().isNotEmpty == true
      ? overrides[key]!
      : fallbackValue;

  String get appTitle => _get('appTitle', fallback.appTitle);
  String get today => _get('today', fallback.today);
  String get training => _get('training', fallback.training);
  String get records => _get('records', fallback.records);
  String get communication => _get('communication', fallback.communication);
  String get settings => _get('settings', fallback.settings);
  String get more => _get('more', fallback.more);
  String get language => _get('language', fallback.language);
  String get languageDescription =>
      _get('languageDescription', fallback.languageDescription);
  String get systemDefault => _get('systemDefault', fallback.systemDefault);
  String get korean => _get('korean', fallback.korean);
  String get englishUs => _get('englishUs', fallback.englishUs);
  String get languageChangeNotice =>
      _get('languageChangeNotice', fallback.languageChangeNotice);
  String get settingsDescription =>
      _get('settingsDescription', fallback.settingsDescription);
  String get resetGoals => _get('resetGoals', fallback.resetGoals);
  String get resetGoalsDescription =>
      _get('resetGoalsDescription', fallback.resetGoalsDescription);
  String get oralTrainingSettings =>
      _get('oralTrainingSettings', fallback.oralTrainingSettings);
  String get oralTrainingSettingsDescription => _get(
    'oralTrainingSettingsDescription',
    fallback.oralTrainingSettingsDescription,
  );
  String get microphoneCheck =>
      _get('microphoneCheck', fallback.microphoneCheck);
  String get microphoneCheckDescription =>
      _get('microphoneCheckDescription', fallback.microphoneCheckDescription);
  String get accessibilityPrinciples =>
      _get('accessibilityPrinciples', fallback.accessibilityPrinciples);
  String get accessibilityPrinciplesDescription => _get(
    'accessibilityPrinciplesDescription',
    fallback.accessibilityPrinciplesDescription,
  );
}
