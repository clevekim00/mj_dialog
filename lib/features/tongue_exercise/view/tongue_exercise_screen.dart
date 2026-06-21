import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/exercise/widgets/animated_exercise_avatar.dart';
import 'package:speech_rehab/features/practice/model/practice_mode.dart';
import 'package:speech_rehab/features/practice/provider/practice_provider.dart';
import 'package:speech_rehab/features/tongue_exercise/model/tongue_exercise_step.dart';
import 'package:speech_rehab/features/tongue_exercise/provider/tongue_exercise_provider.dart';

class TongueExerciseScreen extends ConsumerWidget {
  const TongueExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(tongueExerciseProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('혀운동'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            if (progress.phase == TongueExercisePhase.intro)
              _buildIntro(context, ref, progress)
            else if (progress.phase == TongueExercisePhase.complete)
              _buildComplete(context, ref, progress)
            else
              _buildRoutine(context, ref, progress),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(
    BuildContext context,
    WidgetRef ref,
    TongueExerciseProgress progress,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroHeader(
          icon: Icons.self_improvement,
          title: '발음 연습 전 3분 준비',
          body: '입과 혀를 천천히 풀고, 오늘 연습을 편안하게 시작해요.',
          color: Colors.tealAccent,
        ),
        const SizedBox(height: 16),
        _buildSafetyCard(),
        const SizedBox(height: 16),
        _buildTongueMotionGuide(
          title: '2D 혀 운동 가이드',
          subtitle: '튜터의 입모양과 혀 방향을 보며 천천히 따라 해보세요.',
        ),
        const SizedBox(height: 16),
        _buildFatigueSelector(
          title: '시작 전 피로도',
          value: progress.fatigueBefore,
          onSelected: ref
              .read(tongueExerciseProvider.notifier)
              .setFatigueBefore,
        ),
        const SizedBox(height: 16),
        _buildRoutinePreview(),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: ref.read(tongueExerciseProvider.notifier).startRoutine,
            icon: const Icon(Icons.play_arrow),
            label: Text(progress.fatigueBefore >= 4 ? '천천히 루틴 시작' : '3분 루틴 시작'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutine(
    BuildContext context,
    WidgetRef ref,
    TongueExerciseProgress progress,
  ) {
    final step = progress.currentStep;
    final stepNumber = progress.currentStepIndex + 1;
    final stepProgress = (progress.stepElapsedSeconds / step.seconds).clamp(
      0.0,
      1.0,
    );
    final isPaused = progress.phase == TongueExercisePhase.paused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$stepNumber / ${tongueExerciseSteps.length}',
          style: const TextStyle(
            color: Colors.tealAccent,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.tealAccent.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.tealAccent.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            children: [
              _buildTongueMotionGuide(
                title: step.title,
                subtitle: '2D 튜터의 입모양과 혀 움직임을 보며 현재 운동을 따라 해보세요.',
                compact: true,
              ),
              const SizedBox(height: 18),
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                step.instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: stepProgress,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(Colors.tealAccent),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                step.repetitions > 1
                    ? '${step.repetitions}회 · ${step.seconds - progress.stepElapsedSeconds}초 남음'
                    : '${step.seconds - progress.stepElapsedSeconds}초 남음',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isPaused
                    ? ref.read(tongueExerciseProvider.notifier).resumeRoutine
                    : ref.read(tongueExerciseProvider.notifier).pauseRoutine,
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                label: Text(isPaused ? '다시 시작' : '일시정지'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: ref
                    .read(tongueExerciseProvider.notifier)
                    .completeCurrentStep,
                icon: const Icon(Icons.skip_next),
                label: Text(
                  stepNumber == tongueExerciseSteps.length ? '완료' : '다음',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: ref.read(tongueExerciseProvider.notifier).stopRoutine,
          icon: const Icon(Icons.stop_circle_outlined),
          label: const Text('중단하고 돌아가기'),
          style: TextButton.styleFrom(foregroundColor: Colors.white54),
        ),
        const SizedBox(height: 16),
        _buildStepChecklist(progress),
      ],
    );
  }

  Widget _buildComplete(
    BuildContext context,
    WidgetRef ref,
    TongueExerciseProgress progress,
  ) {
    final duration = _formatDuration(progress.totalElapsedSeconds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroHeader(
          icon: Icons.check_circle_outline,
          title: '혀운동 완료',
          body:
              '${progress.completedStepIds.length}/${tongueExerciseSteps.length}단계 · $duration 동안 천천히 준비했어요.',
          color: Colors.tealAccent,
        ),
        const SizedBox(height: 16),
        _buildFatigueSelector(
          title: '종료 후 피로도',
          value: progress.fatigueAfter ?? progress.fatigueBefore,
          onSelected: ref.read(tongueExerciseProvider.notifier).setFatigueAfter,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () async {
              await ref
                  .read(tongueExerciseProvider.notifier)
                  .saveCompletedSession();
              if (!context.mounted) return;
              ref
                  .read(practiceProvider.notifier)
                  .setMode(PracticeMode.shortSentence);
              Navigator.pushReplacementNamed(context, '/practice');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('추천 연습 시작'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(tongueExerciseProvider.notifier).startRoutine();
            },
            icon: const Icon(Icons.replay),
            label: const Text('혀운동 다시 하기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: () async {
              await ref
                  .read(tongueExerciseProvider.notifier)
                  .saveCompletedSession();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/practice_modes');
            },
            child: const Text('홈으로 돌아가기'),
          ),
        ),
      ],
    );
  }

  Widget _buildTongueMotionGuide({
    required String title,
    required String subtitle,
    bool compact = false,
  }) {
    final height = compact ? 210.0 : 260.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: compact ? 0.04 : 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_outlined,
                color: Colors.tealAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white60,
              fontSize: compact ? 12 : 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: height,
              child: AnimatedExerciseAvatar(
                stepId: compact ? 'tongue_out' : 'breath',
                shape: compact ? 'tongueMove' : null,
                pulse: compact ? 0.72 : 0.42,
                accentColor: Colors.tealAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader({
    required IconData icon,
    required String title,
    required String body,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined, color: Colors.orangeAccent),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '통증, 사레, 삼킴 곤란, 호흡 불편, 어지러움, 갑작스러운 말 변화가 있으면 즉시 중단하고 전문가에게 문의하세요.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFatigueSelector({
    required String title,
    required int value,
    required ValueChanged<int> onSelected,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: List.generate(5, (index) {
              final fatigue = index + 1;
              final selected = value == fatigue;
              return ChoiceChip(
                label: Text('$fatigue'),
                selected: selected,
                onSelected: (_) => onSelected(fatigue),
                selectedColor: Colors.tealAccent,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                labelStyle: TextStyle(
                  color: selected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide(
                  color: selected
                      ? Colors.tealAccent
                      : Colors.white.withValues(alpha: 0.12),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutinePreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘 루틴',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...tongueExerciseSteps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Icon(step.icon, color: Colors.tealAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step.title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    step.repetitions > 1
                        ? '${step.repetitions}회'
                        : '${step.seconds}초',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepChecklist(TongueExerciseProgress progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '진행 체크',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...tongueExerciseSteps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isDone = progress.completedStepIds.contains(step.id);
            final isCurrent = index == progress.currentStepIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    isDone
                        ? Icons.check_circle
                        : isCurrent
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isDone || isCurrent
                        ? Colors.tealAccent
                        : Colors.white24,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      step.title,
                      style: TextStyle(
                        color: isDone || isCurrent
                            ? Colors.white
                            : Colors.white38,
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.w800 : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes == 0) return '$remainingSeconds초';
    return '$minutes분 ${remainingSeconds.toString().padLeft(2, '0')}초';
  }
}
