import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../model/rehab_session.dart';
import '../services/rehab_session_repository.dart';
import 'rehab_player_screen.dart';
import 'rehab_ui.dart';

class RehabSetupScreen extends ConsumerStatefulWidget {
  const RehabSetupScreen({
    super.key,
    this.resume,
    this.scenarioId = 'rest',
    this.repetitions = 1,
    this.pacing = false,
    this.customText,
    this.contentLanguage,
  });
  final RehabSession? resume;
  final String scenarioId;
  final int repetitions;
  final bool pacing;
  final String? customText;
  final String? contentLanguage;
  @override
  ConsumerState<RehabSetupScreen> createState() => _RehabSetupScreenState();
}

class _RehabSetupScreenState extends ConsumerState<RehabSetupScreen> {
  late String _scenarioId;
  late int _repetitions;
  int? _fatigue;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _scenarioId = widget.scenarioId;
    _repetitions = widget.repetitions;
  }

  Future<void> _begin() async {
    if (_saving || _fatigue == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final en = rehabEnglish(context);
    final scenario = rehabScenarios.firstWhere(
      (s) => s.id == _scenarioId,
      orElse: () => rehabScenarios.first,
    );
    final now = DateTime.now();
    final tasks = widget.customText != null
        ? [
            RehabTask(
              id: 'personal',
              title: rehabL10n(context).rehabRepeat,
              text: widget.customText!,
              instruction: en
                  ? 'Listen and repeat at your own pace.'
                  : '예시를 듣고 편안하게 반복해 보세요.',
            ),
          ]
        : scenario.tasks(en, pacing: widget.pacing);
    final session =
        widget.resume?.copyWith(
          status: RehabStatus.inProgress,
          fatigueChecks: [...widget.resume!.fatigueChecks, _fatigue!],
        ) ??
        RehabSession(
          id: const Uuid().v4(),
          title: widget.customText != null
              ? rehabL10n(context).rehabRepeat
              : scenario.title(en),
          language: widget.contentLanguage ?? (en ? 'en-US' : 'ko-KR'),
          startedAt: now.toUtc(),
          localDate: rehabDate(now),
          offsetMinutes: now.timeZoneOffset.inMinutes,
          tasks: tasks,
          repetitions: _repetitions,
          fatigueBefore: _fatigue!,
          fatigueChecks: [_fatigue!],
        );
    try {
      final repo = ref.read(rehabRepositoryProvider);
      if (widget.resume == null &&
          widget.customText == null &&
          !widget.pacing) {
        await repo.savePlan(scenario.id, _repetitions);
      }
      await repo.save(session);
      ref.invalidate(rehabSessionsProvider);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => RehabPlayerScreen(session: session),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = rehabL10n(context).rehabSaveError;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = rehabL10n(context);
    final en = rehabEnglish(context);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(l.rehabPrepare)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.resume?.title ?? l.rehabPlan,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (widget.resume == null && widget.customText == null) ...[
                  RadioGroup<String>(
                    groupValue: _scenarioId,
                    onChanged: (v) {
                      if (!_saving && v != null) {
                        setState(() => _scenarioId = v);
                      }
                    },
                    child: Column(
                      children: [
                        for (final scenario in rehabScenarios)
                          RadioListTile<String>(
                            title: Text(scenario.title(en)),
                            value: scenario.id,
                            enabled: !_saving,
                          ),
                      ],
                    ),
                  ),
                  Text(l.rehabSequence),
                ],
                if (widget.customText != null)
                  Text(
                    widget.customText!,
                    style: const TextStyle(fontSize: 24),
                  ),
                if (widget.resume == null) ...[
                  const SizedBox(height: 20),
                  Text(l.rehabRepetitions),
                  Wrap(
                    spacing: 12,
                    children: [
                      for (final n in [1, 2, 3])
                        ChoiceChip(
                          label: Text(en ? '$n times' : '$n번'),
                          selected: _repetitions == n,
                          onSelected: _saving
                              ? null
                              : (_) => setState(() => _repetitions = n),
                        ),
                    ],
                  ),
                  if (widget.customText == null && !widget.pacing)
                    Text(l.rehabPlanSaved),
                ],
                const SizedBox(height: 24),
                Text(
                  l.rehabFatigue,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(l.rehabFatigueHint),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var n = 1; n <= 5; n++)
                      ChoiceChip(
                        label: Text('$n / 5'),
                        selected: _fatigue == n,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _fatigue = n),
                      ),
                  ],
                ),
                if ((_fatigue ?? 0) >= 4)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(l.rehabRestHint),
                  ),
                const SizedBox(height: 24),
                Text(l.rehabSafety),
                const SizedBox(height: 16),
                Text(l.rehabNoMic),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: _saving || _fatigue == null ? null : _begin,
              child: Text(l.rehabBegin),
            ),
          ),
        ),
      ),
    );
  }
}
