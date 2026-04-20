import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../services/api/ai_service.dart';
import '../../../services/audio/audio_player_service.dart';
import '../../../services/audio/audio_recorder_service.dart';
import '../../../services/audio/stt_service.dart';
import '../../../services/practice_history_service.dart';
import '../../../services/practice_sentence_service.dart';

enum PracticeState { idle, recording, analyzing, completed, error }

class PracticeProgress {
  final PracticeState state;
  final String targetText;
  final String spokenText;
  final AiResponse? feedback;
  final String? lastAudioPath;
  final List<PracticeSession> history;
  final bool isFreeMode;

  PracticeProgress({
    required this.state,
    required this.targetText,
    this.spokenText = '',
    this.feedback,
    this.lastAudioPath,
    this.history = const [],
    this.isFreeMode = false,
  });

  PracticeProgress copyWith({
    PracticeState? state,
    String? targetText,
    String? spokenText,
    AiResponse? feedback,
    String? lastAudioPath,
    List<PracticeSession>? history,
    bool? isFreeMode,
  }) {
    return PracticeProgress(
      state: state ?? this.state,
      targetText: targetText ?? this.targetText,
      spokenText: spokenText ?? this.spokenText,
      feedback: feedback ?? this.feedback,
      lastAudioPath: lastAudioPath ?? this.lastAudioPath,
      history: history ?? this.history,
      isFreeMode: isFreeMode ?? this.isFreeMode,
    );
  }
}

final practiceHistoryServiceProvider = Provider((ref) => PracticeHistoryService());

final practiceProvider =
    NotifierProvider<PracticeNotifier, PracticeProgress>(PracticeNotifier.new);

class PracticeNotifier extends Notifier<PracticeProgress> {
  AudioRecorderService get audioRecorder => ref.watch(audioRecorderServiceProvider);
  AudioPlayerService get audioPlayer => ref.watch(audioPlayerServiceProvider);
  SttService get sttService => ref.watch(sttServiceProvider);
  AiService get aiService => ref.read(aiServiceProvider);
  PracticeHistoryService get historyService => ref.watch(practiceHistoryServiceProvider);
  PracticeSentenceService get sentenceService => ref.watch(practiceSentenceServiceProvider);

  List<String> _sentencesList = [];

  @override
  PracticeProgress build() {
    _init();
    return PracticeProgress(
      state: PracticeState.idle,
      targetText: '꾸준한 연습만이 올바른 발음을 만드는 비결입니다.',
    );
  }

  Future<void> _init() async {
    _sentencesList = await sentenceService.getRecommendedSentences();
    final history = await historyService.loadPractices();
    state = state.copyWith(
      history: history,
      targetText:
          _sentencesList.isNotEmpty ? _sentencesList[0] : state.targetText,
    );
  }

  void toggleFreeMode() {
    final newFreeMode = !state.isFreeMode;
    state = state.copyWith(
      isFreeMode: newFreeMode,
      targetText: newFreeMode ? '' : (_sentencesList.isNotEmpty ? _sentencesList[0] : '꾸준한 연습만이 올바른 발음을 만드는 비결입니다.'),
      feedback: null,
      spokenText: '',
      state: PracticeState.idle,
    );
  }

  void nextSentence() {
    if (state.isFreeMode || _sentencesList.isEmpty) return;
    final currentIndex = _sentencesList.indexOf(state.targetText);
    final nextIndex = (currentIndex + 1) % _sentencesList.length;
    setTargetText(_sentencesList[nextIndex]);
  }

  void setTargetText(String text) {
    state = state.copyWith(
      targetText: text,
      isFreeMode: false,
      state: PracticeState.idle,
      spokenText: '',
      feedback: null,
      lastAudioPath: null,
    );
  }

  String _tempSpokenText = '';

  Future<void> startRecording() async {
    if (state.state == PracticeState.recording) return;

    final hasPermission = await audioRecorder.hasPermission();
    if (!hasPermission) {
      state = state.copyWith(state: PracticeState.error);
      return;
    }

    state = state.copyWith(
      state: PracticeState.recording,
      spokenText: '',
      feedback: null,
    );

    _tempSpokenText = '';
    final fileName = 'practice_${DateTime.now().millisecondsSinceEpoch}';
    await audioRecorder.startRecording(fileName);

    await sttService.startListening(onResult: (text, isFinal) async {
      _tempSpokenText = text;
      // Not updating state.spokenText here to hide live STT
    });
  }

  Future<void> stopRecording() async {
    if (state.state != PracticeState.recording) return;

    state = state.copyWith(
      state: PracticeState.analyzing,
      spokenText: _tempSpokenText, // Show the full text now
    );

    await sttService.stopListening();
    final audioFile = await audioRecorder.stopRecording();

    if (audioFile == null) {
      state = state.copyWith(state: PracticeState.error);
      return;
    }

    final feedback = state.isFreeMode 
      ? await aiService.getFreeReadingFeedback(_tempSpokenText)
      : await aiService.getReadingFeedback(state.targetText, _tempSpokenText);

    final session = PracticeSession(
      id: const Uuid().v4(),
      targetText: state.isFreeMode ? '자유 읽기' : state.targetText,
      spokenText: state.spokenText,
      audioFilePath: audioFile,
      score: feedback.pronunciationScore,
      feedback: feedback.pronunciationFeedback,
      timestamp: DateTime.now(),
    );

    await historyService.savePractice(session);
    final updatedHistory = await historyService.loadPractices();

    state = state.copyWith(
      state: PracticeState.completed,
      feedback: feedback,
      lastAudioPath: audioFile,
      history: updatedHistory,
    );
  }

  Future<void> playRecording(String? path) async {
    final filePath = path ?? state.lastAudioPath;
    if (filePath != null) {
      await audioPlayer.playFile(filePath);
    }
  }
}
