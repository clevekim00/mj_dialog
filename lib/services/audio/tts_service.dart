import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

class TtsService {
  TtsService() {
    _initFuture = _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();
  late final Future<void> _initFuture;
  Completer<void>? _speakCompleter;

  Future<void> _initTts() async {
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage('ko-KR');
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
