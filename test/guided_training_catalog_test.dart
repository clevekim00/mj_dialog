import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/guided_training/data/guided_training_catalog.dart';
import 'package:speech_rehab/features/guided_training/model/guided_training_models.dart';
import 'package:speech_rehab/services/guided_training/guided_training_history_service.dart';

void main() {
  test('catalog contains 46 unique exercises in the planned categories', () {
    expect(allGuidedTrainingExercises, hasLength(46));
    expect(
      allGuidedTrainingExercises.map((exercise) => exercise.id).toSet(),
      hasLength(46),
    );
    expect(guidedExercisesFor(GuidedTrainingCategory.tongue), hasLength(14));
    expect(guidedExercisesFor(GuidedTrainingCategory.lip), hasLength(12));
    expect(
      guidedExercisesFor(GuidedTrainingCategory.alternating),
      hasLength(10),
    );
    expect(guidedExercisesFor(GuidedTrainingCategory.breathing), hasLength(10));
    expect(
      defaultGuidedRoutine.every(
        (exercise) =>
            exercise.safetyTier != GuidedTrainingSafetyTier.clinicianOnly,
      ),
      isTrue,
    );
  });

  test('new history and legacy tongue history are loaded together', () async {
    final now = DateTime(2026, 8, 25, 9);
    SharedPreferences.setMockInitialValues({
      GuidedTrainingHistoryService.legacyTongueStorageKey: jsonEncode([
        {
          'id': 'old-1',
          'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
          'durationSeconds': 60,
          'fatigueBefore': 2,
          'fatigueAfter': 3,
          'completedStepIds': ['tongue_out'],
        },
      ]),
    });
    final service = GuidedTrainingHistoryService();
    await service.saveSession(
      GuidedTrainingSession(
        id: 'new-1',
        startedAt: now,
        completedAt: now.add(const Duration(minutes: 2)),
        routineName: '내 루틴',
        fatigueBefore: 1,
        fatigueAfter: 2,
        results: const [
          GuidedTrainingExerciseResult(
            exerciseId: 'tongue_01_vertical',
            targetLoops: 5,
            completedLoops: 5,
            playbackSpeed: 0.75,
            skipped: false,
            videoFailed: false,
          ),
        ],
      ),
    );

    final sessions = await service.loadAllSessions();
    expect(sessions, hasLength(2));
    expect(sessions.first.routineName, '내 루틴');
    expect(sessions.last.contentVersion, 'legacy');
  });
}
