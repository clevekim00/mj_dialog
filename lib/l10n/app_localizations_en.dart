// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Speech Rehab';

  @override
  String get today => 'Today';

  @override
  String get training => 'Training';

  @override
  String get records => 'Records';

  @override
  String get communication => 'Communication';

  @override
  String get settings => 'Settings';

  @override
  String get more => 'More';

  @override
  String get language => 'Language';

  @override
  String get languageDescription =>
      'Choose the language used for screens, voice guidance, practice content, and pronunciation analysis.';

  @override
  String get systemDefault => 'System Default';

  @override
  String get korean => '한국어';

  @override
  String get englishUs => 'English (US)';

  @override
  String get languageChangeNotice =>
      'Screens, voice guidance, practice content, and pronunciation analysis will change together.';

  @override
  String get settingsDescription =>
      'Manage your training goals and app environment.';

  @override
  String get resetGoals => 'Set rehabilitation goals again';

  @override
  String get resetGoalsDescription =>
      'Adjust your daily training time and primary goals.';

  @override
  String get oralTrainingSettings => 'Oral and breathing training settings';

  @override
  String get oralTrainingSettingsDescription =>
      'Set repetitions, playback speed, captions, and voice guidance.';

  @override
  String get microphoneCheck => 'Microphone check';

  @override
  String get microphoneCheckDescription =>
      'Check your input device and background noise before training.';

  @override
  String get accessibilityPrinciples => 'Accessibility principles';

  @override
  String get accessibilityPrinciplesDescription =>
      'Large controls, clear text guidance, and consistent training buttons are provided.';
}
