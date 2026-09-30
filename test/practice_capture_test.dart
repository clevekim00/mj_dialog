import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:speech_rehab/features/rehab/audio/practice_capture.dart';
import 'package:speech_rehab/services/audio_analysis/audio_input_stream_service.dart';
import 'package:speech_rehab/services/audio_analysis/wav_file_service.dart';

class _Unused implements AudioRecorder {
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('No platform recorder');
}

class _Input extends AudioInputStreamService {
  _Input() : super(recorder: _Unused());
  late StreamController<Uint8List> stream;
  int starts = 0, stops = 0;
  bool permission = true;
  @override
  Future<bool> hasPermission() async => permission;
  @override
  Future<Stream<Uint8List>> start({int sampleRate = 16000}) async {
    starts++;
    stream = StreamController(sync: true);
    return stream.stream;
  }

  @override
  Future<void> stop() async {
    stops++;
    await stream.close();
  }

  @override
  Future<void> dispose() async {}
}

class _Files extends WavFileService {
  bool fail = false;
  Uint8List? saved;
  @override
  Future<String> writePcm16(
    Uint8List pcm, {
    required String fileName,
    int sampleRate = 16000,
    bool persistent = true,
  }) async {
    if (fail) throw StateError('disk');
    saved = Uint8List.fromList(pcm);
    return '/recordings/$fileName.wav';
  }
}

Uint8List _tone() {
  final data = ByteData(2048);
  for (var i = 0; i < 1024; i++) {
    data.setInt16(
      i * 2,
      (math.sin(2 * math.pi * 200 * i / 16000) * 10000).round(),
      Endian.little,
    );
  }
  return data.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'one input produces waveform and saves full audio beyond old 10-second ring',
    () async {
      final input = _Input(), files = _Files();
      final recorder = PracticeCapture(input: input, files: files);
      await recorder.startRecording('rehab_test');
      for (var i = 0; i < 200; i++) {
        input.stream.add(_tone());
      }
      expect(recorder.durationMs, 12800);
      expect(recorder.envelope, hasLength(200));
      expect(recorder.frame.value!.hasReliablePitch, isTrue);
      final path = await recorder.stopRecording();
      expect(path, endsWith('.wav'));
      expect(files.saved!.length, 409600);
      expect(input.starts, 1);
      expect(input.stops, 1);
      await recorder.dispose();
    },
  );
  test('file save retry retains bytes without reopening microphone', () async {
    final input = _Input(), files = _Files();
    final capture = PracticeCapture(input: input, files: files);
    await capture.startRecording('rehab_retry');
    input.stream.add(_tone());
    files.fail = true;
    await expectLater(capture.stopRecording(), throwsStateError);
    expect(capture.hasPendingAudio, isTrue);
    await expectLater(capture.startRecording('new'), throwsStateError);
    files.fail = false;
    await capture.stopRecording();
    expect(files.saved!.length, 2048);
    expect(input.starts, 1);
    expect(input.stops, 1);
    await capture.dispose();
  });
  test(
    'denied permission never starts microphone or fabricates frames',
    () async {
      final input = _Input()..permission = false;
      final capture = PracticeCapture(input: input);
      await expectLater(
        capture.startRecording('rehab_denied'),
        throwsStateError,
      );
      expect(input.starts, 0);
      expect(capture.frame.value, isNull);
      await capture.dispose();
    },
  );
  test(
    'partial PCM frames are joined correctly and reset on new take',
    () async {
      final input = _Input(), files = _Files();
      final capture = PracticeCapture(input: input, files: files);
      await capture.startRecording('one');
      final tone = _tone();
      input.stream.add(tone.sublist(0, 501));
      input.stream.add(tone.sublist(501));
      expect(capture.envelope, hasLength(1));
      await capture.stopRecording();
      expect(files.saved, tone);
      await capture.startRecording('two');
      input.stream.add(Uint8List(1024));
      expect(capture.envelope, isEmpty);
      await capture.stopRecording();
      await capture.dispose();
    },
  );
}
