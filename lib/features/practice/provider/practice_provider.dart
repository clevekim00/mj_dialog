import 'dart:async';
import 'dart:io';
import 'dart:math';
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

enum WordGameStatus { ready, running, gameOver }

class FallingWord {
  const FallingWord({
    required this.id,
    required this.item,
    required this.lane,
    required this.progress,
  });

  final String id;
  final PracticeContentItem item;
  final int lane;
  final double progress;

  FallingWord copyWith({double? progress}) {
    return FallingWord(
      id: id,
      item: item,
      lane: lane,
      progress: progress ?? this.progress,
    );
  }
}

class FailedWordReviewEntry {
  const FailedWordReviewEntry({
    required this.item,
    required this.failureCount,
    required this.latestFailedSession,
    this.latestAudioSession,
  });

  final PracticeContentItem item;
  final int failureCount;
  final PracticeSession latestFailedSession;
  final PracticeSession? latestAudioSession;

  String? get latestAudioPath {
    final path = latestAudioSession?.audioFilePath;
    if (path == null || path.isEmpty) {
      return null;
    }
    return path;
  }
}

class PracticeProgress {
  final PracticeState state;
  final String targetText;
  final String spokenText;
  final bool speechRecognitionUnavailable;
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
  final int wordGameDifficulty;
  final int movementScore;
  final bool isExercisePattern;
  final WordGameStatus wordGameStatus;
  final List<FallingWord> fallingWords;
  final int wordGameScore;
  final int wordGameHits;
  final int wordGameMisses;
  final String? wordGameFocusConsonant;
  final String? wordGameFocusVowel;

  PracticeProgress({
    required this.state,
    required this.targetText,
    this.spokenText = '',
    this.speechRecognitionUnavailable = false,
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
    this.wordGameDifficulty = 1,
    this.movementScore = 1,
    this.isExercisePattern = false,
    this.wordGameStatus = WordGameStatus.ready,
    this.fallingWords = const [],
    this.wordGameScore = 0,
    this.wordGameHits = 0,
    this.wordGameMisses = 0,
    this.wordGameFocusConsonant,
    this.wordGameFocusVowel,
  });

  PracticeProgress copyWith({
    PracticeState? state,
    String? targetText,
    String? spokenText,
    bool? speechRecognitionUnavailable,
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
    int? wordGameDifficulty,
    int? movementScore,
    bool? isExercisePattern,
    WordGameStatus? wordGameStatus,
    List<FallingWord>? fallingWords,
    int? wordGameScore,
    int? wordGameHits,
    int? wordGameMisses,
    String? wordGameFocusConsonant,
    bool clearWordGameFocusConsonant = false,
    String? wordGameFocusVowel,
    bool clearWordGameFocusVowel = false,
  }) {
    return PracticeProgress(
      state: state ?? this.state,
      targetText: targetText ?? this.targetText,
      spokenText: spokenText ?? this.spokenText,
      speechRecognitionUnavailable:
          speechRecognitionUnavailable ?? this.speechRecognitionUnavailable,
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
      wordGameDifficulty: wordGameDifficulty ?? this.wordGameDifficulty,
      movementScore: movementScore ?? this.movementScore,
      isExercisePattern: isExercisePattern ?? this.isExercisePattern,
      wordGameStatus: wordGameStatus ?? this.wordGameStatus,
      fallingWords: fallingWords ?? this.fallingWords,
      wordGameScore: wordGameScore ?? this.wordGameScore,
      wordGameHits: wordGameHits ?? this.wordGameHits,
      wordGameMisses: wordGameMisses ?? this.wordGameMisses,
      wordGameFocusConsonant: clearWordGameFocusConsonant
          ? null
          : (wordGameFocusConsonant ?? this.wordGameFocusConsonant),
      wordGameFocusVowel: clearWordGameFocusVowel
          ? null
          : (wordGameFocusVowel ?? this.wordGameFocusVowel),
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
  Timer? _wordGameTimer;
  int _wordGameTick = 0;
  int _fallingWordSequence = 0;
  final Random _wordGameRandom = Random();

  @override
  PracticeProgress build() {
    ref.onDispose(() {
      _wordGameTimer?.cancel();
    });
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
      movementScore: _currentItems.isNotEmpty
          ? _currentItems[0].movementScore
          : 1,
      isExercisePattern: _currentItems.isNotEmpty
          ? _currentItems[0].isExercisePattern
          : false,
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
      speechRecognitionUnavailable: false,
      isPlaying: false,
      clearFatigueAfter: true,
    );
    audioPlayer.stop(); // Ensure any feedback audio or recording playback stops
  }

  void nextItem() {
    if (state.isFreeMode || _currentItems.isEmpty) return;
    if (state.mode == PracticeMode.wordGame && !state.isReviewMode) {
      _setWeightedWordItem();
      return;
    }
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
      speechRecognitionUnavailable: false,
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
      speechRecognitionUnavailable: false,
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

  void practiceAgainFromSession(PracticeSession session) {
    _wordGameTimer?.cancel();
    final mode = PracticeModeLabel.fromStorageValue(session.mode);
    final isFreeSpeech = mode == PracticeMode.freeSpeech;

    state = state.copyWith(
      mode: mode,
      isFreeMode: isFreeSpeech,
      targetText: isFreeSpeech ? '' : session.targetText,
      currentItemIndex: 0,
      retryCount: session.retryCount,
      streakCount: session.streakCount,
      spokenText: '',
      speechRecognitionUnavailable: false,
      state: PracticeState.idle,
      clearFeedback: true,
      clearLastAudioPath: true,
      clearFatigueAfter: true,
      contentId: session.contentId,
      clearContentId: session.contentId == null,
      category: session.category,
      difficulty: session.difficulty,
      contentSource: PracticeContentSourceValue.fromStorageValue(
        session.contentSource,
      ),
      movementScore: session.movementScore,
      isExercisePattern: session.isExercisePattern,
      isReviewMode: false,
      wordGameStatus: WordGameStatus.ready,
      fallingWords: const [],
      wordGameScore: 0,
      wordGameHits: 0,
      wordGameMisses: 0,
    );
  }

  Future<void> setMode(PracticeMode mode) async {
    _wordGameTimer?.cancel();
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
      speechRecognitionUnavailable: false,
      state: PracticeState.idle,
      clearFeedback: true,
      clearLastAudioPath: true,
      clearFatigueAfter: true,
      contentId: firstItem?.id,
      clearContentId: firstItem == null,
      category: isFreeSpeech ? '자유 말하기' : firstItem?.category ?? '일반',
      difficulty: firstItem?.difficulty ?? 1,
      contentSource: firstItem?.source ?? PracticeContentSource.builtIn,
      movementScore: firstItem?.movementScore ?? 1,
      isExercisePattern: firstItem?.isExercisePattern ?? false,
      isReviewMode: false,
      wordGameStatus: WordGameStatus.ready,
      fallingWords: const [],
      wordGameScore: 0,
      wordGameHits: 0,
      wordGameMisses: 0,
    );
  }

  void setWordGameDifficulty(int value) {
    final nextDifficulty = value.clamp(1, 3);
    state = state.copyWith(wordGameDifficulty: nextDifficulty);
    if (state.mode == PracticeMode.wordGame &&
        !state.isReviewMode &&
        state.wordGameStatus != WordGameStatus.running) {
      _setWeightedWordItem();
    }
  }

  void setWordGameFocusConsonant(String? consonant) {
    state = state.copyWith(
      wordGameFocusConsonant: consonant,
      clearWordGameFocusConsonant: consonant == null,
    );
    if (state.mode == PracticeMode.wordGame &&
        !state.isReviewMode &&
        state.wordGameStatus != WordGameStatus.running) {
      _setWeightedWordItem();
    }
  }

  void setWordGameFocusVowel(String? vowel) {
    state = state.copyWith(
      wordGameFocusVowel: vowel,
      clearWordGameFocusVowel: vowel == null,
    );
    if (state.mode == PracticeMode.wordGame &&
        !state.isReviewMode &&
        state.wordGameStatus != WordGameStatus.running) {
      _setWeightedWordItem();
    }
  }

  void startFallingWordGame() {
    if (state.mode != PracticeMode.wordGame || _currentItems.isEmpty) {
      return;
    }

    _wordGameTimer?.cancel();
    _wordGameTick = 0;
    _fallingWordSequence = 0;
    state = state.copyWith(
      wordGameStatus: WordGameStatus.running,
      fallingWords: const [],
      wordGameScore: 0,
      wordGameHits: 0,
      wordGameMisses: 0,
      state: PracticeState.idle,
      clearFeedback: true,
      spokenText: '',
      speechRecognitionUnavailable: false,
    );
    _spawnFallingWord();
    _spawnFallingWord();
    _wordGameTimer = Timer.periodic(const Duration(milliseconds: 650), (_) {
      _tickFallingWordGame();
    });
  }

  void resetFallingWordGame() {
    _wordGameTimer?.cancel();
    state = state.copyWith(
      wordGameStatus: WordGameStatus.ready,
      fallingWords: const [],
      wordGameScore: 0,
      wordGameHits: 0,
      wordGameMisses: 0,
      state: PracticeState.idle,
      clearFeedback: true,
      spokenText: '',
      speechRecognitionUnavailable: false,
    );
  }

  bool startFailedWordReview() {
    _wordGameTimer?.cancel();
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
      speechRecognitionUnavailable: false,
      state: PracticeState.idle,
      clearFeedback: true,
      clearLastAudioPath: true,
      clearFatigueAfter: true,
      contentId: firstItem.id,
      category: firstItem.category,
      difficulty: firstItem.difficulty,
      contentSource: firstItem.source,
      movementScore: firstItem.movementScore,
      isExercisePattern: firstItem.isExercisePattern,
      isReviewMode: true,
      wordGameStatus: WordGameStatus.ready,
      fallingWords: const [],
      wordGameScore: 0,
      wordGameHits: 0,
      wordGameMisses: 0,
    );
    return true;
  }

  int failedWordReviewCount() {
    return contentService.getFailedWordReviewItems(state.history).length;
  }

  List<FailedWordReviewEntry> failedWordReviewEntries() {
    final wordSessions =
        state.history
            .where(
              (session) =>
                  session.mode == PracticeMode.wordGame.storageValue &&
                  session.contentId != null,
            )
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final sessionsByContentId = <String, List<PracticeSession>>{};
    for (final session in wordSessions) {
      sessionsByContentId
          .putIfAbsent(session.contentId!, () => [])
          .add(session);
    }

    final entries = <FailedWordReviewEntry>[];
    for (final entry in sessionsByContentId.entries) {
      final sessions = entry.value;
      final failures = sessions.where((session) => session.score < 70).toList();
      if (failures.isEmpty) {
        continue;
      }

      final recentTwo = sessions.take(2).toList();
      final hasRecovered =
          recentTwo.length == 2 &&
          recentTwo.every((session) => session.score >= 80);
      if (hasRecovered) {
        continue;
      }

      final item = contentService.getById(entry.key);
      if (item == null || item.mode != PracticeMode.wordGame) {
        continue;
      }

      final audioSessions = failures
          .where((session) => session.audioFilePath.isNotEmpty)
          .toList();
      entries.add(
        FailedWordReviewEntry(
          item: item,
          failureCount: failures.length,
          latestFailedSession: failures.first,
          latestAudioSession: audioSessions.isEmpty
              ? null
              : audioSessions.first,
        ),
      );
    }

    return entries;
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
      speechRecognitionUnavailable: false,
      state: PracticeState.idle,
      clearFeedback: true,
      clearLastAudioPath: true,
      clearFatigueAfter: true,
      contentId: item.id,
      category: item.category,
      difficulty: item.difficulty,
      contentSource: item.source,
      movementScore: item.movementScore,
      isExercisePattern: item.isExercisePattern,
    );
  }

  void _setWeightedWordItem() {
    if (_currentItems.isEmpty) {
      debugPrint('[WordGame] set target skipped: no current items');
      return;
    }
    final item = contentService.pickWeightedWord(
      items: _currentItems,
      history: state.history,
      difficultyLevel: state.wordGameDifficulty,
      currentContentId: state.contentId,
      excludedContentIds: state.contentId == null
          ? const {}
          : {state.contentId!},
      focusedConsonant: state.wordGameFocusConsonant,
      focusedVowel: state.wordGameFocusVowel,
    );
    final index = _currentItems.indexWhere(
      (candidate) => candidate.id == item.id,
    );
    debugPrint(
      '[WordGame] set weighted target: "${item.text}" '
      'id=${item.id} focusC=${state.wordGameFocusConsonant ?? "-"} '
      'focusV=${state.wordGameFocusVowel ?? "-"} '
      'excluded=${state.contentId ?? "-"}',
    );
    _setCurrentItem(index == -1 ? 0 : index);
  }

  void _tickFallingWordGame() {
    if (state.wordGameStatus != WordGameStatus.running) {
      _wordGameTimer?.cancel();
      return;
    }
    if (state.state == PracticeState.recording ||
        state.state == PracticeState.analyzing) {
      return;
    }

    _wordGameTick += 1;
    final speed = switch (state.wordGameDifficulty) {
      1 => 0.035,
      2 => 0.047,
      _ => 0.06,
    };

    final movedWords = state.fallingWords
        .map((word) => word.copyWith(progress: word.progress + speed))
        .toList();
    if (movedWords.any((word) => word.progress >= 1)) {
      final missedWord = movedWords
          .where((word) => word.progress >= 1)
          .fold<FallingWord?>(null, (best, word) {
            if (best == null || word.progress > best.progress) {
              return word;
            }
            return best;
          });
      _wordGameTimer?.cancel();
      state = state.copyWith(
        wordGameStatus: WordGameStatus.gameOver,
        fallingWords: movedWords,
        state: PracticeState.idle,
        wordGameMisses: state.wordGameMisses + 1,
      );
      if (missedWord != null) {
        unawaited(_saveMissedWordSession(missedWord.item));
      }
      return;
    }

    state = state.copyWith(fallingWords: movedWords);
    final spawnInterval = switch (state.wordGameDifficulty) {
      1 => 5,
      2 => 4,
      _ => 3,
    };
    if (_wordGameTick % spawnInterval == 0 && movedWords.length < 5) {
      _spawnFallingWord();
    }
    _syncTargetToFirstFallingWord(keepSelectedTarget: true);
  }

  void _spawnFallingWord() {
    if (_currentItems.isEmpty) {
      debugPrint('[WordGame] spawn skipped: no current items');
      return;
    }

    final item = state.isReviewMode
        ? _currentItems[_fallingWordSequence % _currentItems.length]
        : contentService.pickWeightedWord(
            items: _currentItems,
            history: state.history,
            difficultyLevel: state.wordGameDifficulty,
            currentContentId: state.contentId,
            excludedContentIds: _excludedFallingWordIds(),
            focusedConsonant: state.wordGameFocusConsonant,
            focusedVowel: state.wordGameFocusVowel,
            random: _wordGameRandom,
          );
    final occupiedLanes = state.fallingWords
        .where((word) => word.progress < 0.18)
        .map((word) => word.lane)
        .toSet();
    final availableLanes = [
      0,
      1,
      2,
    ].where((lane) => !occupiedLanes.contains(lane)).toList();
    final lane = availableLanes.isEmpty
        ? _wordGameRandom.nextInt(3)
        : availableLanes[_wordGameRandom.nextInt(availableLanes.length)];
    _fallingWordSequence += 1;

    final word = FallingWord(
      id: '${item.id}_${DateTime.now().microsecondsSinceEpoch}_$_fallingWordSequence',
      item: item,
      lane: lane,
      progress: 0,
    );
    debugPrint(
      '[WordGame] spawned word: "${item.text}" id=${item.id} lane=$lane '
      'focusC=${state.wordGameFocusConsonant ?? "-"} '
      'focusV=${state.wordGameFocusVowel ?? "-"} '
      'active=${state.fallingWords.map((word) => word.item.text).join(",")}',
    );
    state = state.copyWith(fallingWords: [...state.fallingWords, word]);
    _syncTargetToFirstFallingWord(keepSelectedTarget: true);
  }

  Set<String> _excludedFallingWordIds() {
    final ids = state.fallingWords.map((word) => word.item.id).toSet();
    final contentId = state.contentId;
    if (contentId != null) {
      ids.add(contentId);
    }
    return ids;
  }

  void selectFallingWord(String fallingWordId) {
    if (state.wordGameStatus != WordGameStatus.running ||
        state.state == PracticeState.recording ||
        state.state == PracticeState.analyzing) {
      debugPrint(
        '[WordGame] select ignored: id=$fallingWordId '
        'status=${state.wordGameStatus.name} state=${state.state.name}',
      );
      return;
    }

    final selectedWords = state.fallingWords.where(
      (word) => word.id == fallingWordId,
    );
    if (selectedWords.isEmpty) {
      debugPrint('[WordGame] select ignored: missing id=$fallingWordId');
      return;
    }

    final item = selectedWords.first.item;
    debugPrint(
      '[WordGame] selected word: "${item.text}" id=${item.id} '
      'fallingId=$fallingWordId',
    );
    state = state.copyWith(
      targetText: item.text,
      contentId: item.id,
      category: item.category,
      difficulty: item.difficulty,
      contentSource: item.source,
      movementScore: item.movementScore,
      isExercisePattern: item.isExercisePattern,
    );
  }

  void _syncTargetToFirstFallingWord({bool keepSelectedTarget = false}) {
    if (state.fallingWords.isEmpty) {
      state = state.copyWith(clearContentId: true, targetText: '');
      return;
    }

    if (keepSelectedTarget &&
        state.contentId != null &&
        state.fallingWords.any((word) => word.item.id == state.contentId)) {
      return;
    }

    final first = state.fallingWords.reduce(
      (a, b) => a.progress >= b.progress ? a : b,
    );
    final item = first.item;
    debugPrint(
      '[WordGame] synced target to first: "${item.text}" id=${item.id} '
      'progress=${first.progress.toStringAsFixed(2)}',
    );
    state = state.copyWith(
      targetText: item.text,
      contentId: item.id,
      category: item.category,
      difficulty: item.difficulty,
      contentSource: item.source,
      movementScore: item.movementScore,
      isExercisePattern: item.isExercisePattern,
    );
  }

  void _handleFallingWordResult(int score) {
    if (state.mode != PracticeMode.wordGame ||
        state.wordGameStatus != WordGameStatus.running ||
        state.contentId == null) {
      debugPrint(
        '[WordGame] result ignored: mode=${state.mode.storageValue} '
        'status=${state.wordGameStatus.name} contentId=${state.contentId}',
      );
      return;
    }

    if (score < 70) {
      debugPrint(
        '[WordGame] result failed: target="${state.targetText}" '
        'id=${state.contentId} score=$score',
      );
      state = state.copyWith(wordGameMisses: state.wordGameMisses + 1);
      return;
    }

    final targetId = state.contentId;
    final targetWord = state.fallingWords
        .where((word) => word.item.id == targetId)
        .fold<FallingWord?>(null, (best, word) {
          if (best == null || word.progress > best.progress) {
            return word;
          }
          return best;
        });
    debugPrint(
      '[WordGame] result passed: target="${state.targetText}" '
      'id=$targetId score=$score found=${targetWord != null}',
    );
    if (targetWord == null) {
      return;
    }

    final nextWords = state.fallingWords
        .where((word) => word.id != targetWord.id)
        .toList();
    state = state.copyWith(
      fallingWords: nextWords,
      wordGameHits: state.wordGameHits + 1,
      wordGameScore: state.wordGameScore + score,
    );
    if (nextWords.length < 2) {
      _spawnFallingWord();
    }
    _syncTargetToFirstFallingWord();
  }

  Future<void> _saveMissedWordSession(PracticeContentItem item) async {
    final session = PracticeSession(
      id: const Uuid().v4(),
      targetText: item.text,
      spokenText: '',
      audioFilePath: '',
      score: 0,
      feedback: '단어가 바닥에 닿아 복습 목록에 추가했습니다.',
      timestamp: DateTime.now(),
      sessionGoal: state.sessionGoal,
      fatigueBefore: state.fatigueBefore,
      fatigueAfter: state.fatigueAfter ?? state.fatigueBefore,
      durationSeconds: 0,
      mode: PracticeMode.wordGame.storageValue,
      contentId: item.id,
      category: item.category,
      difficulty: item.difficulty,
      retryCount: state.retryCount + 1,
      streakCount: 0,
      contentSource: item.source.storageValue,
      movementScore: item.movementScore,
      isExercisePattern: item.isExercisePattern,
    );

    await historyService.savePractice(session);
    final updatedHistory = await historyService.loadPractices();
    state = state.copyWith(history: updatedHistory);
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
    debugPrint(
      '[PracticeRecording] start requested: mode=${state.mode.storageValue} '
      'state=${state.state.name} status=${state.wordGameStatus.name} '
      'target="${state.targetText}" contentId=${state.contentId}',
    );
    if (state.state == PracticeState.recording) {
      debugPrint('[PracticeRecording] start ignored: already recording');
      return;
    }
    if (state.mode == PracticeMode.wordGame &&
        state.wordGameStatus != WordGameStatus.running) {
      debugPrint(
        '[PracticeRecording] start ignored: word game is '
        '${state.wordGameStatus.name}',
      );
      return;
    }

    final hasPermission = await audioRecorder.hasPermission();
    if (!hasPermission) {
      debugPrint('[PracticeRecording] start failed: microphone denied');
      state = state.copyWith(state: PracticeState.error);
      return;
    }

    state = state.copyWith(
      state: PracticeState.recording,
      spokenText: '',
      speechRecognitionUnavailable: false,
      clearFeedback: true,
      clearFatigueAfter: true,
    );

    _tempSpokenText = '';
    _recordingStartTime = DateTime.now();
    final fileName = 'practice_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('[PracticeRecording] recording state entered: file=$fileName');

    // Start STT before the high-quality recorder so live transcription has the
    // first chance to claim the platform audio session.
    final sttStartWatch = Stopwatch()..start();
    final sttStarted = await sttService.startListening(
      onResult: (text, isFinal) async {
        _tempSpokenText = text;
        debugPrint(
          '[PracticeRecording] live transcription: "$text" final=$isFinal',
        );
        state = state.copyWith(spokenText: text);
      },
    );
    sttStartWatch.stop();
    debugPrint(
      '[PracticeRecording] STT start result=$sttStarted '
      'elapsed=${sttStartWatch.elapsedMilliseconds}ms',
    );

    if (sttStarted) {
      // Wait a bit for the audio session to stabilize before starting the high-quality recorder.
      await Future.delayed(const Duration(milliseconds: 400));
    } else {
      state = state.copyWith(speechRecognitionUnavailable: true);
    }

    final recorderStartWatch = Stopwatch()..start();
    await audioRecorder.startRecording(fileName);
    recorderStartWatch.stop();
    debugPrint(
      '[PracticeRecording] recorder started '
      'elapsed=${recorderStartWatch.elapsedMilliseconds}ms',
    );
  }

  Future<void> stopRecording() async {
    debugPrint(
      '[PracticeRecording] stop requested: state=${state.state.name} '
      'target="${state.targetText}" temp="$_tempSpokenText"',
    );
    if (state.state != PracticeState.recording) {
      debugPrint('[PracticeRecording] stop ignored: not recording');
      return;
    }

    state = state.copyWith(state: PracticeState.analyzing);
    final totalStopWatch = Stopwatch()..start();
    debugPrint('[PracticeRecording] analyzing state entered');

    // Guard: Prevent stopping too fast
    if (_recordingStartTime != null) {
      final elapsed = DateTime.now().difference(_recordingStartTime!);
      if (elapsed.inMilliseconds < 500) {
        debugPrint(
          '[PracticeRecording] stop guard delay='
          '${500 - elapsed.inMilliseconds}ms',
        );
        await Future.delayed(
          Duration(milliseconds: 500 - elapsed.inMilliseconds),
        );
      }
    }

    // Stop the recorder and STT engine
    final recorderStopWatch = Stopwatch()..start();
    final audioFile = await audioRecorder.stopRecording();
    recorderStopWatch.stop();
    debugPrint(
      '[PracticeRecording] recorder stopped path=${audioFile ?? "null"} '
      'elapsed=${recorderStopWatch.elapsedMilliseconds}ms',
    );
    final sttStopWatch = Stopwatch()..start();
    await sttService.stopListening();
    sttStopWatch.stop();
    debugPrint(
      '[PracticeRecording] STT stop completed '
      'elapsed=${sttStopWatch.elapsedMilliseconds}ms',
    );

    // Small delay to allow the STT engine to process the last audio chunk
    await Future.delayed(const Duration(milliseconds: 600));

    String finalSpokenText = _tempSpokenText;
    debugPrint('[PracticeRecording] final transcription: "$finalSpokenText"');

    if (finalSpokenText.isEmpty) {
      if (state.isFreeMode) {
        debugPrint(
          '[PracticeRecording] no transcription: using free speech fallback',
        );
        finalSpokenText = '오늘 있었던 일을 편하게 말했습니다.';
      } else {
        debugPrint(
          '[PracticeRecording] no transcription: keeping empty for scoring',
        );
      }
    }

    state = state.copyWith(spokenText: finalSpokenText);

    if (audioFile == null) {
      debugPrint('[PracticeRecording] stop failed: audio file is null');
      state = state.copyWith(state: PracticeState.error);
      return;
    }

    debugPrint(
      '[PracticeRecording] analysis starting: mode=${state.mode.label} '
      'target="${state.targetText}" spoken="$finalSpokenText"',
    );
    late AiResponse feedback;
    final analysisWatch = Stopwatch()..start();
    try {
      feedback = await aiService.evaluatePracticeByMode(
        mode: state.mode,
        targetText: state.targetText,
        spokenText: finalSpokenText,
        durationSeconds: _recordingStartTime == null
            ? 0
            : DateTime.now().difference(_recordingStartTime!).inSeconds,
      );
      debugPrint(
        '[PracticeRecording] analysis completed '
        'elapsed=${analysisWatch.elapsedMilliseconds}ms '
        'score=${feedback.pronunciationScore}',
      );
    } catch (e) {
      debugPrint('[PracticeRecording] analysis failed, retrying: $e');
      feedback = await aiService.evaluatePracticeByMode(
        mode: state.mode,
        targetText: state.targetText,
        spokenText: finalSpokenText,
        durationSeconds: _recordingStartTime == null
            ? 0
            : DateTime.now().difference(_recordingStartTime!).inSeconds,
      );
      debugPrint(
        '[PracticeRecording] analysis retry completed '
        'elapsed=${analysisWatch.elapsedMilliseconds}ms '
        'score=${feedback.pronunciationScore}',
      );
    }
    analysisWatch.stop();

    feedback = _enforceStrictWordGameMatch(
      feedback: feedback,
      targetText: state.targetText,
      spokenText: finalSpokenText,
    );

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
      movementScore: state.movementScore,
      isExercisePattern: state.isExercisePattern,
    );

    debugPrint('[PracticeRecording] saving history...');
    await historyService.savePractice(session);
    final updatedHistory = await historyService.loadPractices();

    _handleFallingWordResult(feedback.pronunciationScore);

    final keepWordGameRunning =
        state.mode == PracticeMode.wordGame &&
        state.wordGameStatus == WordGameStatus.running;

    state = state.copyWith(
      state: keepWordGameRunning ? PracticeState.idle : PracticeState.completed,
      feedback: feedback,
      lastAudioPath: audioFile,
      history: updatedHistory,
      retryCount: nextRetryCount,
      streakCount: nextStreakCount,
    );
    totalStopWatch.stop();
    debugPrint(
      '[PracticeRecording] stop flow completed: '
      'nextState=${state.state.name} keepWordGameRunning=$keepWordGameRunning '
      'total=${totalStopWatch.elapsedMilliseconds}ms',
    );
  }

  AiResponse _enforceStrictWordGameMatch({
    required AiResponse feedback,
    required String targetText,
    required String spokenText,
  }) {
    if (state.mode != PracticeMode.wordGame) {
      return feedback;
    }

    final normalizedTarget = _normalizeWordGameAnswer(targetText);
    final normalizedSpoken = _normalizeWordGameAnswer(spokenText);
    final isExactMatch =
        normalizedTarget.isNotEmpty && normalizedTarget == normalizedSpoken;
    if (isExactMatch || feedback.pronunciationScore < 70) {
      debugPrint(
        '[WordGame] strict match check: target="$normalizedTarget" '
        'spoken="$normalizedSpoken" score=${feedback.pronunciationScore} '
        'allowed=$isExactMatch',
      );
      return feedback;
    }

    debugPrint(
      '[WordGame] strict mismatch forced fail: target="$normalizedTarget" '
      'spoken="$normalizedSpoken" aiScore=${feedback.pronunciationScore}',
    );
    return AiResponse(
      replyText: '다른 단어로 인식되었습니다.',
      pronunciationScore: 40,
      pronunciationFeedback:
          '목표 단어 "$targetText"로 인식되지 않았습니다. 입 모양을 다시 만들고 한 번 더 또렷하게 말해 보세요.',
      phonemeAccuracy: feedback.phonemeAccuracy,
      intonationFeedback: feedback.intonationFeedback,
    );
  }

  String _normalizeWordGameAnswer(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^\uAC00-\uD7A3a-zA-Z0-9]'), '')
        .toLowerCase();
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
    final sessions = await historyService.loadPractices();
    PracticeSession? targetSession;
    for (final session in sessions) {
      if (session.id == id) {
        targetSession = session;
        break;
      }
    }

    await _deleteAudioFile(targetSession?.audioFilePath);
    await historyService.deletePractice(id);
    final updatedHistory = await historyService.loadPractices();
    state = state.copyWith(history: updatedHistory);
  }

  Future<void> _deleteAudioFile(String? path) async {
    if (kIsWeb || path == null || path.trim().isEmpty) {
      return;
    }

    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Recording file deletion failed: $e');
    }
  }

  Future<bool> playRecording(String? path) async {
    final filePath = path ?? state.lastAudioPath;
    if (filePath == null || filePath.isEmpty) {
      return false;
    }

    state = state.copyWith(isPlaying: true);
    try {
      await audioPlayer.playFile(filePath);
      // We could listen to playback completion here, but for now we reset on stop
      return true;
    } catch (e) {
      debugPrint('Playback failed: $e');
      state = state.copyWith(isPlaying: false);
      return false;
    }
  }

  Future<void> stopPlayback() async {
    await audioPlayer.stop();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> shareRecording() async {
    if (state.lastAudioPath != null) {
      final file = XFile(state.lastAudioPath!);
      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [file],
            text: '내 발음 연습 녹음 파일입니다: "${state.targetText}"',
          ),
        );
      } catch (error) {
        debugPrint('Share recording failed: $error');
      }
    }
  }
}
