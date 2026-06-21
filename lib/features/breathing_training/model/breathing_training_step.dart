class BreathingTrainingStep {
  const BreathingTrainingStep({
    required this.id,
    required this.title,
    required this.seconds,
  });

  final String id;
  final String title;
  final int seconds;
}

const breathingTrainingSteps = [
  BreathingTrainingStep(id: 'neutral', title: '중립 얼굴', seconds: 3),
  BreathingTrainingStep(id: 'breath', title: '깊은 호흡 준비', seconds: 4),
  BreathingTrainingStep(id: 'open', title: '입 크게 벌리기', seconds: 3),
  BreathingTrainingStep(id: 'close', title: '입 부드럽게 다물기', seconds: 3),
  BreathingTrainingStep(id: 'smile', title: '넓게 웃기', seconds: 3),
  BreathingTrainingStep(id: 'round', title: '입술 둥글게 오', seconds: 3),
  BreathingTrainingStep(id: 'tongue_out', title: '혀 내밀고 넣기', seconds: 4),
  BreathingTrainingStep(id: 'tongue_side', title: '혀 좌우 움직이기', seconds: 4),
  BreathingTrainingStep(id: 'cheek_puff', title: '볼 부풀리기', seconds: 3),
  BreathingTrainingStep(id: 'relax', title: '편안히 쉬기', seconds: 4),
];
