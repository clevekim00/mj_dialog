import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mj_dialog/services/api/ai_service.dart';
import 'package:mj_dialog/services/audio/stt_service.dart';
import 'package:mj_dialog/services/audio/tts_service.dart';
import 'package:uuid/uuid.dart';

enum ConversationState {
  idle,
  listening,
  thinking,
  speaking,
  feedback,
}

enum ChatRole {
  user,
  assistant,
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    this.pronunciationScore,
    this.pronunciationFeedback,
  });

  final String id;
  final String text;
  final ChatRole role;
  final int? pronunciationScore;
  final String? pronunciationFeedback;
}

class ChatSessionState {
  const ChatSessionState({
    this.conversationState = ConversationState.idle,
    this.liveText = '',
    this.feedback,
    this.messages = const [],
    this.errorMessage,
  });

  final ConversationState conversationState;
  final String liveText;
  final AiResponse? feedback;
  final List<ChatMessage> messages;
  final String? errorMessage;

  bool get isProcessing =>
      conversationState == ConversationState.thinking ||
      conversationState == ConversationState.speaking;

  ChatSessionState copyWith({
    ConversationState? conversationState,
    String? liveText,
    AiResponse? feedback,
    bool clearFeedback = false,
    List<ChatMessage>? messages,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatSessionState(
      conversationState: conversationState ?? this.conversationState,
      liveText: liveText ?? this.liveText,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      messages: messages ?? this.messages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final chatControllerProvider =
    NotifierProvider<ChatController, ChatSessionState>(ChatController.new);

class ChatController extends Notifier<ChatSessionState> {
  final Uuid _uuid = const Uuid();

  AiService get _aiService => ref.read(aiServiceProvider);
  SttService get _sttService => ref.read(sttServiceProvider);
  TtsService get _ttsService => ref.read(ttsServiceProvider);

  @override
  ChatSessionState build() {
    final sttService = _sttService;
    final ttsService = _ttsService;

    ref.onDispose(() {
      sttService.dispose();
      ttsService.dispose();
    });

    return const ChatSessionState();
  }

  Future<void> toggleVoiceInput({required bool isVoiceSupported}) async {
    if (!isVoiceSupported) {
      return;
    }

    final currentState = state.conversationState;
    if (currentState == ConversationState.idle ||
        currentState == ConversationState.feedback) {
      await _startListening();
      return;
    }

    if (currentState == ConversationState.listening) {
      await stopListeningAndSubmit();
    }
  }

  Future<void> submitText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isProcessing) {
      return;
    }

    await _processInput(trimmed);
  }

  Future<void> stopListeningAndSubmit() async {
    if (state.conversationState != ConversationState.listening) {
      return;
    }

    final spokenText = state.liveText.trim();
    await _sttService.stopListening();

    if (spokenText.isEmpty) {
      state = state.copyWith(
        conversationState: ConversationState.idle,
        liveText: '',
        clearFeedback: true,
      );
      return;
    }

    await _processInput(spokenText);
  }

  void dismissFeedback() {
    state = state.copyWith(
      conversationState: ConversationState.idle,
      liveText: '',
      clearFeedback: true,
      clearError: true,
    );
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }

    state = state.copyWith(clearError: true);
  }

  Future<void> _startListening() async {
    state = state.copyWith(
      conversationState: ConversationState.listening,
      liveText: '',
      clearFeedback: true,
      clearError: true,
    );

    final initialized = await _sttService.init();
    if (!initialized) {
      _setError('음성 인식을 시작할 수 없어요. 권한과 기기 설정을 확인해 주세요.');
      state = state.copyWith(conversationState: ConversationState.idle);
      return;
    }

    final didStart = await _sttService.startListening(
      onResult: (text, isFinal) async {
        state = state.copyWith(liveText: text);
        if (isFinal && state.conversationState == ConversationState.listening) {
          await _processInput(text.trim(), fromVoiceInput: true);
        }
      },
    );

    if (!didStart) {
      _setError('음성 인식을 사용할 수 없는 상태예요. 잠시 후 다시 시도해 주세요.');
      state = state.copyWith(conversationState: ConversationState.idle);
    }
  }

  Future<void> _processInput(
    String text, {
    bool fromVoiceInput = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        conversationState: ConversationState.idle,
        liveText: '',
      );
      return;
    }

    if (fromVoiceInput) {
      await _sttService.stopListening();
    }

    final updatedMessages = [
      ...state.messages,
      ChatMessage(
        id: _uuid.v4(),
        text: trimmed,
        role: ChatRole.user,
      ),
    ];

    state = state.copyWith(
      conversationState: ConversationState.thinking,
      liveText: trimmed,
      messages: updatedMessages,
      clearFeedback: true,
      clearError: true,
    );

    try {
      final aiResult = await _aiService.getResponseAndFeedback(trimmed);
      final withReply = [
        ...updatedMessages,
        ChatMessage(
          id: _uuid.v4(),
          text: aiResult.replyText,
          role: ChatRole.assistant,
          pronunciationScore: aiResult.pronunciationScore,
          pronunciationFeedback: aiResult.pronunciationFeedback,
        ),
      ];

      state = state.copyWith(
        conversationState: ConversationState.speaking,
        liveText: aiResult.replyText,
        feedback: aiResult,
        messages: withReply,
      );

      await _ttsService.speak(aiResult.replyText);

      state = state.copyWith(
        conversationState: ConversationState.feedback,
        feedback: aiResult,
        messages: withReply,
      );
    } catch (_) {
      _setError('응답을 처리하는 중 문제가 생겼어요. 잠시 후 다시 시도해 주세요.');
      state = state.copyWith(conversationState: ConversationState.idle);
    }
  }

  void _setError(String message) {
    state = state.copyWith(errorMessage: message);
  }
}
