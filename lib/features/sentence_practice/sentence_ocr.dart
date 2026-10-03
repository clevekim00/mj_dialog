import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum SentenceImageSource { file, gallery, camera }

class SentenceOcr {
  SentenceOcr({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  Future<bool> openSettings() => openAppSettings();
  bool get mobileSources => Platform.isIOS || Platform.isAndroid;
  static const channel = MethodChannel('speech_rehab/sentence_ocr');
  bool get supported =>
      Platform.isMacOS || Platform.isIOS || Platform.isAndroid;
  Future<Uint8List?> pickImage({
    SentenceImageSource source = SentenceImageSource.file,
    void Function(String)? onStage,
  }) async {
    Uint8List bytes;
    if (source != SentenceImageSource.file) {
      final file = await _picker.pickImage(
        source: source == SentenceImageSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 4000,
        maxHeight: 4000,
        imageQuality: 95,
        requestFullMetadata: false,
      );
      if (file == null) return null;
      onStage?.call('loading');
      try {
        if (await file.length() > 10 * 1024 * 1024) {
          throw StateError('Image exceeds 10 MB');
        }
        bytes = await file.readAsBytes().timeout(const Duration(seconds: 15));
      } finally {
        // image_picker returns an app-cache copy, never the library original.
        final temporary = File(file.path);
        if (await temporary.exists()) await temporary.delete();
      }
    } else if (Platform.isMacOS) {
      final selected = await channel.invokeMethod<Uint8List>('pickImage');
      if (selected == null) return null;
      bytes = selected;
      onStage?.call('loading');
    } else {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'Images',
            extensions: ['png', 'jpg', 'jpeg'],
            uniformTypeIdentifiers: ['public.png', 'public.jpeg'],
            mimeTypes: ['image/png', 'image/jpeg'],
          ),
        ],
      );
      if (file == null) return null;
      onStage?.call('loading');
      if (await file.length() > 10 * 1024 * 1024) {
        throw StateError('Image exceeds 10 MB');
      }
      bytes = await file.readAsBytes().timeout(const Duration(seconds: 15));
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw StateError('Image exceeds 10 MB');
    }
    onStage?.call('decoding');
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      bytes,
    ).timeout(const Duration(seconds: 15));
    try {
      final descriptor = await ui.ImageDescriptor.encoded(
        buffer,
      ).timeout(const Duration(seconds: 15));
      final pixels = descriptor.width * descriptor.height;
      descriptor.dispose();
      if (pixels > 20000000) {
        throw StateError('Image exceeds 20 megapixels');
      }
    } finally {
      buffer.dispose();
    }
    return bytes;
  }

  Future<String> recognize(Uint8List bytes, String language) async {
    if (!supported) throw UnsupportedError('Use text input on this platform');
    final file = File(
      '${(await getTemporaryDirectory()).path}/sentence_ocr_${const Uuid().v4()}.png',
    );
    try {
      await file.writeAsBytes(bytes, flush: true);
      final text = await channel
          .invokeMethod<String>('recognize', {
            'path': file.path,
            'language': language,
          })
          .timeout(const Duration(seconds: 30));
      if (text == null || text.trim().isEmpty) {
        throw StateError('No text recognized');
      }
      return text;
    } finally {
      if (await file.exists()) await file.delete();
    }
  }
}
