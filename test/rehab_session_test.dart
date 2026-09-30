import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/features/rehab/model/rehab_session.dart';
import 'package:speech_rehab/features/rehab/services/rehab_session_repository.dart';
import 'package:speech_rehab/features/rehab/services/rehab_record_index.dart';
import 'package:speech_rehab/services/practice_history_service.dart';

RehabSession sample({String id = 'daily'}) => RehabSession(
  id: id,
  title: '쉬고 싶다고 말하기',
  language: 'ko-KR',
  startedAt: DateTime.utc(2026, 9, 25, 16),
  localDate: '2026-09-26',
  offsetMinutes: 540,
  tasks: rehabScenarios.firstWhere((s) => s.id == 'rest').tasks(false),
  repetitions: 1,
  fatigueBefore: 2,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'concurrent session saves preserve both records and repeated save is idempotent',
    () async {
      final repo = RehabSessionRepository();
      await Future.wait([repo.save(sample()), repo.save(sample(id: 'second'))]);
      final paused = sample().copyWith(
        status: RehabStatus.paused,
        taskIndex: 1,
        takes: [
          RehabTake(
            id: 'take',
            taskId: 'rest-word',
            text: '잠시',
            path: '/tmp/test.m4a',
            createdAt: DateTime.now(),
            seconds: 3,
          ),
        ],
      );
      await repo.save(paused);
      await repo.save(paused);
      final all = await repo.load();
      expect(all.length, 2);
      final resumed = all.singleWhere((s) => s.id == 'daily');
      expect(resumed.canResume, true);
      expect(resumed.taskIndex, 1);
      expect(resumed.takes.length, 1);
      expect(resumed.completedTasks, 1);
      expect(resumed.localDate, '2026-09-26');
      expect(resumed.offsetMinutes, 540);
    },
  );
  test('corrupt history is not overwritten when save is attempted', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(RehabSessionRepository.storageKey, 'broken');
    await expectLater(
      RehabSessionRepository().save(sample()),
      throwsFormatException,
    );
    expect(prefs.getString(RehabSessionRepository.storageKey), 'broken');
  });
  test(
    'unified history keeps old attempts, excludes recordless falls and free response comparisons',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final legacy = PracticeSession(
        id: 'daily',
        targetText: '안녕',
        spokenText: '안녕',
        audioFilePath: '/old.m4a',
        feedback: 'old',
        timestamp: DateTime.now(),
        score: 12,
      );
      await PracticeHistoryService().savePractice(legacy);
      await PracticeHistoryService().savePractice(
        PracticeSession(
          id: 'fall',
          score: null,
          targetText: '물',
          spokenText: '',
          audioFilePath: '',
          feedback: '',
          timestamp: DateTime.now(),
        ),
      );
      final original = prefs.getString('practice_history');
      await RehabSessionRepository().save(
        sample().copyWith(
          takes: [
            RehabTake(
              id: 'free',
              taskId: 'rest-situation',
              text: '잠시 쉬고 싶어요.',
              path: '/daily.m4a',
              createdAt: DateTime.now(),
              seconds: 2,
            ),
          ],
        ),
      );
      final records = await RehabRecordIndex().load();
      expect(
        records.map((r) => r.id),
        containsAll(['practice:daily', 'daily:daily']),
      );
      expect(records.where((r) => r.id == 'practice:fall'), isEmpty);
      expect(
        records
            .singleWhere((r) => r.kind == 'daily')
            .recordings
            .single
            .comparable,
        false,
      );
      expect(prefs.getString('practice_history'), original);
      expect(
        jsonDecode(prefs.getString(RehabSessionRepository.storageKey)!) as List,
        hasLength(1),
      );
    },
  );
}
