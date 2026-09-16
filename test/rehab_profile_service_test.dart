import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/services/rehab_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'restores onboarding goal and duration and shortens tired sessions',
    () async {
      SharedPreferences.setMockInitialValues({});
      await RehabProfileService.saveProfile(
        RehabProfile(
          practiceStage: 'beginner',
          primaryGoal: 'slowSpeech',
          dailyPracticeMinutes: 10,
          hasCaregiverSupport: true,
          acceptedSafetyNoticeAt: DateTime(2026, 9, 15),
        ),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(rehabProfileProvider.future);
      final plan = container.read(rehabSessionProvider);
      expect(plan.goal, '천천히 말하기');
      expect(plan.dailyMinutes, 10);
      expect(plan.fatigueBefore, isNull);
      container.read(rehabSessionProvider.notifier).setFatigue(4);
      expect(container.read(rehabSessionProvider).durationMinutes, 3);
      expect(container.read(rehabSessionProvider).dailyMinutes, 10);
    },
  );

  test('late profile load preserves choices made in this session', () async {
    final profile = Completer<RehabProfile?>();
    final container = ProviderContainer(
      overrides: [rehabProfileProvider.overrideWith((ref) => profile.future)],
    );
    addTearDown(container.dispose);
    container.read(rehabSessionProvider.notifier).setFatigue(5);
    container.read(rehabSessionProvider.notifier).setGoal('숨 조절하기');
    profile.complete(
      RehabProfile(
        practiceStage: 'beginner',
        primaryGoal: 'clearSpeech',
        dailyPracticeMinutes: 10,
        hasCaregiverSupport: false,
        acceptedSafetyNoticeAt: DateTime(2026, 9, 15),
      ),
    );
    await container.read(rehabProfileProvider.future);
    final plan = container.read(rehabSessionProvider);
    expect(plan.goal, '숨 조절하기');
    expect(plan.fatigueBefore, 5);
    expect(plan.dailyMinutes, 10);
  });
}
