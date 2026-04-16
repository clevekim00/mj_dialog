import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef SttResultCallback = Future<void> Function(String text, bool isFinal);

final sttServiceProvider = Provider<SttService>((ref) {
  return SttService();
});

class SttService {
  final SpeechToText _speechToText = SpeechToText();
  bool _sttEnabled = false;

  Future<bool> init() async {
    if (_sttEnabled) {
      return true;
    }

    _sttEnabled = await _speechToText.initialize(
      onError: _handleError,
      onStatus: (status) {
        debugPrint('STT status: $status');
      },
    );

    if (_sttEnabled) {
      final locales = await _speechToText.locales();
      debugPrint(
        'STT locales: ${locales.map((locale) => locale.localeId).join(', ')}',
      );
    } else {
      debugPrint('STT initialization failed.');
    }

    return _sttEnabled;
  }

  Future<bool> startListening({
    required SttResultCallback onResult,
  }) async {
    if (!_sttEnabled) {
      final initialized = await init();
      if (!initialized) {
        debugPrint('STT start aborted because initialization failed.');
        return false;
      }
    }

    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    try {
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) async {
          debugPrint(
            'STT result: "${result.recognizedWords}" '
            '(final: ${result.finalResult})',
          );
          await onResult(result.recognizedWords, result.finalResult);
        },
        localeId: 'ko_KR',
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
      return true;
    } catch (error) {
      debugPrint('STT listen failed: $error');
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!_speechToText.isListening) {
      return;
    }

    debugPrint('STT stopping...');
    await _speechToText.stop();
  }

  Future<void> dispose() async {
    if (_speechToText.isListening) {
      await _speechToText.cancel();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint(
      'STT error: ${error.errorMsg} '
      '(permanent: ${error.permanent})',
    );
  }
}
