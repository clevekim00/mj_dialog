import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/services/microphone_access.dart';

void main() {
  Future<void> host(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      navigatorKey: MicrophoneAccess.navigatorKey,
      home: const Scaffold(body: Text('Practice')),
    ),
  );
  testWidgets('grant proceeds without extra dialog', (tester) async {
    await host(tester);
    expect(await MicrophoneAccess.ensure(() async => true), isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets(
    'denial offers settings, deduplicates, and requires deliberate retry',
    (tester) async {
      await host(tester);
      var requests = 0;
      var settings = 0;
      final result = MicrophoneAccess.ensure(
        () async {
          requests++;
          return false;
        },
        openSettings: () async {
          settings++;
          return true;
        },
      );
      final duplicate = MicrophoneAccess.ensure(() async {
        requests++;
        return false;
      });
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('설정 열기'));
      await tester.pumpAndSettle();
      expect(await result, isFalse);
      expect(await duplicate, isFalse);
      expect(requests, 1);
      expect(settings, 1);
      expect(await MicrophoneAccess.ensure(() async => true), isTrue);
    },
  );
  testWidgets('dismissal does not open settings', (tester) async {
    await host(tester);
    var opened = false;
    final result = MicrophoneAccess.ensure(
      () async => false,
      openSettings: () async {
        opened = true;
        return true;
      },
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
    expect(opened, isFalse);
  });
  testWidgets('settings failure provides manual instructions', (tester) async {
    await host(tester);
    final result = MicrophoneAccess.ensure(
      () async => false,
      openSettings: () async => false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정 열기'));
    await tester.pumpAndSettle();
    expect(find.text('기기 설정을 열어 주세요'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });
}
