import 'package:flutter/material.dart';
import 'package:speech_rehab/features/guided_training/data/guided_training_catalog.dart';
import 'package:speech_rehab/features/guided_training/model/guided_training_models.dart';
import 'package:speech_rehab/services/training/training_settings_service.dart';

class RoutineBuilderScreen extends StatefulWidget {
  const RoutineBuilderScreen({super.key});

  @override
  State<RoutineBuilderScreen> createState() => _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends State<RoutineBuilderScreen> {
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
              return exercise != null &&
                  exercise.safetyTier != GuidedTrainingSafetyTier.clinicianOnly;
            })
            .take(_maximumExercises),
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final available = allGuidedTrainingExercises.where((exercise) {
      return (_category == null || exercise.category == _category) &&
          exercise.safetyTier != GuidedTrainingSafetyTier.clinicianOnly;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('내 루틴 만들기')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
                      final limitReached =
                          _selectedIds.length >= _maximumExercises && !selected;
                      return Card(
                        child: CheckboxListTile(
                          value: selected,
                          onChanged: limitReached
                              ? null
                              : (_) => setState(() {
                                  if (selected) {
                                    _selectedIds.remove(exercise.id);
                                  } else {
                                    _selectedIds.add(exercise.id);
                                  }
                                }),
                          title: Text(exercise.title),
                          subtitle: Text(exercise.shortCaption),
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
          onPressed: _saving ? null : _save,
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
    await TrainingSettingsService.saveCustomRoutineIds(_selectedIds);
    if (!mounted) return;
    Navigator.pop(context, true);
  }
}
