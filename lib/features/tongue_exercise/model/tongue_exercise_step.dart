import 'package:flutter/material.dart';

class TongueExerciseStep {
  const TongueExerciseStep({
    required this.id,
    required this.title,
    required this.instruction,
    required this.seconds,
    required this.repetitions,
    required this.icon,
  });

  final String id;
  final String title;
  final String instruction;
  final int seconds;
  final int repetitions;
  final IconData icon;
}

class TongueExerciseSession {
  const TongueExerciseSession({
    required this.id,
    required this.timestamp,
    required this.completedStepCount,
    required this.totalStepCount,
    required this.durationSeconds,
    required this.fatigueBefore,
    required this.fatigueAfter,
    required this.completedStepIds,
  });

  final String id;
  final DateTime timestamp;
  final int completedStepCount;
  final int totalStepCount;
  final int durationSeconds;
  final int fatigueBefore;
  final int? fatigueAfter;
  final List<String> completedStepIds;

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'completedStepCount': completedStepCount,
    'totalStepCount': totalStepCount,
    'durationSeconds': durationSeconds,
    'fatigueBefore': fatigueBefore,
    'fatigueAfter': fatigueAfter,
    'completedStepIds': completedStepIds,
  };

  factory TongueExerciseSession.fromJson(Map<String, dynamic> json) {
    return TongueExerciseSession(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      completedStepCount: json['completedStepCount'] as int? ?? 0,
      totalStepCount: json['totalStepCount'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      fatigueBefore: json['fatigueBefore'] as int? ?? 1,
      fatigueAfter: json['fatigueAfter'] as int?,
      completedStepIds:
          (json['completedStepIds'] as List?)?.cast<String>() ?? const [],
    );
  }
}

const tongueExerciseSteps = [
  TongueExerciseStep(
    id: 'tongue_out',
    title: '혀 내밀기',
    instruction: '편안히 입을 벌리고 혀를 천천히 내밀어 10초 동안 유지해요.',
    seconds: 10,
    repetitions: 1,
    icon: Icons.face_retouching_natural,
  ),
  TongueExerciseStep(
    id: 'tongue_side',
    title: '좌우 움직이기',
    instruction: '혀를 편안한 범위에서 왼쪽과 오른쪽으로 천천히 움직여요.',
    seconds: 30,
    repetitions: 5,
    icon: Icons.swap_horiz,
  ),
  TongueExerciseStep(
    id: 'tongue_up_down',
    title: '위아래 움직이기',
    instruction: '혀끝을 위아래로 천천히 움직이고 중간에 잠깐 쉬어도 괜찮아요.',
    seconds: 30,
    repetitions: 5,
    icon: Icons.swap_vert,
  ),
  TongueExerciseStep(
    id: 'tongue_roof',
    title: '입천장에 대기',
    instruction: '혀끝을 입천장에 가볍게 대고 10초 동안 편안하게 유지해요.',
    seconds: 10,
    repetitions: 1,
    icon: Icons.keyboard_arrow_up,
  ),
  TongueExerciseStep(
    id: 'lip_circle',
    title: '입술 둘레 돌기',
    instruction: '혀로 입술 둘레를 천천히 한 바퀴씩 양방향으로 돌아요.',
    seconds: 60,
    repetitions: 2,
    icon: Icons.sync,
  ),
  TongueExerciseStep(
    id: 'rest',
    title: '힘 빼고 쉬기',
    instruction: '입과 턱의 힘을 빼고 숨을 편안하게 고르며 마무리해요.',
    seconds: 20,
    repetitions: 1,
    icon: Icons.self_improvement,
  ),
];
