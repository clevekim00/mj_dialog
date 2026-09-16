import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';
import 'package:speech_rehab/features/consonant_training/services/consonant_training_history_service.dart';
import 'package:speech_rehab/features/consonant_training/services/consonant_training_session_service.dart';
import 'package:speech_rehab/features/consonant_training/services/pronunciation_analysis_client.dart';
import 'package:speech_rehab/features/consonant_training/view/consonant_training_screens.dart';
import 'package:speech_rehab/services/audio/audio_player_service.dart';
import 'package:speech_rehab/services/audio/audio_recorder_service.dart';
import 'package:speech_rehab/services/audio/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          (_) async => 1,
        );
  });

  test('목표 음절 강조는 초성과 받침을 구분하고 받침 대표음을 표시한다', () {
    expect(TargetPracticeText.matches('가', _target), isTrue);
    expect(TargetPracticeText.matches('각', _target), isTrue);
    expect(TargetPracticeText.matches('악', _target), isFalse);
    const coda = ConsonantTrainingTarget(
      id: 'coda_d',
      grapheme: 'ㄷ',
      phone: 'tf',
      position: PhonemePosition.coda,
      description: '',
    );
    expect(TargetPracticeText.matches('옷', coda), isTrue);
    expect(TargetPracticeText.matches('다', coda), isFalse);
    expect(TargetPracticeText.matches(' ', coda), isFalse);
  });

  testWidgets('녹음은 분석 없이 저장되고 목표 횟수에서 완료되며 비교 녹음을 보존한다', (tester) async {
    final recorder = _Recorder();
    final client = _Client();
    final history = ConsonantTrainingHistoryService();
    await _show(tester, recorder: recorder, client: client, history: history);
    for (var i = 0; i < 3; i++) {
      await _tap(tester, find.byKey(const Key('consonant-record')));
      await _tap(tester, find.byKey(const Key('consonant-record')));
    }
    expect(client.calls, 0);
    final attempts = await history.load();
    expect(attempts, hasLength(3));
    expect(
      attempts.every(
        (attempt) => attempt.analysis.overallPracticeScore == null,
      ),
      isTrue,
    );
    expect(attempts.every((attempt) => attempt.text == '가'), isTrue);
    expect(find.text('이번 연습을 마쳤어요 · 3회 녹음'), findsOneWidget);
    expect(find.text('이전 같은 항목 녹음 듣기'), findsOneWidget);
    final progress = await ConsonantTrainingSessionService().load();
    expect(progress!.completedAttempts, 3);
    expect(progress.completed, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('시작 대기와 녹음 중 항목 이동을 잠그고 처음 선택한 항목으로 저장한다', (tester) async {
    final recorder = _Recorder()..starting = Completer<void>();
    final history = ConsonantTrainingHistoryService();
    await _show(
      tester,
      recorder: recorder,
      client: _Client(),
      history: history,
    );
    await tester.ensureVisible(find.byKey(const Key('consonant-record')));
    await tester.tap(find.byKey(const Key('consonant-record')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '다음 항목'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '단어'))
          .onSelected,
      isNull,
    );
    recorder.starting!.complete();
    await tester.pumpAndSettle();
    expect(find.text('녹음 끝내고 저장'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '다음 항목'))
          .onPressed,
      isNull,
    );
    await _tap(tester, find.byKey(const Key('consonant-record')));
    expect((await history.load()).single.contentId, 'syllable_ga');
    expect(
      (await history.load()).single.level,
      ConsonantTrainingLevel.syllable,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('동의 후에만 전송하고 취소 이후 늦은 응답은 기록을 바꾸지 않는다', (tester) async {
    final client = _Client()
      ..response = Completer<PronunciationAnalysisResult>();
    final history = ConsonantTrainingHistoryService();
    await _show(
      tester,
      recorder: _Recorder(),
      client: client,
      history: history,
    );
    await _tap(tester, find.byKey(const Key('consonant-record')));
    await _tap(tester, find.byKey(const Key('consonant-record')));
    await _tap(tester, find.text('선택: 서버에서 음소 구간 분석'));
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, '동의한 녹음을 서버로 전송'),
          )
          .onPressed,
      isNull,
    );
    await _tap(tester, find.byType(CheckboxListTile));
    await tester.ensureVisible(find.text('동의한 녹음을 서버로 전송'));
    await tester.tap(find.text('동의한 녹음을 서버로 전송'));
    await tester.pump();
    expect(client.calls, 1);
    expect(client.itemId, 'syllable_ga');
    await tester.ensureVisible(find.text('분석 취소'));
    await tester.tap(find.text('분석 취소'));
    await tester.pumpAndSettle();
    expect(client.token!.isCancelled, isTrue);
    client.response!.complete(
      PronunciationAnalysisResult.unavailable('late response'),
    );
    await tester.pumpAndSettle();
    expect(
      (await history.load()).single.analysis.message,
      contains('서버 분석을 요청하지 않았어요'),
    );
    expect(find.text('late response'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('긴 문장과 글자 200%에서도 녹음 종료 버튼은 화면에 고정된다', (tester) async {
    await _show(
      tester,
      recorder: _Recorder(),
      client: _Client(),
      history: ConsonantTrainingHistoryService(),
    );
    await _tap(tester, find.widgetWithText(ChoiceChip, '짧은 문장'));
    tester.view.physicalSize = const Size(320, 800);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    final record = find.byKey(const Key('consonant-record'));
    await _tap(tester, record);
    final before = tester.getRect(record);
    expect(before.bottom, lessThanOrEqualTo(800));
    expect(before.top, greaterThan(0));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.getRect(record), before);
    expect(find.text('녹음 끝내고 저장'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _tap(tester, record);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('녹음 보관 실패는 횟수로 세지 않고 같은 파일 저장을 다시 시도한다', (tester) async {
    final history = _FailingHistory();
    await _show(
      tester,
      recorder: _Recorder(),
      client: _Client(),
      history: history,
    );
    await _tap(tester, find.byKey(const Key('consonant-record')));
    await _tap(tester, find.byKey(const Key('consonant-record')));
    expect(find.text('0 / 3회 녹음'), findsOneWidget);
    expect(await history.load(), isEmpty);
    await _tap(tester, find.text('녹음 저장 다시 시도'));
    expect((await history.load()).length, 1);
    expect(find.text('1 / 3회 녹음'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('이어하기는 항목 ID와 남은 횟수를 복원한다', (tester) async {
    await _show(
      tester,
      recorder: _Recorder(),
      client: _Client(),
      history: ConsonantTrainingHistoryService(),
      progress: ConsonantTrainingProgress(
        targetId: _target.id,
        grapheme: 'ㄱ',
        position: PhonemePosition.onset,
        level: ConsonantTrainingLevel.syllable,
        itemIndex: 0,
        contentId: 'syllable_go',
        repetitions: 3,
        completedAttempts: 2,
        completed: false,
        updatedAt: DateTime(2026),
      ),
    );
    expect(find.text('2 / 3회 녹음'), findsOneWidget);
    expect(
      tester.widget<TargetPracticeText>(find.byType(TargetPracticeText)).text,
      '고',
    );
    await _tap(tester, find.byKey(const Key('consonant-record')));
    await _tap(tester, find.byKey(const Key('consonant-record')));
    expect(find.text('이번 연습을 마쳤어요 · 3회 녹음'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _show(
  WidgetTester tester, {
  required _Recorder recorder,
  required _Client client,
  required ConsonantTrainingHistoryService history,
  ConsonantTrainingProgress? progress,
}) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: ConsonantTrainingScreen(
        pack: _pack,
        target: _target,
        historyService: history,
        recorder: recorder,
        player: _Player(),
        tts: _Tts(),
        analysisClient: client,
        initialProgress: progress,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FailingHistory extends ConsonantTrainingHistoryService {
  bool fail = true;
  @override
  Future<void> add(ConsonantTrainingAttempt attempt) async {
    if (fail) {
      fail = false;
      throw StateError('save failed');
    }
    await super.add(attempt);
  }
}

class _Recorder extends AudioRecorderService {
  Completer<void>? starting;
  var count = 0;
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<void> startRecording(String fileName) async {
    await starting?.future;
  }

  @override
  Future<String?> stopRecording() async =>
      '${Directory.systemTemp.path}/consonant_test_${count++}.m4a';
  @override
  Future<void> dispose() async {}
}

class _Player extends AudioPlayerService {
  @override
  Future<void> playFile(String path) async {}
  @override
  Future<void> stop() async {}
}

class _Tts extends TtsService {
  @override
  Future<void> speak(String text) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

class _Client extends PronunciationAnalysisClient {
  int calls = 0;
  String? itemId;
  CancelToken? token;
  Completer<PronunciationAnalysisResult>? response;
  @override
  Future<PronunciationAnalysisResult> analyze({
    required String audioFilePath,
    required PronunciationContentItem item,
    required ConsonantTrainingTarget target,
    required String contentVersion,
    required String language,
    double? baselineScore,
    CancelToken? cancelToken,
  }) async {
    calls++;
    itemId = item.id;
    token = cancelToken;
    return response?.future ??
        Future.value(PronunciationAnalysisResult.unavailable('test'));
  }
}

const _target = ConsonantTrainingTarget(
  id: 'onset_g',
  grapheme: 'ㄱ',
  phone: 'k0',
  position: PhonemePosition.onset,
  description: '',
);
const _pack = PronunciationContentPack(
  id: 'test',
  schemaVersion: 1,
  version: '1',
  targets: [_target],
  source: 'test',
  items: [
    PronunciationContentItem(
      id: 'sentence',
      targetId: 'onset_g',
      level: ConsonantTrainingLevel.sentence,
      text: '가게에서 고기를 사고 가족과 공원 길을 같이 걸어요.',
      pronunciation: ['k0'],
      difficulty: 1,
      category: '',
      targetOccurrenceCount: 6,
    ),

    PronunciationContentItem(
      id: 'syllable_ga',
      targetId: 'onset_g',
      level: ConsonantTrainingLevel.syllable,
      text: '가',
      pronunciation: ['k0'],
      difficulty: 1,
      category: '',
      targetOccurrenceCount: 1,
    ),
    PronunciationContentItem(
      id: 'syllable_go',
      targetId: 'onset_g',
      level: ConsonantTrainingLevel.syllable,
      text: '고',
      pronunciation: ['k0'],
      difficulty: 1,
      category: '',
      targetOccurrenceCount: 1,
    ),
    PronunciationContentItem(
      id: 'word',
      targetId: 'onset_g',
      level: ConsonantTrainingLevel.word,
      text: '가방',
      pronunciation: ['k0'],
      difficulty: 1,
      category: '',
      targetOccurrenceCount: 1,
    ),
  ],
);
