import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/navigation/view/window_safe_area.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('speech_rehab/window_layout');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  Future<void> emitInset(WidgetTester tester, double value) async {
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('topInsetChanged', value),
      ),
      (_) {},
    );
    await tester.pump();
  }

  testWidgets(
    'back button avoids controls and follows window resizing',
    (tester) async {
      messenger.setMockMethodCallHandler(channel, (_) async => 64.0);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 24, bottom: 20),
              viewPadding: const EdgeInsets.only(top: 24, bottom: 20),
            ),
            child: WindowSafeArea(child: child!),
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Details')),
                        body: const Text('Detail body'),
                      ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byType(BackButton)).dy,
        greaterThanOrEqualTo(64),
      );
      final media = MediaQuery.of(tester.element(find.byType(Scaffold).last));
      expect(media.viewPadding.top, 64);
      expect(media.viewPadding.bottom, 20);

      await emitInset(tester, 80);
      expect(
        tester.getTopLeft(find.byType(BackButton)).dy,
        greaterThanOrEqualTo(80),
      );
      await emitInset(tester, 0);
      expect(tester.getTopLeft(find.byType(BackButton)).dy, lessThan(64));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Android retains existing safe area without invoking iOS',
    (tester) async {
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (_) async {
        calls++;
        return 80.0;
      });
      MediaQueryData? actual;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(top: 30),
            viewPadding: EdgeInsets.only(top: 30),
          ),
          child: WindowSafeArea(
            child: Builder(
              builder: (context) {
                actual = MediaQuery.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(actual!.padding.top, 30);
      expect(calls, 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
