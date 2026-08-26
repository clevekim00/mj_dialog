# 구조화된 발음 연습 모드 구현 계획

작성일: 2026-06-01

구현 상태: 2026-06-02 기준 MVP 반영 완료 및 UX 개선 반영

추가 기획: 2026-08-26 자음 집중 치료 훈련 및 음소 단위 음향 분석 설계 확정

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

## 14. 자음 집중 치료 훈련 개요

### 14.1 대상과 목적

대상은 특정 자음의 조음이 어려운 **성인 후천성 마비말장애 환자**다. 사용자가 어려운 자음을 선택하면 앱이 해당 자음을 모음과 결합한 음절, 실제 단어, 짧은 문장으로 난이도를 높여 가며 제시한다. 사용자는 기준 발음을 듣고 녹음한 뒤 자신의 발음을 다시 들을 수 있고, 서버는 목표 자음을 음소 단위로 분석한다.

이 기능은 치료적 진단이나 장애 정도 판정이 아니라 반복 훈련과 변화 관찰을 위한 보조 도구다. 언어재활사의 평가·치료 계획을 대체하지 않으며, 자동 점수보다 개인 기준선 대비 변화와 반복 성공 여부를 우선해 보여준다. 성인 마비말장애 치료는 개인의 조음·호흡·발성·운율과 기능적 의사소통 요구를 함께 고려해야 한다는 [ASHA 성인 마비말장애 가이드](https://www.asha.org/practice-portal/clinical-topics/dysarthria-in-adults/)를 안전 원칙으로 삼는다.

### 14.2 확정된 제품 결정

| 항목 | 결정 |
|---|---|
| 분석 방식 | 기기 내 음질 검사 + 서버 음소 분석의 하이브리드 방식 |
| 서버 위치 | 앱 저장소 안의 별도 `server/pronunciation_analysis/` 폴더 |
| 훈련 범위 | 초성 자음과 받침 자음 모두 포함 |
| 평가 단위 | 목표 자음의 구간, 위치, GoP, 대치·누락·왜곡 가능성 |
| 점수 기준 | 음소 공통 기준 + 최초 3~5회 개인 기준선 |
| 콘텐츠 생성 | 앱 개발 단계에서 AI가 후보를 생성하고 자동 검사 후 치료자가 승인 |
| 기본 콘텐츠 | 앱 번들에 포함하여 네트워크 없이도 전체 핵심 훈련 가능 |
| 콘텐츠 업데이트 | 버전 매니페스트를 확인해 CDN에서 증분 다운로드 |
| 기준 발음 | 개발 단계에서 생성한 문장별 기준 음원을 콘텐츠 팩에 포함 |
| 기기 TTS | 기준 음원이 없거나 손상된 경우에만 폴백으로 사용 |

## 15. 사용자 훈련 흐름

```text
자음 집중 훈련 진입
→ 어려운 자음 선택
→ 초성/받침 위치 선택
→ 시작 전 피로도와 난이도 선택
→ 기준 음절 듣기
→ 모음 결합 음절 따라 읽기
→ 목표 자음이 들어간 단어 읽기
→ 짧은 문장 읽기
→ 녹음 종료 및 서버 분석
→ 내 녹음 듣기 / 기준 발음 다시 듣기
→ 음소별 결과와 대치음 후보 확인
→ 같은 항목 다시 읽기 또는 다음 항목
→ 세션 요약과 개인 기준선 대비 변화 저장
```

### 15.1 단계별 훈련

1. **음절 단계**: 목표 초성에 `ㅏ·ㅓ·ㅗ·ㅜ·ㅡ·ㅣ`를 우선 결합하고, 안정되면 이중 모음으로 확장한다. 받침은 앞 모음을 바꾸어 `악·억·옥·욱·윽·익`처럼 훈련한다.
2. **단어 단계**: 목표 자음이 어두·어중·어말에 들어가는 실제 생활 단어를 제시한다. 무의미 음절은 음절 단계에만 사용하고 단어 단계에는 사전에 등록된 실제 단어만 사용한다.
3. **문장 단계**: 목표 자음이 2회 이상 포함된 3~8어절의 성인 생활 문장을 사용한다. 문장당 목표 위치가 지나치게 몰리지 않도록 분산한다.
4. **반복 단계**: 낮은 점수 항목, 치료자가 고정한 항목, 최근 개인 기준선보다 낮아진 항목을 우선 재추천한다.

## 16. 한국어 자음 범위와 발음 표기

### 16.1 초성

UI에서는 현대 한글 초성 19자를 모두 보여준다.

```text
ㄱ ㄲ ㄴ ㄷ ㄸ ㄹ ㅁ ㅂ ㅃ ㅅ ㅆ ㅇ ㅈ ㅉ ㅊ ㅋ ㅌ ㅍ ㅎ
```

초성 `ㅇ`은 실제 자음 소리가 없는 영초성이므로 일반 자음 점수를 계산하지 않는다. 모음 시작 안정성 비교용 대조 항목으로 사용하고 결과 화면에 이 차이를 안내한다. 따라서 1차 음소 모델의 실제 초성 평가 대상은 18개 소리다.

### 16.2 받침

기본 받침 훈련은 실제 표면 발음 기준 7종으로 구성한다.

```text
/ㄱ/ /ㄴ/ /ㄷ/ /ㄹ/ /ㅁ/ /ㅂ/ /ㅇ/
```

철자상 가능한 종성은 음운 규칙에 따라 이 7개 대표 종성으로 중화되거나 뒤 음절과 연음된다. 콘텐츠에는 철자 자모와 실제 목표 음소를 따로 저장한다.

```json
{
  "orthographicTarget": "ㅅ",
  "surfacePhone": "ㄷ",
  "position": "coda",
  "rule": "coda_neutralization"
}
```

겹받침과 연음·비음화·유음화가 포함된 단어는 난이도 3의 확장팩으로 분리한다. 철자만 보고 잘못된 음소를 평가하지 않도록 모든 단어와 문장은 한국어 G2P 변환 결과를 함께 저장한다. 서버의 초기 후보는 한국어 문자열을 발음열로 바꾸는 [KoG2P](https://github.com/scarletcho/KoG2P) 또는 동등한 검증 모듈을 사용하되, 라이선스 검토와 임상 콘텐츠 예외 사전을 반드시 거친다.

## 17. 콘텐츠 팩 설계

### 17.1 기본 제공량

핵심 팩은 18개 초성 음소와 7개 대표 종성 음소, 총 25개 목표군으로 구성한다.

| 목표군당 콘텐츠 | 수량 |
|---|---:|
| 기본 모음 결합 음절 | 6개 이상 |
| 실제 단어 | 12~20개 |
| 짧은 문장 | 20개 |
| 기준 발음 음원 | 모든 음절·단어·문장에 1개 |

짧은 문장은 핵심 팩 기준 최소 500개다. 겹받침과 음운 변동은 별도 확장팩으로 제공한다.

### 17.2 문장 생성 규칙

AI는 개발 단계에서 목표군당 30개 이상의 후보를 생성하고, 자동 검사와 치료자 검수를 통과한 20개만 출시 팩에 넣는다.

- 3~8어절, 한 문장 한 의미 단위
- 성인이 실제로 사용할 수 있는 병원·가족·식사·외출·전화·감정·취미 상황
- 목표 표면 음소가 지정 위치에 2회 이상 포함
- 어려운 고유명사, 유행어, 아동용 표현, 공포·차별·의학적 지시 문장 제외
- 같은 문장 구조와 어휘의 중복 제한
- G2P 결과와 목표 위치가 일치하지 않으면 자동 탈락
- 난이도 1은 목표 자음 주변이 단순한 모음, 난이도 2는 자음군 증가, 난이도 3은 음운 변동 포함
- 치료자 승인 상태가 `approved`인 항목만 빌드와 CDN 배포 허용

### 17.3 콘텐츠 모델

```json
{
  "id": "ko_onset_g_001",
  "schemaVersion": 1,
  "contentVersion": "2026.08.1",
  "language": "ko-KR",
  "targetGrapheme": "ㄱ",
  "targetPhone": "k0",
  "position": "onset",
  "level": "sentence",
  "text": "가게에서 고구마를 골랐어요.",
  "pronunciation": ["k0", "aa", "..."],
  "targetSegments": [0, 4, 8],
  "difficulty": 1,
  "category": "일상",
  "audioAsset": "audio/ko_onset_g_001.m4a",
  "approval": {
    "status": "approved",
    "reviewerRole": "slp",
    "reviewedAt": "2026-08-26T00:00:00Z"
  }
}
```

## 18. 개발 시 콘텐츠 생성·승인 파이프라인

추천 폴더는 다음과 같다.

```text
tools/pronunciation_content/
├── consonant_registry.yaml
├── prompts/
│   ├── syllables.md
│   ├── words.md
│   └── short_sentences.md
├── generate_candidates.py
├── validate_hangul.py
├── validate_g2p.py
├── detect_duplicates.py
├── export_review_sheet.py
├── synthesize_reference_audio.py
├── build_content_pack.py
└── tests/
```

파이프라인은 앱 런타임에서 AI를 호출하지 않는다.

```text
자음 레지스트리 입력
→ AI 후보 생성
→ 한글/길이/금칙어 검사
→ G2P 및 목표 음소 위치 검사
→ 의미 중복 검사
→ 치료자 검수용 CSV 생성
→ 승인 결과 반영
→ 기준 음원 일괄 생성
→ 음량 정규화 및 재생 검사
→ JSON + audio 콘텐츠 팩 빌드
→ SHA-256 및 서명 생성
→ 앱 번들 복사 + CDN 업로드
```

AI 생성 원문, 모델명, 프롬프트 버전, 생성 시각, 자동 검사 결과, 치료자 승인 이력을 보관해 재현 가능하게 한다.

## 19. 앱 내장팩과 CDN 업데이트

### 19.1 내장팩

앱은 `assets/pronunciation/content/` 아래에 승인된 핵심 팩 전체를 포함한다. 최초 실행과 오프라인 상태에서도 음절·단어·짧은 문장·기준 음원·녹음·내 녹음 재생이 동작해야 한다. 내장팩은 삭제하지 않으며 다운로드 팩이 손상되면 항상 내장팩으로 되돌아간다.

기준 음원은 동일 화자·속도·샘플레이트로 사전 생성하고 AAC/M4A 또는 플랫폼 호환성이 검증된 포맷으로 압축한다. 핵심 팩의 앱 용량 목표는 JSON과 전체 기준 음원을 포함해 35MB 이하로 둔다.

### 19.2 매니페스트

CDN 사업자에 종속되지 않는 HTTPS 매니페스트를 사용한다. 초기 운영은 Firebase Cloud Storage 또는 S3+CloudFront 중 하나를 선택할 수 있다. Firebase Storage는 Flutter에서 파일 직접 다운로드와 진행 상태를 지원하고, S3+CloudFront는 엣지 캐시와 버전 경로 운영에 적합하다. [Firebase Flutter 다운로드 문서](https://firebase.google.com/docs/storage/flutter/download-files?hl=en), [CloudFront 버전 파일 권장 방식](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/UpdatingExistingObjects.html)

```json
{
  "schemaVersion": 1,
  "channel": "production",
  "minimumAppVersion": "1.1.0",
  "publishedAt": "2026-08-26T00:00:00Z",
  "packs": [
    {
      "id": "ko-consonant-core",
      "version": "2026.08.1",
      "url": "https://cdn.example.com/packs/ko-consonant-core/2026.08.1.zip",
      "size": 23841024,
      "sha256": "...",
      "signature": "...",
      "required": true
    }
  ]
}
```

### 19.3 업데이트 정책

- 앱 시작 후 홈 화면을 막지 않고 백그라운드에서 매니페스트 확인
- 현재 팩보다 높은 버전이며 앱 버전이 호환될 때만 다운로드
- Wi-Fi 우선, 모바일 데이터는 사용자 동의 후 다운로드
- 임시 파일에 이어받기 다운로드 후 크기·SHA-256·서명 검증
- 검증 성공 뒤 원자적으로 활성 팩 포인터 교체
- 실패 시 이전 다운로드 팩 또는 내장팩 유지
- 매니페스트는 짧게 캐시하고, 버전이 들어간 팩 URL은 장기 캐시
- 최소 1개 이전 정상 버전을 보관해 롤백 지원

## 20. 음소 분석 서버 설계

### 20.1 폴더 구조

```text
server/pronunciation_analysis/
├── README.md
├── pyproject.toml
├── Dockerfile
├── app/
│   ├── main.py
│   ├── api/v1/analysis.py
│   ├── domain/models.py
│   ├── services/audio_preprocessor.py
│   ├── services/korean_g2p.py
│   ├── services/forced_aligner.py
│   ├── services/phoneme_scorer.py
│   ├── services/baseline_calibrator.py
│   └── services/result_explainer.py
├── model_registry/
│   └── manifest.yaml
├── scripts/
│   ├── download_models.py
│   ├── calibrate_thresholds.py
│   └── benchmark.py
└── tests/
    ├── fixtures/
    ├── test_g2p.py
    ├── test_alignment.py
    ├── test_scoring.py
    └── test_api.py
```

대형 모델 파일과 환자 음성은 Git에 넣지 않는다. 모델 레지스트리에는 모델명, 체크섬, 라이선스, 학습 데이터 출처, 평가 지표와 승인 상태만 저장한다.

### 20.2 서버 처리 순서

```text
M4A 업로드
→ 디코딩 및 16kHz mono PCM 정규화
→ 무음·길이·클리핑·신호대잡음비 검사
→ 목표 텍스트 한국어 G2P 변환
→ 목표 음소열 기반 강제 정렬
→ 프레임별 음소 posterior 추출
→ 목표 음소별 GoP 및 경쟁 음소 계산
→ 불확실성 추정
→ 공통 기준 + 개인 기준선 보정
→ 자음별 결과와 재시도 안내 반환
```

한국어 강제 정렬의 초기 기준은 [Montreal Forced Aligner의 한국어 모델](https://huggingface.co/MontrealCorpusTools/korean_mfa)을 검토할 수 있다. 다만 일반 성인 음성 모델만으로 마비말장애 발음을 정확히 판정한다고 가정해서는 안 된다. 마비말장애 음성에서 불확실성을 포함한 GoP가 한국어 명료도 평가 성능을 개선했다는 연구를 참고하되, 실제 출시 임계값은 성인 후천성 마비말장애 음성과 언어재활사 라벨로 별도 검증한다. [INTERSPEECH 2023 연구](https://www.isca-archive.org/interspeech_2023/yeo23_interspeech.pdf)

## 21. 서버 API

짧은 단어라도 모델 대기와 네트워크 재시도가 필요하므로 비동기 작업 API를 기본으로 한다.

### 21.1 분석 요청

```http
POST /v1/analysis/jobs
Content-Type: multipart/form-data

audio=<file>
contentId=ko_onset_g_001
targetText=가게
contentVersion=2026.08.1
anonymousPatientId=<pseudonymous-id>
attemptId=<uuid>
```

서버는 클라이언트가 보낸 음소열을 신뢰하지 않고 승인된 `contentId`와 `contentVersion`으로 목표 발음을 다시 조회한다.

```json
{
  "jobId": "job-uuid",
  "status": "queued",
  "pollAfterMs": 500
}
```

### 21.2 상태 및 결과

```http
GET /v1/analysis/jobs/{jobId}
DELETE /v1/analysis/jobs/{jobId}
GET /health
GET /ready
```

```json
{
  "jobId": "job-uuid",
  "status": "completed",
  "modelVersion": "ko-gop-1.0.0",
  "contentVersion": "2026.08.1",
  "signalQuality": {
    "accepted": true,
    "snrDb": 24.1,
    "clippingRatio": 0.0
  },
  "overallPracticeScore": 74,
  "confidence": 0.81,
  "phonemes": [
    {
      "expected": "k0",
      "observedCandidates": [
        {"phone": "k0", "probability": 0.63},
        {"phone": "kh", "probability": 0.22}
      ],
      "position": "onset",
      "startMs": 120,
      "endMs": 238,
      "gop": -0.41,
      "practiceScore": 71,
      "status": "retry",
      "errorType": "possible_substitution"
    }
  ],
  "baselineDelta": 8,
  "disclaimer": "훈련 참고용 자동 분석이며 임상 진단이 아닙니다."
}
```

## 22. 음소 점수와 개인 기준선

### 22.1 점수 산정

GoP는 목표 음소 구간의 음향 관측이 목표 음소에 얼마나 가까운지 posterior 기반으로 계산한다. 음소별 기준 분포가 다르므로 원시 GoP를 그대로 0~100으로 표시하지 않는다.

```text
원시 GoP
→ 음소·위치별 기준 분포로 정규화
→ 모델 불확실성 패널티
→ 신호 품질 게이트
→ 0~100 훈련 점수 변환
```

전체 문장 점수는 목표 자음 점수를 가장 크게 반영한다.

```text
목표 자음 정확도 60%
단어 완성도/누락 20%
말하기 속도와 과도한 멈춤 10%
신호 및 분석 신뢰도 10%
```

이 가중치는 임상 검증 전 임시값이며 서버 설정으로 버전 관리한다.

### 22.2 개인 기준선

- 자음·위치별 유효 발화 3회가 모이면 임시 기준선 생성
- 5회가 모이면 중앙값과 변동성을 이용해 안정 기준선 확정
- 음질 불량, 정렬 실패, 신뢰도 기준 미달 발화는 기준선에서 제외
- 공통 점수와 별도로 `기준선 대비 +8`처럼 변화 표시
- 질환 진행 가능성이 있는 환자는 향상만 강제하지 않고 유지 목표도 허용
- 기준선 재설정은 사용자 또는 치료자가 명시적으로 실행

### 22.3 결과 표시

```text
74점 · 다시 연습
목표 ㄱ은 이전 기준보다 8점 좋아졌어요.
일부 구간이 ㅋ에 가깝게 분석됐어요.
기준 발음을 듣고 같은 단어를 한 번 더 읽어 보세요.
```

상태는 `정확`, `주의`, `재시도`, `분석 불가` 네 단계로 제한한다. 대치음은 모델 신뢰도가 충분할 때만 `가능성`으로 표시하며 확정적 표현을 사용하지 않는다. GoP는 음소 단위 자동 발음 평가에 널리 쓰이지만 음소별 임계값과 사람 평가 데이터가 중요하다는 고전 연구를 설계 근거로 사용한다. [Witt & Young, 2000](https://doi.org/10.1016/S0167-6393(99)00044-8)

## 23. 앱 UI와 상태 설계

### 23.1 메뉴

```text
오늘의 연습
└── 자음 집중 훈련
    ├── 어려운 자음 선택
    ├── 초성 훈련
    ├── 받침 훈련
    ├── 치료자 지정 훈련
    └── 자음별 변화 기록
```

### 23.2 핵심 화면

1. **자음 선택 화면**: 자음별 최근 점수, 개인 기준선 변화, 치료자 지정 표시
2. **훈련 설정 화면**: 초성/받침, 음절/단어/문장, 반복 수, 느린 기준 음원 선택
3. **훈련 화면**: 큰 목표 텍스트, 목표 자음 강조, 기준 발음 듣기, 녹음 버튼
4. **분석 대기 화면**: 업로드와 분석 단계를 분리 표시하고 취소 허용
5. **결과 화면**: 내 녹음과 기준 음원 A/B 재생, 자음 구간 점수, 대치음 가능성, 재시도
6. **세션 요약**: 시도 횟수, 최고/중앙 점수, 기준선 변화, 다음 추천 자음

청각 피드백 외에 목표 자음 색상 강조와 진동 완료 신호를 제공한다. 색상만으로 상태를 구분하지 않고 텍스트 라벨과 아이콘을 함께 사용한다.

## 24. 앱 데이터 모델과 기존 코드 재사용

### 24.1 신규 모델

```dart
class ConsonantTrainingTarget {
  final String grapheme;
  final String phone;
  final PhonemePosition position;
  final List<String> vowelFrames;
}

class PhonemeAnalysisResult {
  final String expectedPhone;
  final List<PhoneCandidate> observedCandidates;
  final int startMs;
  final int endMs;
  final double rawGop;
  final int practiceScore;
  final double confidence;
  final PhonemeFeedbackStatus status;
  final String? errorType;
}

class ConsonantBaseline {
  final String phone;
  final PhonemePosition position;
  final double medianScore;
  final double variability;
  final int validAttemptCount;
  final String modelVersion;
}
```

### 24.2 기존 구조 재사용

코드 관계 분석 결과, 다음 기존 구성요소를 확장하는 것이 적합하다.

- `AudioRecorderService`: 녹음과 로컬 파일 저장 재사용. 분석 입력 규격을 명시하기 위해 샘플레이트와 채널 설정을 고정하거나 서버 변환을 보장한다.
- `AudioPlayerService`: 내 녹음과 기준 음원 A/B 재생에 재사용한다.
- `PracticeSession.phonemeAccuracy`: 단순 맵 대신 버전이 있는 음소 결과 모델로 교체하거나 호환 필드를 추가한다.
- `PracticeHistoryService`: 새 모드와 분석 작업 ID, 모델 버전, 콘텐츠 버전, 기준선 변화 필드를 추가한다.
- `PracticeContentService`: 런타임 생성 대신 `ContentPackRepository`를 통해 내장팩과 다운로드 팩을 합쳐 읽도록 분리한다.
- `VoiceSignalAnalyzer`: 서버 업로드 전 무음·클리핑·음량 검사에 재사용하되, 음소 판정에는 사용하지 않는다.
- `TtsService`: 런타임 기본 수단이 아니라 기준 음원 실패 시 폴백으로 역할을 변경한다.

현재 `TtsService`는 iOS에서 비활성화되어 있으므로 iOS 핵심 동작을 기기 TTS에 의존하면 안 된다. 사전 생성 기준 음원을 내장하는 결정으로 iOS에서도 동일한 기준 발음을 제공하고, 이후 네이티브 TTS 충돌을 별도 해결한다.

## 25. 개인정보·안전·운영 원칙

- 최초 서버 분석 전 음성 업로드와 처리 목적을 별도로 동의받는다.
- 요청에는 이름·전화번호·병명 등 직접 식별자를 넣지 않고 무작위 환자 ID만 사용한다.
- TLS를 강제하고 원본 음성은 분석 완료 후 즉시 삭제하는 것을 기본값으로 한다.
- 연구·모델 개선용 저장은 별도의 명시적 동의와 철회 기능이 있을 때만 허용한다.
- 서버 로그에 원문 음성, 전체 문장, 로컬 파일 경로를 남기지 않는다.
- 분석 결과에는 모델·콘텐츠·임계값 버전을 기록해 결과 재현성을 확보한다.
- 자동 점수를 진단명, 중증도, 치료 성공/실패로 표현하지 않는다.
- 삼킴 곤란, 호흡 불편, 심한 피로 또는 통증이 있으면 중단하고 전문가와 상의하도록 안내한다.

## 26. 실패 모드와 폴백

| 실패 상황 | 사용자 처리 | 시스템 처리 |
|---|---|---|
| 오프라인 | 녹음·재생·내장 콘텐츠 훈련 계속 | 분석 요청을 암호화된 대기열에 둘지 사용자가 선택 |
| 서버 시간 초과 | `분석이 지연되고 있어요` 표시 | 지수 백오프 재시도, 중복 방지 `attemptId` 사용 |
| 음질 불량 | 조용한 곳에서 다시 녹음 안내 | 점수 미생성, 개인 기준선 제외 |
| 강제 정렬 실패 | 내 녹음 재생과 재시도만 제공 | `analysis_unavailable` 저장, 추정 점수 금지 |
| 낮은 모델 신뢰도 | 대치음 후보 숨김 | 점수 대신 `판단 어려움` 반환 |
| CDN 실패 | 내장 콘텐츠로 즉시 시작 | 기존 정상 팩 유지, 부분 파일 삭제 |
| 체크섬/서명 실패 | 업데이트 알림 생략 | 팩 활성화 금지 및 보안 로그 기록 |
| 기준 음원 손상 | 기기 TTS 또는 텍스트 안내 | 다음 업데이트 때 음원 재다운로드 |
| 모델 버전 변경 | 이전 점수와 직접 비교 제한 안내 | 버전별 기준선 유지, 새 기준선 보정 수행 |

## 27. 단계별 구현 계획

### 1단계: 콘텐츠 스키마와 내장팩

- 자음·음소·위치 레지스트리 정의
- AI 후보 생성과 자동 검사 스크립트
- 치료자 검수 CSV와 승인 게이트
- 핵심 25개 목표군, 문장 500개 및 기준 음원 생성
- 내장 `ContentPackRepository` 구현

완료 조건: 네트워크 없이 자음 선택, 음절·단어·문장 표시, 기준 음원 재생이 가능하다.

### 2단계: 앱 훈련 UX

- 자음 선택·훈련·결과·기록 화면
- 기존 녹음/재생 서비스 연결
- 목표 자음 강조, 반복, 피로도, 내 녹음 다시 듣기
- `PracticeMode.consonantFocus` 또는 독립 기능 모듈 추가

완료 조건: 서버 없이도 콘텐츠 훈련과 내 녹음 비교를 끝까지 수행할 수 있다.

### 3단계: 분석 서버 MVP

- FastAPI 비동기 작업 API
- 오디오 전처리와 음질 게이트
- 한국어 G2P, 강제 정렬, 음소 posterior, GoP
- 초성 18개와 대표 종성 7개 응답 스키마
- 모델·임계값 버전 관리와 Docker 실행

완료 조건: 승인 콘텐츠의 녹음에 대해 음소 구간과 원시 GoP, 신뢰도를 재현 가능하게 반환한다.

### 4단계: 임상 보정과 개인 기준선

- 언어재활사 라벨이 있는 성인 후천성 마비말장애 평가 세트 구축
- 음소·위치별 임계값과 불확실성 보정
- 최초 3~5회 개인 기준선과 변화량
- 모델 버전 간 점수 비교 정책

완료 조건: 사전에 정의한 언어재활사 일치도, 민감도·특이도, 실패 거부율 기준을 충족한다.

### 5단계: CDN 배포

- 매니페스트·체크섬·서명 검증
- 백그라운드 다운로드·이어받기·원자적 교체
- 롤백과 내장팩 폴백
- 스테이징/프로덕션 채널 분리

완료 조건: 손상·중단·구버전·앱 버전 불일치 상황에서도 정상 팩을 잃지 않는다.

### 6단계: 치료자용 설정과 리포트

- 치료자가 지정한 목표 자음과 위치
- 유지/향상 목표, 반복 횟수, 난이도 잠금
- 자음별 주간 중앙값과 기준선 변화
- 원본 음성 공유는 별도 동의가 있을 때만 제공

## 28. 검증 계획

### 28.1 콘텐츠 테스트

- 목표 자음의 철자 위치와 G2P 표면 음소 일치
- 25개 핵심 목표군마다 승인 문장 20개 존재
- 문장 길이, 중복, 금칙어, 카테고리 분포 검사
- 승인되지 않은 항목의 빌드 실패
- 모든 기준 음원의 존재, 길이, 디코딩, 음량 검사

### 28.2 서버 테스트

- 무음·클리핑·과도한 잡음의 점수 생성 거부
- 초성·종성·연음·중화 규칙별 정렬 회귀 테스트
- 같은 파일과 모델 버전에서 결정적 결과 반환
- 낮은 신뢰도에서 대치음 단정 금지
- 작업 중복 요청, 취소, 시간 초과, 모델 미준비 처리
- 처리 시간 목표: 10초 이하 발화의 p95 결과 5초 이내

### 28.3 앱 테스트

- 완전 오프라인 상태에서 내장팩 훈련 완료
- 기준 음원과 내 녹음 A/B 재생
- 앱 종료 후 대기 중 분석 작업 복구
- CDN 다운로드 중 앱 종료와 네트워크 전환
- 체크섬 오류에서 기존 팩 유지
- 큰 글자, 스크린리더 라벨, 키보드 조작, 색상 비의존 상태 표시

### 28.4 임상 검증

- 최소 2명 이상의 언어재활사가 자음별 정확·부정확·판단 불가를 독립 라벨링
- 사람 평가자 간 일치도와 모델-사람 일치도 보고
- 음소·위치·화자 중증도별 민감도와 특이도 분리 보고
- 일반 성인 음성만으로 설정한 임계값을 환자에게 직접 적용하지 않음
- 성별·연령·원인 질환·중증도별 성능 편차 점검
- 실제 사용자에게 점수 문구가 좌절이나 오해를 유발하지 않는지 사용성 평가

## 29. 출시 승인 기준

- 핵심 25개 목표군과 목표군당 승인 문장 20개가 앱에 내장됨
- 오프라인에서도 콘텐츠·기준 음원·녹음·내 녹음 재생이 동작함
- 서버가 음질 불량과 낮은 신뢰도 발화를 점수로 위장하지 않음
- 모든 결과에 모델 버전, 콘텐츠 버전, 신뢰도, 진단 아님 문구가 포함됨
- 초성·종성의 음소별 임상 검증 결과가 사전 승인 기준을 충족함
- 최초 3~5회 유효 시도로 개인 기준선이 생성되고 사용자가 재설정 가능함
- CDN 팩이 실패하거나 손상되어도 내장팩으로 정상 훈련 가능함
- iOS에서 기기 TTS 없이도 모든 핵심 기준 발음을 들을 수 있음
- 원본 음성 보관 기본값이 `저장 안 함`임

## 30. 남은 운영 가정

- CDN은 특정 사업자에 고정하지 않고 표준 HTTPS 매니페스트로 추상화한다.
- 1차 배포의 받침 평가는 대표 표면 음소 7종이며 겹받침·복합 음운 규칙은 확장팩으로 제공한다.
- AI는 개발 도구로만 사용하고 앱 사용 중 문장을 즉석 생성하지 않는다.
- 치료자 승인 도구는 1차에 CSV 기반으로 시작하고, 콘텐츠 규모가 커지면 웹 검수 도구로 확장한다.
- 분석 서버의 구체적인 한국어 음향 모델은 라이선스, 재현성, 성인 마비말장애 검증 결과를 비교한 뒤 모델 레지스트리에서 확정한다.
