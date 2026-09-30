import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/rehab/audio/practice_waveform.dart';
import 'package:speech_rehab/features/rehab/audio/recorder_waveform.dart';
import 'package:speech_rehab/services/audio/audio_recorder_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('speech_rehab/audio_recorder');

  test(
    'meter uses the active recorder, resets, and ignores late stop replies',
    () async {
      final temp = await Directory.systemTemp.createTemp('waveform_test');
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        paths,
        (_) async => temp.path,
      );
      final calls = <String>[];
      final first = Completer<void>();
      Completer<double>? delayed;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        if (call.method == 'hasPermission') return true;
        if (call.method == 'amplitude') {
          if (!first.isCompleted) first.complete();
          return delayed == null ? -6.0 : await delayed.future;
        }
        if (call.method == 'stop') return '${temp.path}/recording.m4a';
        return null;
      });
      final recorder = AudioRecorderService(useIosNative: true);
      try {
        await recorder.startRecording('one');
        await first.future;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(recorder.waveform.single, closeTo(0.501, 0.002));
        await recorder.stopRecording();
        final count = recorder.waveform.length;
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(recorder.waveform.length, count);
        delayed = Completer<double>();
        await recorder.startRecording('two');
        expect(recorder.waveform, isEmpty);
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await recorder.stopRecording();
        delayed.complete(-3);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(recorder.waveform, isEmpty);
        expect(calls.where((v) => v == 'start'), hasLength(2));
      } finally {
        await recorder.dispose();
        binding.defaultBinaryMessenger.setMockMethodCallHandler(paths, null);
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
        await temp.delete(recursive: true);
      }
    },
  );

  testWidgets(
    'waveform is visible by default at four times height and can hide',
    (tester) async {
      final recorder = AudioRecorderService(useIosNative: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(children: [RecorderWaveform(recorder: recorder)]),
          ),
        ),
      );
      expect(find.byType(PracticeWaveform), findsOneWidget);
      final canvas = find.descendant(
        of: find.byType(PracticeWaveform),
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter != null,
        ),
      );
      expect(tester.getSize(canvas).height, 352);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      expect(find.byType(PracticeWaveform), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
