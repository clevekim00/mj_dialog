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
  final bool isPlaying;

  PracticeProgress({
    required this.state,
    required this.targetText,
    this.spokenText = '',
    this.feedback,
    this.lastAudioPath,
    this.history = const [],
    this.isFreeMode = false,
    this.isPlaying = false,
  });

  PracticeProgress copyWith({
    PracticeState? state,
    String? targetText,
    String? spokenText,
    AiResponse? feedback,
    String? lastAudioPath,
    List<PracticeSession>? history,
    bool? isFreeMode,
    bool? isPlaying,
  }) {
    return PracticeProgress(
      state: state ?? this.state,
      targetText: targetText ?? this.targetText,
      spokenText: spokenText ?? this.spokenText,
      feedback: feedback ?? this.feedback,
      lastAudioPath: lastAudioPath ?? this.lastAudioPath,
      history: history ?? this.history,
      isFreeMode: isFreeMode ?? this.isFreeMode,
      isPlaying: isPlaying ?? this.isPlaying,
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
    
    // Listen for audio completion to reset isPlaying state
    audioPlayer.onPlaybackComplete(() {
      state = state.copyWith(isPlaying: false);
    });

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

  void dismissFeedback() {
    state = state.copyWith(
      state: PracticeState.idle, // Return to idle so user can practice again immediately
      feedback: null,
      spokenText: '',
      isPlaying: false,
    );
    audioPlayer.stop(); // Ensure any feedback audio or recording playback stops
  }

  void nextSentence() {
    if (state.isFreeMode || _sentencesList.isEmpty) return;
    final currentIndex = _sentencesList.indexOf(state.targetText);
    final nextIndex = (currentIndex + 1) % _sentencesList.length;
    setTargetText(_sentencesList[nextIndex]);
  }

  void resetPractice() {
    state = state.copyWith(
      state: PracticeState.idle,
      spokenText: '',
      feedback: null,
    );
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
  DateTime? _recordingStartTime;

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
    _recordingStartTime = DateTime.now();
    final fileName = 'practice_${DateTime.now().millisecondsSinceEpoch}';

    // Start STT first to let it configure the audio session
    await sttService.startListening(onResult: (text, isFinal) async {
      _tempSpokenText = text;
      state = state.copyWith(spokenText: text);
    });

    // Wait a bit for the audio session to stabilize before starting the high-quality recorder
    await Future.delayed(const Duration(milliseconds: 400));

    await audioRecorder.startRecording(fileName);
  }

  Future<void> stopRecording() async {
    if (state.state != PracticeState.recording) return;

    // Guard: Prevent stopping too fast
    if (_recordingStartTime != null) {
      final elapsed = DateTime.now().difference(_recordingStartTime!);
      if (elapsed.inMilliseconds < 500) {
        await Future.delayed(Duration(milliseconds: 500 - elapsed.inMilliseconds));
      }
    }

    state = state.copyWith(state: PracticeState.analyzing);

    // Stop the recorder and STT engine
    final audioFile = await audioRecorder.stopRecording();
    await sttService.stopListening();

    // Small delay to allow the STT engine to process the last audio chunk
    await Future.delayed(const Duration(milliseconds: 600));

    String finalSpokenText = _tempSpokenText;
    debugPrint('Final Transcription: "$finalSpokenText"');
    
    // On macOS, STT simulation
    if (defaultTargetPlatform == TargetPlatform.macOS && finalSpokenText.isEmpty) {
      debugPrint('macOS detected: Simulating transcription for testing.');
      finalSpokenText = state.isFreeMode ? '오늘 날씨가 정말 정겹고 화창하네요.' : state.targetText;
    }

    state = state.copyWith(
      spokenText: finalSpokenText,
    );

    if (audioFile == null) {
      debugPrint('Error: Audio file is null.');
      state = state.copyWith(state: PracticeState.error);
      return;
    }

    AiResponse feedback;
    if (audioFile == null) {
      debugPrint('Error: Audio file is null.');
      state = state.copyWith(state: PracticeState.error);
      return;
    }

    debugPrint('Starting Gemma 4 Multimodal Analysis for: ${state.isFreeMode ? "Free Reading" : "Sentence Practice"}');
    try {
      // Transitioning to native audio token processing with Gemma 4
      feedback = await aiService.evaluateAudio(audioFile, state.targetText);
      debugPrint('Gemma 4 Analysis Completed successfully.');
    } catch (e) {
      debugPrint('Gemma 4 Analysis failed with exception: $e');
      feedback = await aiService.getReadingFeedback(state.targetText, finalSpokenText);
    }

    final session = PracticeSession(
      id: const Uuid().v4(),
      targetText: state.isFreeMode ? '자유 읽기' : state.targetText,
      spokenText: finalSpokenText,
      audioFilePath: audioFile,
      score: feedback.pronunciationScore,
      feedback: feedback.pronunciationFeedback,
      phonemeAccuracy: feedback.phonemeAccuracy?.map((e) => {
        'phoneme': e.phoneme,
        'score': e.score,
        'issue': e.issue
      }).toList(),
      intonationFeedback: feedback.intonationFeedback,
      timestamp: DateTime.now(),
    );

    debugPrint('Saving practice history...');
    await historyService.savePractice(session);
    final updatedHistory = await historyService.loadPractices();

    state = state.copyWith(
      state: PracticeState.completed,
      feedback: feedback,
      lastAudioPath: audioFile,
      history: updatedHistory,
    );
  }

  Future<void> deleteSession(String id) async {
    await historyService.deletePractice(id);
    final updatedHistory = await historyService.loadPractices();
    state = state.copyWith(history: updatedHistory);
  }

  Future<void> playRecording(String? path) async {
    final filePath = path ?? state.lastAudioPath;
    if (filePath != null) {
      state = state.copyWith(isPlaying: true);
      try {
        await audioPlayer.playFile(filePath);
        // We could listen to playback completion here, but for now we reset on stop
      } catch (e) {
        debugPrint('Playback failed: $e');
        state = state.copyWith(isPlaying: false);
      }
    }
  }

  Future<void> stopPlayback() async {
    await audioPlayer.stop();
    state = state.copyWith(isPlaying: false);
  }
}
