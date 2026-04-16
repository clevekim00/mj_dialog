import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:mj_dialog/features/chat/view/chat_screen.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only attempt Gemma initialization on mobile platforms where the plugin is fully supported.
  // On macOS/Windows/Linux desktop, the asset copy mechanism is not implemented.
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
  } else {
    debugPrint('Running on desktop — skipping Gemma model loading (not supported on desktop).');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MJ Dialog',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.blueAccent,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard', // Fallback cleanly if not available
      ),
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
