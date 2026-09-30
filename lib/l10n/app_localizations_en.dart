// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SpeechBridge';

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

  @override
  String get rehabToday => 'Today’s practice';

  @override
  String get rehabIdentity => 'Practice the words you need, at your own pace.';

  @override
  String get rehabStart => 'Start today’s practice';

  @override
  String get rehabResume => 'Continue practice';

  @override
  String get rehabChangePlan => 'Change plan';

  @override
  String get rehabPlan => 'Practice plan';

  @override
  String get rehabSequence => 'Word → Sentence → Everyday situation';

  @override
  String get rehabPrepare => 'Before you start';

  @override
  String get rehabFatigue => 'How tired do you feel?';

  @override
  String get rehabFatigueHint => '1 Comfortable · 5 Very tired';

  @override
  String get rehabRestHint =>
      'It is fine to shorten practice or rest. You can reduce repetitions.';

  @override
  String get rehabSafety =>
      'Stop if you feel discomfort or pain. Discuss suitable practice and duration with your clinician.';

  @override
  String get rehabBegin => 'Begin practice';

  @override
  String get rehabRepetitions => 'Repetitions per task';

  @override
  String get rehabListen => 'Listen to example (TTS)';

  @override
  String get rehabRecord => 'Start recording';

  @override
  String get rehabStopRecording => 'Finish recording';

  @override
  String get rehabListenMine => 'Listen to my recording';

  @override
  String get rehabStopAudio => 'Stop audio';

  @override
  String get rehabPause => 'Take a break';

  @override
  String get rehabPaused => 'Practice is paused';

  @override
  String get rehabNext => 'Next task';

  @override
  String get rehabFinish => 'Finish';

  @override
  String get rehabSkip => 'Next without recording';

  @override
  String get rehabNoMic =>
      'You can listen, follow along, or prepare a sentence. Tasks without recordings are not counted as recorded attempts.';

  @override
  String get rehabSaved => 'Practice saved';

  @override
  String get rehabSaveError => 'Could not save. Please try saving again.';

  @override
  String get rehabRetrySave => 'Retry saving';

  @override
  String get rehabRecordError =>
      'Could not start or save recording. Check your microphone or continue without recording.';

  @override
  String get rehabAudioError =>
      'Could not play audio. Check device volume and the file.';

  @override
  String get rehabOptionalFatigue => 'Tiredness after practice (optional)';

  @override
  String get rehabDone => 'Back to today';

  @override
  String get rehabRecent => 'Recent practice';

  @override
  String get rehabEmpty => 'No practice yet. Start with a short session.';

  @override
  String get rehabRecords => 'Practice records';

  @override
  String get rehabAll => 'All';

  @override
  String get rehabCalendar => 'Choose date';

  @override
  String get rehabClearDate => 'All dates';

  @override
  String get rehabRecordings => 'My recordings';

  @override
  String get rehabCompare => 'Compare the same words';

  @override
  String get rehabRepeat => 'Practice these words again';

  @override
  String get rehabReference => 'Reference information';

  @override
  String get rehabUnscored =>
      'These are recordings and activity records, not assessments of pronunciation accuracy or treatment outcomes.';

  @override
  String get rehabDetails => 'Practice details';

  @override
  String get rehabTraining => 'What would you like to practice?';

  @override
  String get rehabArticulation => 'Clear speech practice';

  @override
  String get rehabArticulationHint =>
      'Choose consonants, syllables, or words to repeat.';

  @override
  String get rehabSentences => 'Speaking in sentences';

  @override
  String get rehabSentencesHint =>
      'Practice short, long, or personal sentences.';

  @override
  String get rehabEveryday => 'Everyday speaking';

  @override
  String get rehabEverydayHint =>
      'Practice requests, explanations, and phone calls.';

  @override
  String get rehabVoice => 'Comfortable voice practice';

  @override
  String get rehabVoiceHint =>
      'Use a comfortable voice and speak through the end of a sentence.';

  @override
  String get rehabPacing => 'Pacing and pauses';

  @override
  String get rehabPacingHint =>
      'Break sentences into short phrases with comfortable pauses.';

  @override
  String get rehabWarmup => 'Optional preparation';

  @override
  String get rehabWarmupHint =>
      'Explore lip, tongue, and breathing guidance when needed.';

  @override
  String get rehabConsonants => 'Choose a consonant';

  @override
  String get rehabWords => 'Speaking words';

  @override
  String get rehabShort => 'Short sentences';

  @override
  String get rehabLong => 'Long and personal sentences';

  @override
  String get rehabFree => 'Free conversation (optional)';

  @override
  String get rehabTools => 'Additional voice tools';

  @override
  String get rehabOffline => 'Offline content';

  @override
  String get rehabAccessibility => 'Text size';

  @override
  String get rehabManageRecordings => 'Manage earlier recordings';

  @override
  String get rehabManageHint => 'Delete and share earlier sentence recordings';

  @override
  String get rehabLoadingError => 'Could not load records. Please try again.';

  @override
  String get rehabRetry => 'Try again';

  @override
  String get rehabDelete => 'Delete this session';

  @override
  String get rehabDeleteConfirm =>
      'Delete this session and its app-owned recordings?';

  @override
  String get rehabCancel => 'Cancel';

  @override
  String get rehabPracticeAgain => 'Practice again';

  @override
  String get rehabRecordingOnly =>
      'Save your voice without waiting for recognition or scores.';

  @override
  String get rehabPlanSaved => 'Your plan will be used next time too.';
}
