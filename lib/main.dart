import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:speech_rehab/features/chat/view/history_screen.dart';
import 'package:speech_rehab/features/chat/view/permission_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_screen.dart';
import 'package:speech_rehab/features/practice/view/practice_history_screen.dart';
import 'package:speech_rehab/services/permission_service.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final isDesktop = !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
  
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
    return const ProviderScope(
      child: _AppView(),
    );
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
        '/practice_history': (context) => const PracticeHistoryScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class StartupResolver extends StatelessWidget {
  const StartupResolver({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PermissionService.hasAllPermissions(),
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

        final hasPermissions = snapshot.data ?? false;
        if (hasPermissions) {
          return const HistoryScreen();
        } else {
          return const PermissionScreen();
        }
      },
    );
  }
}
