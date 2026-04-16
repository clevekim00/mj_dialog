import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/services/api/ai_service.dart';
import 'package:speech_rehab/services/audio/stt_service.dart';
import 'package:speech_rehab/services/audio/tts_service.dart';
import 'package:speech_rehab/services/history_service.dart';
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'role': role.name,
        'pronunciationScore': pronunciationScore,
        'pronunciationFeedback': pronunciationFeedback,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        text: json['text'],
        role: ChatRole.values.byName(json['role']),
        pronunciationScore: json['pronunciationScore'],
        pronunciationFeedback: json['pronunciationFeedback'],
      );
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  ChatSession copyWith({
    String? title,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'],
        title: json['title'],
        createdAt: DateTime.parse(json['createdAt']),
        messages: (json['messages'] as List)
            .map((m) => ChatMessage.fromJson(m))
            .toList(),
      );
}

class ChatSessionState {
  const ChatSessionState({
    this.currentSessionId,
    this.sessions = const [],
    this.conversationState = ConversationState.idle,
    this.liveText = '',
    this.feedback,
    this.errorMessage,
  });

  final String? currentSessionId;
  final List<ChatSession> sessions;
  final ConversationState conversationState;
  final String liveText;
  final AiResponse? feedback;
  final String? errorMessage;

  ChatSession? get currentSession {
    if (currentSessionId == null) return null;
    try {
      return sessions.firstWhere((s) => s.id == currentSessionId);
    } catch (_) {
      return null;
    }
  }

  bool get isProcessing =>
      conversationState == ConversationState.thinking ||
      conversationState == ConversationState.speaking;

  ChatSessionState copyWith({
    String? currentSessionId,
    List<ChatSession>? sessions,
    ConversationState? conversationState,
    String? liveText,
    AiResponse? feedback,
    bool clearFeedback = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatSessionState(
      currentSessionId: currentSessionId ?? this.currentSessionId,
      sessions: sessions ?? this.sessions,
      conversationState: conversationState ?? this.conversationState,
      liveText: liveText ?? this.liveText,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final historyServiceProvider = Provider<HistoryService>((ref) => HistoryService());

final chatControllerProvider =
    NotifierProvider<ChatController, ChatSessionState>(ChatController.new);

class ChatController extends Notifier<ChatSessionState> {
  final Uuid _uuid = const Uuid();

  AiService get _aiService => ref.read(aiServiceProvider);
  SttService get _sttService => ref.read(sttServiceProvider);
  TtsService get _ttsService => ref.read(ttsServiceProvider);
  HistoryService get _historyService => ref.read(historyServiceProvider);

  @override
  ChatSessionState build() {
    final sttService = _sttService;
    final ttsService = _ttsService;

    ref.onDispose(() {
      sttService.dispose();
      ttsService.dispose();
    });

    // Load history on initialization
    _loadHistory();

    return const ChatSessionState();
  }

  Future<void> _loadHistory() async {
    final sessions = await _historyService.loadSessions();
    if (sessions.isNotEmpty) {
      state = state.copyWith(
        sessions: sessions,
        currentSessionId: sessions.first.id,
      );
    } else {
      createNewSession();
    }
  }

  void createNewSession() {
    final newSession = ChatSession(
      id: _uuid.v4(),
      title: '새 대화',
      createdAt: DateTime.now(),
      messages: [],
    );

    final updatedSessions = [newSession, ...state.sessions];
    state = state.copyWith(
      sessions: updatedSessions,
      currentSessionId: newSession.id,
      conversationState: ConversationState.idle,
      liveText: '',
      clearFeedback: true,
    );
    _historyService.saveSessions(updatedSessions);
  }

  void switchSession(String sessionId) {
    if (state.currentSessionId == sessionId) return;
    
    state = state.copyWith(
      currentSessionId: sessionId,
      conversationState: ConversationState.idle,
      liveText: '',
      clearFeedback: true,
      clearError: true,
    );
  }

  void deleteSession(String sessionId) {
    final updatedSessions = state.sessions.where((s) => s.id != sessionId).toList();
    String? newCurrentId = state.currentSessionId;
    
    if (newCurrentId == sessionId) {
      newCurrentId = updatedSessions.isNotEmpty ? updatedSessions.first.id : null;
    }

    state = state.copyWith(
      sessions: updatedSessions,
      currentSessionId: newCurrentId,
    );
    
    _historyService.saveSessions(updatedSessions);
    
    if (updatedSessions.isEmpty) {
      createNewSession();
    }
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

    final currentSession = state.currentSession;
    if (currentSession == null) return;

    final updatedMessages = [
      ...currentSession.messages,
      ChatMessage(
        id: _uuid.v4(),
        text: trimmed,
        role: ChatRole.user,
      ),
    ];

    // Update session title if it's the first message
    String updatedTitle = currentSession.title;
    if (currentSession.messages.isEmpty) {
      updatedTitle = trimmed.length > 20 ? '${trimmed.substring(0, 20)}...' : trimmed;
    }

    final updatedSession = currentSession.copyWith(
      messages: updatedMessages,
      title: updatedTitle,
    );

    final updatedSessions = state.sessions.map((s) => s.id == updatedSession.id ? updatedSession : s).toList();

    state = state.copyWith(
      conversationState: ConversationState.thinking,
      liveText: trimmed,
      sessions: updatedSessions,
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

      final finalSession = updatedSession.copyWith(messages: withReply);
      final finalSessions = state.sessions.map((s) => s.id == finalSession.id ? finalSession : s).toList();

      state = state.copyWith(
        conversationState: ConversationState.speaking,
        liveText: aiResult.replyText,
        feedback: aiResult,
        sessions: finalSessions,
      );

      await _ttsService.speak(aiResult.replyText);

      state = state.copyWith(
        conversationState: ConversationState.feedback,
        feedback: aiResult,
        sessions: finalSessions,
      );
      
      _historyService.saveSessions(finalSessions);

    } catch (_) {
      _setError('응답을 처리하는 중 문제가 생겼어요. 잠시 후 다시 시도해 주세요.');
      state = state.copyWith(conversationState: ConversationState.idle);
    }
  }

  void _setError(String message) {
    state = state.copyWith(errorMessage: message);
  }
}

