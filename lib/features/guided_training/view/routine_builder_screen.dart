import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/services/training/training_availability_provider.dart';
import 'package:flutter/material.dart';
import 'package:speech_rehab/features/guided_training/data/guided_training_catalog.dart';
import 'package:speech_rehab/features/guided_training/model/guided_training_models.dart';
import 'package:speech_rehab/services/training/training_settings_service.dart';

class RoutineBuilderScreen extends ConsumerStatefulWidget {
  const RoutineBuilderScreen({super.key});

  @override
  ConsumerState<RoutineBuilderScreen> createState() =>
      _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends ConsumerState<RoutineBuilderScreen> {
  static const _maximumExercises = 8;
  final List<String> _selectedIds = [];
  GuidedTrainingCategory? _category;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await TrainingSettingsService.loadCustomRoutineIds();
    if (!mounted) return;
    setState(() {
      _selectedIds.addAll(
        ids
            .where((id) {
              final exercise = guidedExerciseById(id);
              return exercise != null;
            })
            .take(_maximumExercises),
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final policy = ref.watch(trainingAvailabilityProvider);
    final available = allGuidedTrainingExercises.where((exercise) {
      return _category == null || exercise.category == _category;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('내 루틴 만들기')),
      body: _loading || policy.isLoading
          ? const Center(child: CircularProgressIndicator())
          : policy.hasError
          ? Center(
              child: TextButton(
                onPressed: () => ref.invalidate(trainingAvailabilityProvider),
                child: const Text('설정 불러오기 다시 시도'),
              ),
            )
          : Column(
              children: [
                if (_selectedIds.isNotEmpty) _buildSelected(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: DropdownButtonFormField<GuidedTrainingCategory?>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: '운동 종류',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('전체')),
                      for (final category in GuidedTrainingCategory.values)
                        DropdownMenuItem(
                          value: category,
                          child: Text(category.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => _category = value),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    itemCount: available.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final exercise = available[index];
                      final selected = _selectedIds.contains(exercise.id);
                      final enabled =
                          policy.asData?.value.isEnabled(exercise.id) ?? false;
                      final limitReached =
                          _selectedIds.length >= _maximumExercises && !selected;
                      return Card(
                        child: CheckboxListTile(
                          value: selected,
                          onChanged: limitReached || (!enabled && !selected)
                              ? null
                              : (_) => setState(() {
                                  if (selected) {
                                    _selectedIds.remove(exercise.id);
                                  } else {
                                    _selectedIds.add(exercise.id);
                                  }
                                }),
                          title: Text(exercise.title),
                          subtitle: Text(
                            enabled
                                ? exercise.shortCaption
                                : '관리자가 일시적으로 닫은 훈련 · 루틴 실행 시 건너뜁니다',
                          ),
                          secondary: CircleAvatar(
                            child: Text('${exercise.sourceOrder}'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _saving || _loading || policy.asData == null
              ? null
              : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text('저장 (${_selectedIds.length}/$_maximumExercises)'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
        ),
      ),
    );
  }

  Widget _buildSelected() {
    return Container(
      color: Colors.white.withValues(alpha: 0.04),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('선택 순서', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedIds.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final exercise = guidedExerciseById(_selectedIds[index])!;
                return InputChip(
                  avatar: Text('${index + 1}'),
                  label: Text(exercise.title),
                  onDeleted: () => setState(() => _selectedIds.removeAt(index)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final policy = ref.read(trainingAvailabilityProvider).asData?.value;
    if (policy == null) {
      setState(() => _saving = false);
      return;
    }
    await TrainingSettingsService.saveCustomRoutineIds(_selectedIds);
    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
