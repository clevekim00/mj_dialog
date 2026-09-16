import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/guided_training/model/guided_training_models.dart';
import 'package:speech_rehab/services/guided_training/guided_training_history_service.dart';

GuidedTrainingSession session({
  GuidedTrainingSessionStatus status = GuidedTrainingSessionStatus.paused,
  int completedLoops = 2,
  int activeSeconds = 20,
}) => GuidedTrainingSession(
  id: 'same-session',
  startedAt: DateTime(2026, 9, 15, 9),
  completedAt: DateTime(2026, 9, 16, 9),
  routineName: '두 운동',
  fatigueBefore: 2,
  fatigueAfter: null,
  status: status,
  activeDurationSeconds: activeSeconds,
  exerciseIds: const ['one'],
  exerciseIndex: 0,
  currentCompletedLoops: completedLoops,
  repeatCount: 5,
  currentTargetLoops: 5,
  playbackSpeed: 0.5,
  results: [
    GuidedTrainingExerciseResult(
      exerciseId: 'one',
      targetLoops: 5,
      completedLoops: completedLoops,
      playbackSpeed: 0.5,
      skipped: false,
      videoFailed: true,
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'autosave upserts a session and preserves repeat and resume progress',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = GuidedTrainingHistoryService();
      await Future.wait([
        service.saveSession(session()),
        service.saveSession(session(completedLoops: 3, activeSeconds: 30)),
      ]);
      final history = await service.loadSessions();
      expect(history, hasLength(1));
      final saved = history.single;
      expect(saved.canResume, isTrue);
      expect(saved.completed, isFalse);
      expect(saved.currentCompletedLoops, 3);
      expect(saved.currentTargetLoops, 5);
      expect(saved.repeatCount, 5);
      expect(saved.playbackSpeed, 0.5);
      expect(saved.durationSeconds, 30);
      expect(saved.fatigueAfter, isNull);
    },
  );

  test('a stopped or incomplete exercise is not counted as fully complete', () {
    expect(
      session(status: GuidedTrainingSessionStatus.stopped).completed,
      isFalse,
    );
    final partial = session(status: GuidedTrainingSessionStatus.completed);
    expect(partial.completed, isFalse);
    expect(partial.completedExerciseCount, 0);
    expect(partial.statusLabel, '부분완료');
    expect(partial.canResume, isFalse);
    expect(
      session(
        status: GuidedTrainingSessionStatus.completed,
        completedLoops: 5,
      ).completed,
      isTrue,
    );
  });
}
