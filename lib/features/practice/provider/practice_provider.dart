import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../services/api/ai_service.dart';
import '../../../services/audio/audio_player_service.dart';
import '../../../services/audio/audio_recorder_service.dart';
import '../../../services/audio/stt_service.dart';
import '../../../services/practice_content_service.dart';
import '../../../services/practice_history_service.dart';
import '../model/practice_mode.dart';

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
  final String sessionGoal;
  final int fatigueBefore;
  final int? fatigueAfter;
  final PracticeMode mode;
  final int currentItemIndex;
  final int retryCount;
  final int streakCount;
  final String? contentId;
  final String category;
  final int difficulty;
  final PracticeContentSource contentSource;
  final bool isReviewMode;

  PracticeProgress({
    required this.state,
    required this.targetText,
    this.spokenText = '',
    this.feedback,
    this.lastAudioPath,
    this.history = const [],
    this.isFreeMode = false,
    this.isPlaying = false,
    this.sessionGoal = '또렷하게 말하기',
    this.fatigueBefore = 1,
    this.fatigueAfter,
    this.mode = PracticeMode.shortSentence,
    this.currentItemIndex = 0,
    this.retryCount = 0,
    this.streakCount = 0,
    this.contentId,
    this.category = '일반',
    this.difficulty = 1,
    this.contentSource = PracticeContentSource.builtIn,
    this.isReviewMode = false,
  });

  PracticeProgress copyWith({
    PracticeState? state,
    String? targetText,
    String? spokenText,
    AiResponse? feedback,
    bool clearFeedback = false,
    String? lastAudioPath,
    bool clearLastAudioPath = false,
    List<PracticeSession>? history,
    bool? isFreeMode,
    bool? isPlaying,
    String? sessionGoal,
    int? fatigueBefore,
    int? fatigueAfter,
    bool clearFatigueAfter = false,
    PracticeMode? mode,
    int? currentItemIndex,
    int? retryCount,
    int? streakCount,
    String? contentId,
    bool clearContentId = false,
    String? category,
    int? difficulty,
    PracticeContentSource? contentSource,
    bool? isReviewMode,
  }) {
    return PracticeProgress(
      state: state ?? this.state,
      targetText: targetText ?? this.targetText,
      spokenText: spokenText ?? this.spokenText,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      lastAudioPath: clearLastAudioPath
          ? null
          : (lastAudioPath ?? this.lastAudioPath),
      history: history ?? this.history,
      isFreeMode: isFreeMode ?? this.isFreeMode,
      isPlaying: isPlaying ?? this.isPlaying,
      sessionGoal: sessionGoal ?? this.sessionGoal,
      fatigueBefore: fatigueBefore ?? this.fatigueBefore,
      fatigueAfter: clearFatigueAfter
          ? null
          : (fatigueAfter ?? this.fatigueAfter),
      mode: mode ?? this.mode,
      currentItemIndex: currentItemIndex ?? this.currentItemIndex,
      retryCount: retryCount ?? this.retryCount,
      streakCount: streakCount ?? this.streakCount,
      contentId: clearContentId ? null : (contentId ?? this.contentId),
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      contentSource: contentSource ?? this.contentSource,
      isReviewMode: isReviewMode ?? this.isReviewMode,
    );
  }
}

final practiceHistoryServiceProvider = Provider(
  (ref) => PracticeHistoryService(),
);

final practiceProvider = NotifierProvider<PracticeNotifier, PracticeProgress>(
  PracticeNotifier.new,
);

class PracticeNotifier extends Notifier<PracticeProgress> {
  AudioRecorderService get audioRecorder =>
      ref.watch(audioRecorderServiceProvider);
  AudioPlayerService get audioPlayer => ref.watch(audioPlayerServiceProvider);
  SttService get sttService => ref.watch(sttServiceProvider);
  AiService get aiService => ref.read(aiServiceProvider);
  PracticeHistoryService get historyService =>
      ref.watch(practiceHistoryServiceProvider);
  PracticeContentService get contentService =>
      ref.watch(practiceContentServiceProvider);
  CustomPracticeContentService get customContentService =>
      ref.watch(customPracticeContentServiceProvider);

  List<PracticeContentItem> _currentItems = [];

  @override
  PracticeProgress build() {
    _init();
    return PracticeProgress(
      state: PracticeState.idle,
      targetText: '물을 마시고 싶어요.',
    );
  }

  Future<void> _init() async {
    _currentItems = await _loadItemsForMode(PracticeMode.shortSentence);
    final history = await historyService.loadPractices();

    // Listen for audio completion to reset isPlaying state
    audioPlayer.onPlaybackComplete(() {
      state = state.copyWith(isPlaying: false);
    });

    state = state.copyWith(
      history: history,
      targetText: _currentItems.isNotEmpty
          ? _currentItems[0].text
          : state.targetText,
      contentId: _currentItems.isNotEmpty ? _currentItems[0].id : null,
      category: _currentItems.isNotEmpty ? _currentItems[0].category : '일반',
      difficulty: _currentItems.isNotEmpty ? _currentItems[0].difficulty : 1,
      contentSource: _currentItems.isNotEmpty
          ? _currentItems[0].source
          : PracticeContentSource.builtIn,
      isReviewMode: false,
    );
  }

  void toggleFreeMode() {
    setMode(
      state.isFreeMode ? PracticeMode.shortSentence : PracticeMode.freeSpeech,
    );
  }

  void dismissFeedback() {
    state = state.copyWith(
      state: PracticeState
          .idle, // Return to idle so user can practice again immediately
      clearFeedback: true,
      spokenText: '',
      isPlaying: false,
      clearFatigueAfter: true,
    );
    audioPlayer.stop(); // Ensure any feedback audio or recording playback stops
  }

  void nextItem() {
    if (state.isFreeMode || _currentItems.isEmpty) return;
    final nextIndex = (state.currentItemIndex + 1) % _currentItems.length;
    _setCurrentItem(nextIndex);
  }

  void nextSentence() {
    nextItem();
  }

  void resetPractice() {
    state = state.copyWith(
      state: PracticeState.idle,
      spokenText: '',
      feedback: null,
      clearFatigueAfter: true,
    );
  }

  void setTargetText(String text) {
    state = state.copyWith(
      targetText: text,
      isFreeMode: false,
      mode: PracticeMode.shortSentence,
      state: PracticeState.idle,
      spokenText: '',
      feedback: null,
      lastAudioPath: null,
      clearFatigueAfter: true,
      clearContentId: true,
      category: '직접 입력',
      difficulty: 1,
      retryCount: 0,
      isReviewMode: false,
    );
  }

  Future<void> setMode(PracticeMode mode) async {
    final isFreeSpeech = mode == PracticeMode.freeSpeech;
    _currentItems = isFreeSpeech ? [] : await _loadItemsForMode(mode);
    final firstItem = _currentItems.isEmpty ? null : _currentItems.first;

    state = state.copyWith(
      mode: mode,
      isFreeMode: isFreeSpeech,
      targetText: isFreeSpeech ? '' : firstItem?.text ?? state.targetText,
      currentItemIndex: 0,
      retryCount: 0,
      streakCount: 0,
      spokenText: '',
      state: PracticeState.idle,
      clearFeedback: true,
      clearLastAudioPath: true,
      clearFatigueAfter: true,
      contentId: firstItem?.id,
      clearContentId: firstItem == null,
      category: isFreeSpeech ? '자유 말하기' : firstItem?.category ?? '일반',
      difficulty: firstItem?.difficulty ?? 1,
      contentSource: firstItem?.source ?? PracticeContentSource.builtIn,
      isReviewMode: false,
    );
  }

  bool startFailedWordReview() {
    final reviewItems = contentService.getFailedWordReviewItems(state.history);
    if (reviewItems.isEmpty) {
      return false;
    }

    _currentItems = reviewItems;
    final firstItem = _currentItems.first;
    state = state.copyWith(
      mode: PracticeMode.wordGame,
      isFreeMode: false,
      targetText: firstItem.text,
      currentItemIndex: 0,
      retryCount: 0,
      spokenText: '',
      state: PracticeState.idle,
      clearFeedback: true,
      clearLastAudioPath: true,
      clearFatigueAfter: true,
      contentId: firstItem.id,
      category: firstItem.category,
      difficulty: firstItem.difficulty,
      contentSource: firstItem.source,
      isReviewMode: true,
    );
    return true;
  }

  Future<List<PracticeContentItem>> _loadItemsForMode(PracticeMode mode) async {
    final builtInItems = contentService.getItems(mode);
    if (mode != PracticeMode.longSentence) {
      return builtInItems;
    }

    final customItems = await customContentService.loadLongSentences();
    return [...customItems, ...builtInItems];
  }

  void _setCurrentItem(int index) {
    final item = _currentItems[index];
    state = state.copyWith(
      targetText: item.text,
      currentItemIndex: index,
      retryCount: 0,
      spokenText: '',
      state: PracticeState.idle,
      clearFeedback: true,
      clearLastAudioPath: true,
      clearFatigueAfter: true,
      contentId: item.id,
      category: item.category,
      difficulty: item.difficulty,
      contentSource: item.source,
    );
  }

  Future<void> addCustomLongSentence({
    required String text,
    required String category,
  }) async {
    final item = await customContentService.addLongSentence(
      text: text,
      category: category,
    );
    await _refreshLongSentenceItems(selectContentId: item.id);
  }

  Future<void> updateCustomLongSentence({
    required String id,
    required String text,
    required String category,
  }) async {
    await customContentService.updateLongSentence(
      id: id,
      text: text,
      category: category,
    );
    await _refreshLongSentenceItems(selectContentId: id);
  }

  Future<void> deleteCustomLongSentence(String id) async {
    await customContentService.deleteLongSentence(id);
    await _refreshLongSentenceItems();
  }

  Future<List<PracticeContentItem>> loadCustomLongSentences() {
    return customContentService.loadLongSentences();
  }

  Future<void> _refreshLongSentenceItems({String? selectContentId}) async {
    if (state.mode != PracticeMode.longSentence) {
      return;
    }

    _currentItems = await _loadItemsForMode(PracticeMode.longSentence);
    if (_currentItems.isEmpty) {
      return;
    }

    final selectedIndex = selectContentId == null
        ? state.currentItemIndex.clamp(0, _currentItems.length - 1)
        : _currentItems.indexWhere((item) => item.id == selectContentId);
    _setCurrentItem(selectedIndex == -1 ? 0 : selectedIndex);
  }

  void setSessionGoal(String goal) {
    state = state.copyWith(sessionGoal: goal);
  }

  void setFatigueBefore(int value) {
    state = state.copyWith(fatigueBefore: value);
  }

  void setFatigueAfter(int value) {
    state = state.copyWith(fatigueAfter: value);
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
      clearFeedback: true,
      clearFatigueAfter: true,
    );

    _tempSpokenText = '';
    _recordingStartTime = DateTime.now();
    final fileName = 'practice_${DateTime.now().millisecondsSinceEpoch}';

    // Start STT first to let it configure the audio session
    await sttService.startListening(
      onResult: (text, isFinal) async {
        _tempSpokenText = text;
        state = state.copyWith(spokenText: text);
      },
    );

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
        await Future.delayed(
          Duration(milliseconds: 500 - elapsed.inMilliseconds),
        );
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
    if (defaultTargetPlatform == TargetPlatform.macOS &&
        finalSpokenText.isEmpty) {
      debugPrint('macOS detected: Simulating transcription for testing.');
      finalSpokenText = state.isFreeMode
          ? '오늘 날씨가 정말 정겹고 화창하네요.'
          : state.targetText;
    }

    state = state.copyWith(spokenText: finalSpokenText);

    if (audioFile == null) {
      debugPrint('Error: Audio file is null.');
      state = state.copyWith(state: PracticeState.error);
      return;
    }

    debugPrint('Starting practice analysis for: ${state.mode.label}');
    late final AiResponse feedback;
    try {
      feedback = await aiService.evaluatePracticeByMode(
        mode: state.mode,
        targetText: state.targetText,
        spokenText: finalSpokenText,
        durationSeconds: _recordingStartTime == null
            ? 0
            : DateTime.now().difference(_recordingStartTime!).inSeconds,
      );
      debugPrint('Practice analysis completed successfully.');
    } catch (e) {
      debugPrint('Gemma 4 Analysis failed with exception: $e');
      feedback = await aiService.evaluatePracticeByMode(
        mode: state.mode,
        targetText: state.targetText,
        spokenText: finalSpokenText,
        durationSeconds: _recordingStartTime == null
            ? 0
            : DateTime.now().difference(_recordingStartTime!).inSeconds,
      );
    }

    final previousBestScore = _previousBestScore();
    final nextRetryCount = feedback.pronunciationScore >= 70
        ? state.retryCount
        : state.retryCount + 1;
    final nextStreakCount = feedback.pronunciationScore >= 80
        ? state.streakCount + 1
        : 0;

    final session = PracticeSession(
      id: const Uuid().v4(),
      targetText: state.isFreeMode ? '자유 읽기' : state.targetText,
      spokenText: finalSpokenText,
      audioFilePath: audioFile,
      score: feedback.pronunciationScore,
      feedback: feedback.pronunciationFeedback,
      phonemeAccuracy: feedback.phonemeAccuracy
          ?.map(
            (e) => {'phoneme': e.phoneme, 'score': e.score, 'issue': e.issue},
          )
          .toList(),
      intonationFeedback: feedback.intonationFeedback,
      timestamp: DateTime.now(),
      sessionGoal: state.sessionGoal,
      fatigueBefore: state.fatigueBefore,
      fatigueAfter: state.fatigueAfter ?? state.fatigueBefore,
      durationSeconds: _recordingStartTime == null
          ? 0
          : DateTime.now().difference(_recordingStartTime!).inSeconds,
      mode: state.mode.storageValue,
      contentId: state.contentId,
      category: state.category,
      difficulty: state.difficulty,
      retryCount: nextRetryCount,
      streakCount: nextStreakCount,
      previousBestScore: previousBestScore,
      contentSource: state.contentSource.storageValue,
    );

    debugPrint('Saving practice history...');
    await historyService.savePractice(session);
    final updatedHistory = await historyService.loadPractices();

    state = state.copyWith(
      state: PracticeState.completed,
      feedback: feedback,
      lastAudioPath: audioFile,
      history: updatedHistory,
      retryCount: nextRetryCount,
      streakCount: nextStreakCount,
    );
  }

  int? _previousBestScore() {
    final contentId = state.contentId;
    if (contentId == null) {
      return null;
    }

    final matchingScores = state.history
        .where((session) => session.contentId == contentId)
        .map((session) => session.score)
        .toList();
    if (matchingScores.isEmpty) {
      return null;
    }
    matchingScores.sort();
    return matchingScores.last;
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

  Future<void> shareRecording() async {
    if (state.lastAudioPath != null) {
      final file = XFile(state.lastAudioPath!);
      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          text: '내 발음 연습 녹음 파일입니다: "${state.targetText}"',
        ),
      );
    }
  }
}
