import 'dart:io';
import 'dart:async';
import 'package:speech_rehab/features/sentence_practice/sentence_ocr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:speech_rehab/l10n/app_localizations.dart';
import 'package:speech_rehab/features/sentence_practice/sentence_repository.dart';
import 'package:speech_rehab/features/sentence_practice/sentence_screens.dart';
import 'package:speech_rehab/features/rehab/audio/practice_capture.dart';

class FakeCapture extends PracticeCapture {
  FakeCapture(this.root);
  final Directory root;
  int count = 0;
  @override
  Future<void> startRecording(String name) async {
    envelope.addAll([.1, .3, .2]);
  }

  @override
  int get durationMs => 1000;
  @override
  Future<String?> stopRecording() async {
    final f = File('${root.path}/input${count++}.wav');
    await f.writeAsBytes([count, 2, 3, 4]);
    return f.path;
  }
}

class PendingOcr extends SentenceOcr {
  final picked = Completer<Uint8List?>();
  @override
  bool get supported => true;
  @override
  Future<Uint8List?> pickImage({
    SentenceImageSource source = SentenceImageSource.file,
    void Function(String)? onStage,
  }) => picked.future;
}

class MobileOcr extends SentenceOcr {
  final sources = <SentenceImageSource>[];
  Object? failure;
  bool settingsOpened = false;
  @override
  Future<bool> openSettings() async {
    settingsOpened = true;
    return true;
  }

  @override
  bool get mobileSources => true;
  @override
  Future<Uint8List?> pickImage({
    SentenceImageSource source = SentenceImageSource.file,
    void Function(String)? onStage,
  }) async {
    sources.add(source);
    if (failure != null) throw failure!;
    return null;
  }
}

void main() {
  late Directory root;
  late SentenceRepository repo;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('sentence_ui');
    repo = SentenceRepository(sqlite3.openInMemory(), root);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('speech_rehab/audio_player'),
          (_) async => null,
        );
  });
  tearDown(() async {
    repo.db.close();
    await root.delete(recursive: true);
  });
  Widget app(Widget home, {String lang = 'ko'}) => MaterialApp(
    locale: Locale(lang),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
  testWidgets(
    'sentence and full screen editors dismiss keyboard without losing text',
    (tester) async {
      await tester.pumpWidget(app(SentenceInputScreen(repository: repo)));
      final sentence = find.byKey(const ValueKey('sentence-text'));
      await tester.enterText(sentence, '편집할 문장');
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.tap(find.byTooltip('키보드 내리기'));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.ensureVisible(find.text('문장 크게 편집하기'));
      await tester.tap(find.text('문장 크게 편집하기'));
      await tester.pumpAndSettle();
      final editor = find.byType(TextField).last;
      await tester.enterText(editor, '수정 완료한 문장');
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.tap(find.byTooltip('키보드 내리기'));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.tap(find.text('편집 완료'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(sentence).controller!.text, '수정 완료한 문장');
    },
  );

  testWidgets(
    'library opens with folders and supports create rename and bulk move',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      repo.addSentence('옮길 문장', 'ko-KR');
      await tester.pumpWidget(app(SentenceLibraryScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('아직 담지 않은 문장'), findsOneWidget);
      expect(find.text('옮길 문장'), findsNothing);
      await tester.tap(find.text('문장집 추가'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '병원');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(find.text('병원'), findsOneWidget);
      await tester.tap(find.byTooltip('문장집 이름 변경'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '진료');
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(find.text('진료'), findsOneWidget);
      await tester.tap(find.text('아직 담지 않은 문장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('문장 선택'));
      await tester.pump();
      await tester.tap(find.text('전체 선택'));
      await tester.pump();
      await tester.tap(find.text('1개 이동'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('진료'));
      await tester.pumpAndSettle();
      expect(repo.sentences().single['folder'], '진료');
      expect(find.text('옮길 문장'), findsNothing);
      await tester.tap(find.text('문장집 목록'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('진료'));
      await tester.pumpAndSettle();
      expect(find.text('옮길 문장'), findsOneWidget);
      await tester.tap(find.text('문장 추가 · 입력 / 사진 / 음성'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('sentence-folder')))
            .controller!
            .text,
        '진료',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('edits imported text and saves all lines into a folder', (
    tester,
  ) async {
    await tester.pumpWidget(app(SentenceInputScreen(repository: repo)));
    await tester.enterText(find.byKey(const ValueKey('sentence-folder')), '병원');
    await tester.enterText(
      find.byKey(const ValueKey('sentence-text')),
      '인식 오류',
    );
    await tester.ensureVisible(find.text('문장 크게 편집하기'));
    await tester.tap(find.text('문장 크게 편집하기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '수정한 문장\n두 번째 문장');
    await tester.tap(find.text('편집 완료'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('문장 저장'));
    await tester.pumpAndSettle();
    expect(repo.sentences().map((s) => s['text']).toSet(), {
      '수정한 문장',
      '두 번째 문장',
    });
    expect(repo.sentences().every((s) => s['folder'] == '병원'), isTrue);
    expect(repo.folders(), ['병원']);
  });

  testWidgets(
    'photo library and camera dispatch separately and cancellation keeps text',
    (tester) async {
      final ocr = MobileOcr();
      await tester.pumpWidget(
        app(SentenceInputScreen(repository: repo, ocr: ocr)),
      );
      await tester.enterText(
        find.byKey(const ValueKey('sentence-text')),
        '기존 문장',
      );
      await tester.ensureVisible(find.text('사진 보관함에서 선택'));
      await tester.tap(find.text('사진 보관함에서 선택'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('카메라로 촬영'));
      await tester.tap(find.text('카메라로 촬영'));
      await tester.pumpAndSettle();
      expect(ocr.sources, [
        SentenceImageSource.gallery,
        SentenceImageSource.camera,
      ]);
      expect(find.text('기존 문장'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('sentence-text')))
            .enabled,
        isTrue,
      );
    },
  );
  for (final code in [
    'camera_access_denied',
    'photo_access_denied',
    'camera_access_restricted',
    'channel-error',
  ]) {
    testWidgets('OCR handles $code without losing text and allows retry', (
      tester,
    ) async {
      final ocr = MobileOcr()..failure = PlatformException(code: code);
      await tester.pumpWidget(
        app(SentenceInputScreen(repository: repo, ocr: ocr)),
      );
      await tester.enterText(
        find.byKey(const ValueKey('sentence-text')),
        '남겨 둘 문장',
      );
      await tester.ensureVisible(
        find.text(code.startsWith('photo') ? '사진 보관함에서 선택' : '카메라로 촬영'),
      );
      await tester.tap(
        find.text(code.startsWith('photo') ? '사진 보관함에서 선택' : '카메라로 촬영'),
      );
      await tester.pumpAndSettle();
      expect(find.text('남겨 둘 문장'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('sentence-text')))
            .enabled,
        isTrue,
      );
      final settings = find.text('앱 권한 설정 열기');
      if (code.endsWith('_denied')) {
        await tester.scrollUntilVisible(
          settings,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(settings, findsOneWidget);
        await Scrollable.ensureVisible(tester.element(settings), alignment: .5);
        await tester.pumpAndSettle();
        await tester.tap(settings);
        await tester.pumpAndSettle();
        expect(ocr.settingsOpened, isTrue);
      } else {
        expect(settings, findsNothing);
        expect(
          find.textContaining(
            code == 'channel-error' ? '사진 기능에 연결하지' : '기기에서 카메라',
          ),
          findsOneWidget,
        );
      }
      ocr.failure = null;
      await tester.ensureVisible(find.text('카메라로 촬영'));
      await tester.ensureVisible(find.text('카메라로 촬영'));
      await tester.tap(find.text('카메라로 촬영'));
      await tester.pumpAndSettle();
      expect(settings, findsNothing);
      expect(find.text('남겨 둘 문장'), findsOneWidget);
    });
  }
  testWidgets(
    'saves more than 30 lines and 5000 total characters without truncation',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final lines = List.generate(
        31,
        (i) => '$i ${List.filled(600, "가").join()}',
      );
      await tester.pumpWidget(app(SentenceInputScreen(repository: repo)));
      await tester.enterText(
        find.byKey(const ValueKey('sentence-text')),
        lines.join('\n'),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(CheckboxListTile),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(repo.sentences().map((s) => s['text']).toSet(), lines.toSet());
    },
  );
  testWidgets('42 OCR lines keep confirmation and save visible with keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(app(SentenceInputScreen(repository: repo)));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sentence-text')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('sentence-text')),
      List.generate(42, (i) => '$i 번째 연습 문장입니다.').join('\n'),
    );
    await tester.pumpAndSettle();
    final confirm = find.byType(CheckboxListTile);
    final save = find.text('문장 저장');
    expect(confirm.hitTestable(), findsOneWidget);
    expect(save.hitTestable(), findsOneWidget);
    expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(468));
    await tester.tap(confirm);
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repo.sentences(), hasLength(42));
    expect(tester.takeException(), isNull);
  });
  testWidgets('input requires review and saves separate lines', (tester) async {
    await tester.pumpWidget(app(SentenceInputScreen(repository: repo)));
    await tester.enterText(
      find.byKey(const ValueKey('sentence-text')),
      '물을 주세요.\n천천히 말할게요.',
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(repo.sentences().length, 2);
  });
  testWidgets('cancelled image import restores input and ignores late result', (
    tester,
  ) async {
    final ocr = PendingOcr();
    await tester.pumpWidget(
      app(SentenceInputScreen(repository: repo, ocr: ocr)),
    );
    await tester.tap(find.text('사진에서 글 가져오기 (OCR)'));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('sentence-text')))
          .enabled,
      isFalse,
    );
    await tester.tap(find.text('가져오기 취소'));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('sentence-text')))
          .enabled,
      isTrue,
    );
    ocr.picked.complete(Uint8List.fromList([1, 2, 3]));
    await tester.pumpAndSettle();
    expect(find.text('문장 입력·확인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'two recordings remain distinct and controls stay visible with waveform',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final id = repo.addSentence('물을 주세요.', 'ko-KR');
      final sentence = repo.sentences().single;
      await tester.pumpWidget(
        app(
          SentencePairScreen(
            repository: repo,
            sentence: sentence,
            capture: FakeCapture(root),
          ),
        ),
      );
      final record = find.text('1차 녹음');
      expect(record, findsOneWidget);
      await tester.tap(record);
      await tester.pumpAndSettle();
      expect(find.text('녹음 끝내고 저장'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('녹음 끝내고 저장'));
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while ((repo
                    .recordings(repo.pairs(id).single['id'] as String)
                    .isEmpty ||
                repo.db.select('SELECT * FROM cleanup').isNotEmpty) &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();
      expect(repo.recordings(repo.pairs(id).single['id'] as String).length, 1);
      await tester.tap(find.text('2차 녹음'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('녹음 끝내고 저장'));
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while ((repo.recordings(repo.pairs(id).single['id'] as String).length <
                    2 ||
                repo.db.select('SELECT * FROM cleanup').isNotEmpty) &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();
      final takes = repo.recordings(repo.pairs(id).single['id'] as String);
      expect(takes.length, 2);
      expect(takes[0]['id'], isNot(takes[1]['id']));
      expect(takes[0]['hash'], isNot(takes[1]['hash']));
      final playedPaths = <String>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        const MethodChannel('speech_rehab/audio_player/events'),
        (_) async => null,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('speech_rehab/audio_player'),
        (call) async {
          if (call.method == 'playFile') {
            playedPaths.add((call.arguments as Map)['path'] as String);
          }
          return null;
        },
      );
      Future<void> completePlayback() async {
        await tester.runAsync(() async {
          await messenger.handlePlatformMessage(
            'speech_rehab/audio_player/events',
            const StandardMethodCodec().encodeSuccessEnvelope('complete'),
            (_) {},
          );
          await Future<void>.delayed(const Duration(milliseconds: 10));
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
      }

      // Latest recording is first, but each button keeps its explicit slot.
      await tester.ensureVisible(find.text('2차 녹음 듣기'));
      await tester.tap(find.text('2차 녹음 듣기'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('2차 녹음 듣기')).dy,
        lessThan(tester.getTopLeft(find.text('1차 녹음 듣기')).dy),
      );
      expect(playedPaths, [repo.audioPath(takes[1])]);
      await completePlayback();
      await tester.ensureVisible(find.text('1차 녹음 듣기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1차 녹음 듣기'));
      await tester.pumpAndSettle();
      expect(playedPaths.last, repo.audioPath(takes[0]));
      await completePlayback();
      playedPaths.clear();
      await tester.ensureVisible(find.text('1차 → 2차 순서대로 듣기'));
      await tester.tap(find.text('1차 → 2차 순서대로 듣기'));
      await tester.pumpAndSettle();
      expect(playedPaths, [repo.audioPath(takes[0])]);
      await completePlayback();
      expect(playedPaths, [repo.audioPath(takes[0]), repo.audioPath(takes[1])]);
      await completePlayback();

      // Native stop replies may arrive out of order during quick switching.
      final pendingStops = <Completer<void>>[];
      messenger.setMockMethodCallHandler(
        const MethodChannel('speech_rehab/audio_player'),
        (call) async {
          if (call.method == 'stop') {
            final pending = Completer<void>();
            pendingStops.add(pending);
            await pending.future;
          } else if (call.method == 'playFile') {
            playedPaths.add((call.arguments as Map)['path'] as String);
          }
          return null;
        },
      );
      playedPaths.clear();
      await tester.tap(find.text('1차 녹음 듣기'));
      await tester.pump();
      await tester.tap(find.text('2차 녹음 듣기'));
      await tester.pump();
      expect(pendingStops, hasLength(2));
      pendingStops[1].complete();
      await tester.pumpAndSettle();
      pendingStops[0].complete();
      await tester.pumpAndSettle();
      expect(playedPaths, [repo.audioPath(takes[1])]);
      await completePlayback();
      messenger.setMockMethodCallHandler(
        const MethodChannel('speech_rehab/audio_player'),
        (_) async => null,
      );
      expect(find.text('오늘 마치기'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets(
    'English reading screen at large text keeps bottom record control',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      repo.addSentence('Please give me water.', 'en-US');
      await tester.pumpWidget(
        app(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SentencePairScreen(
              repository: repo,
              sentence: repo.sentences().single,
              capture: FakeCapture(root),
            ),
          ),
          lang: 'en',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 · Record'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}
