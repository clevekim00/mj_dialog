import 'package:speech_rehab/features/practice/model/practice_mode.dart';

/// Explicit launch intent prevents a previous screen's mode leaking into a task.
class TrainingLaunchSpec {
  const TrainingLaunchSpec({required this.mode, this.text, this.goal});
  final PracticeMode mode;
  final String? text;
  final String? goal;
}
