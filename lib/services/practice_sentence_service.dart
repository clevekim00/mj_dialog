import 'package:flutter_riverpod/flutter_riverpod.dart';

final practiceSentenceServiceProvider = Provider((ref) => PracticeSentenceService());

class PracticeSentenceService {
  // These are linguistically selected difficult Korean phrases for pronunciation/articulation rehab.
  static const List<String> _difficultSentences = [
    '간장 공장 공장장은 강 공장장이고, 된장 공장 공장장은 장 공장장이다.',
    '우리 집 옆집 앞집 뒷창살은 홑겹창살이고, 우리 집 뒷집 앞집 옆창살은 겹홑창살이다.',
    '저기 저 뜀틀이 내가 뛸 뜀틀인가 내가 안 뛸 뜀틀인가.',
    '서울특별시 특허허가과 허가과장 허과장.',
    '멍멍이네 꿀꿀이는 멍멍해도 꿀꿀이네 멍멍이는 꿀꿀하네.',
    '경찰청 창살 외철창살, 검찰청 창살 쌍철창살.',
    '들판의 밀밭은 갓 깎은 밀밭인가 안 깎은 밀밭인가.',
    '고려고 교복은 고급 교복이고 고려고 교복은 고급 코트다.',
  ];

  static const List<String> _dailySentences = [
    '안녕하세요, 오늘 날씨가 참 맑고 화창하네요.',
    '따뜻한 아메리카노 한 잔 부탁드립니다.',
    '버스 정류장까지 가는 길을 가르쳐 주시겠어요?',
    '내일 오전 열 시에 중요한 회의가 있습니다.',
    '꾸준한 연습만이 올바른 언어 습관을 만드는 비결입니다.',
  ];

  /// Returns a combined list of sentences. 
  /// In the future, this could fetch from a database of common mistakes.
  Future<List<String>> getRecommendedSentences() async {
    // Logic can be added here to prioritize sentences based on user logs
    return [
      ..._difficultSentences,
      ..._dailySentences,
    ];
  }
}
