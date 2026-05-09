# Speech Rehab 프로젝트 구조 분석 및 개선 검토

작성일: 2026-04-29

## 1. 프로젝트 요약

Speech Rehab은 Flutter 기반의 AI 언어 연습 코치 앱이다. 핵심 기능은 음성 기반 AI 대화, 소리 내어 읽기 연습, 발음 피드백, 대화/연습 히스토리 관리로 구성되어 있다.

현재 코드는 단순 채팅 프로토타입에서 한 단계 확장되어, `chat` 기능과 `practice` 기능이 분리되어 있고 공통 서비스 계층이 추가된 상태다. 앱의 첫 진입점은 권한 상태를 확인한 뒤 히스토리 화면 또는 권한 안내 화면으로 분기한다.

## 2. 상위 구조

```text
.
├── lib/
│   ├── main.dart
│   ├── features/
│   │   ├── chat/
│   │   │   ├── provider/
│   │   │   └── view/
│   │   └── practice/
│   │       ├── provider/
│   │       └── view/
│   └── services/
│       ├── api/
│       ├── audio/
│       ├── history_service.dart
│       ├── permission_service.dart
│       ├── practice_history_service.dart
│       └── practice_sentence_service.dart
├── backend/
│   └── src/main/kotlin/
├── docs/
├── test/
├── android/
├── ios/
├── macos/
├── web/
├── linux/
└── windows/
```

## 3. 주요 모듈 분석

### 앱 진입 및 라우팅

`lib/main.dart`는 Flutter 초기화, 모바일 환경의 Gemma 모델 초기화, Riverpod `ProviderScope`, 라우트 등록, `StartupResolver`를 담당한다.

현재 시작 흐름은 다음과 같다.

```text
main()
→ Flutter/Gemma 초기화
→ MyApp
→ StartupResolver
→ PermissionService.hasAllPermissions()
→ 권한 있음: HistoryScreen
→ 권한 없음: PermissionScreen
```

이 구조는 권한 안내를 앱 초입에 배치한다는 점에서 사용자 흐름이 명확하다. 다만 `StartupResolver`가 `FutureBuilder`로 직접 권한 상태를 읽고 있어, 권한 상태 변경 후 재확인 흐름은 화면 간 이동에 의존한다.

### Chat 기능

주요 파일은 다음과 같다.

```text
lib/features/chat/provider/chat_provider.dart
lib/features/chat/view/history_screen.dart
lib/features/chat/view/chat_screen.dart
lib/features/chat/view/permission_screen.dart
lib/features/chat/view/widgets/animated_orb.dart
lib/features/chat/view/widgets/feedback_card.dart
```

`ChatController`는 대화 세션 목록, 현재 세션, STT 상태, AI 응답, TTS 재생, 히스토리 저장까지 관리한다. 이전보다 상태는 많이 정리되었지만, 한 Controller가 세션 관리와 음성 입출력 흐름을 모두 담당하고 있어 기능이 더 커질 경우 책임 분리가 필요하다.

현재 대화 흐름은 다음과 같다.

```text
HistoryScreen에서 대화 선택 또는 새 대화 생성
→ ChatScreen 진입
→ 마이크 탭
→ SttService.startListening()
→ 최종 텍스트 감지
→ AiService.getResponseAndFeedback()
→ TtsService.speak()
→ FeedbackCard 표시
→ HistoryService.saveSessions()
```

### Practice 기능

주요 파일은 다음과 같다.

```text
lib/features/practice/provider/practice_provider.dart
lib/features/practice/view/practice_screen.dart
lib/features/practice/view/practice_history_screen.dart
lib/features/practice/view/dashboard_screen.dart
```

`PracticeNotifier`는 문장 연습, 자유 읽기, 녹음, STT, AI 평가, 재생, 공유, 연습 히스토리 저장을 담당한다. 사용자 관점의 기능은 풍부하지만, 녹음과 STT와 AI 분석이 하나의 Notifier에 많이 모여 있다.

현재 연습 흐름은 다음과 같다.

```text
PracticeScreen
→ 문장 연습 또는 자유 읽기 선택
→ 녹음 시작
→ STT와 로컬 녹음 시작
→ 녹음 종료
→ STT 종료 및 텍스트 확정
→ AiService.evaluateAudio()
→ 실패 시 getReadingFeedback() fallback
→ PracticeHistoryService.savePractice()
→ 피드백, 녹음 재생, 공유 제공
```

### 서비스 계층

서비스 계층은 UI와 플랫폼 기능 사이의 경계 역할을 한다.

```text
lib/services/api/ai_service.dart
lib/services/audio/stt_service.dart
lib/services/audio/tts_service.dart
lib/services/audio/audio_recorder_service.dart
lib/services/audio/audio_player_service.dart
lib/services/history_service.dart
lib/services/practice_history_service.dart
lib/services/permission_service.dart
lib/services/practice_sentence_service.dart
```

현재 장점은 기능별 서비스가 이미 분리되어 있다는 점이다. 반면 저장소 모델이 Provider 파일에 위치하거나, 일부 서비스가 예외를 삼키고 단순 fallback으로 넘어가는 구조라서 테스트와 오류 추적이 어려워질 수 있다.

### Backend 모듈

백엔드 Kotlin 모듈에는 Spring 스타일의 Gemma 4 음성 평가 API 스텁이 있다.

현재 백엔드는 실제 앱의 `AiService.evaluateAudio()`와 연결되어 있지 않다. Flutter 쪽에서는 800ms 지연 후 `getReadingFeedback(targetText, "")`를 호출하는 시뮬레이션에 가깝다.

## 4. 현재 검증 결과

초기 점검 시 직접 실행한 결과는 다음과 같았다.

```text
flutter analyze
→ 15 issues found

flutter test
→ 실패
```

테스트 실패 원인은 현재 앱이 히스토리 우선 진입과 음성 전용 UI로 바뀌었는데, `test/widget_test.dart`가 여전히 `Gemma AI Coach`와 `메시지를 입력하세요...` 텍스트를 기대하기 때문이다.

정적 분석의 주요 이슈는 다음과 같다.

```text
lib/features/practice/provider/practice_provider.dart
→ 중복 null 체크로 인한 dead code
→ deprecated Share API 사용

lib/services/api/ai_service.dart
→ 사용되지 않는 Gemma 4 helper 함수
→ 불필요한 dart:ui import
→ 중괄호 없는 if/else 스타일 이슈

lib/features/practice/view/practice_screen.dart
→ 사용되지 않는 import

lib/services/audio/audio_recorder_service.dart
→ path 패키지를 직접 import하지만 pubspec 의존성에 없음

lib/services/practice_history_service.dart
→ 사용되지 않는 uuid import

lib/features/chat/view/history_screen.dart
→ whereType 사용 권장
```

이후 검증 결과 개선사항을 반영하여 2026-04-29 기준 최종 상태는 다음과 같다.

```text
flutter analyze
→ No issues found

flutter test
→ All tests passed
```

반영한 수정 사항은 다음과 같다.

```text
test/widget_test.dart
→ 현재 Startup 흐름에 맞춰 데스크톱 권한 우회 경로와 히스토리 화면을 검증하도록 수정

lib/features/practice/provider/practice_provider.dart
→ 중복 audioFile null 체크 제거
→ deprecated Share API를 SharePlus.instance.share()로 교체

lib/services/api/ai_service.dart
→ 불필요한 dart:ui import 제거
→ 미사용 Gemma 4 helper 함수 제거
→ if/else 중괄호 스타일 정리

lib/features/practice/view/practice_screen.dart
→ 미사용 import 제거

lib/services/practice_history_service.dart
→ 미사용 uuid import 제거

lib/features/chat/view/history_screen.dart
→ whereType 사용

pubspec.yaml
→ 직접 import 중인 path 패키지를 dependencies에 명시
```

## 5. 개선사항 검토

### P0. 테스트 복구

초기 점검 시 `flutter test`가 실패했으나, 현재는 복구되어 통과한다. 테스트는 앱의 현재 진입점인 `StartupResolver`와 히스토리 화면 기준으로 조정되었다.

개선 방향은 다음과 같다.

```text
test/widget_test.dart
→ "Gemma AI Coach"와 텍스트 입력창 기대 제거 완료
→ 테스트 플랫폼을 macOS로 고정해 권한 우회 경로를 명확히 함
→ 히스토리 화면과 자동 생성되는 "새 대화" 항목을 검증
```

추가로 `ChatController`, `PracticeNotifier`, `AiService` 파싱 로직은 위젯 테스트보다 단위 테스트가 더 적합하다.

### P0. 정적 분석 경고 제거

초기 점검 시 `flutter analyze`가 15개 이슈를 보고했으나, 현재는 모두 정리되어 통과한다. 대부분은 작은 정리였지만, 일부는 실제 품질 신호였다.

우선 처리할 항목은 다음과 같다.

```text
practice_provider.dart
→ audioFile null 중복 체크 제거 완료

practice_provider.dart
→ Share.shareXFiles를 SharePlus.instance.share() 방식으로 변경 완료

audio_recorder_service.dart
→ path 패키지를 pubspec.yaml dependencies에 명시 완료

ai_service.dart
→ 미사용 Gemma 4 prompt/parser 제거 완료
```

### P1. 모델과 상태 책임 분리

현재 `ChatSession`, `ChatMessage`, `ChatSessionState`가 `chat_provider.dart` 안에 함께 있다. 기능이 커진 지금은 모델, 저장소, controller를 분리하는 편이 좋다.

권장 구조는 다음과 같다.

```text
lib/features/chat/model/chat_message.dart
lib/features/chat/model/chat_session.dart
lib/features/chat/provider/chat_controller.dart
lib/features/chat/provider/chat_state.dart
```

Practice 쪽도 유사하게 `PracticeProgress`와 `PracticeSession`을 별도 모델 파일로 이동하면 view/provider/service 간 순환 의존 가능성을 줄일 수 있다.

### P1. 저장소 계층 개선

현재 대화 히스토리와 연습 히스토리는 `SharedPreferences`에 JSON 문자열로 저장된다. 초기 MVP에는 충분하지만, 데이터가 늘어나면 성능과 마이그레이션이 부담이 된다.

개선 방향은 다음과 같다.

```text
단기
→ JSON 파싱 실패 시 빈 배열 반환만 하지 말고 debug 로그 또는 복구 루틴 추가
→ 저장 데이터 버전 필드 추가
→ 오래된 녹음 파일 정리 정책 추가

중기
→ Drift, Isar, SQLite 등 로컬 DB 검토
→ ChatSession과 PracticeSession을 통합 검색할 수 있는 repository 계층 도입
```

### P1. 음성 처리 파이프라인 안정화

Practice 기능은 STT와 고품질 녹음을 동시에 사용한다. 현재 400ms 지연으로 오디오 세션 안정화를 기다리는데, 기기별 차이가 있을 수 있다.

개선 방향은 다음과 같다.

```text
AudioRecordingController 또는 SpeechCaptureService 도입
→ STT와 recorder 시작/중지 순서를 한 곳에서 관리
→ 녹음 실패, STT 실패, 권한 실패를 구분한 상태 반환
→ 녹음 파일 생성 여부를 명확히 보장
```

또한 `AudioRecorderService.isRecording()`이 항상 `false`를 반환하므로 실제 상태 추적 또는 메서드 제거가 필요하다.

### P1. AI 평가 경로 명확화

`AiService.evaluateAudio()`는 Gemma 4 분석처럼 보이지만 현재는 실제 오디오 파일을 사용하지 않는다. 이 상태는 README와 UI 기대를 높이지만 실제 품질과 차이가 생긴다.

개선 선택지는 두 가지다.

```text
로컬 MVP 방향
→ evaluateAudio 이름을 evaluateReadingFromTranscript처럼 바꾸고 STT 텍스트 기반 평가임을 명확히 표현

백엔드 연동 방향
→ backend의 /api/ai/evaluate 엔드포인트를 Flutter Dio 클라이언트와 연결
→ 오디오 파일 multipart 업로드
→ GemmaResponse를 AiResponse로 매핑
```

### P2. 백엔드/빌드 산출물 정리

현재 Git 추적 파일에 다음과 같은 산출물 또는 의미가 불분명한 파일이 포함되어 있다.

```text
Components.
Settings
backend/.gradle/**
backend/bin/main/**
```

이 파일들은 일반적으로 소스 관리 대상이 아니다. 삭제 및 `.gitignore` 보강을 검토하는 것이 좋다.

권장 `.gitignore` 추가 후보는 다음과 같다.

```text
backend/.gradle/
backend/build/
backend/bin/
Components.
Settings
```

### P2. 문서 최신화

README는 현재 기능을 잘 설명하고 있지만, 다음 내용은 더 명확해질 수 있다.

```text
현재 실제 AI 오디오 분석은 시뮬레이션 또는 fallback 중심임을 명시
테스트 상태와 지원 플랫폼별 제한사항 추가
backend 모듈의 현재 상태를 "실험적 스텁"으로 표현
모바일과 데스크톱의 권한/STT/Gemma 차이 정리
```

## 6. 권장 실행 순서

1. 테스트 복구

완료. `test/widget_test.dart`를 현재 Startup/히스토리 흐름 기준으로 수정했고 `flutter test`가 통과한다.

2. Analyze 이슈 정리

완료. dead code, unused import, deprecated API, dependency 누락을 정리했고 `flutter analyze`가 통과한다.

3. Git 추적 파일 정리

`backend/.gradle`, `backend/bin`, `Components.`, `Settings`의 추적 여부를 정리하고 `.gitignore`를 보강한다.

4. AI 평가 경로 결정

오디오 기반 평가를 실제 백엔드와 연결할지, STT 텍스트 기반 MVP로 명확히 유지할지 결정한다.

5. 모델/상태 파일 분리

Chat과 Practice의 model/state/controller 파일을 분리해 유지보수성을 높인다.

6. 저장소 계층 고도화

히스토리 데이터가 늘어날 것을 대비해 저장소 버전 관리와 로컬 DB 전환 가능성을 검토한다.

## 7. 제안하는 다음 작업 단위

가장 작은 단위로 안전하게 진행하려면 아래 순서가 좋다.

```text
Step 1
→ widget_test.dart 수정 완료
→ flutter test 통과 확인 완료

Step 2
→ flutter analyze 15개 이슈 정리 완료
→ flutter analyze 통과 확인 완료

Step 3
→ .gitignore 보강
→ 추적 중인 빌드 산출물 제거 여부 결정

Step 4
→ AiService.evaluateAudio의 실제 책임 정리
→ README에 현재 AI 평가 경로 반영
```

## 8. 결론

현재 프로젝트는 기능 확장 속도가 빠른 편이고, 음성 대화와 읽기 연습이라는 앱의 방향도 분명하다. 이번 반영으로 테스트와 정적 분석은 다시 통과 상태가 되었다. 다만 AI 오디오 평가 경로가 실제 구현보다 앞서 표현된 부분은 여전히 다음 단계의 핵심 개선 과제다.

이제 다음 기준점은 AI 평가 경로와 저장소 계층을 명확히 정리하는 것이다. 특히 `evaluateAudio()`가 실제 오디오를 분석하는지, STT 텍스트 기반 평가를 대표하는지부터 결정하면 이후 백엔드 연동과 문서 신뢰도가 함께 좋아진다.
