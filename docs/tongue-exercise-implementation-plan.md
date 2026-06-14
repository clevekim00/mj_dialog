# 혀 운동 기능 추가 구현 계획

작성일: 2026-06-01

최근 업데이트: 2026-06-14

현재 구현 요약:

- 혀운동 전용 화면, 라우트, 홈 준비운동 카드, 대시보드 루틴 카드가 구현되어 있다.
- 혀운동 기록은 `TongueExerciseSession`과 `TongueExerciseHistoryService`로 별도 저장한다.
- 완료 화면에서 `추천 연습 시작`, `홈으로 돌아가기`, `혀운동 다시 하기`를 제공한다.
- `model_viewer_plus`로 GLB 3D 혀/입 구조 미리보기를 표시한다.
- 앱 기본 GLB asset은 `assets/models/tongue_exercise_preview.glb`이다.
- Blender 4.x용 생성 스크립트는 `blender_tongue_exercise/create_tongue_exercise_animation.py`에 있다.

## 1. 목적

혀 운동 기능은 사용자가 소리 내어 읽기나 자유 발화 연습을 시작하기 전에 입과 혀를 짧게 준비할 수 있도록 돕는 워밍업 모듈이다. 핵심 목적은 영상을 그대로 재현하는 것이 아니라, 사용자가 앱 안에서 안전하게 따라 할 수 있는 단계형 운동 가이드를 제공하는 데 있다.

이 기능은 다음 흐름에 자연스럽게 붙인다.

```text
히스토리
→ 혀 운동 / 읽기 연습 선택
→ 혀 운동 준비 루틴
→ 소리 내어 읽기 또는 자유 발화
→ 기록 확인
```

## 2. 구현 원칙

### 2.1 영상 참고 방식

사용자가 제공한 YouTube 영상은 운동 구성을 참고하는 자료로만 사용한다. 영상 화면, 음성, 자막, 설명 문구를 그대로 앱에 포함하지 않는다.

권장 방식:

- 앱 자체 운동 카드로 재구성한다.
- 운동 이름과 설명은 일반적인 재활/구강 운동 표현으로 새로 작성한다.
- 필요한 경우 외부 영상은 "참고 영상 열기" 링크로만 제공한다.
- 앱 안에서는 자체 타이머, 반복 횟수, 안전 안내, 완료 기록을 중심으로 만든다.

### 2.2 의료/안전 표현

이 앱은 전문적인 평가나 치료를 대체하지 않는 보조 도구로 표현해야 한다.

모든 혀 운동 화면에는 다음 성격의 안내가 포함되어야 한다.

```text
통증, 사레, 삼킴 곤란, 호흡 불편, 어지러움, 갑작스러운 말 변화가 있으면 즉시 중단하고 전문가에게 문의하세요.
```

운동 강도는 "세게", "무리해서"보다 "천천히", "편안한 범위에서", "짧게 쉬면서"로 안내한다.

## 3. 추천 기능 범위

### 3.1 MVP

첫 구현은 아래 범위로 제한한다.

1. 혀 운동 전용 화면 추가
2. 히스토리 화면에서 혀 운동 진입 버튼 추가
3. 5-7개의 운동 카드 제공
4. 각 운동별 타이머 또는 반복 체크 제공
5. 전체 루틴 완료 기록 저장
6. 연습 기록 또는 대시보드에서 완료 횟수 확인

### 3.2 이후 확장

MVP 이후에는 다음을 검토한다.

- 사용자별 운동 즐겨찾기
- 보호자와 함께 보기 모드
- 운동 난이도 선택
- 읽기 연습 시작 전 자동 워밍업 제안
- 혀 운동 완료 후 추천 문장 연습 연결
- 운동 기록을 주간 리포트에 포함

## 4. 화면 구조

### 4.1 진입점

현재 앱은 `HistoryScreen`을 중심 화면으로 사용한다. 따라서 `히스토리` 화면의 상단 액션 영역에 혀 운동 버튼을 추가하는 것이 가장 자연스럽다.

대상 파일:

```text
lib/features/chat/view/history_screen.dart
```

추천 버튼:

```text
IconButton
→ icon: Icons.self_improvement 또는 Icons.face_retouching_natural
→ tooltip: '혀 운동'
→ onPressed: Navigator.pushNamed(context, '/tongue_exercise')
```

### 4.2 라우트 추가

대상 파일:

```text
lib/main.dart
```

추가 라우트:

```text
'/tongue_exercise': (context) => const TongueExerciseScreen(),
```

### 4.3 신규 화면 위치

추천 디렉터리:

```text
lib/features/tongue_exercise/
├── model/
│   └── tongue_exercise_step.dart
├── provider/
│   └── tongue_exercise_provider.dart
└── view/
    └── tongue_exercise_screen.dart
```

기록 저장 서비스가 필요하면 다음 파일을 추가한다.

```text
lib/services/tongue_exercise_history_service.dart
```

## 5. 운동 콘텐츠 설계

### 5.1 기본 루틴

초기 루틴은 5분 이내로 끝나는 짧은 구성을 권장한다.

```text
1. 편안히 입 벌리고 혀 내밀기
2. 혀를 왼쪽과 오른쪽으로 천천히 움직이기
3. 혀끝을 위쪽과 아래쪽으로 움직이기
4. 혀끝을 입천장에 가볍게 대기
5. 혀로 입술 둘레 천천히 돌기
6. 혀로 볼 안쪽을 가볍게 밀기
7. 휴식하며 입과 턱 힘 빼기
```

### 5.2 운동 카드 필드

각 운동은 아래 정보를 가진다.

```dart
class TongueExerciseStep {
  final String id;
  final String title;
  final String instruction;
  final int seconds;
  final int repetitions;
  final IconData icon;
}
```

`seconds`와 `repetitions` 중 하나를 주 지표로 사용하고, 필요하면 둘 다 표시한다.

예시:

```text
title: '혀 좌우 움직이기'
instruction: '입을 편안히 벌리고 혀를 왼쪽, 오른쪽으로 천천히 움직입니다.'
seconds: 20
repetitions: 5
```

## 6. 상태 관리

현재 앱은 Riverpod `NotifierProvider` 패턴을 사용한다. 혀 운동도 같은 패턴을 따른다.

추천 상태:

```dart
enum TongueExerciseState {
  ready,
  running,
  paused,
  completed,
}

class TongueExerciseProgress {
  final TongueExerciseState state;
  final int currentStepIndex;
  final int remainingSeconds;
  final Set<String> completedStepIds;
  final int fatigueBefore;
  final int? fatigueAfter;
}
```

추천 동작:

- `startRoutine()`
- `pauseRoutine()`
- `resumeRoutine()`
- `completeCurrentStep()`
- `skipStep()`
- `resetRoutine()`
- `setFatigueBefore(int value)`
- `setFatigueAfter(int value)`

## 7. 기록 저장

혀 운동 기록은 기존 `PracticeSession`에 넣지 않는 것이 좋다. 기존 모델은 발음 점수, 녹음 파일, STT 결과 중심이라 혀 운동과 데이터 성격이 다르다.

추천 모델:

```dart
class TongueExerciseSession {
  final String id;
  final DateTime timestamp;
  final int completedStepCount;
  final int totalStepCount;
  final int durationSeconds;
  final int fatigueBefore;
  final int? fatigueAfter;
  final List<String> completedStepIds;
}
```

추천 저장소:

```text
SharedPreferences key: tongue_exercise_history
```

기존 `PracticeHistoryService`와 같은 방식으로 JSON 리스트를 저장하면 앱 구조와 잘 맞는다.

## 8. UI 구성

### 8.1 화면 상단

구성:

- 제목: `혀 운동`
- 짧은 설명: `발음 연습 전 입과 혀를 천천히 준비합니다.`
- 안전 안내 카드
- 시작 전 피로도 선택

### 8.2 운동 진행 영역

구성:

- 현재 운동 제목
- GLB 기반 3D 혀/입 구조 미리보기
- 짧은 지시문
- 남은 시간 또는 반복 횟수
- 시작/일시정지 버튼
- 다음 운동 버튼

버튼은 기존 앱의 어두운 배경, 흰색/파란색 포인트 스타일을 유지한다.

### 8.3 운동 목록

하단에는 전체 운동 목록을 체크리스트 형태로 보여준다.

표시 예:

```text
✓ 혀 내밀기
✓ 좌우 움직이기
현재 진행 중: 입천장 대기
대기: 입술 둘레 돌기
```

### 8.4 완료 화면

완료 시 다음 선택지를 제공한다.

- `읽기 연습으로 이동`
- `다시 하기`
- `기록 보기`

`읽기 연습으로 이동`은 `/practice`로 이동한다.

## 8.5 3D 모델 미리보기

혀운동 화면은 `model_viewer_plus` 패키지로 GLB asset을 렌더링한다.

대상 파일:

```text
lib/features/tongue_exercise/view/tongue_exercise_screen.dart
```

Asset 등록:

```yaml
flutter:
  assets:
    - assets/models/tongue_exercise_preview.glb
```

기본 모델은 교육용 미리보기 수준의 경량 GLB이다. 실제 해부학 또는 애니메이션 모델을 사용할 때는 동일 경로의 파일을 교체한다.

```text
assets/models/tongue_exercise_preview.glb
```

Blender 4.x에서 교육용 모델을 다시 생성하려면 아래 스크립트를 사용한다.

```text
blender_tongue_exercise/create_tongue_exercise_animation.py
```

실행 명령:

```bash
cd /Users/youngwhankim/Project/mj_dialog/blender_tongue_exercise
blender --background --python create_tongue_exercise_animation.py
```

생성된 `tongue_exercise_animation.glb`를 앱에 적용하려면 `assets/models/tongue_exercise_preview.glb`로 교체한다.

## 9. 대시보드/히스토리 반영

MVP에서는 대시보드에 간단한 완료 횟수만 추가한다.

대상 파일:

```text
lib/features/practice/view/dashboard_screen.dart
```

추천 지표:

```text
최근 7일 혀 운동 완료 횟수
최근 혀 운동 완료일
평균 운동 시간
```

통합 히스토리에 바로 섞을 경우 `ChatSession`, `PracticeSession`, `TongueExerciseSession` 타입 분기가 더 복잡해진다. 따라서 1차 구현에서는 혀 운동 화면 안에 자체 기록 목록을 두고, 2차에서 통합 히스토리 편입을 검토한다.

## 10. 구현 순서

1. `TongueExerciseStep` 모델과 기본 루틴 상수 추가
2. `TongueExerciseProgress`와 `TongueExerciseNotifier` 추가
3. `TongueExerciseScreen` UI 구현
4. `main.dart`에 `/tongue_exercise` 라우트 추가
5. `HistoryScreen`에 혀 운동 진입 버튼 추가
6. `TongueExerciseSession`과 저장 서비스 추가
7. 완료 시 기록 저장
8. 대시보드에 최근 7일 혀 운동 요약 추가
9. `flutter analyze`와 `flutter test`로 검증

## 11. 테스트 계획

### 11.1 단위 테스트

- 기본 루틴 개수가 5개 이상인지 확인
- `completeCurrentStep()` 호출 시 완료 목록과 현재 인덱스가 갱신되는지 확인
- 마지막 운동 완료 시 상태가 `completed`로 바뀌는지 확인
- 저장 서비스가 JSON 저장/로드를 정상 처리하는지 확인

### 11.2 위젯 테스트

- 혀 운동 화면이 안전 안내를 표시하는지 확인
- 시작 버튼을 누르면 진행 상태가 바뀌는지 확인
- 완료 후 `읽기 연습으로 이동` 버튼이 표시되는지 확인

### 11.3 수동 확인

- 작은 화면에서 텍스트가 버튼 밖으로 넘치지 않는지 확인
- 운동 중 뒤로 가기 시 타이머가 정리되는지 확인
- 완료 기록이 앱 재실행 후에도 유지되는지 확인
- 혀 운동 완료 후 `/practice` 이동이 정상 동작하는지 확인

## 12. 주의 사항

- 운동 설명을 과도하게 의학적으로 단정하지 않는다.
- 사용자의 증상 개선을 보장하는 표현을 쓰지 않는다.
- 영상 콘텐츠를 그대로 복제하지 않는다.
- 운동은 짧고 쉬운 기본값으로 시작한다.
- 피로도와 불편감 기록을 통해 무리한 반복을 피하도록 한다.

## 13. 결론

혀 운동 기능은 현재 앱의 `소리 내어 읽기 연습`을 보완하는 준비 루틴으로 넣는 것이 가장 적합하다. 별도 화면과 별도 기록 모델로 시작하면 기존 발음 평가 흐름을 건드리지 않으면서도 재활 보조 앱의 완성도를 높일 수 있다.

1차 목표는 다음처럼 정의한다.

```text
사용자가 발음 연습 전 3-5분 동안
안전 안내를 확인하고,
짧은 혀 운동 루틴을 따라 하며,
완료 기록을 남길 수 있게 한다.
```
