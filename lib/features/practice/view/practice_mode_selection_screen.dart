import 'package:flutter/material.dart';
import 'package:speech_rehab/services/rehab_profile_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/features/rehab/model/rehab_session.dart';
import 'package:speech_rehab/features/rehab/services/rehab_session_repository.dart';
import 'package:speech_rehab/features/rehab/view/rehab_setup_screen.dart';
import 'package:speech_rehab/features/rehab/view/rehab_ui.dart';
import 'package:speech_rehab/features/rehab/view/rehab_records_screen.dart';

/// Home offers one selected plan. Catalog browsing belongs in Training.
class PracticeModeSelectionScreen extends ConsumerStatefulWidget {
  const PracticeModeSelectionScreen({super.key});
  @override
  ConsumerState<PracticeModeSelectionScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<PracticeModeSelectionScreen> {
  late Future<({String scenarioId, int repetitions})> _plan;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _plan = ref.read(rehabRepositoryProvider).loadPlan();
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (!mounted) return;
    ref.invalidate(rehabSessionsProvider);
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final l = rehabL10n(context), en = rehabEnglish(context);
    final sessions = ref.watch(rehabSessionsProvider);
    final profile = ref.watch(rehabProfileProvider).asData?.value;
    return RehabPage(
      title: l.rehabToday,
      children: [
        Text(l.rehabIdentity, style: Theme.of(context).textTheme.titleLarge),
        if (profile != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              en
                  ? 'Daily goal: ${profile.dailyPracticeMinutes} minutes · this plan uses a repetition target.'
                  : '하루 목표 ${profile.dailyPracticeMinutes}분 · 이번 계획은 반복 횟수를 기준으로 해요.',
            ),
          ),
        const SizedBox(height: 24),
        sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Column(
            children: [
              Text(l.rehabLoadingError),
              TextButton(
                onPressed: () => ref.invalidate(rehabSessionsProvider),
                child: Text(l.rehabRetry),
              ),
            ],
          ),
          data: (items) => FutureBuilder<({String scenarioId, int repetitions})>(
            future: _plan,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  children: [
                    Text(l.rehabLoadingError),
                    TextButton(
                      onPressed: () => setState(_reload),
                      child: Text(l.rehabRetry),
                    ),
                  ],
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final plan = snapshot.data!;
              final scenario = rehabScenarios.firstWhere(
                (s) => s.id == plan.scenarioId,
                orElse: () => rehabScenarios.first,
              );
              final ongoing = items
                  .where(
                    (s) =>
                        s.canResume && s.language == (en ? 'en-US' : 'ko-KR'),
                  )
                  .firstOrNull;
              final today = items
                  .where(
                    (s) =>
                        s.localDate == rehabDate(DateTime.now()) &&
                        s.feedback['kind'] != 'voiceFlight' &&
                        s.feedback['kind'] != 'mpt',
                  )
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l.rehabPlan),
                          const SizedBox(height: 12),
                          Text(
                            ongoing?.title ?? scenario.title(en),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            ongoing != null
                                ? ongoing.tasks.map((t) => t.title).join(' → ')
                                : l.rehabSequence,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            en
                                ? '${ongoing?.tasks.length ?? 3} tasks · ${ongoing?.repetitions ?? plan.repetitions} recordings each'
                                : '${ongoing?.tasks.length ?? 3}개 과제 · 과제마다 ${ongoing?.repetitions ?? plan.repetitions}번 녹음',
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                            ),
                            onPressed: () => _open(
                              RehabSetupScreen(
                                resume: ongoing,
                                scenarioId: scenario.id,
                                repetitions: plan.repetitions,
                              ),
                            ),
                            icon: Icon(
                              ongoing == null
                                  ? Icons.play_arrow
                                  : Icons.play_circle_outline,
                            ),
                            label: Text(
                              ongoing == null ? l.rehabStart : l.rehabResume,
                            ),
                          ),
                          if (ongoing == null)
                            TextButton(
                              onPressed: () => _open(
                                RehabSetupScreen(
                                  scenarioId: scenario.id,
                                  repetitions: plan.repetitions,
                                ),
                              ),
                              child: Text(l.rehabChangePlan),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    en
                        ? '${today.expand((s) => s.takes).length} recordings in today’s plans'
                        : '오늘 계획에서 녹음 ${today.expand((s) => s.takes).length}번',
                  ),
                  const SizedBox(height: 12),
                  RehabCard(
                    title: l.rehabRecent,
                    subtitle: en
                        ? 'View practice and previous recordings'
                        : '연습 기록과 이전 녹음을 확인하세요',
                    icon: Icons.history,
                    onTap: () => _open(const RehabRecordsScreen()),
                  ),
                  const SizedBox(height: 20),
                  Text(l.rehabSafety),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
