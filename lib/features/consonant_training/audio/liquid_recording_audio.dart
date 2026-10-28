import 'dart:io';
import 'dart:typed_data';
import '../../../services/audio_analysis/wav_file_service.dart';

/// Only accepts PCM16 mono WAV. Unknown encodings never become guessed audio.
class LiquidRecordingAudio {
  LiquidRecordingAudio(this.pcm, this.sampleRate);
  final Uint8List pcm;
  final int sampleRate;
  int get durationMs => pcm.length * 1000 ~/ (sampleRate * 2);

  static LiquidRecordingAudio decode(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    String tag(int start) =>
        String.fromCharCodes(bytes.sublist(start, start + 4));
    if (bytes.length < 44 || tag(0) != 'RIFF' || tag(8) != 'WAVE') {
      throw const FormatException('Not WAV');
    }
    int? rate;
    Uint8List? pcm;
    for (var offset = 12; offset + 8 <= bytes.length;) {
      final length = data.getUint32(offset + 4, Endian.little);
      final start = offset + 8, end = start + length;
      if (end > bytes.length) throw const FormatException('Truncated WAV');
      if (tag(offset) == 'fmt ') {
        if (length < 16 ||
            data.getUint16(start, Endian.little) != 1 ||
            data.getUint16(start + 2, Endian.little) != 1 ||
            data.getUint16(start + 14, Endian.little) != 16) {
          throw const FormatException('Expected PCM16 mono');
        }
        rate = data.getUint32(start + 4, Endian.little);
      }
      if (tag(offset) == 'data') pcm = Uint8List.sublistView(bytes, start, end);
      offset = end + (length.isOdd ? 1 : 0);
    }
    if (rate == null ||
        rate <= 0 ||
        pcm == null ||
        pcm.isEmpty ||
        pcm.length.isOdd) {
      throw const FormatException('Invalid WAV');
    }
    return LiquidRecordingAudio(pcm, rate);
  }

  static Future<LiquidRecordingAudio> load(String path) async =>
      decode(await File(path).readAsBytes());

  /// Repeat the complete spoken syllable with a short gap, without clipping it.
  LiquidRecordingAudio repeated(int count, {int gapMs = 180}) {
    if (count < 1 || count > 10 || gapMs < 0 || gapMs > 2000) {
      throw ArgumentError('Invalid repetition settings');
    }
    final gapBytes = sampleRate * gapMs ~/ 1000 * 2;
    final result = Uint8List(pcm.length * count + gapBytes * (count - 1));
    for (var i = 0; i < count; i++) {
      result.setRange(
        i * (pcm.length + gapBytes),
        i * (pcm.length + gapBytes) + pcm.length,
        pcm,
      );
    }
    return LiquidRecordingAudio(result, sampleRate);
  }

  Uint8List slice(int startMs, int endMs) {
    if (startMs < 0 || endMs <= startMs || endMs > durationMs) {
      throw ArgumentError('Invalid audio range');
    }
    final start = startMs * sampleRate ~/ 1000 * 2;
    final end = endMs * sampleRate ~/ 1000 * 2;
    if (end <= start) throw ArgumentError('Empty audio range');
    return Uint8List.sublistView(pcm, start, end);
  }

  Future<String> writeClip(int startMs, int endMs, String name) =>
      const WavFileService().writePcm16(
        slice(startMs, endMs),
        fileName: name,
        sampleRate: sampleRate,
        persistent: false,
      );
}
