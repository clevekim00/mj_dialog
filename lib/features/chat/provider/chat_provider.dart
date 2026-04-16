import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mj_dialog/services/api/ai_service.dart';

enum ConversationState {
  idle,
  listening,
  thinking,
  speaking,
  feedback, // showing pronunciation feedback
}

// 1. STT Live Text Provider
class SttLiveTextNotifier extends Notifier<String> {
  @override
  String build() => '';
  
  void updateText(String text) {
    state = text;
  }
}
final sttLiveTextProvider = NotifierProvider<SttLiveTextNotifier, String>(() => SttLiveTextNotifier());

// 2. Conversation State Provider
class ConversationStateNotifier extends Notifier<ConversationState> {
  @override
  ConversationState build() => ConversationState.idle;
  
  void updateState(ConversationState newState) {
    state = newState;
  }
}
final conversationStateProvider = NotifierProvider<ConversationStateNotifier, ConversationState>(() => ConversationStateNotifier());

// 3. AI Feedback Provider
class AiFeedbackNotifier extends Notifier<AiResponse?> {
  @override
  AiResponse? build() => null;
  
  void updateFeedback(AiResponse? feedback) {
    state = feedback;
  }
}
final aiFeedbackProvider = NotifierProvider<AiFeedbackNotifier, AiResponse?>(() => AiFeedbackNotifier());

// ChatMessage to keep historical types intact if needed
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final int? pronunciationScore;
  final String? pronunciationFeedback;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.pronunciationScore,
    this.pronunciationFeedback,
  });
}

class ChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => [];

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(() {
  return ChatNotifier();
});
