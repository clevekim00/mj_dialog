# 구강·교호·호흡 통합 훈련 구현 기획서

작성일: 2026-06-01

통합 개정일: 2026-08-25

## 1. 개요

기존의 혀운동, 얼굴운동, 연속 교대운동, 호흡훈련을 `docs/breathing-and-oral-exercises.md`에 정리된 46개 항목으로 대체한다. 사용자는 훈련 종류를 선택하고, 짧은 시범 영상과 동기화된 자막을 보면서 정해진 횟수만큼 반복한 뒤 결과를 저장한다.

이 문서는 다음 세 가지를 제품 기준으로 고정한다.

- 46개 훈련 콘텐츠의 분류와 제공 방식
- 영상·자막·반복 횟수를 공유하는 단일 훈련 플레이어
- 기존 화면과 기록을 새 구조로 이관하는 구현 순서

세부 영상 파일명과 Higgsfield 프롬프트는 `docs/training-video-prompts/training-video-production-plan.md`, 메뉴 정보구조는 `docs/adaptive-ui-menu-architecture.md`를 기준으로 한다.

## 2. 목표와 비목표

### 2.1 목표

- 사진 문서의 혀 운동 14개, 입술 운동 12개, 교호 운동 10개, 호흡 훈련 10개를 빠짐없이 탐색할 수 있게 한다.
- 모든 훈련에서 동일한 영상 재생, 자막, 반복 횟수, 속도, 일시정지, 건너뛰기 동작을 제공한다.
- 사용자가 46개 전체를 한 번에 수행하지 않고 카테고리별 또는 개인 루틴으로 짧게 훈련하게 한다.
- 영상이 없거나 재생에 실패해도 포스터 이미지와 텍스트 안내로 훈련을 계속할 수 있게 한다.
- 기존 혀운동 기록을 보존하면서 새 통합 훈련 기록으로 점진적으로 이전한다.

### 2.2 비목표

- 카메라로 실제 수행 정확도를 자동 판정하지 않는다.
- 영상 반복 횟수를 사용자의 실제 수행 성공 횟수로 표현하지 않는다.
- 앱이 질환을 진단하거나 개인별 치료 강도를 자동 처방하지 않는다.
- 참고 문서의 문구를 임상 검토 없이 모든 사용자에게 동일 강도로 강제하지 않는다.

## 3. 핵심 결정

| 항목 | 결정 |
|---|---|
| 콘텐츠 원본 | `docs/breathing-and-oral-exercises.md`를 전사 원본으로 사용 |
| 전체 구조 | 46개 콘텐츠 라이브러리와 짧은 루틴을 분리 |
| 영상 | 운동별 4~8초 무음 루프 MP4 |
| 자막 | 영상에 굽지 않고 앱이 단계·설정에 따라 오버레이 |
| 반복 | 영상 루프 횟수를 자동 집계하되 사용자 수행 여부는 주장하지 않음 |
| 기본 루틴 | 3~5개 운동, 약 3~7분 |
| 20회 표기 | 원문의 권장 횟수로 보존하되 사용자는 5·10·20회 또는 사용자 설정 선택 |
| 속도 | 0.5배, 0.75배, 1배 제공 |
| 오프라인 | MVP는 최적화된 46개 영상을 앱에 포함, 총량 60MB 이내 목표 |
| 향후 배포 | 용량 초과 시 핵심 영상만 번들하고 나머지는 카테고리 팩으로 내려받기 |

## 4. 안전 및 임상 검토

후천성 마비말장애 치료는 호흡·발성·조음 등 영향을 받은 하위 체계와 개인 상태에 맞춰 달라져야 하며, 운동 용량도 개인의 에너지와 중증도에 따라 조정되어야 한다. 자세·사진·영상은 조음 위치를 알려주는 시각적 단서로 사용할 수 있다. 근거: [ASHA Dysarthria in Adults](https://www.asha.org/practice-portal/clinical-topics/dysarthria-in-adults/).

빠르거나 과도한 호흡은 어지럼 등의 과호흡 증상을 유발할 수 있으므로 앱의 일반 루틴은 느리고 안정된 호흡으로 돌아오도록 안내한다. 근거: [Cambridge University Hospitals의 과호흡 호흡 운동 안내](https://www.cuh.nhs.uk/patient-information/breathing-exercises-in-the-treatment-of-hyperventilation/).

### 4.1 안전 등급

| 등급 | 의미 | 앱 제공 방식 |
|---|---|---|
| `general` | 일반적인 낮은 강도의 시범 | 기본 라이브러리와 추천 루틴에 노출 |
| `caution` | 피로·턱관절·어지럼 등에 주의 | 시작 전 경고 확인, 추천 루틴에서는 짧게 제공 |
| `clinicianOnly` | 도구 사용, 최대 유지, 빠른 호흡 등 전문가 확인 필요 | 기본 루틴 제외, 임상 검토 완료 또는 전문가 모드에서만 노출 |

### 4.2 반드시 검토할 항목

- 혀 운동 7번: 입을 크게 벌린 상태에서 오래 버티기
- 혀 운동 8번: 설압자로 저항 주기
- 호흡 훈련 2번: 참기 어려울 때 힘차게 흡기
- 호흡 훈련 3번: 빠른 심호흡
- 호흡 훈련 4번: 딸꾹질·흐느낌 흉내
- 호흡 훈련 5~7번: 최대 유지 또는 부분 호흡 후 정지
- 호흡 훈련 8~10번: 모음 최대 지속 발성

설압자 사용 영상에는 사용자가 혼자 도구를 입 안에 넣도록 유도하지 않는다. 화면에는 전문가 지도 필요 표시를 하고, 도구 없이 방향만 익히는 대체 시범을 함께 제공한다.

### 4.3 공통 중단 조건

다음 상태가 나타나면 즉시 중단하고 휴식하도록 안내한다.

- 통증, 사레, 삼킴 곤란 또는 호흡 불편
- 어지럼, 두근거림, 입 주변이나 손발의 저림
- 갑작스러운 목소리 변화 또는 말하기 악화
- 턱관절 통증이나 혀·입술의 과도한 피로

## 5. 콘텐츠 구조

### 5.1 카테고리

| 카테고리 | 개수 | 코드 | 기존 화면 대체 대상 |
|---|---:|---|---|
| 혀 운동 | 14 | `tongue` | `TongueExerciseScreen` 및 개별 혀 운동 |
| 입술 운동 | 12 | `lip` | `FaceExerciseScreen`의 입·입술 중심 항목 |
| 교호 운동 | 10 | `alternating` | `OralAlternatingExerciseScreen` |
| 호흡 훈련 | 10 | `breathing` | `BreathingTrainingScreen` |

기존 얼굴 운동 중 턱 좌우와 볼 부풀리기처럼 원본 문서에 직접 대응하지 않는 항목은 기본 메뉴에서 제거한다. 단, 기존 기록의 제목과 ID는 삭제하지 않고 레거시 표시용 매핑에 보존한다.

### 5.2 공통 데이터 모델

```dart
enum TrainingCategory { tongue, lip, alternating, breathing }
enum TrainingSafetyTier { general, caution, clinicianOnly }
enum TrainingVisualMode { faceCloseUp, oralCutaway, upperBody, phoneme }

class GuidedTrainingExercise {
  final String id;
  final TrainingCategory category;
  final int sourceOrder;
  final String title;
  final String instruction;
  final String shortCaption;
  final String? secondaryCaption;
  final String videoAsset;
  final String posterAsset;
  final TrainingVisualMode visualMode;
  final int defaultRepeatCount;
  final List<int> repeatOptions;
  final Duration loopDuration;
  final List<double> speedOptions;
  final TrainingSafetyTier safetyTier;
  final String? safetyMessage;
  final List<TrainingCue> cues;
}

class TrainingCue {
  final Duration start;
  final Duration end;
  final String caption;
  final TrainingCuePhase phase;
}
```

운동 데이터는 화면 코드에 하드코딩하지 않고 카테고리별 Dart 데이터 파일 또는 검증 가능한 JSON으로 관리한다. 첫 구현은 컴파일 타임 검증이 쉬운 Dart 상수 목록을 권장한다.

### 5.3 ID 규칙

```text
tongue_01_vertical
tongue_02_lips
...
lip_01_tuck_extend
...
alternating_01_uiui
...
breathing_01_posture_inhale
```

ID는 영상 파일, 포스터, 기록, 자막 큐를 연결하는 영구 키다. 제목이 바뀌어도 ID는 변경하지 않는다.

## 6. 사용자 흐름

### 6.1 라이브러리에서 시작

```text
훈련
→ 구강·호흡 훈련
→ 혀 / 입술 / 교호 / 호흡
→ 운동 목록
→ 운동 상세 및 안전 안내
→ 반복 횟수·속도 선택
→ 영상 훈련
→ 완료 또는 다시 하기
```

### 6.2 오늘의 추천 루틴

```text
오늘
→ 오늘의 구강·호흡 루틴
→ 시작 전 피로도
→ 3~5개 운동 순차 재생
→ 중간 휴식
→ 종료 후 피로도
→ 기록 저장
```

### 6.3 개인 루틴

- 사용자가 운동 목록에서 최대 8개까지 고른다.
- 운동별 반복 횟수와 속도를 저장한다.
- `내 루틴`은 하나로 시작하고 추후 여러 루틴 이름 저장을 확장한다.
- `clinicianOnly` 항목을 추가할 때는 경고를 다시 확인한다.

## 7. 통합 영상 플레이어

### 7.1 화면 구성

```text
┌──────────────────────────────┐
│ 혀 운동 · 3/14        닫기  │
│ 혀로 입술 전체 돌리기       │
├──────────────────────────────┤
│                              │
│        무음 시범 영상        │
│                              │
│  [현재 단계 자막 1~2줄]      │
├──────────────────────────────┤
│ 시범 반복 06 / 20            │
│ ●●●●●●○○○○○○○○○○○○○○      │
│ [0.5×] [0.75×] [1×]          │
│ [이전] [일시정지] [다음]     │
└──────────────────────────────┘
```

### 7.2 재생 규칙

- 영상 1회 종료를 `시범 반복 1회`로 집계한다.
- 영상 시작과 함께 반복 수를 올리지 않고 `completed` 이벤트에서 올린다.
- 마지막 반복이 끝나면 자동으로 멈추고 `완료`, `5회 더`, `다음 운동`을 표시한다.
- 사용자가 화면을 벗어나거나 앱이 백그라운드로 가면 자동 일시정지한다.
- 속도를 변경하면 영상과 자막 큐를 함께 재계산한다.
- `다음`을 누를 때 미완료 상태면 `현재 운동을 건너뛸까요?`를 한 번 확인한다.
- 영상 루프 수는 실제 사용자 수행을 검증한 값이 아니므로 UI에 `성공 횟수`라고 표시하지 않는다.

### 7.3 반복 설정

- 빠른 선택: 5회, 10회, 20회
- 사용자 설정: 1~30회
- 원문 기본값: 20회
- 시작 전 피로도 4~5 선택 시 앱 제안: 반복 횟수 절반 및 30초 휴식
- 한 루틴의 예상 시간이 10분을 넘으면 분할을 권고한다.
- 교호 운동은 영상 루프와 발화 박자를 함께 표시하되 음성 성공 판정은 하지 않는다.

## 8. 자막과 음성 안내

### 8.1 자막 원칙

- 영상에는 텍스트를 생성하거나 굽지 않는다.
- 앱에서 한국어 자막을 오버레이한다.
- 한 화면 최대 2줄, 한 줄 18자 안팎을 목표로 한다.
- 동작 설명, 유지, 복귀, 휴식을 서로 다른 큐로 나눈다.
- 교호 운동은 현재 음절을 크게 표시하고 다음 음절을 흐리게 미리 보여준다.
- 좌우 동작은 사용자가 보는 화면 기준인지 수행자 기준인지 자막과 화살표로 명확히 표시한다.

### 8.2 접근성 설정

- 자막 켜기·끄기
- 글자 크기 100%, 125%, 150%
- 반투명 검정 배경 또는 고대비 흰색 배경
- TTS 음성 안내 켜기·끄기
- 진동으로 반복 종료 알림
- `자막만`, `음성+자막`, `시범만` 모드

### 8.3 TTS 규칙

- 첫 반복 전에 전체 지시문을 한 번 읽는다.
- 반복 중에는 `시작`, `유지`, `돌아오기`, 숫자 카운트만 선택적으로 읽는다.
- 교호 운동은 TTS 발음과 사용자의 발화를 겹치지 않게 `듣기`와 `따라 하기` 구간을 분리한다.
- TTS가 실패해도 영상과 자막 재생은 계속한다.

## 9. 영상 자산 전략

### 9.1 시각 유형

| 유형 | 적용 | 설명 |
|---|---|---|
| 얼굴 정면 클로즈업 | 외부에서 보이는 혀·입술 동작 | 머리와 턱을 고정하고 입 주변을 크게 표시 |
| 구강 측면 단면도 | 연구개·경구개·입천장 등 내부 동작 | 사실적인 의료 영상보다 친근한 2D 교육 일러스트 사용 |
| 상반신 정면 | 호흡과 자세 | 어깨·가슴·복부 움직임을 볼 수 있게 표시 |
| 음절 카드형 | 교호 운동 | 동일 튜터의 입 모양과 앱의 음절 자막을 결합 |

### 9.2 포맷

- 컨테이너: MP4
- 코덱: H.264 baseline/main 호환 프로필
- 화면비: 16:9
- 해상도: 1280×720
- 프레임률: 24fps 또는 30fps로 통일
- 길이: 4~8초
- 오디오: 없음
- 목표 용량: 영상당 평균 1.3MB 이하, 전체 60MB 이하
- 루프: 첫 프레임과 마지막 프레임의 기본 자세를 일치시킨다.

### 9.3 실패 처리

- 로딩 2초 이상이면 포스터와 진행 표시를 노출한다.
- 디코딩 실패 시 포스터, 방향 화살표, 자막, 타이머로 대체한다.
- 앱에 포함되지 않은 영상은 목록에서 숨기지 않고 `텍스트 안내로 시작`을 제공한다.
- 영상 오류는 운동 완료 기록과 분리해 저장한다.

## 10. 상태와 기록

```dart
enum GuidedTrainingPhase { ready, playing, paused, rest, complete, error }

class GuidedTrainingProgress {
  final GuidedTrainingPhase phase;
  final List<String> exerciseIds;
  final int exerciseIndex;
  final int completedLoops;
  final int targetLoops;
  final double playbackSpeed;
  final int fatigueBefore;
  final int? fatigueAfter;
  final Set<String> skippedExerciseIds;
  final List<TrainingExerciseResult> results;
}
```

저장 항목:

- 세션 ID와 시작·종료 시각
- 선택한 카테고리 또는 루틴 ID
- 운동별 목표 반복 수와 완료된 영상 루프 수
- 사용한 재생 속도
- 건너뛴 운동과 중단 지점
- 시작 전·후 피로도
- 영상 재생 실패 여부
- 콘텐츠 버전과 기록 스키마 버전

기존 `TongueExerciseSession`은 읽기 호환을 유지한다. 새 기록 화면에서는 레거시 세션에 `이전 혀운동 기록` 라벨을 붙이고, 새 세션과 같은 날짜 흐름 안에서 표시한다.

## 11. Flutter 구현 구조

```text
lib/features/guided_training/
├── model/
│   ├── guided_training_exercise.dart
│   ├── guided_training_routine.dart
│   └── guided_training_session.dart
├── data/
│   ├── tongue_exercises.dart
│   ├── lip_exercises.dart
│   ├── alternating_exercises.dart
│   └── breathing_exercises.dart
├── provider/
│   └── guided_training_controller.dart
├── view/
│   ├── guided_training_hub_screen.dart
│   ├── training_category_screen.dart
│   ├── guided_training_player_screen.dart
│   └── routine_builder_screen.dart
└── widgets/
    ├── training_video_stage.dart
    ├── timed_caption_overlay.dart
    ├── repetition_progress.dart
    └── training_safety_card.dart

lib/services/guided_training/
├── guided_training_history_service.dart
└── training_settings_service.dart
```

`video_player`는 현재 프로젝트 의존성을 그대로 사용한다. 기존 `AnimatedExerciseAvatar`는 영상이 없는 항목의 임시 폴백으로 유지하되 새 콘텐츠의 주 렌더러로 확장하지 않는다.

## 12. 라우트와 이전 호환

새 라우트:

```text
/guided_training
/guided_training/tongue
/guided_training/lip
/guided_training/alternating
/guided_training/breathing
/guided_training/player
/guided_training/routine_builder
```

기존 라우트 처리:

| 기존 라우트 | 전환 |
|---|---|
| `/tongue_exercise_menu` | `/guided_training/tongue`로 연결 |
| `/tongue_exercise` | 기본 혀 루틴으로 연결 |
| `/face_exercise` | `/guided_training/lip`으로 연결 |
| `/oral_alternating_exercise` | `/guided_training/alternating`으로 연결 |
| `/breathing_training` | `/guided_training/breathing`으로 연결 |

북마크나 기존 홈 카드가 깨지지 않도록 한 릴리스 동안 기존 라우트를 유지한다.

## 13. 구현 단계

### 1단계: 콘텐츠와 플레이어 기반

1. 46개 운동 데이터와 영구 ID 작성
2. 안전 등급 및 임상 검토 상태 추가
3. 공통 플레이어, 반복 카운터, 자막 큐 구현
4. 샘플 영상 4개로 혀·입술·교호·호흡 각 유형 검증
5. 플레이어 단위·위젯 테스트 추가

### 2단계: 영상 제작과 카테고리 전환

1. Higgsfield로 46개 영상 초안 생성
2. 캐릭터·해부학·루프·좌우 방향 QA
3. 승인 영상 압축 및 asset 등록
4. 새 허브와 카테고리 목록 구현
5. 기존 네 화면을 새 플레이어로 전환

### 3단계: 기록과 개인 루틴

1. 통합 세션 저장소 구현
2. 레거시 혀운동 기록 읽기 호환
3. 내 루틴 편집과 설정 저장
4. 오늘 화면과 대시보드 연결

### 4단계: 안정화

1. iOS·Android 저사양 기기 영상 메모리 확인
2. 접근성 글자 크기와 화면 읽기 검증
3. 앱 백그라운드·전화 수신·오디오 충돌 처리
4. 언어재활사 검수와 안전 문구 승인

## 14. 테스트 및 승인 기준

### 14.1 콘텐츠

- 46개 ID, 제목, 순서가 전사 원본과 일치한다.
- 모든 항목에 영상 또는 포스터 폴백이 있다.
- `clinicianOnly` 항목이 기본 추천 루틴에 포함되지 않는다.
- 영상의 좌우 방향과 자막이 일치한다.

### 14.2 플레이어

- 재생 완료 이벤트마다 반복 수가 정확히 1 증가한다.
- 0.5·0.75·1배에서 자막 큐와 반복 완료가 동기화된다.
- 일시정지, 백그라운드 전환, 재시작 시 중복 카운트가 없다.
- 마지막 반복 뒤 자동 재생이 멈춘다.
- 영상 오류에도 텍스트 훈련을 완료할 수 있다.

### 14.3 접근성과 안전

- 150% 자막에서도 중요한 조작이 가려지지 않는다.
- 스크린 리더가 운동 제목, 반복 진행, 버튼 상태를 읽는다.
- 색상을 제외한 텍스트와 아이콘으로 상태를 구분한다.
- 안전 등급별 경고와 중단 안내가 올바르게 노출된다.

### 14.4 완료 조건

- 네 기존 훈련 진입점이 모두 새 통합 구조로 연결된다.
- 사용자가 카테고리 선택부터 기록 저장까지 중단 없이 완료할 수 있다.
- 46개 콘텐츠 중 임상 승인된 항목이 모두 영상·자막·반복 기능으로 동작한다.
- 기존 혀운동 기록을 잃지 않는다.
- `flutter analyze`와 관련 테스트가 통과한다.

## 15. 확정된 가정과 남은 확인 사항

### 확정된 가정

- 주 사용자는 후천성 마비말장애가 있는 성인이다.
- 앱은 오프라인에서도 핵심 훈련을 수행할 수 있어야 한다.
- 첫 버전은 수행 인식보다 정확하고 일관된 시범 제공에 집중한다.
- 영상 속 캐릭터는 기존 2D 여성 재활 안내자 이미지를 기준으로 통일한다.

### 임상 또는 제작 단계에서 확인할 사항

- 각 항목의 최종 반복 수와 유지 시간
- 좌우 표기의 사용자 기준·튜터 기준 최종 정책
- 호흡 훈련 2~7번의 일반 사용자 공개 여부
- 설압자 훈련의 대체 시범과 전문가 모드 제공 여부
- 생성 영상 전체를 번들할 때 최종 앱 용량
