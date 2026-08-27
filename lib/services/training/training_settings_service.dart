import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TrainingSettingsService {
  static const _defaultRepeatKey = 'training_default_repeat_count';
  static const _playbackSpeedKey = 'training_playback_speed';
  static const _captionsEnabledKey = 'training_captions_enabled';
  static const _captionScaleKey = 'training_caption_scale';
  static const _ttsEnabledKey = 'training_tts_enabled';
  static const _hapticsEnabledKey = 'training_haptics_enabled';
  static const _customRoutineKey = 'training_custom_routine_ids';

  static const defaultRepeatCount = 20;
  static const defaultPlaybackSpeed = 0.75;

  static Future<int> loadDefaultRepeatCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_defaultRepeatKey) ?? defaultRepeatCount).clamp(1, 30);
  }

  static Future<void> saveDefaultRepeatCount(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultRepeatKey, value.clamp(1, 30));
  }

  static Future<int> loadRepeatCount(String trainingId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt('training_repeat_$trainingId') ??
            await loadDefaultRepeatCount())
        .clamp(1, 30);
  }

  static Future<void> saveRepeatCount(String trainingId, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('training_repeat_$trainingId', value.clamp(1, 30));
  }

  static Future<double> loadPlaybackSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_playbackSpeedKey) ?? defaultPlaybackSpeed;
    return const [0.5, 0.75, 1.0].contains(value)
        ? value
        : defaultPlaybackSpeed;
  }

  static Future<void> savePlaybackSpeed(double value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = const [0.5, 0.75, 1.0].contains(value)
        ? value
        : defaultPlaybackSpeed;
    await prefs.setDouble(_playbackSpeedKey, normalized);
  }

  static Future<bool> loadCaptionsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_captionsEnabledKey) ?? true;
  }

  static Future<void> saveCaptionsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_captionsEnabledKey, value);
  }

  static Future<double> loadCaptionScale() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_captionScaleKey) ?? 1;
    return const [1.0, 1.25, 1.5].contains(value) ? value : 1;
  }

  static Future<void> saveCaptionScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = const [1.0, 1.25, 1.5].contains(value) ? value : 1.0;
    await prefs.setDouble(_captionScaleKey, normalized);
  }

  static Future<bool> loadTtsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_ttsEnabledKey) ?? true;
  }

  static Future<void> saveTtsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ttsEnabledKey, value);
  }

  static Future<bool> loadHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hapticsEnabledKey) ?? true;
  }

  static Future<void> saveHapticsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticsEnabledKey, value);
  }

  static Future<List<String>> loadCustomRoutineIds() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_customRoutineKey);
    if (value == null) return [];
    try {
      return (jsonDecode(value) as List<dynamic>).whereType<String>().toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomRoutineIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customRoutineKey, jsonEncode(ids.take(8).toList()));
  }

  static String renderCaption(String template, int repeatCount) {
    return template.replaceAll('{repeatCount}', repeatCount.toString());
  }
}
