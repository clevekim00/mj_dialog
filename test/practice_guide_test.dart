import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/rehab/guide/practice_guide.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'consonant prompt handles Hangul without inventing onset for vowels',
    () {
      expect(firstHangulConsonant('물을 주세요.'), 'ㅁ');
      expect(firstHangulConsonant('아'), isNull);
      expect(firstHangulConsonant('water'), isNull);
    },
  );
  test(
    'speech demonstration requires exact text, reviewer and synchronized sound',
    () {
      const draft = ReviewedSpeechMedia(
        asset: 'x',
        prompt: '물',
        reviewedBy: '',
        version: '1',
        audioSynchronized: true,
      );
      expect(draft.matches('물'), isFalse);
      const approved = ReviewedSpeechMedia(
        asset: 'x',
        prompt: '물',
        reviewedBy: 'review-123',
        version: '1',
        audioSynchronized: true,
      );
      expect(approved.matches('물'), isTrue);
      expect(approved.matches('잠시'), isFalse);
    },
  );
  testWidgets('stop remains reachable while example locks other controls', (
    tester,
  ) async {
    var stops = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PracticeGuide(
            text: '물',
            instruction: '편안하게 말해요.',
            english: false,
            locked: true,
            playing: true,
            listen: (_) async {},
            stop: () async {
              stops++;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('예시 멈추기'));
    await tester.pumpAndSettle();
    expect(stops, 1);
  });

  testWidgets(
    'guide waits for explicit next, speaks only selected part, can be reopened',
    (tester) async {
      final spoken = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PracticeGuide(
                text: '물을 / 주세요.',
                instruction: '편안한 곳에서 쉬어요.',
                english: false,
                locked: false,
                listen: (text) async {
                  spoken.add(text);
                },
                stop: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 · 먼저 들어요'), findsOneWidget);
      expect(spoken, isEmpty);
      await tester.tap(find.text('다음 안내'));
      await tester.pumpAndSettle();
      expect(find.text('첫소리 확인: ㅁ → 물'), findsOneWidget);
      await tester.tap(find.text('물을'));
      await tester.pumpAndSettle();
      expect(spoken, ['물을']);
      await tester.tap(find.text('다음 안내'));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3 · 준비되면 말해요'), findsOneWidget);
      await tester.tap(find.text('직접 연습할게요'));
      await tester.pumpAndSettle();
      expect(find.text('안내 다시 보기'), findsOneWidget);
      await tester.tap(find.text('안내 다시 보기'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 · 먼저 들어요'), findsOneWidget);
    },
  );
  testWidgets('quick mode survives restart and large text has no overflow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'rehab_guide_quick': true});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PracticeGuide(
              text: '물을 주세요.',
              instruction: '편안하게 말해요.',
              english: false,
              locked: false,
              listen: (_) async {},
              stop: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('안내 다시 보기'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('안내 다시 보기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
