import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/services/api/ai_service.dart';
import 'package:speech_rehab/services/audio/stt_service.dart';
import 'package:speech_rehab/services/audio/tts_service.dart';
import 'package:speech_rehab/services/history_service.dart';
import 'package:speech_rehab/services/video/mouth_video_recorder_service.dart';
import 'package:uuid/uuid.dart';

enum ConversationState { idle, listening, thinking, speaking, feedback }

enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.role,
    this.pronunciationScore,
    this.pronunciationFeedback,
    this.mouthVideoPath,
    this.inputMethod = 'text',
    this.evaluationMethod = 'notAssessed',
    this.evaluationVersion = 'chat-text-v1',
  });

  final String id;
  final String text;
  final ChatRole role;
  final int? pronunciationScore;
  final String? pronunciationFeedback;
  final String? mouthVideoPath;
  final String inputMethod;
  final String evaluationMethod;
  final String evaluationVersion;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'role': role.name,
    'pronunciationScore': pronunciationScore,
    'pronunciationFeedback': pronunciationFeedback,
    'mouthVideoPath': mouthVideoPath,
    'inputMethod': inputMethod,
    'evaluationMethod': evaluationMethod,
    'evaluationVersion': evaluationVersion,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    text: json['text'],
    role: ChatRole.values.byName(json['role']),
    pronunciationScore: json['pronunciationScore'],
    pronunciationFeedback: json['pronunciationFeedback'],
    mouthVideoPath: json['mouthVideoPath'] as String?,
    inputMethod: json['inputMethod'] as String? ?? 'unknown',
    evaluationMethod: json['evaluationMethod'] as String? ?? 'legacy',
    evaluationVersion: json['evaluationVersion'] as String? ?? 'legacy',
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

  ChatSession copyWith({String? title, List<ChatMessage>? messages}) {
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
    this.mouthVideoEnabled = false,
    this.isMouthVideoReady = false,
    this.isMouthVideoRecording = false,
    this.lastMouthVideoPath,
    this.mouthVideoError,
  });

  final String? currentSessionId;
  final List<ChatSession> sessions;
  final ConversationState conversationState;
  final String liveText;
  final AiResponse? feedback;
  final String? errorMessage;
  final bool mouthVideoEnabled;
  final bool isMouthVideoReady;
  final bool isMouthVideoRecording;
  final String? lastMouthVideoPath;
  final String? mouthVideoError;

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
    bool? mouthVideoEnabled,
    bool? isMouthVideoReady,
    bool? isMouthVideoRecording,
    String? lastMouthVideoPath,
    bool clearLastMouthVideoPath = false,
    String? mouthVideoError,
    bool clearMouthVideoError = false,
  }) {
    return ChatSessionState(
      currentSessionId: currentSessionId ?? this.currentSessionId,
      sessions: sessions ?? this.sessions,
      conversationState: conversationState ?? this.conversationState,
      liveText: liveText ?? this.liveText,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      mouthVideoEnabled: mouthVideoEnabled ?? this.mouthVideoEnabled,
      isMouthVideoReady: isMouthVideoReady ?? this.isMouthVideoReady,
      isMouthVideoRecording:
          isMouthVideoRecording ?? this.isMouthVideoRecording,
      lastMouthVideoPath: clearLastMouthVideoPath
          ? null
          : (lastMouthVideoPath ?? this.lastMouthVideoPath),
      mouthVideoError: clearMouthVideoError
          ? null
          : (mouthVideoError ?? this.mouthVideoError),
    );
  }
}

final historyServiceProvider = Provider<HistoryService>(
  (ref) => HistoryService(),
);

final chatControllerProvider =
    NotifierProvider<ChatController, ChatSessionState>(ChatController.new);

class ChatController extends Notifier<ChatSessionState> {
  final Uuid _uuid = const Uuid();

  AiService get _aiService => ref.read(aiServiceProvider);
  SttService get _sttService => ref.read(sttServiceProvider);
  TtsService get _ttsService => ref.read(ttsServiceProvider);
  HistoryService get _historyService => ref.read(historyServiceProvider);
  MouthVideoRecorderService get _mouthVideoRecorder =>
      ref.read(mouthVideoRecorderServiceProvider);
  CameraController? get mouthVideoController => _mouthVideoRecorder.controller;

  String? _mouthVideoFileName;
  int _conversationEpoch = 0;
  Future<void>? _listeningStartFuture;
  Future<void>? _endingFuture;
  bool _ending = false;

  bool _isCurrent(int epoch) => ref.mounted && epoch == _conversationEpoch;

  /// Stops capture and speech, and ignores responses from the ended turn.
  Future<void> endConversation() async {
    final pending = _endingFuture;
    if (pending != null) return pending;
    final ending = _endConversation();
    _endingFuture = ending;
    try {
      await ending;
    } finally {
      _endingFuture = null;
      _ending = false;
    }
  }

  Future<void> _endConversation() async {
    _ending = true;
    _conversationEpoch++;
    state = state.copyWith(
      conversationState: ConversationState.idle,
      liveText: '',
      clearFeedback: true,
    );
    // Stop TTS promptly, without waiting for a pending microphone permission.
    try {
      await _ttsService.stop();
    } catch (_) {}
    try {
      await _listeningStartFuture;
    } catch (_) {}
    if (!ref.mounted) return;
    try {
      await _sttService.stopListening();
    } catch (_) {}
    if (!ref.mounted) return;
    try {
      await _stopMouthVideoIfNeeded();
    } catch (_) {}
    if (!ref.mounted) return;
    await _historyService.saveSessions(state.sessions);
  }

  @override
  ChatSessionState build() {
    final sttService = _sttService;
    final ttsService = _ttsService;
    final mouthVideoRecorder = _mouthVideoRecorder;

    ref.onDispose(() {
      sttService.dispose();
      ttsService.dispose();
      mouthVideoRecorder.dispose();
    });

    // Load history on initialization
    _loadHistory();

    return const ChatSessionState();
  }

  Future<void> _loadHistory() async {
    final sessions = await _historyService.loadSessions();
    if (!ref.mounted) return;
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
      clearLastMouthVideoPath: true,
      clearMouthVideoError: true,
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
      clearLastMouthVideoPath: true,
      clearMouthVideoError: true,
    );
  }

  Future<void> setMouthVideoEnabled(bool enabled) async {
    if (!enabled) {
      await _stopMouthVideoIfNeeded();
      state = state.copyWith(
        mouthVideoEnabled: false,
        isMouthVideoRecording: false,
        clearMouthVideoError: true,
      );
      return;
    }

    state = state.copyWith(clearMouthVideoError: true);
    final ready = await _mouthVideoRecorder.initialize();
    state = state.copyWith(
      mouthVideoEnabled: ready,
      isMouthVideoReady: ready,
      mouthVideoError: ready ? null : '카메라를 사용할 수 없습니다.',
      clearMouthVideoError: ready,
    );
  }

  void deleteSession(String sessionId) {
    final updatedSessions = state.sessions
        .where((s) => s.id != sessionId)
        .toList();
    String? newCurrentId = state.currentSessionId;

    if (newCurrentId == sessionId) {
      newCurrentId = updatedSessions.isNotEmpty
          ? updatedSessions.first.id
          : null;
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
    if (!isVoiceSupported || _ending) {
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

  Future<void> submitText(String text, {String inputMethod = 'text'}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isProcessing || _ending) {
      return;
    }

    await _processInput(trimmed, inputMethod: inputMethod);
  }

  Future<void> stopListeningAndSubmit() async {
    if (_ending || state.conversationState != ConversationState.listening) {
      return;
    }

    final epoch = _conversationEpoch;
    state = state.copyWith(conversationState: ConversationState.thinking);
    await _listeningStartFuture;
    if (!_isCurrent(epoch)) return;
    await _sttService.stopListening();
    if (!_isCurrent(epoch)) return;
    final spokenText = state.liveText.trim();

    if (spokenText.isEmpty) {
      await _stopMouthVideoIfNeeded();
      if (!_isCurrent(epoch)) return;
      state = state.copyWith(
        conversationState: ConversationState.idle,
        liveText: '',
        clearFeedback: true,
      );
      return;
    }

    state = state.copyWith(conversationState: ConversationState.idle);
    await _processInput(spokenText, inputMethod: 'voice');
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
    if (_ending || _listeningStartFuture != null) return;
    final starting = _runStartListening();
    _listeningStartFuture = starting;
    try {
      await starting;
    } finally {
      _listeningStartFuture = null;
    }
  }

  Future<void> _runStartListening() async {
    final epoch = _conversationEpoch;
    state = state.copyWith(
      conversationState: ConversationState.listening,
      liveText: '',
      clearFeedback: true,
      clearError: true,
      clearLastMouthVideoPath: true,
      clearMouthVideoError: true,
    );

    if (state.mouthVideoEnabled) {
      _mouthVideoFileName = 'chat_${DateTime.now().millisecondsSinceEpoch}';
      final started = await _mouthVideoRecorder.startRecording(
        _mouthVideoFileName!,
      );
      if (!_isCurrent(epoch)) return;
      state = state.copyWith(
        isMouthVideoReady: started || _mouthVideoRecorder.isReady,
        isMouthVideoRecording: started,
        mouthVideoError: started ? null : '입모양 영상 녹화를 시작하지 못했습니다.',
        clearMouthVideoError: started,
      );
    }

    final initialized = await _sttService.init();
    if (!_isCurrent(epoch)) return;
    if (!initialized) {
      await _stopMouthVideoIfNeeded();
      if (!_isCurrent(epoch)) return;
      _setError('음성 인식을 시작할 수 없어요. 권한과 기기 설정을 확인해 주세요.');
      state = state.copyWith(conversationState: ConversationState.idle);
      return;
    }

    final didStart = await _sttService.startListening(
      onResult: (text, isFinal) async {
        if (!_isCurrent(epoch)) return;
        state = state.copyWith(liveText: text);
        if (isFinal && state.conversationState == ConversationState.listening) {
          await _processInput(text.trim(), fromVoiceInput: true);
        }
      },
    );
    if (!_isCurrent(epoch)) return;

    if (!didStart) {
      await _stopMouthVideoIfNeeded();
      if (!_isCurrent(epoch)) return;
      _setError('음성 인식을 사용할 수 없는 상태예요. 잠시 후 다시 시도해 주세요.');
      state = state.copyWith(conversationState: ConversationState.idle);
    }
  }

  Future<void> _processInput(
    String text, {
    bool fromVoiceInput = false,
    String inputMethod = 'text',
  }) async {
    if (state.isProcessing || _ending) return;
    final epoch = _conversationEpoch;
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        conversationState: ConversationState.idle,
        liveText: '',
      );
      return;
    }

    state = state.copyWith(conversationState: ConversationState.thinking);
    if (fromVoiceInput) {
      await _sttService.stopListening();
      if (!_isCurrent(epoch)) return;
    }
    final mouthVideoPath = await _stopMouthVideoIfNeeded();
    if (!_isCurrent(epoch)) return;

    final currentSession = state.currentSession;
    if (currentSession == null) return;

    final updatedMessages = [
      ...currentSession.messages,
      ChatMessage(
        id: _uuid.v4(),
        text: trimmed,
        role: ChatRole.user,
        mouthVideoPath: mouthVideoPath,
        inputMethod: fromVoiceInput ? 'voice' : inputMethod,
      ),
    ];

    // Update session title if it's the first message
    String updatedTitle = currentSession.title;
    if (currentSession.messages.isEmpty) {
      updatedTitle = trimmed.length > 20
          ? '${trimmed.substring(0, 20)}...'
          : trimmed;
    }

    final updatedSession = currentSession.copyWith(
      messages: updatedMessages,
      title: updatedTitle,
    );

    final updatedSessions = state.sessions
        .map((s) => s.id == updatedSession.id ? updatedSession : s)
        .toList();

    state = state.copyWith(
      conversationState: ConversationState.thinking,
      liveText: trimmed,
      sessions: updatedSessions,
      clearFeedback: true,
      clearError: true,
      lastMouthVideoPath: mouthVideoPath,
      clearLastMouthVideoPath: mouthVideoPath == null,
    );

    try {
      final aiResult = await _aiService.getResponseAndFeedback(trimmed);
      if (!_isCurrent(epoch)) return;

      final withReply = [
        ...updatedMessages,
        ChatMessage(
          id: _uuid.v4(),
          text: aiResult.replyText,
          role: ChatRole.assistant,
          pronunciationScore: aiResult.pronunciationScore,
          evaluationMethod: aiResult.evaluationMethod,
          evaluationVersion: aiResult.evaluationVersion,
          pronunciationFeedback: aiResult.pronunciationFeedback,
        ),
      ];

      final finalSession = updatedSession.copyWith(messages: withReply);
      final finalSessions = state.sessions
          .map((s) => s.id == finalSession.id ? finalSession : s)
          .toList();

      state = state.copyWith(
        conversationState: ConversationState.speaking,
        liveText: aiResult.replyText,
        feedback: aiResult,
        sessions: finalSessions,
      );

      await _historyService.saveSessions(finalSessions);
      if (!_isCurrent(epoch)) return;
      try {
        await _ttsService.speak(aiResult.replyText);
      } catch (_) {
        // The written reply remains usable when speech output is unavailable.
      }
      if (!_isCurrent(epoch)) return;

      state = state.copyWith(
        conversationState: ConversationState.feedback,
        feedback: aiResult,
        sessions: finalSessions,
      );
    } catch (_) {
      if (!_isCurrent(epoch)) return;
      _setError('응답을 처리하는 중 문제가 생겼어요. 잠시 후 다시 시도해 주세요.');
      state = state.copyWith(conversationState: ConversationState.idle);
    }
  }

  void _setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  Future<String?> _stopMouthVideoIfNeeded() async {
    if (!state.isMouthVideoRecording && !_mouthVideoRecorder.isRecording) {
      return null;
    }

    final path = await _mouthVideoRecorder.stopRecording(
      _mouthVideoFileName ?? 'chat_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (!ref.mounted) return path;
    state = state.copyWith(
      isMouthVideoRecording: false,
      lastMouthVideoPath: path,
      mouthVideoError: path == null ? '입모양 영상 저장에 실패했습니다.' : null,
      clearMouthVideoError: path != null,
    );
    return path;
  }
}
