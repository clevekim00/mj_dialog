import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_rehab/services/app_language_service.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final languageTag = ref.watch(appLanguageProvider).languageTag;
  final service = TtsService(languageTag: languageTag);
  ref.onDispose(service.dispose);
  return service;
});

class TtsService {
  TtsService({this.languageTag = 'ko-KR'}) {
    _initFuture = _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();
  static const MethodChannel _iosTtsChannel = MethodChannel('speech_rehab/tts');
  late final Future<void> _initFuture;
  Completer<void>? _speakCompleter;
  final String languageTag;

  bool get _usesNativeIosTts => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _initTts() async {
    if (_usesNativeIosTts) {
      debugPrint('Using the native iOS speech synthesizer.');
      return;
    }

    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage(languageTag);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(_completeSpeak);
    _flutterTts.setCancelHandler(_completeSpeak);
    _flutterTts.setErrorHandler((message) {
      _failSpeak(StateError(message));
    });
  }

  Future<void> speak(String text) async {
    if (_usesNativeIosTts) {
      if (text.isNotEmpty) {
        await _iosTtsChannel.invokeMethod<void>('speak', {
          'text': text,
          'language': languageTag,
        });
      }
      return;
    }

    if (text.isEmpty) {
      return;
    }

    await _initFuture;
    await stop();

    _speakCompleter = Completer<void>();
    final result = await _flutterTts.speak(text);
    if (result == 0) {
      throw StateError('TTS playback could not be started.');
    }

    await _speakCompleter!.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _completeSpeak();
      },
    );
  }

  Future<void> stop() async {
    if (_usesNativeIosTts) {
      await _iosTtsChannel.invokeMethod<void>('stop');
      _completeSpeak();
      return;
    }

    await _initFuture;
    await _flutterTts.stop();
    _completeSpeak();
  }

  Future<void> dispose() async {
    try {
      await stop();
    } catch (error) {
      debugPrint('TTS dispose failed: $error');
    }
  }

  void _completeSpeak() {
    final completer = _speakCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _failSpeak(Object error) {
    final completer = _speakCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
      return;
    }

    debugPrint('TTS error: $error');
  }
}
