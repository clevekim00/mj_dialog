import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class WavFileService {
  const WavFileService();

  Future<String> writePcm16(
    Uint8List pcm, {
    required String fileName,
    int sampleRate = 16000,
  }) async {
    final directory = await getTemporaryDirectory();
    final filePath = path.join(directory.path, '$fileName.wav');
    final header = _wavHeader(pcm.length, sampleRate: sampleRate);
    await File(filePath).writeAsBytes([...header, ...pcm], flush: true);
    return filePath;
  }

  Future<String> writeTone({
    required double frequencyHz,
    int durationMs = 1200,
    int sampleRate = 16000,
  }) {
    final sampleCount = sampleRate * durationMs ~/ 1000;
    final data = ByteData(sampleCount * 2);
    for (var index = 0; index < sampleCount; index++) {
      final envelope = math.min(
        1.0,
        math.min(index / 240, (sampleCount - index) / 240),
      );
      final value =
          math.sin(2 * math.pi * frequencyHz * index / sampleRate) *
          0.2 *
          envelope;
      data.setInt16(index * 2, (value * 32767).round(), Endian.little);
    }
    return writePcm16(
      data.buffer.asUint8List(),
      fileName: 'target_tone_${frequencyHz.round()}',
      sampleRate: sampleRate,
    );
  }

  Uint8List _wavHeader(int dataLength, {required int sampleRate}) {
    final header = ByteData(44);
    void text(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        header.setUint8(offset + index, value.codeUnitAt(index));
      }
    }

    text(0, 'RIFF');
    header.setUint32(4, dataLength + 36, Endian.little);
    text(8, 'WAVE');
    text(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    text(36, 'data');
    header.setUint32(40, dataLength, Endian.little);
    return header.buffer.asUint8List();
  }
}
