import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/guided_training/data/guided_training_catalog.dart';
import 'package:speech_rehab/features/guided_training/model/guided_training_models.dart';
import 'package:speech_rehab/features/guided_training/view/guided_training_player_screen.dart';
import 'package:speech_rehab/features/guided_training/view/routine_builder_screen.dart';
import 'package:speech_rehab/services/guided_training/guided_training_history_service.dart';
import 'package:speech_rehab/services/training/training_settings_service.dart';

class GuidedTrainingHubScreen extends ConsumerWidget {
  const GuidedTrainingHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(guidedTrainingSessionsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('구강·호흡 훈련'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: '훈련 기록',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GuidedTrainingHistoryScreen(),
              ),
            ),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: '훈련 설정',
            onPressed: () => Navigator.pushNamed(context, '/training_settings'),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _HeroCard(
            completedToday:
                sessions.whenOrNull(data: (items) => items.isTodayCompleted) ??
                false,
            onStart: () =>
                _start(context, defaultGuidedRoutine, '오늘의 구강·호흡 루틴'),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<String>>(
            future: TrainingSettingsService.loadCustomRoutineIds(),
            builder: (context, snapshot) {
              final exercises = (snapshot.data ?? const <String>[])
                  .map(guidedExerciseById)
                  .whereType<GuidedTrainingExercise>()
                  .toList();
              return _ActionCard(
                title: '내 루틴',
                subtitle: exercises.isEmpty
                    ? '최대 8개의 운동을 골라 나만의 순서를 만들어요.'
                    : '${exercises.length}개 운동이 저장되어 있어요.',
                icon: Icons.playlist_add_check_circle_outlined,
                color: Colors.purpleAccent,
                primaryLabel: exercises.isEmpty ? '루틴 만들기' : '내 루틴 시작',
                onPrimary: () => exercises.isEmpty
                    ? _openBuilder(context)
                    : _start(context, exercises, '내 루틴'),
                secondaryLabel: exercises.isEmpty ? null : '편집',
                onSecondary: exercises.isEmpty
                    ? null
                    : () => _openBuilder(context),
              );
            },
          ),
          const SizedBox(height: 22),
          const Text(
            '전체 운동',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          for (final category in GuidedTrainingCategory.values) ...[
            _CategoryCard(
              category: category,
              count: guidedExercisesFor(category).length,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GuidedTrainingCategoryScreen(category: category),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          const _SafetyCard(),
        ],
      ),
    );
  }

  void _start(
    BuildContext context,
    List<GuidedTrainingExercise> exercises,
    String name,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GuidedTrainingPlayerScreen(exercises: exercises, routineName: name),
      ),
    );
  }

  Future<void> _openBuilder(BuildContext context) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RoutineBuilderScreen()),
    );
    if (context.mounted && changed == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GuidedTrainingHubScreen()),
      );
    }
  }
}

class GuidedTrainingCategoryScreen extends StatelessWidget {
  const GuidedTrainingCategoryScreen({super.key, required this.category});
  final GuidedTrainingCategory category;

  @override
  Widget build(BuildContext context) {
    final exercises = guidedExercisesFor(category);
    final recommended = exercises
        .where(
          (item) => item.safetyTier != GuidedTrainingSafetyTier.clinicianOnly,
        )
        .take(4)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(category.label)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            category.description,
            style: const TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: recommended.isEmpty
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuidedTrainingPlayerScreen(
                        exercises: recommended,
                        routineName: '${category.label} 추천 루틴',
                      ),
                    ),
                  ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('추천 4개 시작'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 20),
          for (final exercise in exercises) ...[
            _ExerciseCard(exercise: exercise),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class GuidedTrainingHistoryScreen extends ConsumerWidget {
  const GuidedTrainingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(guidedTrainingSessionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('구강·호흡 훈련 기록')),
      body: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('기록을 불러올 수 없습니다.')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('아직 저장된 훈련 기록이 없습니다.'))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final session = items[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        session.contentVersion == 'legacy'
                            ? Icons.history
                            : Icons.check_circle_outline,
                        color: Colors.tealAccent,
                      ),
                      title: Text(session.routineName),
                      subtitle: Text(
                        '${session.startedAt.year}.${session.startedAt.month}.${session.startedAt.day} · '
                        '${session.completedExerciseCount}개 · ${session.durationSeconds ~/ 60}분 '
                        '· 피로도 ${session.fatigueBefore}→${session.fatigueAfter ?? '-'}',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise});
  final GuidedTrainingExercise exercise;

  @override
  Widget build(BuildContext context) {
    final locked =
        exercise.safetyTier == GuidedTrainingSafetyTier.clinicianOnly;
    final color = switch (exercise.safetyTier) {
      GuidedTrainingSafetyTier.general => Colors.tealAccent,
      GuidedTrainingSafetyTier.caution => Colors.orangeAccent,
      GuidedTrainingSafetyTier.clinicianOnly => Colors.redAccent,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked
            ? () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('전문가 확인이 필요합니다'),
                  content: Text(exercise.safetyMessage ?? ''),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              )
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GuidedTrainingPlayerScreen(
                    exercises: [exercise],
                    routineName: exercise.title,
                  ),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${exercise.sourceOrder}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.title,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (exercise.hasVideo)
                          const Icon(
                            Icons.play_circle_outline,
                            size: 18,
                            color: Colors.white54,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.shortCaption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${exercise.defaultRepeatCount}회 · ${exercise.safetyTier.label}',
                      style: TextStyle(color: color, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(locked ? Icons.lock_outline : Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.completedToday, required this.onStart});
  final bool completedToday;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF123D3A), Color(0xFF173149)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.self_improvement, color: Colors.tealAccent),
              const SizedBox(width: 8),
              Text(
                completedToday ? '오늘 완료했어요' : '오늘의 추천 루틴',
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '혀·입술·교호·호흡을 짧게 준비해요',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            '4개 운동 · 반복 횟수와 속도를 시작 전에 조절할 수 있어요.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow),
            label: Text(completedToday ? '다시 하기' : '추천 루틴 시작'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white60)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: onPrimary,
                        child: Text(primaryLabel),
                      ),
                      if (secondaryLabel != null)
                        TextButton(
                          onPressed: onSecondary,
                          child: Text(secondaryLabel!),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.count,
    required this.onTap,
  });
  final GuidedTrainingCategory category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (category) {
      GuidedTrainingCategory.tongue => (
        Icons.self_improvement,
        Colors.tealAccent,
      ),
      GuidedTrainingCategory.lip => (
        Icons.face_retouching_natural,
        Colors.pinkAccent,
      ),
      GuidedTrainingCategory.alternating => (Icons.repeat, Colors.amberAccent),
      GuidedTrainingCategory.breathing => (Icons.air, Colors.lightBlueAccent),
    };
    return Card(
      color: color.withValues(alpha: 0.08),
      child: ListTile(
        minTileHeight: 78,
        onTap: onTap,
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          category.label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        subtitle: Text('$count개 · ${category.description}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          '통증, 사레, 삼킴 곤란, 호흡 불편 또는 어지럼이 생기면 즉시 중단하세요. 전문가 확인 항목은 기본 추천 루틴에서 제외됩니다.',
          style: TextStyle(color: Colors.white70, height: 1.45),
        ),
      ),
    );
  }
}
