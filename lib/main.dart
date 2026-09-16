import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/chat/view/permission_screen.dart';
import 'package:speech_rehab/features/consonant_training/data/consonant_content_repository.dart';
import 'package:speech_rehab/features/consonant_training/view/consonant_training_screens.dart';
import 'package:speech_rehab/features/exercise/view/exercise_menu_screen.dart';
import 'package:speech_rehab/features/guided_training/data/guided_training_catalog.dart';
import 'package:speech_rehab/features/guided_training/model/guided_training_models.dart';
import 'package:speech_rehab/features/guided_training/view/guided_training_hub_screen.dart';
import 'package:speech_rehab/features/guided_training/view/guided_training_player_screen.dart';
import 'package:speech_rehab/features/guided_training/view/guided_training_settings_screen.dart';
import 'package:speech_rehab/features/guided_training/view/routine_builder_screen.dart';
import 'package:speech_rehab/features/onboarding/view/rehab_onboarding_screen.dart';
import 'package:speech_rehab/features/navigation/view/adaptive_app_shell.dart';
import 'package:speech_rehab/features/practice/view/practice_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_mode_selection_screen.dart';
import 'package:speech_rehab/features/practice/view/word_game_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_history_screen.dart';
import 'package:speech_rehab/features/practice/view/recording_library_screen.dart';
import 'package:speech_rehab/features/practice/view/dashboard_screen.dart';
import 'package:speech_rehab/features/startup/view/startup_splash_screen.dart';
import 'package:speech_rehab/features/settings/view/language_settings_screen.dart';
import 'package:speech_rehab/features/settings/view/resource_center_screen.dart';
import 'package:speech_rehab/features/voice_analysis/view/voice_analysis_screens.dart';
import 'package:speech_rehab/l10n/app_localizations.dart';
import 'package:speech_rehab/services/app_language_service.dart';
import 'package:speech_rehab/services/permission_service.dart';
import 'package:speech_rehab/services/rehab_profile_service.dart';
import 'package:speech_rehab/services/resources/resource_catalog_repository.dart';
import 'package:speech_rehab/services/resources/resource_pack_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  // 리소스 확인은 첫 화면 표시를 차단하지 않는다.
  unawaited(_refreshResources());
  unawaited(_refreshPronunciationContent());
}

Future<void> _refreshResources() async {
  try {
    final repository = ResourceCatalogRepository();
    final result = await repository.checkForUpdates();
    final preferences = await SharedPreferences.getInstance();
    final preference = AppLanguagePreferenceValue.parse(
      preferences.getString(AppLanguageController.preferenceKey),
    );
    final locale = resolveSupportedLocale(
      preference,
      WidgetsBinding.instance.platformDispatcher.locale,
    );
    final languageTag = locale.languageCode == 'ko' ? 'ko-KR' : 'en-US';
    final languages = result.snapshot.catalog.languages.where(
      (item) => item.locale == languageTag && item.enabled,
    );
    if (languages.isEmpty) return;
    final manager = ResourcePackManager();
    for (final packId in languages.first.requiredPacks) {
      final descriptor = result.snapshot.catalog.packById(packId);
      if (descriptor != null) await manager.install(descriptor);
    }
  } catch (error) {
    debugPrint('Resource update skipped: $error');
  }
}

Future<void> _refreshPronunciationContent() async {
  final repository = ConsonantContentRepository();
  if (repository.manifestUrl.trim().isEmpty) return;
  try {
    await repository.updateIfAvailable();
  } catch (error) {
    debugPrint('Pronunciation content update skipped: $error');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _AppView());
  }
}

class _AppView extends ConsumerWidget {
  const _AppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    return MaterialApp(
      title: 'Speech Rehab',
      locale: language.resolvedLocale,
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.blueAccent,
        ),
        useMaterial3: true,
      ),
      home: const StartupResolver(),
      routes: {
        '/practice': (context) => const PracticeScreen(),
        '/practice_modes': (context) => const PracticeModeSelectionScreen(),
        '/app': (context) => const AdaptiveAppShell(),
        '/onboarding': (context) => const RehabOnboardingScreen(),
        '/word_game': (context) => const WordGameScreen(),
        '/practice_history': (context) => const PracticeHistoryScreen(),
        '/recording_library': (context) => const RecordingLibraryScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/exercise_menu': (context) => const ExerciseMenuScreen(),
        '/guided_training': (context) => const GuidedTrainingHubScreen(),
        '/consonant_training': (context) => const ConsonantTrainingHubScreen(),
        '/guided_training/tongue': (context) =>
            const GuidedTrainingCategoryScreen(
              category: GuidedTrainingCategory.tongue,
            ),
        '/guided_training/lip': (context) => const GuidedTrainingCategoryScreen(
          category: GuidedTrainingCategory.lip,
        ),
        '/guided_training/alternating': (context) =>
            const GuidedTrainingCategoryScreen(
              category: GuidedTrainingCategory.alternating,
            ),
        '/guided_training/breathing': (context) =>
            const GuidedTrainingCategoryScreen(
              category: GuidedTrainingCategory.breathing,
            ),
        '/guided_training/player': (context) => GuidedTrainingPlayerScreen(
          exercises: defaultGuidedRoutine,
          routineName: '오늘의 구강·호흡 루틴',
        ),
        '/guided_training/routine_builder': (context) =>
            const RoutineBuilderScreen(),
        '/guided_training/history': (context) =>
            const GuidedTrainingHistoryScreen(),
        // 한 릴리스 동안 기존 딥 링크를 새 통합 화면으로 연결합니다.
        '/face_exercise': (context) => const GuidedTrainingCategoryScreen(
          category: GuidedTrainingCategory.lip,
        ),
        '/breathing_training': (context) => const GuidedTrainingCategoryScreen(
          category: GuidedTrainingCategory.breathing,
        ),
        '/tongue_exercise_menu': (context) => const GuidedTrainingHubScreen(),
        '/oral_alternating_exercise': (context) =>
            const GuidedTrainingCategoryScreen(
              category: GuidedTrainingCategory.alternating,
            ),
        '/tongue_exercise': (context) => GuidedTrainingPlayerScreen(
          exercises: defaultGuidedRoutine,
          routineName: '오늘의 구강·호흡 루틴',
        ),
        '/voice_analysis_menu': (context) => const VoiceAnalysisMenuScreen(),
        '/voice_pitch': (context) => const PitchTrainingScreen(),
        '/target_tone': (context) => const TargetToneScreen(),
        '/voice_volume': (context) => const VolumeTrainingScreen(),
        '/voice_spectrogram': (context) => const SpectrogramTrainingScreen(),
        '/balanced_sentences': (context) => const BalancedSentenceScreen(),
        '/quick_voice_recording': (context) => const QuickRecordingScreen(),
        '/voice_analysis_result': (context) =>
            const VoiceAnalysisResultScreen(),
        '/voice_bank': (context) => const VoiceBankScreen(),
        '/voice_analysis_history': (context) =>
            const VoiceAnalysisHistoryScreen(),
        '/microphone_check': (context) => const MicrophoneCheckScreen(),
        '/training_settings': (context) => const GuidedTrainingSettingsScreen(),
        '/language_settings': (context) => const LanguageSettingsScreen(),
        '/resource_center': (context) => const ResourceCenterScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class StartupResolver extends StatefulWidget {
  const StartupResolver({super.key});

  @override
  State<StartupResolver> createState() => _StartupResolverState();
}

class _StartupResolverState extends State<StartupResolver> {
  late final String _motivationMessage;
  late final Future<_StartupDestination> _startupFuture;

  @override
  void initState() {
    super.initState();
    _motivationMessage =
        startupMotivationMessages[Random().nextInt(
          startupMotivationMessages.length,
        )];
    _startupFuture = _resolveDestinationWithSplash();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupDestination>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return StartupSplashScreen(message: _motivationMessage);
        }

        return switch (snapshot.data ?? _StartupDestination.permission) {
          _StartupDestination.permission => const PermissionScreen(),
          _StartupDestination.onboarding => const RehabOnboardingScreen(),
          _StartupDestination.practiceModes => const AdaptiveAppShell(),
        };
      },
    );
  }

  Future<_StartupDestination> _resolveDestinationWithSplash() async {
    final results = await Future.wait([
      _resolveDestination(),
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
    return results.first as _StartupDestination;
  }

  Future<_StartupDestination> _resolveDestination() async {
    final hasPermissions = await PermissionService.hasAllPermissions();
    if (!hasPermissions) {
      return _StartupDestination.permission;
    }

    final completedOnboarding =
        await RehabProfileService.hasCompletedOnboarding();
    if (!completedOnboarding) {
      return _StartupDestination.onboarding;
    }

    return _StartupDestination.practiceModes;
  }
}

enum _StartupDestination { permission, onboarding, practiceModes }
