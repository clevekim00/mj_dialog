import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/services/audio/stt_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const method = MethodChannel('speech_rehab/speech_recognition');
  const event = MethodChannel('speech_rehab/speech_recognition/events');
  const codec = StandardMethodCodec();
  var subscriptionsCancelled = 0;

  Future<void> emit(Map<String, Object> value) async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      event.name,
      codec.encodeSuccessEnvelope(value),
      (_) {},
    );
  }

  setUp(() {
    subscriptionsCancelled = 0;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(event, (
      call,
    ) async {
      if (call.method == 'cancel') subscriptionsCancelled++;
      return null;
    });
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(method, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(event, null);
  });

  test(
    'stop keeps the event subscription until delayed final text arrives',
    () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(method, (
        call,
      ) async {
        if (call.method == 'initialize' || call.method == 'startListening') {
          return true;
        }
        if (call.method == 'stopListening') {
          unawaited(
            Future<void>.delayed(const Duration(milliseconds: 25), () async {
              expect(subscriptionsCancelled, 0);
              await emit({'text': '마지막 말', 'isFinal': true});
            }),
          );
        }
        return null;
      });
      final service = SttService(useIosNative: true);
      final values = <String>[];
      expect(
        await service.startListening(
          onResult: (text, finalResult) async {
            values.add(text);
          },
        ),
        isTrue,
      );
      await service.stopListening();
      expect(values, ['마지막 말']);
      expect(subscriptionsCancelled, 1);
      await service.dispose();
    },
  );

  test('final callback may stop listening without waiting on itself', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(method, (
      call,
    ) async {
      return call.method == 'initialize' || call.method == 'startListening'
          ? true
          : null;
    });
    final service = SttService(useIosNative: true);
    final done = Completer<void>();
    await service.startListening(
      onResult: (text, isFinal) async {
        if (isFinal) {
          await service.stopListening();
          done.complete();
        }
      },
    );
    await emit({'text': '완료', 'isFinal': true});
    await done.future.timeout(const Duration(milliseconds: 250));
    await service.dispose();
  });
  test(
    'native terminal and error events are observable without a final transcript',
    () async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        method,
        (call) async =>
            call.method == 'initialize' || call.method == 'startListening'
            ? true
            : null,
      );
      final service = SttService(useIosNative: true);
      final values = <String>[];
      await service.startListening(
        onResult: (text, isFinal) async {
          values.add(text);
        },
      );
      final ended = Completer<void>();
      service.sessionEnded.addListener(() {
        if (!ended.isCompleted) ended.complete();
      });
      await emit({
        'text': '부분 문장',
        'isFinal': false,
        'done': true,
        'error': 'recognition_failed',
      });
      await ended.future.timeout(const Duration(seconds: 1));
      expect(values, ['부분 문장']);
      expect(service.sessionEnded.value, 1);
      expect(service.recognitionError.value, 'recognition_failed');
      await service.stopListening();
      await service.dispose();
    },
  );

  test(
    'disposing during permission wait prevents a late microphone start',
    () async {
      final permission = Completer<bool>(), entered = Completer<void>();
      final calls = <String>[];
      binding.defaultBinaryMessenger.setMockMethodCallHandler(method, (
        call,
      ) async {
        calls.add(call.method);
        if (call.method == 'initialize') {
          entered.complete();
          return permission.future;
        }
        return null;
      });
      final service = SttService(useIosNative: true);
      final starting = service.startListening(onResult: (_, _) async {});
      await entered.future;
      await service.dispose();
      permission.complete(true);
      expect(await starting, isFalse);
      expect(calls, ['initialize']);
      await service.dispose();
    },
  );
}
