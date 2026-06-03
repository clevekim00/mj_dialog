import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:speech_rehab/features/chat/view/permission_screen.dart';
import 'package:speech_rehab/features/onboarding/view/rehab_onboarding_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_mode_selection_screen.dart';
import 'package:speech_rehab/features/practice/view/word_game_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_history_screen.dart';
import 'package:speech_rehab/features/practice/view/dashboard_screen.dart';
import 'package:speech_rehab/services/permission_service.dart';
import 'package:speech_rehab/services/rehab_profile_service.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isDesktop =
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  if (!isDesktop) {
    try {
      await FlutterGemma.initialize();
      if (!FlutterGemma.hasActiveModel()) {
        await FlutterGemma.installModel(
          modelType: ModelType.gemmaIt,
          fileType: ModelFileType.binary,
        ).fromAsset('assets/gemma-2b-it-gpu-int4.bin').install();
      }
    } catch (e) {
      debugPrint('Gemma init failed or no model loaded: $e');
    }
  }

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
        '/dashboard': (context) => const DashboardScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class StartupResolver extends StatelessWidget {
  const StartupResolver({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupDestination>(
      future: _resolveDestination(),
      builder: (context, snapshot) {
        // While checking, show a blank dark screen or a loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white10),
            ),
          );
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
