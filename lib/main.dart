import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/chat/view/permission_screen.dart';
import 'package:speech_rehab/features/onboarding/view/rehab_onboarding_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_mode_selection_screen.dart';
import 'package:speech_rehab/features/practice/view/word_game_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_history_screen.dart';
import 'package:speech_rehab/features/practice/view/recording_library_screen.dart';
import 'package:speech_rehab/features/practice/view/dashboard_screen.dart';
import 'package:speech_rehab/features/startup/view/startup_splash_screen.dart';
import 'package:speech_rehab/features/tongue_exercise/view/tongue_exercise_screen.dart';
import 'package:speech_rehab/services/permission_service.dart';
import 'package:speech_rehab/services/rehab_profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _AppView());
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech Rehab',
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
        '/word_game': (context) => const WordGameScreen(),
        '/practice_history': (context) => const PracticeHistoryScreen(),
        '/recording_library': (context) => const RecordingLibraryScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/tongue_exercise': (context) => const TongueExerciseScreen(),
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
          _StartupDestination.practiceModes =>
            const PracticeModeSelectionScreen(),
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
