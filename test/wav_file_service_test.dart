import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/services/audio_analysis/wav_file_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('voice_wav_test_');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      final folder = Directory(
        '${directory.path}/${call.method == 'getTemporaryDirectory' ? 'temp' : 'documents'}',
      );
      await folder.create(recursive: true);
      return folder.path;
    });
  });
  tearDown(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });
  test(
    'saved PCM lives in documents while generated tones remain temporary',
    () async {
      const wav = WavFileService();
      final saved = await wav.writePcm16(
        Uint8List(32000),
        fileName: 'reference',
      );
      final tone = await wav.writeTone(frequencyHz: 180);
      expect(saved, contains('/documents/voice_analysis/'));
      expect(tone, contains('/temp/'));
      final bytes = await File(saved).readAsBytes();
      expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
      expect(bytes.length, 32044);
    },
  );
}
