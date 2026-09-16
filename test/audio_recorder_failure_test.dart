import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/services/audio/audio_recorder_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('speech_rehab/audio_recorder');
  test(
    'permission denial reaches the caller and never reports recording',
    () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => false,
      );
      final recorder = AudioRecorderService(useIosNative: true);
      await expectLater(recorder.startRecording('denied'), throwsStateError);
      expect(recorder.isRecording(), isFalse);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    },
  );
}
