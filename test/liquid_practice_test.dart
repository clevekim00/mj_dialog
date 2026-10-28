import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/consonant_training/audio/liquid_recording_audio.dart';
import 'package:speech_rehab/features/consonant_training/data/liquid_practice_content.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';
import 'package:speech_rehab/features/consonant_training/services/consonant_training_history_service.dart';
import 'package:speech_rehab/features/consonant_training/services/pronunciation_analysis_client.dart';
import 'package:speech_rehab/features/consonant_training/view/liquid_practice_screen.dart';
import 'package:speech_rehab/features/rehab/audio/practice_capture.dart';
import 'package:speech_rehab/services/audio/audio_player_service.dart';

Uint8List wav() {
  final bytes = Uint8List(32044), header = ByteData(44);
  void text(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      header.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  header.setUint32(4, 32036, Endian.little);
  text(8, 'WAVE');
  text(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, 1, Endian.little);
  header.setUint32(24, 16000, Endian.little);
  header.setUint32(28, 32000, Endian.little);
  header.setUint16(32, 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  text(36, 'data');
  header.setUint32(40, 32000, Endian.little);
  bytes.setAll(0, header.buffer.asUint8List());
  final data = ByteData.sublistView(bytes);
  for (var i = 0; i < 16000; i++) {
    data.setInt16(44 + i * 2, i, Endian.little);
  }
  return bytes;
}

class Capture extends PracticeCapture {
  Capture(this.paths);
  final List<String> paths;
  int count = 0;
  @override
  int get durationMs => 1000;
  @override
  Future<void> startRecording(String name) async {
    envelope.clear();
    envelope.addAll([.2, .5, .3]);
  }

  @override
  Future<String?> stopRecording() async => paths[count++ % paths.length];
}

class Analysis extends PronunciationAnalysisClient {
  bool? all;
  int calls = 0;
  Completer<PronunciationAnalysisResult>? pending;
  @override
  Future<PronunciationAnalysisResult> analyze({
    required String audioFilePath,
    required PronunciationContentItem item,
    required ConsonantTrainingTarget target,
    required String contentVersion,
    required String language,
    double? baselineScore,
    bool allOccurrences = false,
    CancelToken? cancelToken,
  }) async {
    all = allOccurrences;
    calls++;
    return pending?.future ??
        PronunciationAnalysisResult.unavailable('정렬만 지원 · 점수 없음');
  }
}

class FailingHistory extends ConsonantTrainingHistoryService {
  bool fail = true;
  @override
  Future<void> add(ConsonantTrainingAttempt attempt) async {
    if (fail) {
      fail = false;
      throw StateError('storage');
    }
    await super.add(attempt);
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late List<String> paths;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('liquid_test');
    paths = [for (var i = 0; i < 3; i++) '${root.path}/$i.wav'];
    for (final path in paths) {
      await File(path).writeAsBytes(wav());
    }
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('speech_rehab/audio_player'),
      (_) async => null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('speech_rehab/audio_player/events'),
      (_) async => null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => root.path,
    );
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('reference and waveform players share one native completion stream', () {
    expect(
      identical(
        AudioPlayerService().playbackEvents,
        AudioPlayerService().playbackEvents,
      ),
      isTrue,
    );
  });

  test(
    'every Korean example resolves through an ASCII bundle key and contains audio',
    () async {
      final examples = {
        ...LiquidPracticeContent.vowels,
        ...LiquidPracticeContent.examples.values.expand((items) => items),
      };
      expect(examples, hasLength(30));
      for (final text in examples) {
        final key = LiquidPracticeContent.referenceAsset(text);
        expect(key.codeUnits.every((c) => c < 128), isTrue);
        final data = await rootBundle.load(key);
        final audio = LiquidRecordingAudio.decode(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        expect(audio.durationMs, greaterThan(100), reason: text);
        expect(audio.pcm.any((value) => value != 0), isTrue, reason: text);
      }
    },
  );

  test(
    'repeated reference contains exactly the selected count with silent gaps',
    () {
      final source = LiquidRecordingAudio.decode(wav());
      for (final count in [1, 3, 5, 7]) {
        final repeated = source.repeated(count);
        expect(repeated.durationMs, 1000 * count + 180 * (count - 1));
        for (var i = 0; i < count; i++) {
          final start = i * (source.pcm.length + 5760);
          expect(
            repeated.pcm.sublist(start, start + source.pcm.length),
            source.pcm,
          );
          if (i < count - 1) {
            expect(
              repeated.pcm
                  .sublist(
                    start + source.pcm.length,
                    start + source.pcm.length + 5760,
                  )
                  .every((b) => b == 0),
              isTrue,
            );
          }
        }
      }
      expect(() => source.repeated(0), throwsArgumentError);
    },
  );

  test(
    'PCM slicing preserves sample rate, exact boundaries and rejects invalid input',
    () {
      final audio = LiquidRecordingAudio.decode(wav());
      expect(audio.durationMs, 1000);
      final clip = audio.slice(250, 500);
      expect(clip.length, 8000);
      expect(ByteData.sublistView(clip).getInt16(0, Endian.little), 4000);
      expect(() => audio.slice(900, 1001), throwsArgumentError);
      expect(() => audio.slice(100, 100), throwsArgumentError);
      expect(
        () => LiquidRecordingAudio.decode(wav().sublist(0, 50)),
        throwsFormatException,
      );
      final stereo = wav();
      ByteData.sublistView(stereo).setUint16(22, 2, Endian.little);
      expect(() => LiquidRecordingAudio.decode(stereo), throwsFormatException);
    },
  );
  test(
    'repetition conditions have separate stable content IDs and coda uses lf',
    () {
      final three = LiquidPracticeContent.item(
        LiquidExercise.repetition,
        '라',
        repetitions: 3,
      );
      final five = LiquidPracticeContent.item(
        LiquidExercise.repetition,
        '라',
        repetitions: 5,
      );
      expect(three.text, '라 라 라');
      expect(three.id, isNot(five.id));
      expect(LiquidPracticeContent.target(LiquidExercise.coda).phone, 'lf');
      expect(
        LiquidPracticeContent.target(LiquidExercise.medial).position,
        PhonemePosition.onset,
      );
    },
  );

  Future<void> show(
    WidgetTester tester,
    ConsonantTrainingHistoryService history, {
    Analysis? client,
  }) async {
    tester.view.physicalSize = const Size(1024, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: LiquidPracticeScreen(
          history: history,
          capture: Capture(paths),
          analysisClient: client,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> record(WidgetTester tester) async {
    await tap(tester, find.byKey(const ValueKey('liquid-record')));
    await tap(tester, find.byKey(const ValueKey('liquid-record')));
  }

  test(
    'liquid metadata survives analysis updates and delete removes owned audio',
    () async {
      final history = ConsonantTrainingHistoryService();
      final item = LiquidPracticeContent.item(LiquidExercise.repetition, '라');
      final original = ConsonantTrainingAttempt(
        id: 'delete-me',
        targetId: item.targetId,
        contentId: item.id,
        text: item.text,
        level: item.level,
        audioFilePath: paths.first,
        createdAt: DateTime(2026),
        durationMs: 1000,
        waveform: const [.2, .5],
        plannedRepetitions: 5,
        contentVersion: LiquidPracticeContent.version,
        exerciseKind: LiquidExercise.repetition.name,
        analysis: PronunciationAnalysisResult.unavailable('local'),
      ).withSelfReport('더 어려워요');
      await history.add(
        original.withAnalysis(
          PronunciationAnalysisResult.unavailable('aligned only'),
        ),
      );
      final loaded = (await history.load()).single;
      expect(loaded.waveform, [.2, .5]);
      expect(loaded.plannedRepetitions, 5);
      expect(loaded.selfReport, '더 어려워요');
      expect(loaded.exerciseKind, 'repetition');
      await history.delete(original.id);
      expect(await history.load(), isEmpty);
      expect(await File(paths.first).exists(), isFalse);
    },
  );

  testWidgets(
    'all three difficulty families and repeat conditions are selectable',
    (tester) async {
      await show(tester, ConsonantTrainingHistoryService());
      await tap(tester, find.text('7번 반복'));
      expect(find.text('라 라 라 라 라 라 라', findRichText: true), findsOneWidget);
      await tap(tester, find.text('단어 속 ㄹ'));
      expect(find.text('다리'), findsOneWidget);
      await tap(tester, find.text('받침 ㄹ'));
      expect(find.text('물'), findsOneWidget);
      await tap(tester, find.text('이어지는 ㄹ'));
      expect(find.text('멀리'), findsOneWidget);
      await tap(tester, find.text('내 연습'));
      await tester.enterText(find.byType(TextField), '소리를 들려 주세요');
      await tester.pump();
      expect(find.text('소리를 들려 주세요', findRichText: true), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'saves waveform and self report, preserves previous attempts and never fabricates scores',
    (tester) async {
      final history = ConsonantTrainingHistoryService();
      await show(tester, history);
      await record(tester);
      final first = (await history.load()).single;
      expect(first.durationMs, 1000);
      expect(first.waveform, [.2, .5, .3]);
      expect(first.plannedRepetitions, 5);
      expect(first.analysis.hasReliableScore, isFalse);
      await tap(tester, find.text('더 어려워요'));
      expect((await history.load()).single.selfReport, '더 어려워요');
      await record(tester);
      expect(await history.load(), hasLength(2));
      expect(find.textContaining('발음 점수 · 평가 준비 전'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('이전 → 이번 순서대로 듣기'), 350);
      expect(find.text('이전 같은 조건 녹음 · 1.0초'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'history save failure retains recording and locks changing conditions until retry',
    (tester) async {
      final history = FailingHistory();
      await show(tester, history);
      await record(tester);
      expect(find.text('녹음 저장 재시도'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '받침 ㄹ'))
            .onSelected,
        isNull,
      );
      await tap(tester, find.text('녹음 저장 재시도'));
      expect(await history.load(), hasLength(1));
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '받침 ㄹ'))
            .onSelected,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'example button loads bundled speech and invokes native playback',
    (tester) async {
      String? played;
      LiquidRecordingAudio? playedAudio;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('speech_rehab/audio_player'),
        (call) async {
          if (call.method == 'playFile') {
            played = (call.arguments as Map)['path'] as String;
            playedAudio = await LiquidRecordingAudio.load(played!);
            await binding.defaultBinaryMessenger.handlePlatformMessage(
              'speech_rehab/audio_player/events',
              const StandardMethodCodec().encodeSuccessEnvelope('complete'),
              (_) {},
            );
          }
          return null;
        },
      );
      await show(tester, ConsonantTrainingHistoryService());
      await record(tester);
      await tester.ensureVisible(find.text('예시 듣기 · 합성 음성'));
      await tester.runAsync(() async {
        await tester.tap(find.text('예시 듣기 · 합성 음성'));
        final until = DateTime.now().add(const Duration(seconds: 3));
        while (playedAudio == null && DateTime.now().isBefore(until)) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        expect(played, isNotNull);
        final data = await rootBundle.load(
          LiquidPracticeContent.referenceAsset('라'),
        );
        final base = LiquidRecordingAudio.decode(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        expect(playedAudio!.pcm, base.repeated(5).pcm);
        expect(playedAudio!.durationMs, greaterThan(2500));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('재생하지 못했어요'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('liquid-record')))
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('selected range plays an exact PCM clip and stops cleanly', (
    tester,
  ) async {
    String? played;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('speech_rehab/audio_player'),
      (call) async {
        if (call.method == 'playFile') {
          played = (call.arguments as Map)['path'] as String;
        }
        return null;
      },
    );
    await show(tester, ConsonantTrainingHistoryService());
    await record(tester);
    await tester.scrollUntilVisible(
      find.byType(RangeSlider),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    tester.widget<RangeSlider>(find.byType(RangeSlider)).onChanged!(
      const RangeValues(.25, .5),
    );
    await tester.pump();
    final play = find.textContaining('선택 구간 듣기');
    await tester.ensureVisible(play);
    await tester.runAsync(() async {
      await tester.tap(play);
      final until = DateTime.now().add(const Duration(seconds: 3));
      while (played == null && DateTime.now().isBefore(until)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(played, isNotNull);
      final clip = await LiquidRecordingAudio.load(played!);
      expect(clip.durationMs, 250);
      expect(ByteData.sublistView(clip.pcm).getInt16(0, Endian.little), 4000);
      await binding.defaultBinaryMessenger.handlePlatformMessage(
        'speech_rehab/audio_player/events',
        const StandardMethodCodec().encodeSuccessEnvelope('complete'),
        (_) {},
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('듣기 멈추기'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'large text on a narrow screen keeps record and stop accessible',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: LiquidPracticeScreen(
              history: ConsonantTrainingHistoryService(),
              capture: Capture(paths),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('liquid-record')).hitTestable(),
        findsOneWidget,
      );
      await record(tester);
      expect(
        find.byKey(const ValueKey('liquid-record')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'cancelled analysis unlocks immediately and ignores a late response',
    (tester) async {
      final history = ConsonantTrainingHistoryService(),
          client = Analysis()
            ..pending = Completer<PronunciationAnalysisResult>();
      await show(tester, history, client: client);
      await record(tester);
      await tap(tester, find.text('동의 후 음성 분석 · 서버 설정'));
      await tester.scrollUntilVisible(
        find.byType(CheckboxListTile),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tap(tester, find.byType(CheckboxListTile));
      final request = find.text('음소 구간과 발음 피드백 요청');
      await tester.ensureVisible(request);
      await tester.tap(request);
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('분석 취소'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('분석 취소'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('liquid-record')))
            .onPressed,
        isNotNull,
      );
      client.pending!.complete(
        PronunciationAnalysisResult.unavailable('late result'),
      );
      await tester.pumpAndSettle();
      expect(
        (await history.load()).single.analysis.message,
        isNot('late result'),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('analysis requires consent and requests every occurrence', (
    tester,
  ) async {
    final history = ConsonantTrainingHistoryService(), client = Analysis();
    await show(tester, history, client: client);
    await record(tester);
    expect(client.calls, 0);
    await tap(tester, find.text('동의 후 음성 분석 · 서버 설정'));
    await tester.scrollUntilVisible(
      find.byType(CheckboxListTile),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(tester, find.byType(CheckboxListTile));
    await tap(tester, find.text('음소 구간과 발음 피드백 요청'));
    expect(client.all, isTrue);
    expect(client.calls, 1);
    expect((await history.load()).single.waveform, [.2, .5, .3]);
    expect((await history.load()).single.analysis.hasReliableScore, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
