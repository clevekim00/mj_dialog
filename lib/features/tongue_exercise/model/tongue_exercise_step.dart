import 'package:flutter/material.dart';

class TongueExerciseStep {
  const TongueExerciseStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.instruction,
    required this.tip,
    required this.seconds,
    required this.repetitions,
    required this.difficulty,
    required this.targetArea,
    required this.animationType,
    required this.audioText,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final String instruction;
  final String tip;
  final int seconds;
  final int repetitions;
  final TongueExerciseDifficulty difficulty;
  final TongueExerciseTargetArea targetArea;
  final TongueExerciseAnimationType animationType;
  final String audioText;
  final IconData icon;
}

enum TongueExerciseDifficulty { easy, normal, hard }

enum TongueExerciseTargetArea {
  tongueTip,
  tongueBody,
  tongueSide,
  jawTongueCoordination,
}

enum TongueExerciseAnimationType {
  ready,
  tongueOut,
  tongueIn,
  tongueLeft,
  tongueRight,
  tongueUp,
  tongueDown,
  tongueCircle,
  tonguePressCheekLeft,
  tonguePressCheekRight,
  tongueTipUp,
  tongueHold,
  relax,
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
    id: 'tongue_ready',
    title: '준비 호흡',
    subtitle: '어깨와 턱의 힘을 빼고 편안하게 시작해요.',
    instruction: '입술과 턱을 편안히 두고 코로 천천히 숨을 들이마셔요.',
    tip: '혀는 아랫니 뒤쪽에 가볍게 두고 목에 힘을 주지 마세요.',
    seconds: 8,
    repetitions: 1,
    difficulty: TongueExerciseDifficulty.easy,
    targetArea: TongueExerciseTargetArea.jawTongueCoordination,
    animationType: TongueExerciseAnimationType.ready,
    audioText: '어깨와 턱의 힘을 빼고 천천히 준비 호흡을 해 주세요.',
    icon: Icons.self_improvement,
  ),
  TongueExerciseStep(
    id: 'tongue_out',
    title: '혀 내밀기',
    subtitle: '혀를 앞으로 내밀고 잠깐 유지해요.',
    instruction: '입을 살짝 벌리고 혀를 앞으로 천천히 내밀었다가 돌아와요.',
    tip: '턱은 고정하고 혀만 움직이는 느낌으로 해보세요.',
    seconds: 10,
    repetitions: 2,
    difficulty: TongueExerciseDifficulty.easy,
    targetArea: TongueExerciseTargetArea.tongueBody,
    animationType: TongueExerciseAnimationType.tongueOut,
    audioText: '입을 살짝 벌리고 혀를 앞으로 내밀어 주세요.',
    icon: Icons.arrow_forward,
  ),
  TongueExerciseStep(
    id: 'tongue_in',
    title: '혀 넣기',
    subtitle: '내민 혀를 입 안으로 부드럽게 되돌려요.',
    instruction: '혀끝을 긴장시키지 말고 천천히 입 안쪽으로 넣어 주세요.',
    tip: '입술을 세게 다물지 말고 편안한 공간을 유지해요.',
    seconds: 8,
    repetitions: 2,
    difficulty: TongueExerciseDifficulty.easy,
    targetArea: TongueExerciseTargetArea.tongueBody,
    animationType: TongueExerciseAnimationType.tongueIn,
    audioText: '혀를 천천히 입 안으로 넣고 입술을 편안하게 해 주세요.',
    icon: Icons.keyboard_return,
  ),
  TongueExerciseStep(
    id: 'tongue_left',
    title: '혀 왼쪽 이동',
    subtitle: '혀끝을 왼쪽 입꼬리 방향으로 움직여요.',
    instruction: '머리는 움직이지 않고 혀만 왼쪽 입꼬리 쪽으로 천천히 이동해요.',
    tip: '거울을 보듯 화면을 보며 좌우가 헷갈리지 않게 따라 해요.',
    seconds: 8,
    repetitions: 3,
    difficulty: TongueExerciseDifficulty.normal,
    targetArea: TongueExerciseTargetArea.tongueSide,
    animationType: TongueExerciseAnimationType.tongueLeft,
    audioText: '혀를 왼쪽 입꼬리 방향으로 움직여 주세요.',
    icon: Icons.keyboard_arrow_left,
  ),
  TongueExerciseStep(
    id: 'tongue_right',
    title: '혀 오른쪽 이동',
    subtitle: '혀끝을 오른쪽 입꼬리 방향으로 움직여요.',
    instruction: '턱과 고개는 그대로 두고 혀를 오른쪽으로 부드럽게 이동해요.',
    tip: '속도보다 정확한 방향과 편안함이 더 중요해요.',
    seconds: 8,
    repetitions: 3,
    difficulty: TongueExerciseDifficulty.normal,
    targetArea: TongueExerciseTargetArea.tongueSide,
    animationType: TongueExerciseAnimationType.tongueRight,
    audioText: '혀를 오른쪽 입꼬리 방향으로 움직여 주세요.',
    icon: Icons.keyboard_arrow_right,
  ),
  TongueExerciseStep(
    id: 'tongue_up',
    title: '혀 위로 올리기',
    subtitle: '혀끝을 윗입술 방향으로 올려요.',
    instruction: '입을 살짝 열고 혀끝을 위쪽으로 천천히 올렸다가 내려요.',
    tip: '목에 힘이 들어가면 잠깐 쉬고 다시 시작해요.',
    seconds: 8,
    repetitions: 3,
    difficulty: TongueExerciseDifficulty.normal,
    targetArea: TongueExerciseTargetArea.tongueTip,
    animationType: TongueExerciseAnimationType.tongueUp,
    audioText: '혀끝을 위로 올려 주세요.',
    icon: Icons.keyboard_arrow_up,
  ),
  TongueExerciseStep(
    id: 'tongue_down',
    title: '혀 아래로 내리기',
    subtitle: '혀끝을 아랫입술 방향으로 내려요.',
    instruction: '혀끝을 아래쪽으로 천천히 내렸다가 편안한 위치로 돌아와요.',
    tip: '입을 너무 크게 벌리지 않아도 괜찮아요.',
    seconds: 8,
    repetitions: 3,
    difficulty: TongueExerciseDifficulty.normal,
    targetArea: TongueExerciseTargetArea.tongueTip,
    animationType: TongueExerciseAnimationType.tongueDown,
    audioText: '혀끝을 아래로 내려 주세요.',
    icon: Icons.keyboard_arrow_down,
  ),
  TongueExerciseStep(
    id: 'tongue_circle',
    title: '혀 원 그리기',
    subtitle: '입술 둘레를 따라 천천히 원을 그려요.',
    instruction: '혀끝으로 입술 둘레를 천천히 한 바퀴 돌고 반대 방향도 해요.',
    tip: '작은 원부터 시작하고 불편하면 범위를 줄여요.',
    seconds: 14,
    repetitions: 2,
    difficulty: TongueExerciseDifficulty.hard,
    targetArea: TongueExerciseTargetArea.jawTongueCoordination,
    animationType: TongueExerciseAnimationType.tongueCircle,
    audioText: '천천히 원을 그리듯 혀를 움직여 주세요.',
    icon: Icons.sync,
  ),
  TongueExerciseStep(
    id: 'cheek_left',
    title: '왼쪽 볼 밀기',
    subtitle: '혀로 왼쪽 볼 안쪽을 가볍게 밀어요.',
    instruction: '입을 다문 상태에서 혀를 왼쪽 볼 안쪽으로 밀었다가 돌아와요.',
    tip: '볼이 아주 살짝 부풀 정도면 충분해요.',
    seconds: 8,
    repetitions: 3,
    difficulty: TongueExerciseDifficulty.normal,
    targetArea: TongueExerciseTargetArea.tongueSide,
    animationType: TongueExerciseAnimationType.tonguePressCheekLeft,
    audioText: '혀로 왼쪽 볼 안쪽을 가볍게 밀어 주세요.',
    icon: Icons.arrow_back_ios_new,
  ),
  TongueExerciseStep(
    id: 'cheek_right',
    title: '오른쪽 볼 밀기',
    subtitle: '혀로 오른쪽 볼 안쪽을 가볍게 밀어요.',
    instruction: '입을 다문 상태에서 혀를 오른쪽 볼 안쪽으로 밀었다가 돌아와요.',
    tip: '턱을 비틀지 말고 혀 움직임만 느껴보세요.',
    seconds: 8,
    repetitions: 3,
    difficulty: TongueExerciseDifficulty.normal,
    targetArea: TongueExerciseTargetArea.tongueSide,
    animationType: TongueExerciseAnimationType.tonguePressCheekRight,
    audioText: '혀로 오른쪽 볼 안쪽을 가볍게 밀어 주세요.',
    icon: Icons.arrow_forward_ios,
  ),
  TongueExerciseStep(
    id: 'tongue_tip_up',
    title: '혀끝 올리기',
    subtitle: 'ㄹ, ㄴ, ㄷ 준비를 위한 혀끝 움직임이에요.',
    instruction: '혀끝을 윗잇몸 뒤쪽에 가볍게 닿게 한 뒤 편안히 내려요.',
    tip: '세게 누르지 말고 톡 닿는 느낌만 유지해요.',
    seconds: 10,
    repetitions: 3,
    difficulty: TongueExerciseDifficulty.normal,
    targetArea: TongueExerciseTargetArea.tongueTip,
    animationType: TongueExerciseAnimationType.tongueTipUp,
    audioText: '혀끝을 윗잇몸 뒤쪽에 가볍게 올려 주세요.',
    icon: Icons.vertical_align_top,
  ),
  TongueExerciseStep(
    id: 'rest',
    title: '휴식',
    subtitle: '입과 혀의 힘을 빼고 편안히 마무리해요.',
    instruction: '입과 턱의 힘을 빼고 숨을 편안하게 고르며 마무리해요.',
    tip: '잘 따라왔어요. 불편함이 남으면 다음 연습 전 충분히 쉬어주세요.',
    seconds: 10,
    repetitions: 1,
    difficulty: TongueExerciseDifficulty.easy,
    targetArea: TongueExerciseTargetArea.jawTongueCoordination,
    animationType: TongueExerciseAnimationType.relax,
    audioText: '입과 혀의 힘을 빼고 편안히 쉬어 주세요.',
    icon: Icons.self_improvement,
  ),
];
