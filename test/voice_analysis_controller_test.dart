import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:speech_rehab/features/voice_analysis/provider/voice_analysis_controller.dart';
import 'package:speech_rehab/services/audio_analysis/audio_input_stream_service.dart';

class _UnusedRecorder implements AudioRecorder {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('The fake input must not call a platform recorder.');
}

class _Input extends AudioInputStreamService {
  _Input() : super(recorder: _UnusedRecorder());
  late StreamController<Uint8List> stream;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<Stream<Uint8List>> start({int sampleRate = 16000}) async {
    stream = StreamController<Uint8List>(sync: true);
    return stream.stream;
  }

  @override
  Future<void> stop() async {
    await stream.close();
  }

  @override
  Future<void> dispose() async {
    await stream.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Uint8List tone() {
    final data = ByteData(2048);
    for (var i = 0; i < 1024; i++) {
      data.setInt16(
        i * 2,
        (math.sin(2 * math.pi * 200 * i / 16000) * 12000).round(),
        Endian.little,
      );
    }
    return data.buffer.asUint8List();
  }

  test('frames use PCM timing and noise follows recent frames', () async {
    final input = _Input();
    final controller = VoiceAnalysisController(input: input);
    await controller.start();
    for (var i = 0; i < 20; i++) {
      input.stream.add(Uint8List(2048));
    }
    for (var i = 0; i < 21; i++) {
      input.stream.add(tone());
    }
    expect(controller.frames[0].timestamp.inMilliseconds, 64);
    expect(controller.frames[1].timestamp.inMilliseconds, 128);
    expect(controller.recordingDuration.inMilliseconds, 41 * 64);
    expect(controller.latestFrame!.noiseFloorDbfs, greaterThan(-30));
    expect(controller.metrics.phonationDurationMs, 21 * 64);
    await controller.stop();
    controller.dispose();
  });
  test(
    'restart clears an incomplete frame from the previous recording',
    () async {
      final input = _Input();
      final controller = VoiceAnalysisController(input: input);
      await controller.start();
      input.stream.add(Uint8List(1024));
      await controller.stop();
      await controller.start();
      input.stream.add(Uint8List(1024));
      expect(controller.frames, isEmpty);
      await controller.stop();
      controller.dispose();
    },
  );
}
