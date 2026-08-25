import 'package:shared_preferences/shared_preferences.dart';

class TrainingSettingsService {
  static const _defaultRepeatKey = 'training_default_repeat_count';
  static const defaultRepeatCount = 3;

  static Future<int> loadDefaultRepeatCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_defaultRepeatKey) ?? defaultRepeatCount).clamp(1, 10);
  }

  static Future<void> saveDefaultRepeatCount(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultRepeatKey, value.clamp(1, 10));
  }

  static Future<int> loadRepeatCount(String trainingId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt('training_repeat_$trainingId') ??
            await loadDefaultRepeatCount())
        .clamp(1, 10);
  }

  static Future<void> saveRepeatCount(String trainingId, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('training_repeat_$trainingId', value.clamp(1, 10));
  }

  static String renderCaption(String template, int repeatCount) {
    return template.replaceAll('{repeatCount}', repeatCount.toString());
  }
}
