import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

final sttServiceProvider = Provider<SttService>((ref) {
  return SttService();
});

class SttService {
  final SpeechToText _speechToText = SpeechToText();
  bool _sttEnabled = false;

  Future<bool> init() async {
    if (_sttEnabled) return true;

    _sttEnabled = await _speechToText.initialize(
      onError: (SpeechRecognitionError error) {
        print('STT Error: ${error.errorMsg} (permanent: ${error.permanent})');
      },
      onStatus: (String status) {
        print('STT Status: $status');
      },
    );
    
    if (_sttEnabled) {
      final locales = await _speechToText.locales();
      print('STT Available locales: ${locales.map((l) => l.localeId).toList()}');
    } else {
      print('STT initialization failed. Speech recognition may not be available.');
    }
    
    return _sttEnabled;
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
  }) async {
    if (!_sttEnabled) {
      bool initialized = await init();
      if (!initialized) {
        print('STT: Cannot start listening - not initialized');
        return;
      }
    }

    print('STT: Starting to listen with locale ko_KR...');
    
    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        print('STT Result: "${result.recognizedWords}" (final: ${result.finalResult})');
        onResult(result.recognizedWords, result.finalResult);
      },
      localeId: 'ko_KR',
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    print('STT: Stopping...');
    await _speechToText.stop();
  }
  
  bool get isListening => _speechToText.isListening;
}
