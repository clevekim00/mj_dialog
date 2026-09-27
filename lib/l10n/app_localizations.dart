import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Speech Rehab'**
  String get appTitle;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @communication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get communication;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used for screens, voice guidance, practice content, and pronunciation analysis.'**
  String get languageDescription;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @korean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get korean;

  /// No description provided for @englishUs.
  ///
  /// In en, this message translates to:
  /// **'English (US)'**
  String get englishUs;

  /// No description provided for @languageChangeNotice.
  ///
  /// In en, this message translates to:
  /// **'Screens, voice guidance, practice content, and pronunciation analysis will change together.'**
  String get languageChangeNotice;

  /// No description provided for @settingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your training goals and app environment.'**
  String get settingsDescription;

  /// No description provided for @resetGoals.
  ///
  /// In en, this message translates to:
  /// **'Set rehabilitation goals again'**
  String get resetGoals;

  /// No description provided for @resetGoalsDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust your daily training time and primary goals.'**
  String get resetGoalsDescription;

  /// No description provided for @oralTrainingSettings.
  ///
  /// In en, this message translates to:
  /// **'Oral and breathing training settings'**
  String get oralTrainingSettings;

  /// No description provided for @oralTrainingSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Set repetitions, playback speed, captions, and voice guidance.'**
  String get oralTrainingSettingsDescription;

  /// No description provided for @microphoneCheck.
  ///
  /// In en, this message translates to:
  /// **'Microphone check'**
  String get microphoneCheck;

  /// No description provided for @microphoneCheckDescription.
  ///
  /// In en, this message translates to:
  /// **'Check your input device and background noise before training.'**
  String get microphoneCheckDescription;

  /// No description provided for @accessibilityPrinciples.
  ///
  /// In en, this message translates to:
  /// **'Accessibility principles'**
  String get accessibilityPrinciples;

  /// No description provided for @accessibilityPrinciplesDescription.
  ///
  /// In en, this message translates to:
  /// **'Large controls, clear text guidance, and consistent training buttons are provided.'**
  String get accessibilityPrinciplesDescription;

  /// No description provided for @rehabToday.
  ///
  /// In en, this message translates to:
  /// **'Today’s practice'**
  String get rehabToday;

  /// No description provided for @rehabIdentity.
  ///
  /// In en, this message translates to:
  /// **'Practice the words you need, at your own pace.'**
  String get rehabIdentity;

  /// No description provided for @rehabStart.
  ///
  /// In en, this message translates to:
  /// **'Start today’s practice'**
  String get rehabStart;

  /// No description provided for @rehabResume.
  ///
  /// In en, this message translates to:
  /// **'Continue practice'**
  String get rehabResume;

  /// No description provided for @rehabChangePlan.
  ///
  /// In en, this message translates to:
  /// **'Change plan'**
  String get rehabChangePlan;

  /// No description provided for @rehabPlan.
  ///
  /// In en, this message translates to:
  /// **'Practice plan'**
  String get rehabPlan;

  /// No description provided for @rehabSequence.
  ///
  /// In en, this message translates to:
  /// **'Word → Sentence → Everyday situation'**
  String get rehabSequence;

  /// No description provided for @rehabPrepare.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get rehabPrepare;

  /// No description provided for @rehabFatigue.
  ///
  /// In en, this message translates to:
  /// **'How tired do you feel?'**
  String get rehabFatigue;

  /// No description provided for @rehabFatigueHint.
  ///
  /// In en, this message translates to:
  /// **'1 Comfortable · 5 Very tired'**
  String get rehabFatigueHint;

  /// No description provided for @rehabRestHint.
  ///
  /// In en, this message translates to:
  /// **'It is fine to shorten practice or rest. You can reduce repetitions.'**
  String get rehabRestHint;

  /// No description provided for @rehabSafety.
  ///
  /// In en, this message translates to:
  /// **'Stop if you feel discomfort or pain. Discuss suitable practice and duration with your clinician.'**
  String get rehabSafety;

  /// No description provided for @rehabBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin practice'**
  String get rehabBegin;

  /// No description provided for @rehabRepetitions.
  ///
  /// In en, this message translates to:
  /// **'Repetitions per task'**
  String get rehabRepetitions;

  /// No description provided for @rehabListen.
  ///
  /// In en, this message translates to:
  /// **'Listen to example (TTS)'**
  String get rehabListen;

  /// No description provided for @rehabRecord.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get rehabRecord;

  /// No description provided for @rehabStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Finish recording'**
  String get rehabStopRecording;

  /// No description provided for @rehabListenMine.
  ///
  /// In en, this message translates to:
  /// **'Listen to my recording'**
  String get rehabListenMine;

  /// No description provided for @rehabStopAudio.
  ///
  /// In en, this message translates to:
  /// **'Stop audio'**
  String get rehabStopAudio;

  /// No description provided for @rehabPause.
  ///
  /// In en, this message translates to:
  /// **'Take a break'**
  String get rehabPause;

  /// No description provided for @rehabPaused.
  ///
  /// In en, this message translates to:
  /// **'Practice is paused'**
  String get rehabPaused;

  /// No description provided for @rehabNext.
  ///
  /// In en, this message translates to:
  /// **'Next task'**
  String get rehabNext;

  /// No description provided for @rehabFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get rehabFinish;

  /// No description provided for @rehabSkip.
  ///
  /// In en, this message translates to:
  /// **'Next without recording'**
  String get rehabSkip;

  /// No description provided for @rehabNoMic.
  ///
  /// In en, this message translates to:
  /// **'You can listen, follow along, or prepare a sentence. Tasks without recordings are not counted as recorded attempts.'**
  String get rehabNoMic;

  /// No description provided for @rehabSaved.
  ///
  /// In en, this message translates to:
  /// **'Practice saved'**
  String get rehabSaved;

  /// No description provided for @rehabSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try saving again.'**
  String get rehabSaveError;

  /// No description provided for @rehabRetrySave.
  ///
  /// In en, this message translates to:
  /// **'Retry saving'**
  String get rehabRetrySave;

  /// No description provided for @rehabRecordError.
  ///
  /// In en, this message translates to:
  /// **'Could not start or save recording. Check your microphone or continue without recording.'**
  String get rehabRecordError;

  /// No description provided for @rehabAudioError.
  ///
  /// In en, this message translates to:
  /// **'Could not play audio. Check device volume and the file.'**
  String get rehabAudioError;

  /// No description provided for @rehabOptionalFatigue.
  ///
  /// In en, this message translates to:
  /// **'Tiredness after practice (optional)'**
  String get rehabOptionalFatigue;

  /// No description provided for @rehabDone.
  ///
  /// In en, this message translates to:
  /// **'Back to today'**
  String get rehabDone;

  /// No description provided for @rehabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent practice'**
  String get rehabRecent;

  /// No description provided for @rehabEmpty.
  ///
  /// In en, this message translates to:
  /// **'No practice yet. Start with a short session.'**
  String get rehabEmpty;

  /// No description provided for @rehabRecords.
  ///
  /// In en, this message translates to:
  /// **'Practice records'**
  String get rehabRecords;

  /// No description provided for @rehabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get rehabAll;

  /// No description provided for @rehabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get rehabCalendar;

  /// No description provided for @rehabClearDate.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get rehabClearDate;

  /// No description provided for @rehabRecordings.
  ///
  /// In en, this message translates to:
  /// **'My recordings'**
  String get rehabRecordings;

  /// No description provided for @rehabCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare the same words'**
  String get rehabCompare;

  /// No description provided for @rehabRepeat.
  ///
  /// In en, this message translates to:
  /// **'Practice these words again'**
  String get rehabRepeat;

  /// No description provided for @rehabReference.
  ///
  /// In en, this message translates to:
  /// **'Reference information'**
  String get rehabReference;

  /// No description provided for @rehabUnscored.
  ///
  /// In en, this message translates to:
  /// **'These are recordings and activity records, not assessments of pronunciation accuracy or treatment outcomes.'**
  String get rehabUnscored;

  /// No description provided for @rehabDetails.
  ///
  /// In en, this message translates to:
  /// **'Practice details'**
  String get rehabDetails;

  /// No description provided for @rehabTraining.
  ///
  /// In en, this message translates to:
  /// **'What would you like to practice?'**
  String get rehabTraining;

  /// No description provided for @rehabArticulation.
  ///
  /// In en, this message translates to:
  /// **'Clear speech practice'**
  String get rehabArticulation;

  /// No description provided for @rehabArticulationHint.
  ///
  /// In en, this message translates to:
  /// **'Choose consonants, syllables, or words to repeat.'**
  String get rehabArticulationHint;

  /// No description provided for @rehabSentences.
  ///
  /// In en, this message translates to:
  /// **'Speaking in sentences'**
  String get rehabSentences;

  /// No description provided for @rehabSentencesHint.
  ///
  /// In en, this message translates to:
  /// **'Practice short, long, or personal sentences.'**
  String get rehabSentencesHint;

  /// No description provided for @rehabEveryday.
  ///
  /// In en, this message translates to:
  /// **'Everyday speaking'**
  String get rehabEveryday;

  /// No description provided for @rehabEverydayHint.
  ///
  /// In en, this message translates to:
  /// **'Practice requests, explanations, and phone calls.'**
  String get rehabEverydayHint;

  /// No description provided for @rehabVoice.
  ///
  /// In en, this message translates to:
  /// **'Comfortable voice practice'**
  String get rehabVoice;

  /// No description provided for @rehabVoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Use a comfortable voice and speak through the end of a sentence.'**
  String get rehabVoiceHint;

  /// No description provided for @rehabPacing.
  ///
  /// In en, this message translates to:
  /// **'Pacing and pauses'**
  String get rehabPacing;

  /// No description provided for @rehabPacingHint.
  ///
  /// In en, this message translates to:
  /// **'Break sentences into short phrases with comfortable pauses.'**
  String get rehabPacingHint;

  /// No description provided for @rehabWarmup.
  ///
  /// In en, this message translates to:
  /// **'Optional preparation'**
  String get rehabWarmup;

  /// No description provided for @rehabWarmupHint.
  ///
  /// In en, this message translates to:
  /// **'Explore lip, tongue, and breathing guidance when needed.'**
  String get rehabWarmupHint;

  /// No description provided for @rehabConsonants.
  ///
  /// In en, this message translates to:
  /// **'Choose a consonant'**
  String get rehabConsonants;

  /// No description provided for @rehabWords.
  ///
  /// In en, this message translates to:
  /// **'Speaking words'**
  String get rehabWords;

  /// No description provided for @rehabShort.
  ///
  /// In en, this message translates to:
  /// **'Short sentences'**
  String get rehabShort;

  /// No description provided for @rehabLong.
  ///
  /// In en, this message translates to:
  /// **'Long and personal sentences'**
  String get rehabLong;

  /// No description provided for @rehabFree.
  ///
  /// In en, this message translates to:
  /// **'Free conversation (optional)'**
  String get rehabFree;

  /// No description provided for @rehabTools.
  ///
  /// In en, this message translates to:
  /// **'Additional voice tools'**
  String get rehabTools;

  /// No description provided for @rehabOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline content'**
  String get rehabOffline;

  /// No description provided for @rehabAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get rehabAccessibility;

  /// No description provided for @rehabManageRecordings.
  ///
  /// In en, this message translates to:
  /// **'Manage earlier recordings'**
  String get rehabManageRecordings;

  /// No description provided for @rehabManageHint.
  ///
  /// In en, this message translates to:
  /// **'Delete and share earlier sentence recordings'**
  String get rehabManageHint;

  /// No description provided for @rehabLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Could not load records. Please try again.'**
  String get rehabLoadingError;

  /// No description provided for @rehabRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get rehabRetry;

  /// No description provided for @rehabDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this session'**
  String get rehabDelete;

  /// No description provided for @rehabDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this session and its app-owned recordings?'**
  String get rehabDeleteConfirm;

  /// No description provided for @rehabCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get rehabCancel;

  /// No description provided for @rehabPracticeAgain.
  ///
  /// In en, this message translates to:
  /// **'Practice again'**
  String get rehabPracticeAgain;

  /// No description provided for @rehabRecordingOnly.
  ///
  /// In en, this message translates to:
  /// **'Save your voice without waiting for recognition or scores.'**
  String get rehabRecordingOnly;

  /// No description provided for @rehabPlanSaved.
  ///
  /// In en, this message translates to:
  /// **'Your plan will be used next time too.'**
  String get rehabPlanSaved;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
