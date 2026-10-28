import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:speech_rehab/l10n/app_localizations.dart';
import 'package:speech_rehab/services/audio/stt_service.dart';
import 'package:speech_rehab/features/sentence_practice/sentence_repository.dart';
import 'package:speech_rehab/features/sentence_practice/sentence_screens.dart';
import 'package:speech_rehab/features/sentence_practice/sentence_voice_input_screen.dart';

class FakeSpeech extends SttService {
  SttResultCallback? callback;
  bool available = true;
  int stopped = 0, disposed = 0;
  Completer<bool>? starting;
  Completer<void>? stopping;
  String? finalText;
  @override
  Future<bool> startListening({
    required SttResultCallback onResult,
    List<String> contextualStrings = const [],
  }) async {
    callback = onResult;
    return starting?.future ?? available;
  }

  Future<void> emit(String text, {bool finalResult = false}) async {
    await callback?.call(text, finalResult);
    if (finalResult) sessionEnded.value++;
  }

  @override
  Future<void> stopListening() async {
    stopped++;
    await stopping?.future;
    if (finalText != null) await callback?.call(finalText!, true);
  }

  @override
  Future<void> dispose() async {
    disposed++;
  }
}

void main() {
  late Directory root;
  late SentenceRepository repo;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('sentence_voice');
    repo = SentenceRepository(sqlite3.openInMemory(), root);
  });
  tearDown(() async {
    repo.db.close();
    await root.delete(recursive: true);
  });
  Widget app(Widget home, {String locale = 'ko'}) => MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
  final editor = find.byKey(const ValueKey('sentence-voice-text'));
  final toggle = find.byKey(const ValueKey('sentence-voice-toggle'));
  final apply = find.byKey(const ValueKey('sentence-voice-apply'));
  final parentText = find.byKey(const ValueKey('sentence-text'));
  Future<void> open(
    WidgetTester tester,
    FakeSpeech speech, {
    String initial = '',
  }) async {
    await tester.pumpWidget(
      app(
        SentenceInputScreen(
          repository: repo,
          initialFolder: '병원',
          speechFactory: (_) => speech,
        ),
      ),
    );
    if (initial.isNotEmpty) await tester.enterText(parentText, initial);
    await tester.ensureVisible(find.text('음성으로 입력'));
    await tester.tap(find.text('음성으로 입력'));
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester) async {
    await tester.tap(toggle);
    await tester.pump();
  }

  String text(WidgetTester tester) =>
      tester.widget<TextField>(editor).controller!.text;

  testWidgets(
    'Edit reopens a keyboard hidden by iPad while the field stays focused',
    (tester) async {
      await open(tester, FakeSpeech(), initial: '편집 중인 글');
      await tester.enterText(editor, '첫 번째 편집');
      await tester.pump();
      final focus = tester.widget<TextField>(editor).focusNode!;
      expect(focus.hasFocus, isTrue);
      tester.testTextInput.hide();
      expect(focus.hasFocus, isTrue);
      final edit = find.byKey(const ValueKey('sentence-voice-edit'));
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(editor, '음성 입력 없이 두 번째 편집');
      expect(text(tester), '음성 입력 없이 두 번째 편집');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('editing can resume repeatedly without another voice session', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await open(tester, speech, initial: '처음 글');
    for (var i = 1; i <= 3; i++) {
      final edit = find.byKey(const ValueKey('sentence-voice-edit'));
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(editor, '$i 번째 수정');
      await tester.pump();
      await tester.tap(find.byTooltip('키보드 내리기'));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(text(tester), '$i 번째 수정');
    }
    expect(speech.callback, isNull);
    await tester.ensureVisible(editor);
    await tester.tap(editor);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(editor, '다시 눌러서 수정');
    await tester.pump();
    expect(text(tester), '다시 눌러서 수정');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'edit action ends recognition and late results cannot overwrite typing',
    (tester) async {
      final speech = FakeSpeech()..finalText = '최종 인식';
      await open(tester, speech);
      await start(tester);
      await speech.emit('중간 인식');
      await tester.pump();
      final edit = find.byKey(const ValueKey('sentence-voice-edit'));
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expect(speech.stopped, 1);
      expect(tester.widget<TextField>(editor).readOnly, isFalse);
      await tester.enterText(editor, '직접 고친 문장');
      await speech.emit('늦은 인식');
      await tester.pump();
      expect(text(tester), '직접 고친 문장');
      await tester.tap(find.byTooltip('키보드 내리기'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      await tester.enterText(editor, '두 번째 직접 수정');
      expect(text(tester), '두 번째 직접 수정');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('hide keyboard keeps edits and allows continuing voice input', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await open(tester, speech, initial: '처음 문장');
    await tester.enterText(editor, '수정한 문장');
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(find.byTooltip('키보드 내리기'));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(text(tester), '수정한 문장');
    await start(tester);
    await speech.emit('다음 문장', finalResult: true);
    await tester.pumpAndSettle();
    expect(text(tester), '수정한 문장\n다음 문장');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'partial text is replaced, final text edited, and saved in the selected collection',
    (tester) async {
      final speech = FakeSpeech()..finalText = '물을 주세요.';
      await open(tester, speech, initial: '기존 문장');
      await start(tester);
      await speech.emit('물');
      await tester.pump();
      await speech.emit('물을 주세요');
      await tester.pump();
      expect(text(tester), '기존 문장\n물을 주세요');
      expect(tester.widget<TextField>(editor).readOnly, isTrue);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(text(tester), '기존 문장\n물을 주세요.');
      await tester.enterText(editor, '기존 문장\n따뜻한 물을 주세요.');
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(parentText).controller!.text,
        '기존 문장\n따뜻한 물을 주세요.',
      );
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.tap(find.text('문장 저장'));
      await tester.pumpAndSettle();
      expect(repo.sentences().map((s) => s['text']).toSet(), {
        '기존 문장',
        '따뜻한 물을 주세요.',
      });
      expect(
        repo.sentences().every(
          (s) => s['folder'] == '병원' && s['source'] == 'voice',
        ),
        isTrue,
      );
      expect(repo.db.select('SELECT * FROM pairs'), isEmpty);
    },
  );
  testWidgets('cancel preserves original input and ignores late text', (
    tester,
  ) async {
    final speech = FakeSpeech();
    await open(tester, speech, initial: '남길 문장');
    await start(tester);
    await speech.emit('취소할 말');
    await tester.pump();
    await tester.tap(find.byTooltip('취소 · 기존 문장 유지'));
    await tester.pumpAndSettle();
    await speech.emit('늦은 결과');
    await tester.pump();
    expect(tester.widget<TextField>(parentText).controller!.text, '남길 문장');
    expect(speech.disposed, greaterThanOrEqualTo(1));
    expect(repo.sentences(), isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'automatic end unlocks editing and a new utterance appends to edited text',
    (tester) async {
      final speech = FakeSpeech();
      await open(tester, speech);
      await start(tester);
      await speech.emit('첫 문장', finalResult: true);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(editor).readOnly, isFalse);
      await tester.enterText(editor, '수정한 첫 문장');
      await start(tester);
      await speech.emit('두 번째 문장', finalResult: true);
      await tester.pumpAndSettle();
      expect(text(tester), '수정한 첫 문장\n두 번째 문장');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'unavailable recognition keeps existing text and allows manual editing',
    (tester) async {
      final speech = FakeSpeech()..available = false;
      await open(tester, speech, initial: '기존 내용');
      await start(tester);
      await tester.pumpAndSettle();
      expect(text(tester), '기존 내용');
      expect(tester.widget<TextField>(editor).readOnly, isFalse);
      expect(find.textContaining('음성 입력을 시작하지 못했어요'), findsOneWidget);
      await tester.enterText(editor, '직접 수정한 문장');
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(parentText).controller!.text,
        '직접 수정한 문장',
      );
    },
  );
  testWidgets('stop waits for final transcript before enabling the editor', (
    tester,
  ) async {
    final speech = FakeSpeech()
      ..stopping = Completer<void>()
      ..finalText = '최종 문장';
    await open(tester, speech);
    await start(tester);
    await speech.emit('중간 문장');
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<TextField>(editor).readOnly, isTrue);
    expect(tester.widget<FilledButton>(apply).onPressed, isNull);
    speech.stopping!.complete();
    await tester.pumpAndSettle();
    expect(text(tester), '최종 문장');
    expect(tester.widget<TextField>(editor).readOnly, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'cancel during delayed permission does not apply or revive the session',
    (tester) async {
      final speech = FakeSpeech()..starting = Completer<bool>();
      await open(tester, speech, initial: '원래 문장');
      await start(tester);
      await tester.tap(find.byTooltip('취소 · 기존 문장 유지'));
      await tester.pumpAndSettle();
      speech.starting!.complete(true);
      await speech.emit('뒤늦은 인식');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(parentText).controller!.text, '원래 문장');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'recognition error retains partial text and allows another attempt',
    (tester) async {
      final speech = FakeSpeech();
      await open(tester, speech);
      await start(tester);
      await speech.emit('보존할 글');
      speech.recognitionError.value = 'network';
      await tester.pumpAndSettle();
      expect(text(tester), '보존할 글');
      expect(tester.widget<TextField>(editor).readOnly, isFalse);
      expect(find.textContaining('음성 인식이 중단됐어요'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('language selection is passed to voice recognition', (
    tester,
  ) async {
    String? language;
    final speech = FakeSpeech();
    await tester.pumpWidget(
      app(
        SentenceInputScreen(
          repository: repo,
          speechFactory: (value) {
            language = value;
            return speech;
          },
        ),
      ),
    );
    await tester.tap(find.text('한국어'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('음성으로 입력'));
    await tester.tap(find.text('음성으로 입력'));
    await tester.pumpAndSettle();
    expect(language, 'en-US');
    expect(find.text('Recognition language: English'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('narrow screen and large text keep voice controls reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      app(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SentenceVoiceInputScreen(
            language: 'ko-KR',
            speech: FakeSpeech(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(toggle.hitTestable(), findsOneWidget);
    expect(apply.hitTestable(), findsOneWidget);
    await start(tester);
    expect(toggle.hitTestable(), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
