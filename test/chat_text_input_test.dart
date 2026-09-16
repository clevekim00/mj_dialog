import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/chat/provider/chat_provider.dart';
import 'package:speech_rehab/features/chat/view/chat_screen.dart';
import 'package:speech_rehab/services/api/ai_service.dart';
import 'package:speech_rehab/services/audio/stt_service.dart';
import 'package:speech_rehab/services/audio/tts_service.dart';

class _TextAi extends AiService {
  @override
  Future<AiResponse> getResponseAndFeedback(String text) async =>
      const AiResponse(
        replyText: '편한 방법으로 이어가세요.',
        pronunciationScore: null,
        pronunciationFeedback: '발음 평가는 하지 않습니다.',
      );
}

class _NoMicrophone extends SttService {
  int starts = 0;
  int stops = 0;
  @override
  Future<void> stopListening() async => stops++;
  @override
  Future<bool> startListening({required SttResultCallback onResult}) async {
    starts++;
    return false;
  }

  @override
  Future<void> dispose() async {}
}

class _SilentTts extends TtsService {
  int speaks = 0;
  int stops = 0;
  @override
  Future<void> speak(String text) async => speaks++;
  @override
  Future<void> stop() async => stops++;
  @override
  Future<void> dispose() async {}
}

class _DelayedTextAi extends AiService {
  final reply = Completer<AiResponse>();
  @override
  Future<AiResponse> getResponseAndFeedback(String text) => reply.future;
}

void main() {
  testWidgets(
    'ending a busy conversation stops audio and ignores a late reply',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final ai = _DelayedTextAi();
      final stt = _NoMicrophone();
      final tts = _SilentTts();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(ai),
            sttServiceProvider.overrideWithValue(stt),
            ttsServiceProvider.overrideWithValue(tts),
          ],
          child: MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(body: Text('홈')),
          ),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const ChatScreen()),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChatScreen)),
      );
      await tester.enterText(find.byType(TextField), '나중에 대답해 주세요.');
      await tester.tap(find.byTooltip('입력한 글 보내기'));
      await tester.pump();
      expect(container.read(chatControllerProvider).isProcessing, isTrue);
      await navigator.currentState!.maybePop();
      await tester.pump();
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('소리와 녹음을 멈추려면 대화 마치기를 눌러 주세요.'), findsOneWidget);
      await tester.tap(find.text('대화 마치기'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsNothing);
      expect(stt.stops, greaterThan(0));
      expect(tts.stops, greaterThan(0));
      ai.reply.complete(
        const AiResponse(
          replyText: '늦게 도착한 답변',
          pronunciationScore: null,
          pronunciationFeedback: '',
        ),
      );
      await tester.pumpAndSettle();
      expect(tts.speaks, 0);
      expect(
        container.read(chatControllerProvider).conversationState,
        ConversationState.idle,
      );
      expect(
        container.read(chatControllerProvider).currentSession!.messages.length,
        1,
      );
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets(
    'typing and prepared phrases continue a conversation without microphone permission',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final stt = _NoMicrophone();
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiServiceProvider.overrideWithValue(_TextAi()),
            sttServiceProvider.overrideWithValue(stt),
            ttsServiceProvider.overrideWithValue(_SilentTts()),
          ],
          child: const MaterialApp(home: ChatScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('말로 이야기하기'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '글로 이야기할게요.');
      await tester.tap(find.byTooltip('입력한 글 보내기'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ChatScreen)),
      );
      var messages = container
          .read(chatControllerProvider)
          .currentSession!
          .messages;
      expect(messages.first.text, '글로 이야기할게요.');
      expect(messages.first.inputMethod, 'text');
      expect(messages.last.pronunciationScore, isNull);
      await tester.ensureVisible(find.text('잠시 쉬고 싶어요.'));
      await tester.tap(find.text('잠시 쉬고 싶어요.'));
      await tester.pumpAndSettle();
      messages = container
          .read(chatControllerProvider)
          .currentSession!
          .messages;
      expect(
        messages
            .where((message) => message.inputMethod == 'prepared')
            .single
            .text,
        '잠시 쉬고 싶어요.',
      );
      expect(stt.starts, 0);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
