class OralAlternatingStep {
  const OralAlternatingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.seconds,
    required this.shape,
    this.pronunciation,
  });

  final String id;
  final String title;
  final String description;
  final int seconds;
  final String shape;
  final String? pronunciation;
}

const oralAlternatingSteps = [
  OralAlternatingStep(
    id: 'neutral',
    title: '중립 얼굴',
    description: '입과 턱의 힘을 가볍게 풀어요.',
    seconds: 3,
    shape: 'neutral',
  ),
  OralAlternatingStep(
    id: 'a',
    title: '아 발음',
    description: '입을 크게 열며 아 소리를 냅니다.',
    seconds: 3,
    shape: 'open',
    pronunciation: '아',
  ),
  OralAlternatingStep(
    id: 'i',
    title: '이 발음',
    description: '입술을 옆으로 넓게 당깁니다.',
    seconds: 3,
    shape: 'wideSmile',
    pronunciation: '이',
  ),
  OralAlternatingStep(
    id: 'u',
    title: '우 발음',
    description: '입술을 둥글게 앞으로 모읍니다.',
    seconds: 3,
    shape: 'round',
    pronunciation: '우',
  ),
  OralAlternatingStep(
    id: 'aiu',
    title: '아-이-우 연속',
    description: '입 모양을 크게, 넓게, 둥글게 이어갑니다.',
    seconds: 4,
    shape: 'pataka',
    pronunciation: '아 이 우',
  ),
  OralAlternatingStep(
    id: 'pataka',
    title: '파-타-카 교대',
    description: '입술, 혀끝, 뒤쪽 혀 움직임을 번갈아 씁니다.',
    seconds: 4,
    shape: 'pataka',
    pronunciation: '파 타 카',
  ),
  OralAlternatingStep(
    id: 'lalala',
    title: '라-라-라 혀끝',
    description: '혀끝을 가볍게 움직입니다.',
    seconds: 4,
    shape: 'lala',
    pronunciation: '라 라 라',
  ),
  OralAlternatingStep(
    id: 'jaw',
    title: '턱 좌우 움직임',
    description: '무리하지 않는 범위에서 턱을 좌우로 움직입니다.',
    seconds: 4,
    shape: 'jawMove',
  ),
  OralAlternatingStep(
    id: 'tongue-side',
    title: '혀 좌우 움직임',
    description: '입을 살짝 열고 혀를 좌우로 움직입니다.',
    seconds: 4,
    shape: 'tongueMove',
  ),
  OralAlternatingStep(
    id: 'relax',
    title: '편안히 쉬기',
    description: '입과 턱, 볼의 힘을 빼고 쉬어요.',
    seconds: 3,
    shape: 'neutral',
  ),
];
