class TrainingVideoSpec {
  const TrainingVideoSpec({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.captionTemplate,
    required this.defaultRepeatCount,
  });

  final String id;
  final String title;
  final String assetPath;
  final String captionTemplate;
  final int defaultRepeatCount;
}

const trainingVideoSpecs = <TrainingVideoSpec>[
  TrainingVideoSpec(
    id: 'tongue_out',
    title: '혀 내밀기',
    assetPath: 'assets/videos/training/01_tongue_out.mp4',
    captionTemplate: '혀를 앞으로 내밀었다 돌아오세요. {repeatCount}회 반복하세요.',
    defaultRepeatCount: 3,
  ),
  TrainingVideoSpec(
    id: 'tongue_side',
    title: '혀 좌우 이동',
    assetPath: 'assets/videos/training/02_tongue_side.mp4',
    captionTemplate: '고개는 고정하고 혀만 좌우로 움직이세요. {repeatCount}회 반복하세요.',
    defaultRepeatCount: 3,
  ),
  TrainingVideoSpec(
    id: 'tongue_up_down',
    title: '혀 위아래 이동',
    assetPath: 'assets/videos/training/03_tongue_up_down.mp4',
    captionTemplate: '혀끝을 위와 아래로 천천히 움직이세요. {repeatCount}회 반복하세요.',
    defaultRepeatCount: 3,
  ),
  TrainingVideoSpec(
    id: 'tongue_circle',
    title: '혀 원 그리기',
    assetPath: 'assets/videos/training/04_tongue_circle.mp4',
    captionTemplate: '혀끝으로 입술 둘레를 천천히 돌리세요. 방향별 {repeatCount}회 반복하세요.',
    defaultRepeatCount: 2,
  ),
  TrainingVideoSpec(
    id: 'cheek_press',
    title: '혀로 볼 밀기',
    assetPath: 'assets/videos/training/05_cheek_press.mp4',
    captionTemplate: '혀로 양쪽 볼 안쪽을 번갈아 미세요. 각 {repeatCount}회 반복하세요.',
    defaultRepeatCount: 3,
  ),
  TrainingVideoSpec(
    id: 'mouth_open_close',
    title: '입 벌리고 다물기',
    assetPath: 'assets/videos/training/06_mouth_open_close.mp4',
    captionTemplate: '입을 편안하게 벌렸다 부드럽게 다무세요. {repeatCount}회 반복하세요.',
    defaultRepeatCount: 3,
  ),
  TrainingVideoSpec(
    id: 'lip_round_smile',
    title: '입술 모으고 웃기',
    assetPath: 'assets/videos/training/07_lip_round_smile.mp4',
    captionTemplate: '입술을 오 모양으로 모았다 이 모양으로 웃으세요. {repeatCount}회 반복하세요.',
    defaultRepeatCount: 3,
  ),
  TrainingVideoSpec(
    id: 'cheek_puff',
    title: '볼 부풀리기',
    assetPath: 'assets/videos/training/08_cheek_puff.mp4',
    captionTemplate: '입술을 다물고 양쪽 볼을 천천히 부풀리세요. {repeatCount}회 반복하세요.',
    defaultRepeatCount: 3,
  ),
  TrainingVideoSpec(
    id: 'diaphragmatic_breath',
    title: '편안한 호흡',
    assetPath: 'assets/videos/training/09_diaphragmatic_breath.mp4',
    captionTemplate: '코로 들이마시고 입으로 천천히 내쉬세요. {repeatCount}회 반복하세요.',
    defaultRepeatCount: 3,
  ),
  TrainingVideoSpec(
    id: 'sustained_voice',
    title: '지속 발성',
    assetPath: 'assets/videos/training/10_sustained_voice.mp4',
    captionTemplate: '편안한 높이로 아 소리를 길게 내세요. {repeatCount}회 반복하세요.',
    defaultRepeatCount: 3,
  ),
];

TrainingVideoSpec? trainingVideoFor(String stepId) {
  const aliases = <String, String>{
    'tongue_left': 'tongue_side',
    'tongue_right': 'tongue_side',
    'tongue_up': 'tongue_up_down',
    'tongue_down': 'tongue_up_down',
    'cheek_left': 'cheek_press',
    'cheek_right': 'cheek_press',
    'open': 'mouth_open_close',
    'close': 'mouth_open_close',
    'pucker': 'lip_round_smile',
    'smile': 'lip_round_smile',
    'breath': 'diaphragmatic_breath',
  };
  final target = aliases[stepId] ?? stepId;
  for (final spec in trainingVideoSpecs) {
    if (spec.id == target) return spec;
  }
  return null;
}
