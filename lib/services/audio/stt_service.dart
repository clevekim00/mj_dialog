import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_rehab/services/app_language_service.dart';

typedef SttResultCallback = Future<void> Function(String text, bool isFinal);

final sttServiceProvider = Provider<SttService>((ref) {
  final languageTag = ref.watch(appLanguageProvider).languageTag;
  final service = SttService(languageTag: languageTag);
  ref.onDispose(service.dispose);
  return service;
});

class SttService {
  SttService({this.languageTag = 'ko-KR', bool? useIosNative})
    : _useIosNative = useIosNative ?? (!kIsWeb && Platform.isIOS);

  final bool _useIosNative;

  final String languageTag;
  static const MethodChannel _iosSpeechChannel = MethodChannel(
    'speech_rehab/speech_recognition',
  );
  static const EventChannel _iosSpeechEvents = EventChannel(
    'speech_rehab/speech_recognition/events',
  );

  final SpeechToText _speechToText = SpeechToText();
  bool _sttEnabled = false;
  bool _iosListening = false;
  Completer<void>? _iosTerminalResult;
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

    if (_useIosNative) {
      if (_sttEnabled) {
        return true;
      }
      try {
        _sttEnabled =
            await _iosSpeechChannel.invokeMethod<bool>('initialize', {
              'language': languageTag,
            }) ??
            false;
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

    if (_useIosNative) {
      if (_iosListening) {
        await stopListening();
      }

      try {
        await _iosSpeechSubscription?.cancel();
        final terminal = Completer<void>();
        _iosTerminalResult = terminal;
        _iosSpeechSubscription = _iosSpeechEvents
            .receiveBroadcastStream()
            .listen(
              (event) async {
                if (event is! Map) {
                  return;
                }
                final text = event['text'] as String? ?? '';
                final isFinal = event['isFinal'] as bool? ?? false;
                debugPrint('[STT] iOS result received (final: $isFinal)');
                // Invoke the callback first so consumers receive the text.
                // Do not wait for downstream AI work: a final callback may
                // itself call stopListening(), which would wait on itself.
                final handling = onResult(text, isFinal);
                if ((isFinal || event['done'] == true) &&
                    !terminal.isCompleted) {
                  terminal.complete();
                }
                await handling;
              },
              onError: (Object error) {
                debugPrint('[STT] iOS event error: $error');
                if (!terminal.isCompleted) terminal.complete();
              },
            );

        _iosListening =
            await _iosSpeechChannel.invokeMethod<bool>('startListening', {
              'language': languageTag,
            }) ??
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
          debugPrint('[STT] result received (final: ${result.finalResult})');
          await onResult(result.recognizedWords, result.finalResult);
        },
        localeId: languageTag.replaceAll('-', '_'),
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
    if (_useIosNative) {
      if (!_iosListening) {
        debugPrint('[STT] iOS stop skipped: not listening');
        return;
      }

      debugPrint('[STT] stopping iOS native recognizer...');
      try {
        await _iosSpeechChannel
            .invokeMethod<void>('stopListening')
            .timeout(const Duration(seconds: 3));
        // Method and event channels can arrive in either order. Retain the
        // subscription until the terminal text callback has been consumed.
        await _iosTerminalResult?.future.timeout(
          const Duration(milliseconds: 500),
          onTimeout: () {},
        );
      } on TimeoutException {
        debugPrint('[STT] native final result deadline reached');
        await _iosSpeechChannel
            .invokeMethod<void>('cancelListening')
            .timeout(const Duration(milliseconds: 500), onTimeout: () {});
      } finally {
        await _iosSpeechSubscription?.cancel();
        _iosSpeechSubscription = null;
        _iosListening = false;
      }
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
    if (_useIosNative) {
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
