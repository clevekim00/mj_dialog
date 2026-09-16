import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

class RehabProfile {
  const RehabProfile({
    required this.practiceStage,
    required this.primaryGoal,
    required this.dailyPracticeMinutes,
    required this.hasCaregiverSupport,
    required this.acceptedSafetyNoticeAt,
  });

  final String practiceStage;
  final String primaryGoal;
  final int dailyPracticeMinutes;
  final bool hasCaregiverSupport;
  final DateTime acceptedSafetyNoticeAt;

  Map<String, dynamic> toJson() => {
    'practiceStage': practiceStage,
    'primaryGoal': primaryGoal,
    'dailyPracticeMinutes': dailyPracticeMinutes,
    'hasCaregiverSupport': hasCaregiverSupport,
    'acceptedSafetyNoticeAt': acceptedSafetyNoticeAt.toIso8601String(),
  };

  factory RehabProfile.fromJson(Map<String, dynamic> json) {
    return RehabProfile(
      practiceStage: json['practiceStage'] as String? ?? 'unknown',
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

final rehabProfileProvider = FutureProvider<RehabProfile?>(
  (ref) => RehabProfileService.loadProfile(),
);

class RehabSessionPreferences {
  const RehabSessionPreferences({
    this.goal = '또렷하게 말하기',
    this.dailyMinutes = 5,
    this.fatigueBefore,
  });
  final String goal;
  final int dailyMinutes;
  final int? fatigueBefore;
  int get durationMinutes =>
      (fatigueBefore ?? 0) >= 4 ? dailyMinutes.clamp(1, 3) : dailyMinutes;
}

final rehabSessionProvider =
    NotifierProvider<RehabSessionController, RehabSessionPreferences>(
      RehabSessionController.new,
    );

class RehabSessionController extends Notifier<RehabSessionPreferences> {
  String? _selectedGoal;
  int? _selectedFatigue;
  @override
  RehabSessionPreferences build() {
    final profile = ref.watch(rehabProfileProvider).asData?.value;
    return RehabSessionPreferences(
      goal:
          _selectedGoal ??
          (profile == null
              ? '또렷하게 말하기'
              : switch (profile.primaryGoal) {
                  'clearSpeech' => '또렷하게 말하기',
                  'slowSpeech' => '천천히 말하기',
                  'loudSpeech' => '크게 말하기',
                  'breathing' => '숨 조절하기',
                  _ => '또렷하게 말하기',
                }),
      fatigueBefore: _selectedFatigue,
      dailyMinutes: (profile?.dailyPracticeMinutes ?? 5).clamp(1, 30),
    );
  }

  void setGoal(String goal) {
    _selectedGoal = goal;
    state = RehabSessionPreferences(
      goal: goal,
      dailyMinutes: state.dailyMinutes,
      fatigueBefore: state.fatigueBefore,
    );
  }

  void beginSession() {
    _selectedFatigue = null;
    state = RehabSessionPreferences(
      goal: state.goal,
      dailyMinutes: state.dailyMinutes,
    );
  }

  void setFatigue(int fatigue) {
    _selectedFatigue = fatigue.clamp(1, 5);
    state = RehabSessionPreferences(
      goal: state.goal,
      dailyMinutes: state.dailyMinutes,
      fatigueBefore: _selectedFatigue,
    );
  }
}
