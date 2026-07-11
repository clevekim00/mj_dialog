class FaceExerciseStep {
  const FaceExerciseStep({
    required this.id,
    required this.title,
    required this.seconds,
  });

  final String id;
  final String title;
  final int seconds;
}

const faceExerciseSteps = [
  FaceExerciseStep(id: 'relaxed', title: '편안한 얼굴', seconds: 3),
  FaceExerciseStep(id: 'open', title: '입 크게 벌리기', seconds: 3),
  FaceExerciseStep(id: 'close', title: '입 다물기', seconds: 3),
  FaceExerciseStep(id: 'pucker', title: '입술 앞으로 모으기', seconds: 3),
  FaceExerciseStep(id: 'smile', title: '넓게 웃기', seconds: 3),
  FaceExerciseStep(id: 'jaw_side', title: '턱 좌우 움직이기', seconds: 4),
  FaceExerciseStep(id: 'cheek_puff', title: '볼 부풀리기', seconds: 3),
];
