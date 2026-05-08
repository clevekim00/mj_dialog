import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class RehabProfile {
  const RehabProfile({
    required this.strokeStage,
    required this.primaryGoal,
    required this.dailyPracticeMinutes,
    required this.hasCaregiverSupport,
    required this.acceptedSafetyNoticeAt,
  });

  final String strokeStage;
  final String primaryGoal;
  final int dailyPracticeMinutes;
  final bool hasCaregiverSupport;
  final DateTime acceptedSafetyNoticeAt;

  Map<String, dynamic> toJson() => {
    'strokeStage': strokeStage,
    'primaryGoal': primaryGoal,
    'dailyPracticeMinutes': dailyPracticeMinutes,
    'hasCaregiverSupport': hasCaregiverSupport,
    'acceptedSafetyNoticeAt': acceptedSafetyNoticeAt.toIso8601String(),
  };

  factory RehabProfile.fromJson(Map<String, dynamic> json) {
    return RehabProfile(
      strokeStage: json['strokeStage'] as String? ?? 'unknown',
      primaryGoal: json['primaryGoal'] as String? ?? 'clearSpeech',
      dailyPracticeMinutes: json['dailyPracticeMinutes'] as int? ?? 5,
      hasCaregiverSupport: json['hasCaregiverSupport'] as bool? ?? false,
      acceptedSafetyNoticeAt:
          DateTime.tryParse(json['acceptedSafetyNoticeAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class RehabProfileService {
  static const String _profileKey = 'rehab_profile';

  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileKey) != null;
  }

  static Future<RehabProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProfile = prefs.getString(_profileKey);
    if (rawProfile == null) {
      return null;
    }

    try {
      return RehabProfile.fromJson(
        jsonDecode(rawProfile) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProfile(RehabProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }
}
