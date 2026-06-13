import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef SttResultCallback = Future<void> Function(String text, bool isFinal);

final sttServiceProvider = Provider<SttService>((ref) {
  return SttService();
});

class SttService {
  static const MethodChannel _iosSpeechChannel = MethodChannel(
    'speech_rehab/speech_recognition',
  );
  static const EventChannel _iosSpeechEvents = EventChannel(
    'speech_rehab/speech_recognition/events',
  );

  final SpeechToText _speechToText = SpeechToText();
  bool _sttEnabled = false;
  bool _iosListening = false;
  StreamSubscription<dynamic>? _iosSpeechSubscription;

  Future<bool> init() async {
    final isSupportedPlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    debugPrint(
      '[STT] init requested: platform=$defaultTargetPlatform web=$kIsWeb',
    );
    if (kIsWeb || !isSupportedPlatform) {
      debugPrint('[STT] disabled on this platform. Avoiding initialization.');
      return false;
    }

    if (Platform.isIOS) {
      if (_sttEnabled) {
        return true;
      }
      try {
        _sttEnabled =
            await _iosSpeechChannel.invokeMethod<bool>('initialize') ?? false;
      } catch (error) {
        debugPrint('[STT] iOS native initialization error: $error');
        _sttEnabled = false;
      }
      return _sttEnabled;
    }

    if (_sttEnabled) {
      debugPrint('[STT] init skipped: already enabled');
      return true;
    }

    try {
      _sttEnabled = await _speechToText.initialize(
        onError: _handleError,
        onStatus: (status) {
          debugPrint('[STT] status: $status');
        },
      );
    } catch (e) {
      debugPrint('[STT] initialization error: $e');
      _sttEnabled = false;
    }

    if (_sttEnabled) {
      final locales = await _speechToText.locales();
      debugPrint(
        '[STT] locales: ${locales.map((locale) => locale.localeId).join(', ')}',
      );
    } else {
      debugPrint('[STT] initialization failed.');
    }

    return _sttEnabled;
  }

  Future<bool> startListening({required SttResultCallback onResult}) async {
    debugPrint(
      '[STT] start requested: enabled=$_sttEnabled '
      'isListening=${_speechToText.isListening}',
    );
    if (!_sttEnabled) {
      final initialized = await init();
      if (!initialized) {
        debugPrint('[STT] start aborted because initialization failed.');
        return false;
      }
    }

    if (Platform.isIOS) {
      if (_iosListening) {
        await stopListening();
      }

      try {
        await _iosSpeechSubscription?.cancel();
        _iosSpeechSubscription = _iosSpeechEvents
            .receiveBroadcastStream()
            .listen(
              (event) async {
                if (event is! Map) {
                  return;
                }
                final text = event['text'] as String? ?? '';
                final isFinal = event['isFinal'] as bool? ?? false;
                debugPrint('[STT] iOS result: "$text" (final: $isFinal)');
                await onResult(text, isFinal);
              },
              onError: (Object error) {
                debugPrint('[STT] iOS event error: $error');
              },
            );

        _iosListening =
            await _iosSpeechChannel.invokeMethod<bool>('startListening') ??
            false;
        debugPrint('[STT] iOS listen started: $_iosListening');
        return _iosListening;
      } catch (error) {
        debugPrint('[STT] iOS listen failed: $error');
        _iosListening = false;
        return false;
      }
    }

    if (_speechToText.isListening) {
      debugPrint('[STT] previous session detected. Stopping first.');
      await _speechToText.stop();
    }

    try {
      final listenWatch = Stopwatch()..start();
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) async {
          debugPrint(
            '[STT] result: "${result.recognizedWords}" '
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
      listenWatch.stop();
      debugPrint(
        '[STT] listen started: isListening=${_speechToText.isListening} '
        'elapsed=${listenWatch.elapsedMilliseconds}ms',
      );
      return true;
    } catch (error) {
      debugPrint('[STT] listen failed: $error');
      return false;
    }
  }

  Future<void> stopListening() async {
    if (Platform.isIOS) {
      if (!_iosListening) {
        debugPrint('[STT] iOS stop skipped: not listening');
        return;
      }

      debugPrint('[STT] stopping iOS native recognizer...');
      await _iosSpeechChannel.invokeMethod<void>('stopListening');
      await _iosSpeechSubscription?.cancel();
      _iosSpeechSubscription = null;
      _iosListening = false;
      debugPrint('[STT] iOS recognizer stopped');
      return;
    }

    if (!_speechToText.isListening) {
      debugPrint('[STT] stop skipped: not listening');
      return;
    }

    debugPrint('[STT] stopping...');
    await _speechToText.stop();
    debugPrint('[STT] stopped: isListening=${_speechToText.isListening}');
  }

  Future<void> dispose() async {
    if (Platform.isIOS) {
      if (_iosListening) {
        await _iosSpeechChannel.invokeMethod<void>('cancelListening');
      }
      await _iosSpeechSubscription?.cancel();
      _iosSpeechSubscription = null;
      _iosListening = false;
      return;
    }

    if (_speechToText.isListening) {
      await _speechToText.cancel();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint(
      '[STT] error: ${error.errorMsg} '
      '(permanent: ${error.permanent})',
    );
  }
}
