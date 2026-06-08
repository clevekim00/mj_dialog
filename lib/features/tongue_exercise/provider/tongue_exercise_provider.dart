import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/tongue_exercise/model/tongue_exercise_step.dart';
import 'package:speech_rehab/services/tongue_exercise_history_service.dart';

enum TongueExercisePhase { intro, routine, paused, complete }

class TongueExerciseProgress {
  const TongueExerciseProgress({
    required this.phase,
    this.currentStepIndex = 0,
    this.stepElapsedSeconds = 0,
    this.totalElapsedSeconds = 0,
    this.fatigueBefore = 1,
    this.fatigueAfter,
    this.isCurrentSessionSaved = false,
    this.completedStepIds = const [],
    this.history = const [],
  });

  final TongueExercisePhase phase;
  final int currentStepIndex;
  final int stepElapsedSeconds;
  final int totalElapsedSeconds;
  final int fatigueBefore;
  final int? fatigueAfter;
  final bool isCurrentSessionSaved;
  final List<String> completedStepIds;
  final List<TongueExerciseSession> history;

  TongueExerciseStep get currentStep => tongueExerciseSteps[currentStepIndex];
  bool get isTodayCompleted {
    final today = DateTime.now();
    return history.any(
      (session) =>
          session.timestamp.year == today.year &&
          session.timestamp.month == today.month &&
          session.timestamp.day == today.day &&
          session.completedStepCount == session.totalStepCount,
    );
  }

  int get completedDaysInLast7 {
    final now = DateTime.now();
    final recentDays = List.generate(7, (index) {
      final date = now.subtract(Duration(days: index));
      return DateTime(date.year, date.month, date.day);
    }).toSet();

    return history
        .where(
          (session) => session.completedStepCount == session.totalStepCount,
        )
        .map(
          (session) => DateTime(
            session.timestamp.year,
            session.timestamp.month,
            session.timestamp.day,
          ),
        )
        .where(recentDays.contains)
        .toSet()
        .length;
  }

  int get averageDurationLast7 {
    final now = DateTime.now();
    final recent = history
        .where((session) => now.difference(session.timestamp).inDays < 7)
        .toList();
    if (recent.isEmpty) return 0;
    return recent
            .map((session) => session.durationSeconds)
            .reduce((a, b) => a + b) ~/
        recent.length;
  }

  TongueExerciseProgress copyWith({
    TongueExercisePhase? phase,
    int? currentStepIndex,
    int? stepElapsedSeconds,
    int? totalElapsedSeconds,
    int? fatigueBefore,
    int? fatigueAfter,
    bool clearFatigueAfter = false,
    bool? isCurrentSessionSaved,
    List<String>? completedStepIds,
    List<TongueExerciseSession>? history,
  }) {
    return TongueExerciseProgress(
      phase: phase ?? this.phase,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      stepElapsedSeconds: stepElapsedSeconds ?? this.stepElapsedSeconds,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
      fatigueBefore: fatigueBefore ?? this.fatigueBefore,
      fatigueAfter: clearFatigueAfter
          ? null
          : (fatigueAfter ?? this.fatigueAfter),
      isCurrentSessionSaved:
          isCurrentSessionSaved ?? this.isCurrentSessionSaved,
      completedStepIds: completedStepIds ?? this.completedStepIds,
      history: history ?? this.history,
    );
  }
}

final tongueExerciseProvider =
    NotifierProvider<TongueExerciseNotifier, TongueExerciseProgress>(
      TongueExerciseNotifier.new,
    );

class TongueExerciseNotifier extends Notifier<TongueExerciseProgress> {
  Timer? _timer;

  TongueExerciseHistoryService get historyService =>
      ref.watch(tongueExerciseHistoryServiceProvider);

  @override
  TongueExerciseProgress build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    _loadHistory();
    return const TongueExerciseProgress(phase: TongueExercisePhase.intro);
  }

  Future<void> _loadHistory() async {
    final history = await historyService.loadSessions();
    state = state.copyWith(history: history);
  }

  void setFatigueBefore(int fatigue) {
    if (state.phase != TongueExercisePhase.intro) return;
    state = state.copyWith(fatigueBefore: fatigue);
  }

  void setFatigueAfter(int fatigue) {
    if (state.phase != TongueExercisePhase.complete) return;
    state = state.copyWith(fatigueAfter: fatigue);
  }

  void startRoutine() {
    _timer?.cancel();
    state = state.copyWith(
      phase: TongueExercisePhase.routine,
      currentStepIndex: 0,
      stepElapsedSeconds: 0,
      totalElapsedSeconds: 0,
      completedStepIds: const [],
      isCurrentSessionSaved: false,
      clearFatigueAfter: true,
    );
    _startTimer();
  }

  void pauseRoutine() {
    if (state.phase != TongueExercisePhase.routine) return;
    _timer?.cancel();
    state = state.copyWith(phase: TongueExercisePhase.paused);
  }

  void resumeRoutine() {
    if (state.phase != TongueExercisePhase.paused) return;
    state = state.copyWith(phase: TongueExercisePhase.routine);
    _startTimer();
  }

  void completeCurrentStep() {
    if (state.phase != TongueExercisePhase.routine &&
        state.phase != TongueExercisePhase.paused) {
      return;
    }

    final currentStepId = state.currentStep.id;
    final completedStepIds = {
      ...state.completedStepIds,
      currentStepId,
    }.toList();

    if (state.currentStepIndex >= tongueExerciseSteps.length - 1) {
      _timer?.cancel();
      state = state.copyWith(
        phase: TongueExercisePhase.complete,
        completedStepIds: completedStepIds,
        isCurrentSessionSaved: false,
      );
      return;
    }

    state = state.copyWith(
      phase: TongueExercisePhase.routine,
      currentStepIndex: state.currentStepIndex + 1,
      stepElapsedSeconds: 0,
      completedStepIds: completedStepIds,
    );
    _startTimer();
  }

  void stopRoutine() {
    _timer?.cancel();
    state = state.copyWith(
      phase: TongueExercisePhase.intro,
      currentStepIndex: 0,
      stepElapsedSeconds: 0,
      totalElapsedSeconds: 0,
      completedStepIds: const [],
      isCurrentSessionSaved: false,
      clearFatigueAfter: true,
    );
  }

  void resetToIntro() {
    _timer?.cancel();
    state = state.copyWith(
      phase: TongueExercisePhase.intro,
      currentStepIndex: 0,
      stepElapsedSeconds: 0,
      totalElapsedSeconds: 0,
      completedStepIds: const [],
      isCurrentSessionSaved: false,
      clearFatigueAfter: true,
    );
  }

  Future<void> saveCompletedSession() async {
    if (state.phase != TongueExercisePhase.complete ||
        state.isCurrentSessionSaved) {
      return;
    }
    await _saveCurrentSession();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.phase != TongueExercisePhase.routine) return;

      final nextStepElapsed = state.stepElapsedSeconds + 1;
      state = state.copyWith(
        stepElapsedSeconds: nextStepElapsed,
        totalElapsedSeconds: state.totalElapsedSeconds + 1,
      );

      if (nextStepElapsed >= state.currentStep.seconds) {
        completeCurrentStep();
      }
    });
  }

  Future<void> _saveCurrentSession() async {
    final now = DateTime.now();
    final session = TongueExerciseSession(
      id: 'tongue_${now.microsecondsSinceEpoch}',
      timestamp: now,
      completedStepCount: state.completedStepIds.length,
      totalStepCount: tongueExerciseSteps.length,
      durationSeconds: state.totalElapsedSeconds,
      fatigueBefore: state.fatigueBefore,
      fatigueAfter: state.fatigueAfter,
      completedStepIds: state.completedStepIds,
    );

    await historyService.saveSession(session);
    final history = await historyService.loadSessions();
    state = state.copyWith(history: history, isCurrentSessionSaved: true);
  }
}
