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
    await f.writeAsBytes([1, 2, 3, 4]);
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
    'photo library and camera dispatch separately and cancellation keeps text',
    (tester) async {
      final ocr = MobileOcr();
      await tester.pumpWidget(
        app(SentenceInputScreen(repository: repo, ocr: ocr)),
      );
      await tester.enterText(find.byType(TextField), '기존 문장');
      await tester.tap(find.text('사진 보관함에서 선택'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('카메라로 촬영'));
      await tester.pumpAndSettle();
      expect(ocr.sources, [
        SentenceImageSource.gallery,
        SentenceImageSource.camera,
      ]);
      expect(find.text('기존 문장'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
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
      await tester.enterText(find.byType(TextField), '남겨 둘 문장');
      await tester.tap(
        find.text(code.startsWith('photo') ? '사진 보관함에서 선택' : '카메라로 촬영'),
      );
      await tester.pumpAndSettle();
      expect(find.text('남겨 둘 문장'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
      final settings = find.text('앱 권한 설정 열기');
      if (code.endsWith('_denied')) {
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
      await tester.enterText(find.byType(TextField), lines.join('\n'));
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
    await tester.enterText(
      find.byType(TextField),
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
    await tester.enterText(find.byType(TextField), '물을 주세요.\n천천히 말할게요.');
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
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.tap(find.text('가져오기 취소'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    ocr.picked.complete(Uint8List.fromList([1, 2, 3]));
    await tester.pumpAndSettle();
    expect(find.text('문장 입력·확인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'two recordings remain distinct and controls stay visible with waveform',
    (tester) async {
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
