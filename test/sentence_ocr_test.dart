import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/sentence_practice/sentence_ocr.dart';

class FakeImagePicker extends ImagePicker {
  XFile? result;
  ImageSource? source;
  bool? metadata;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.source = source;
    metadata = requestFullMetadata;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'camera and library decode cache copies, delete them, and omit full metadata',
    (tester) async {
      await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp('ocr_picker');
        try {
          final bytes = await File(
            'assets/branding/app-icon.png',
          ).readAsBytes();
          for (final source in [
            SentenceImageSource.gallery,
            SentenceImageSource.camera,
          ]) {
            final file = File('${root.path}/photo.png');
            await file.writeAsBytes(bytes);
            final picker = FakeImagePicker()..result = XFile(file.path);
            expect(
              await SentenceOcr(picker: picker).pickImage(source: source),
              bytes,
            );
            expect(
              picker.source,
              source == SentenceImageSource.camera
                  ? ImageSource.camera
                  : ImageSource.gallery,
            );
            expect(picker.metadata, isFalse);
            expect(await file.exists(), isFalse);
          }
          final picker = FakeImagePicker();
          expect(
            await SentenceOcr(
              picker: picker,
            ).pickImage(source: SentenceImageSource.camera),
            isNull,
          );
        } finally {
          await root.delete(recursive: true);
        }
      });
    },
  );
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SentenceOcr.channel, null);
  });
  test(
    'native macOS picker cancellation returns without decoding',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SentenceOcr.channel, (call) async {
            expect(call.method, 'pickImage');
            return null;
          });
      expect(await SentenceOcr().pickImage(), isNull);
    },
    skip: !Platform.isMacOS,
  );
  test('native image data enforces size limit', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SentenceOcr.channel,
          (_) async => Uint8List(10 * 1024 * 1024 + 1),
        );
    await expectLater(SentenceOcr().pickImage(), throwsStateError);
  }, skip: !Platform.isMacOS);
  testWidgets('native image bytes reach the preview pipeline', (tester) async {
    await tester.runAsync(() async {
      final bytes = await File('assets/branding/app-icon.png').readAsBytes();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SentenceOcr.channel, (_) async => bytes);
      final stages = <String>[];
      expect(await SentenceOcr().pickImage(onStage: stages.add), bytes);
      expect(stages, ['loading', 'decoding']);
    });
  }, skip: !Platform.isMacOS);
}
