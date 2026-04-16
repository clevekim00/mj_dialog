# MJ Dialog — AI 언어 재활 코치 앱

> **Gemma 2B 기반 온디바이스 AI**를 활용한 한국어 발음 교정 & 대화 연습 앱

---

## 📌 프로젝트 개요

MJ Dialog는 **언어 재활이 필요한 사용자**를 위한 AI 대화 코치 앱입니다.  
사용자의 발화를 인식하고, Gemma AI가 자연스러운 한국어 대화로 응답하면서 **발음 피드백과 점수**를 실시간으로 제공합니다.

### 핵심 특징

- 🎙 **음성 인식 (STT)** — `speech_to_text` 기반 실시간 한국어 음성 → 텍스트 변환 (모바일)
- 🤖 **온디바이스 AI 추론** — `flutter_gemma`로 Gemma 2B 모델을 디바이스에서 직접 실행 (프라이버시 보호)
- 🔊 **음성 합성 (TTS)** — `flutter_tts` 기반 AI 응답 음성 출력
- 📊 **발음 피드백** — AI가 발음 점수(0~100)와 교정 코칭 제공
- 🎨 **Voice-First UI** — ChatGPT 음성 모드 스타일의 몰입형 다크 테마 인터페이스

---

## 🏗 프로젝트 구조

```
lib/
├── main.dart                                    # 앱 진입점, Gemma 초기화, 테마 설정
├── features/
│   └── chat/
│       ├── provider/
│       │   └── chat_provider.dart               # ChatController 기반 세션 상태/흐름 관리
│       └── view/
│           ├── chat_screen.dart                  # 메인 화면 (데스크톱: 텍스트 입력 / 모바일: 음성 입력)
│           └── widgets/
│               ├── animated_orb.dart            # 상태별 애니메이션 구슬 위젯
│               └── feedback_card.dart           # 글래스모피즘 발음 피드백 카드
└── services/
    ├── api/
    │   └── ai_service.dart                      # Gemma AI 추론 서비스 (프롬프트 → JSON 응답 파싱)
    └── audio/
        ├── stt_service.dart                     # 음성 인식 서비스 (한국어)
        └── tts_service.dart                     # 음성 합성 서비스 (한국어)
```

---

## 🎨 UI 디자인

### Voice-First 인터페이스

ChatGPT의 음성 모드에서 영감을 받은 **풀스크린 몰입형 UI**:

| 구성 요소 | 설명 |
|-----------|------|
| **Animated Orb** | 화면 중앙의 애니메이션 구슬. 대기(회색) → 듣기(청록 맥동) → 생각(보라 회전) → 말하기(백색 파동) → 피드백(틸) 상태 전환 |
| **실시간 텍스트** | 사용자의 음성/입력이 하단에 큰 글씨로 실시간 표시 |
| **피드백 카드** | AI 응답 후 하단에서 슬라이드 업되는 반투명 글래스모피즘 카드 (점수 + 코칭) |
| **입력 방식** | 데스크톱: 텍스트 입력창 / 모바일: 마이크 버튼 |

### 테마

- **다크 모드** (`#121212` 배경)
- Material 3 디자인 시스템
- 상태별 색상 그라데이션 및 글로우 이펙트

---

## 🛠 기술 스택

| 기술 | 버전 | 용도 |
|------|------|------|
| **Flutter** | 3.38.5 | 크로스 플랫폼 UI 프레임워크 |
| **Dart** | 3.10.4 | 프로그래밍 언어 |
| **flutter_gemma** | 0.12.6 | 온디바이스 Gemma 2B 모델 추론 |
| **flutter_riverpod** | 3.3.1 | 상태 관리 (Notifier 패턴) |
| **speech_to_text** | 7.3.0 | 음성 → 텍스트 변환 |
| **flutter_tts** | 4.2.5 | 텍스트 → 음성 합성 |
| **uuid** | 4.0.0 | 고유 메시지 ID 생성 |

---

## 📱 플랫폼별 지원 현황

| 플랫폼 | 상태 | 입력 방식 | 비고 |
|--------|------|-----------|------|
| **iOS** | ✅ 지원 | 🎙 음성(STT) | Gemma 온디바이스 추론 |
| **Android** | ✅ 지원 | 🎙 음성(STT) | Gemma 온디바이스 추론 |
| **macOS** | ⚠️ 부분 지원 | ⌨️ 텍스트 입력 | Gemma 에셋 로딩 미지원 → fallback 응답 사용. STT는 TCC 제한으로 비활성화 |

---

## 🚀 실행 방법

### 사전 요구사항

- Flutter 3.38+ 설치
- Xcode 16+ (macOS/iOS)
- Gemma 2B 모델 파일: `assets/gemma-2b-it-gpu-int4.bin`

### 빌드 & 실행

```bash
# 의존성 설치
flutter pub get

# macOS 실행
flutter run -d macos

# iOS 실행
flutter run -d ios

# Android 실행
flutter run -d android
```

### macOS 특이사항

- `macos/Podfile`: 플랫폼 타겟 `11.0` 이상 필요
- `macos/Runner.xcodeproj/project.pbxproj`: `MACOSX_DEPLOYMENT_TARGET = 11.0`
- `macos/Runner/DebugProfile.entitlements`: App Sandbox **비활성화** (개발용)
- `macos/Runner/Info.plist`: `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription` 키 포함

---

## 🧠 AI 프롬프트 구조

```
You are '영은', a friendly language rehabilitation assistant in Korean.
The user said: "[사용자 발화]".
1. Give a conversational reply.
2. Provide a pronunciation score out of 100.
3. Provide brief pronunciation and speech feedback.
Respond EXACTLY in this JSON format:
{
  "replyText": "...",
  "pronunciationScore": 85,
  "pronunciationFeedback": "..."
}
```

---

## 📂 주요 파일 설명

### `main.dart`
- Flutter 앱 진입점
- 데스크톱 환경에서는 Gemma 초기화를 스킵 (네이티브 에셋 복사 미지원)
- 다크 테마 적용

### `chat_provider.dart`
- `ChatSessionState`로 대화 상태, 표시 텍스트, 피드백, 메시지 목록을 일관되게 관리
- `ChatController`가 텍스트 제출, STT 시작/정지, AI 요청, TTS 완료 후 상태 전환을 담당

### `chat_screen.dart`
- 플랫폼 감지: 데스크톱은 텍스트 입력, 모바일은 마이크 버튼
- Stack 기반 레이아웃: Orb + 텍스트 + 피드백 카드 + 입력 영역
- 에러 메시지는 Riverpod 상태를 listen 해서 Snackbar로 표시

### `animated_orb.dart`
- `AnimationController`로 1.5초 주기 반복 애니메이션
- 상태별로 크기, 색상, 그림자가 동적으로 변화

### `feedback_card.dart`
- `BackdropFilter` + 반투명 배경의 글래스모피즘 디자인
- 발음 점수에 따라 색상 변화 (초록 ≥ 80, 주황 ≥ 60, 빨강 < 60)

### `ai_service.dart`
- Gemma 온디바이스 추론 또는 fallback 응답 제공
- JSON 응답 파싱 (`jsonDecode` 기반)

---

## ⚠️ 알려진 제한사항

1. **macOS Gemma 모델 로딩**: `flutter_gemma`의 에셋 복사가 데스크톱에서 미지원 → fallback 응답 사용
2. **macOS STT**: `speech_to_text`가 macOS TCC(Transparency, Consent, Control)와 충돌하여 SIGABRT 크래시 발생 → 데스크톱에서는 텍스트 입력으로 대체
3. **Gemma 2B 성능**: 소형 모델이므로 복잡한 한국어 문장에 대한 품질이 제한적

---

## ✅ 품질 개선 반영 사항

- 앱 루트에서 `ProviderScope`를 직접 포함해 테스트/실행 환경 차이를 줄였습니다.
- 대화 상태를 단일 세션 모델로 통합해 상태 불일치 가능성을 낮췄습니다.
- TTS는 고정 지연이 아니라 실제 완료 시점 기준으로 피드백 단계로 넘어갑니다.
- 위젯 테스트를 현재 앱 구조에 맞게 교체했습니다.

---

## 📋 향후 계획

- [ ] Gemma API 서버 모드 (macOS에서 로컬 서버로 모델 호스팅)
- [ ] 대화 히스토리 화면 추가
- [ ] 발음 트렌드 그래프 (시간에 따른 점수 변화)
- [ ] 음성 파형 시각화
- [ ] iOS/Android 실기기 테스트 및 최적화
