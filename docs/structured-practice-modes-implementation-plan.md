# 구조화된 발음 연습 모드 구현 계획

작성일: 2026-06-01

구현 상태: 2026-06-02 기준 MVP 반영 완료 및 UX 개선 반영

반영 파일:

```text
lib/features/practice/model/practice_mode.dart
lib/services/practice_content_service.dart
lib/features/practice/view/practice_mode_selection_screen.dart
lib/features/practice/view/word_game_screen.dart
lib/features/practice/provider/practice_provider.dart
lib/features/practice/view/practice_screen.dart
lib/features/practice/view/practice_history_screen.dart
lib/features/practice/view/dashboard_screen.dart
lib/features/chat/view/history_screen.dart
lib/services/practice_history_service.dart
lib/services/practice_content_service.dart
lib/services/api/ai_service.dart
```

검증 결과:

```text
dart analyze
→ No issues found

flutter test
→ All tests passed
```

## 1. 목적

현재 앱은 자유 대화와 소리 내어 읽기 연습을 중심으로 구성되어 있다. 자유 대화는 실제 말하기 상황에 가깝다는 장점이 있지만, 사용자가 매번 다른 말을 하기 때문에 발음 평가와 이전 기록 비교가 안정적이지 않다.

따라서 한컴타자연습처럼 난이도와 길이가 정해진 연습 모드를 추가한다. 사용자는 단어, 짧은 문장, 긴 문장을 단계적으로 읽고, 앱은 같은 항목을 반복 평가하면서 발음 변화와 연습 지속성을 더 명확하게 보여준다.

핵심 방향은 다음과 같다.

```text
자유 대화
→ 실전 말하기와 자연스러운 코칭

단어/문장 읽기
→ 반복 훈련과 안정적인 발음 평가
```

## 2. 추천 연습 구조

최종적으로 앱의 말하기 연습은 4개 모드로 나눈다.

```text
1. 단어 게임
2. 짧은 문장 읽기
3. 긴 문장 읽기
4. 자유 대화
```

혀 운동 기능을 함께 고려하면 전체 훈련 흐름은 아래처럼 구성할 수 있다.

```text
혀 준비운동
→ 단어 게임
→ 짧은 문장 읽기
→ 긴 문장 읽기
→ 자유 대화
```

## 3. 모드별 역할

### 3.1 단어 게임

목적:

- 짧고 부담 없는 발음 반복
- 특정 음소나 자주 쓰는 핵심 단어 훈련
- 성공 경험을 빠르게 제공

예시 콘텐츠:

```text
물
약
병원
화장실
도와주세요
괜찮아요
아파요
천천히
```

추천 평가:

- 목표 단어와 인식 텍스트 일치도
- 재시도 횟수
- 연속 성공 횟수
- 어려운 단어 누적 기록
- 실패한 단어 복습 여부
- 혀/입술 움직임이 많은 발음군 실패 빈도

UI 성격:

- 떨어지는 단어 게임 방식
- 큰 글자와 큰 녹음 버튼
- 성공 시 별, 체크, 연속 성공 표시
- 틀린 단어만 다시 도는 복습 진입 버튼
- 쉬움/보통/집중 난이도 선택
- 현재 단어의 움직임 점수와 운동 음절 여부 표시

구현 결과:

- 단어 게임은 `WordGameScreen` 전용 화면으로 분리했다.
- 단어가 위에서 아래로 내려오는 게임 보드를 추가했다.
- 현재 목표 단어를 발음해 70점 이상이면 해당 단어가 사라진다.
- 단어가 바닥에 닿으면 게임이 종료되고 성공 개수, 실패 개수, 평균 점수를 보여준다.
- 게임 중에는 `목표 단어`, 움직임 점수, 운동 음절 여부를 함께 표시한다.
- `wordGame` 기록 중 70점 미만이 있었던 단어를 복습 후보로 계산한다.
- 같은 단어의 최근 2회 기록이 모두 80점 이상이면 복습 목록에서 제외한다.
- 단어 게임 화면에서 `틀린 단어 복습` 버튼으로 복습 목록을 시작한다.
- 복습 중인 단어는 화면에 `복습` 칩으로 표시된다.
- `퍼터커`, `파타카`, `피티키`, `버더거`, `타라카` 같은 운동 음절을 기본 단어에 추가했다.
- `movementScore`, `baseWeight`, `isExercisePattern`으로 단어의 운동성 및 출현 가중치를 관리한다.
- 쉬움은 일반 단어 비중을 높이고, 집중은 운동 음절과 움직임 점수가 높은 단어 비중을 높인다.
- 실패한 단어와 같은 목표 발음군은 가중치가 올라가 다시 나올 확률이 높아진다.

### 3.2 짧은 문장 읽기

목적:

- 실제 생활에서 바로 쓸 수 있는 짧은 표현 훈련
- 발음 정확도와 전달력 평가
- 현재 앱의 `PracticeSentenceService`와 가장 잘 맞는 기본 모드

예시 콘텐츠:

```text
물을 마시고 싶어요.
조금 쉬고 싶어요.
화장실에 가고 싶어요.
천천히 다시 말해 주세요.
제가 천천히 말해 볼게요.
```

추천 평가:

- 문장 전체 명료도
- 누락된 단어
- 바뀐 단어
- 발화 속도
- 다시 읽기 후 개선 여부

UI 성격:

- 현재 `PracticeScreen`을 확장해 구현 가능
- 한 문장당 1-3회 반복
- 같은 문장에 대한 이전 최고 기록 표시

### 3.3 긴 문장 읽기

목적:

- 호흡, 속도, 끊어 읽기, 리듬 훈련
- 짧은 문장보다 실제 말하기 지속 시간에 가까운 평가
- 단어/짧은 문장에 익숙해진 뒤 진행하는 상위 모드

예시 콘텐츠:

```text
오늘은 발음 연습을 천천히 하면서 또렷하게 말해 보겠습니다.
병원에 가기 전에 약 먹는 시간을 가족과 함께 확인하겠습니다.
꾸준한 연습만이 올바른 언어 습관을 만드는 비결입니다.
```

추천 평가:

- 전체 문장 완주 여부
- 중간 멈춤 횟수
- 말 속도
- 끊어 읽기
- 호흡 지속
- 핵심 단어 전달 여부

UI 성격:

- 문장을 의미 단위로 줄바꿈
- 너무 긴 문장은 2-3구간으로 나누어 표시
- "한 번에 읽기"와 "구간별 읽기" 선택 가능

### 3.4 자유 대화

목적:

- 실제 상황에 가까운 자연 발화 연습
- 문장 정확도보다 의사소통 참여와 자신감 강화
- AI 코칭과 대화 유지

추천 평가:

- 점수 중심보다 피드백 중심
- 말이 막힌 지점 요약
- 사용자가 말하려던 의도 정리
- 다음에 연습할 단어/문장 추천

UI 성격:

- 기존 자유 대화 흐름 유지
- 구조화된 연습 결과를 바탕으로 AI가 추천 질문을 던질 수 있음

## 4. 정보 구조 변경

### 4.1 연습 선택 화면 추가

현재 앱은 온보딩 이후 `오늘의 연습` 홈에서 바로 연습을 선택하도록 구성한다. 히스토리는 홈 상단 액션으로 이동한다.

추천 라우트:

```text
'/practice_modes': PracticeModeSelectionScreen
```

추천 카드:

```text
혀 준비운동
단어 게임
짧은 문장 읽기
긴 문장 읽기
자유 말하기
```

처음에는 온보딩 이후 `/practice_modes`로 이동하도록 바꾸고, 기존 `/practice`는 짧은 문장 읽기와 긴 문장 읽기 화면으로 유지한다.

구현 결과:

- 온보딩 이후 첫 화면은 `PracticeModeSelectionScreen`이다.
- `PracticeModeSelectionScreen`은 `오늘의 연습` 홈 역할을 하며 히스토리와 대시보드 이동 버튼을 제공한다.
- 단어 게임은 전용 `/word_game` 화면으로 이동한다.
- 짧은 문장과 긴 문장 모드는 기존 `/practice` 화면을 재사용한다.
- 자유 대화는 기존 `ChatScreen`으로 연결한다.

### 4.2 기존 PracticeScreen 재사용 전략

현재 `PracticeScreen`은 문장 연습과 자유 읽기를 모두 처리한다. 초기 구현에서는 화면을 완전히 새로 만들기보다, `PracticeMode`를 추가해 기존 녹음/분석 루프를 재사용한다.

추천 enum:

```dart
enum PracticeMode {
  wordGame,
  shortSentence,
  longSentence,
  freeSpeech,
}
```

`PracticeProgress`에 추가할 필드:

```dart
final PracticeMode mode;
final int currentItemIndex;
final int retryCount;
final int streakCount;
final String category;
```

## 5. 콘텐츠 데이터 설계

현재 `PracticeSentenceService`는 기능적 문장, 어려운 문장, 일상 문장을 제공한다. 이를 구조화된 콘텐츠 서비스로 확장한다.

추천 파일:

```text
lib/services/practice_content_service.dart
```

추천 모델:

```dart
class PracticeContentItem {
  final String id;
  final PracticeMode mode;
  final String text;
  final String category;
  final int difficulty;
  final List<String> targetSounds;
  final int movementScore;
  final int baseWeight;
  final bool isExercisePattern;
}
```

예시 카테고리:

```text
일상
병원
가족
전화
감정
어려운 발음
호흡 연습
```

단어와 문장을 한 모델로 관리하면 이후 추천, 통계, 즐겨찾기 구현이 쉬워진다.

구현 결과:

- `PracticeContentService`를 추가했다.
- 단어, 짧은 문장, 긴 문장 콘텐츠를 `PracticeContentItem`으로 관리한다.
- 각 항목은 `id`, `mode`, `text`, `category`, `difficulty`, `targetSounds`, `source`를 가진다.
- 단어 항목은 `movementScore`, `baseWeight`, `isExercisePattern`을 추가로 가진다.
- `PracticeContentService.getFailedWordReviewItems()`로 틀린 단어 복습 목록을 계산한다.
- `PracticeContentService.pickWeightedWord()`로 난이도와 기록 기반 가중치 선택을 수행한다.
- `PracticeContentService.getDifficultSoundCounts()`로 실패 발음군을 집계한다.
- 긴 문장은 기본 문장과 사용자가 저장한 `내 긴 문장`을 함께 불러온다.
- `CustomPracticeContentService`가 `SharedPreferences`에 사용자 긴 문장을 저장한다.

## 6. 발음 평가 개선 방향

모드별 평가 기준을 다르게 적용한다.

```text
단어 게임
→ 목표 단어 일치도, 재시도, 연속 성공

짧은 문장 읽기
→ 명료도, 누락 단어, 바뀐 단어, 속도

긴 문장 읽기
→ 완주 여부, 호흡, 중간 멈춤, 끊어 읽기

자유 대화
→ 의도 전달, 자연스러움, 다음 연습 추천
```

`AiService`의 피드백 프롬프트도 모드별로 분리하는 것이 좋다.

추천 메서드:

```dart
Future<AiResponse> evaluatePracticeByMode({
  required PracticeMode mode,
  required String targetText,
  required String spokenText,
  required int durationSeconds,
});
```

MVP에서는 기존 `getReadingFeedback()`을 유지하되, 프롬프트에 모드 정보를 추가하는 방식으로 시작한다.

구현 결과:

- `AiService.evaluatePracticeByMode()`를 추가했다.
- 단어 게임, 짧은 문장, 긴 문장, 자유 말하기에 따라 평가 프롬프트와 fallback 피드백이 달라진다.
- 긴 문장은 호흡과 끊어 읽기, 단어 게임은 목표 단어 명료도를 우선한다.

## 7. 기록 저장 확장

현재 `PracticeSession`은 발음 연습 기록을 저장한다. 구조화된 모드가 들어가면 어떤 모드에서 어떤 콘텐츠를 읽었는지 저장해야 한다.

추가 권장 필드:

```dart
final String mode;
final String contentId;
final String category;
final int difficulty;
final int retryCount;
final int streakCount;
final int? previousBestScore;
```

기존 기록과의 호환성을 위해 nullable 또는 기본값을 사용한다.

예시 기본값:

```text
mode: shortSentence
contentId: null
category: 일반
difficulty: 1
retryCount: 0
streakCount: 0
```

구현 결과:

- `PracticeSession`에 `mode`, `contentId`, `category`, `difficulty`, `retryCount`, `streakCount`, `previousBestScore`를 추가했다.
- 사용자 등록 문장 여부를 남기기 위해 `contentSource`를 추가했다.
- 기존 저장 기록은 기본값으로 로드되도록 호환성을 유지했다.

## 8. UI 구현 계획

### 8.1 PracticeModeSelectionScreen

신규 화면:

```text
lib/features/practice/view/practice_mode_selection_screen.dart
```

구성:

- 오늘의 추천 루틴
- 혀 준비운동 카드
- 단어 게임 카드
- 짧은 문장 읽기 카드
- 긴 문장 읽기 카드
- 자유 말하기 카드
- 최근 연습 요약

구현 결과:

- 오늘 연습 횟수 요약과 4개 모드 카드를 제공한다.
- 단어/짧은 문장/긴 문장 카드는 `PracticeNotifier.setMode()` 후 `/practice`로 이동한다.
- 자유 대화 카드는 새 대화 세션을 만들고 `ChatScreen`으로 이동한다.

### 8.5 내 긴 문장 등록

구현 결과:

- 긴 문장 모드에서 `내 긴 문장 추가` 버튼을 제공한다.
- 문장과 상황 카테고리를 입력하면 난이도를 자동 추정해 저장한다.
- `내 긴 문장 관리`에서 저장한 문장을 수정하거나 삭제할 수 있다.
- 저장한 문장은 긴 문장 모드의 기본 문장보다 앞에 표시되어 바로 반복 연습할 수 있다.

### 8.2 단어 게임 화면

초기에는 `PracticeScreen`을 재사용해도 되지만, 게임성이 강해지면 별도 화면을 권장한다.

추천 파일:

```text
lib/features/practice/view/word_game_screen.dart
```

MVP는 다음만 포함한다.

- 큰 단어 카드
- 녹음 시작 버튼
- 다음 단어 버튼
- 성공/재시도 표시
- 연속 성공 수 표시

### 8.3 짧은/긴 문장 읽기 화면

기존 `PracticeScreen`을 확장한다.

변경 사항:

- 상단에 현재 모드 표시
- 짧은 문장/긴 문장 콘텐츠 리스트 분리
- 긴 문장은 의미 단위 줄바꿈
- 이전 최고 점수와 최근 점수 표시
- 같은 문장 다시 하기 버튼 강화

### 8.4 자유 대화

기존 `ChatScreen`과 `PracticeScreen`의 자유 읽기 흐름을 유지한다. 다만 연습 선택 화면에서는 `자유 대화`를 별도 카드로 보여준다.

## 9. 단계별 구현 계획

### 1단계: 콘텐츠 구조화

목표:

- 단어/짧은 문장/긴 문장 데이터를 분리한다.
- 기존 `PracticeSentenceService`를 확장하거나 `PracticeContentService`로 교체한다.

작업:

1. `PracticeMode` enum 추가
2. `PracticeContentItem` 모델 추가
3. `PracticeContentService` 추가
4. 기존 문장 목록을 짧은 문장/긴 문장으로 분리
5. 단어 목록 추가

### 2단계: 연습 선택 화면

목표:

- 사용자가 연습 유형을 명확히 선택할 수 있게 한다.

작업:

1. `PracticeModeSelectionScreen` 추가
2. `main.dart`에 `/practice_modes` 라우트 추가
3. `HistoryScreen`의 읽기 연습 버튼을 `/practice_modes`로 변경
4. 각 카드에서 해당 모드로 이동

### 3단계: PracticeScreen 모드화

목표:

- 기존 녹음/분석/기록 루프를 유지하면서 모드별 콘텐츠를 제공한다.

작업:

1. `PracticeProgress`에 `mode`, `currentItemIndex`, `retryCount`, `streakCount` 추가
2. `PracticeNotifier`에 `setMode(PracticeMode mode)` 추가
3. `nextSentence()`를 `nextItem()`으로 일반화
4. 모드별 화면 문구 변경
5. 기록 저장 시 모드 정보 저장

### 4단계: 단어 게임 MVP

목표:

- 단어 읽기 반복을 게임처럼 사용할 수 있게 한다.

작업:

1. 단어 모드에서 큰 단어 카드 표시
2. 녹음 후 일치 여부 피드백
3. 재시도 횟수와 연속 성공 표시
4. 성공 시 다음 단어 이동

### 5단계: 평가 프롬프트 분리

목표:

- 모드에 맞는 피드백을 제공한다.

작업:

1. `AiService`에 모드 기반 평가 메서드 추가
2. 단어/짧은 문장/긴 문장/자유 대화별 프롬프트 작성
3. 점수 설명을 모드별로 다르게 표시
4. 긴 문장에서는 속도와 호흡 피드백 강화

### 6단계: 대시보드와 기록 개선

목표:

- 사용자가 어떤 모드에서 얼마나 연습했는지 확인한다.

작업:

1. `PracticeSession`에 모드/카테고리/난이도 필드 추가
2. `PracticeHistoryScreen`에 모드 칩 표시
3. `DashboardScreen`에 모드별 연습 횟수 추가
4. 최근 7일 단어/문장/자유 말하기 활동 분리

## 10. 테스트 계획

### 10.1 단위 테스트

- `PracticeContentService`가 모드별 콘텐츠를 올바르게 반환하는지 확인
- `setMode()` 호출 시 목표 텍스트와 인덱스가 초기화되는지 확인
- `nextItem()`이 현재 모드의 콘텐츠 안에서 순환하는지 확인
- 기존 저장 기록이 새 필드 없이도 로드되는지 확인

### 10.2 위젯 테스트

- 연습 선택 화면에 4개 모드가 표시되는지 확인
- 단어 게임 카드 선택 시 단어 모드로 이동하는지 확인
- 짧은 문장과 긴 문장 화면의 안내 문구가 다르게 보이는지 확인
- 완료 후 기록 화면에 모드 칩이 표시되는지 확인

### 10.3 수동 확인

- 작은 화면에서 긴 문장이 넘치지 않는지 확인
- 단어 게임에서 빠르게 녹음/중지를 반복해도 상태가 꼬이지 않는지 확인
- 자유 대화 기존 흐름이 깨지지 않는지 확인
- 히스토리와 대시보드가 기존 기록을 정상 표시하는지 확인

## 11. 우선순위

가장 추천하는 순서는 다음과 같다.

```text
1. 짧은 문장 읽기 구조화
2. 단어 게임 MVP
3. 긴 문장 읽기
4. 연습 선택 화면 정리
5. 모드별 평가 프롬프트 분리
6. 대시보드/히스토리 확장
```

단, 사용자가 바로 체감하는 변화는 연습 선택 화면과 단어 게임에서 크다. 그래서 실제 개발은 아래 순서가 더 좋다.

```text
1. 연습 선택 화면
2. 콘텐츠 구조화
3. 단어 게임
4. 짧은/긴 문장 모드 분리
5. 기록/대시보드 개선
6. 평가 프롬프트 고도화
```

## 12. 결론

단어 게임, 짧은 문장 읽기, 긴 문장 읽기를 추가하면 앱은 자유 대화형 보조 도구에서 구조화된 발음 훈련 플랫폼으로 발전할 수 있다. 특히 같은 단어와 문장을 반복해서 읽게 되므로 발음 평가, 이전 기록 비교, 사용자별 약점 파악이 훨씬 안정적이다.

1차 구현 목표는 다음처럼 정의한다.

```text
사용자가 연습 모드를 선택하고,
단어 또는 문장을 읽고,
앱이 모드에 맞는 피드백과 기록을 남기며,
기존 자유 대화 흐름은 그대로 유지한다.
```

## 13. 구현 후 남은 확장 과제

이번 구현은 MVP 범위에 집중했다. 다음 단계에서는 아래를 검토한다.

- 단어 게임 전용 화면 분리
- 틀린 단어 복습 성과 요약
- 단어 낙하 속도와 출현 간격의 사용자 맞춤 조절
- 콘텐츠 즐겨찾기
- 문장별 이전 최고 점수 표시 강화
- 긴 문장의 구간별 읽기 모드
- 혀 운동 완료 후 연습 선택 화면으로 연결
- 보호자 공유 리포트에 모드별 변화 포함
