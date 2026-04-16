# Speech Rehab — AI 언어 재활 코치 앱

> **Gemma 2B 기반 온디바이스 AI**를 활용한 한국어 발음 교정 & 대화 연습 앱

---

## 📌 프로젝트 개요

Speech Rehab은 **언어 재활이 필요한 사용자**를 위한 AI 대화 코치 앱입니다.  
사용자의 발화를 인식하여 Gemma AI가 자연스러운 한국어 대화로 응답하며, **실시간 발음 피드백과 객관적인 점수**를 제공합니다.

### 핵심 특징

- 🏁 **히스토리 우선 진입** — 앱 실행 시 지난 대화 내역이 먼저 표시되어 학습 흐름을 바로 파악 가능
- 🎙 **순수 음성 인터페이스** — 텍스트 입력창 없이 오직 음성으로만 대화하는 몰입형 환경
- 🛡 **권한 안내 시스템** — 처음 사용하는 사용자를 위해 마이크/음성 인식 권한 필요성을 친절하게 안내
- 🤖 **객관적인 AI 코칭** — 전문적인 '영은' 페르소나가 객관적인 평가와 문법 교정 팁을 제공
- 🕗 **대화 히스토리 영구 저장** — 모든 대화 세션은 기기에 자동 저장되며 제목이 자동 생성됨

---

## 🏗 프로젝트 구조

```
lib/
├── main.dart                                    # 앱 진입점 및 권한 기반 조건부 시작(StartupResolver)
├── features/
│   └── chat/
│       ├── provider/
│       │   └── chat_provider.dart               # 세션/히스토리 상태 관리 Notifier
│       └── view/
│           ├── chat_screen.dart                  # 음성 전용 대화 화면 (Orb 중심 UI)
│           ├── history_screen.dart               # 앱의 메인 엔트리, 대화 목록 관리
│           ├── permission_screen.dart            # 권한 안내 및 요청 화면
│           └── widgets/
│               ├── animated_orb.dart            # 상태별 시각화 구슬 위젯
│               └── feedback_card.dart           # 발음 피드백용 카드 위젯
└── services/
    ├── api/
    │   └── ai_service.dart                      # Gemma AI 추론 및 프롬프트 서비스
    ├── audio/
    │   ├── stt_service.dart                     # 음성인식 (플랫폼 안정성 가드 포함)
    │   └── tts_service.dart                     # 음성합성 서비스
    ├── history_service.dart                     # 로컬 저장소 서비스
    └── permission_service.dart                  # 멀티 플랫폼 권한 관리 서비스
```

---

## 📱 플랫폼별 지원 현황

| 플랫폼 | 상태 | 입력 방식 | 비고 |
|--------|------|-----------|------|
| **iOS** | ✅ 지원 | 🎙 음성(STT) | Gemma 온디바이스 추론 지원 |
| **Android** | ✅ 지원 | 🎙 음성(STT) | Gemma 온디바이스 추론 지원 |
| **macOS** | ✅ 지원 | - (읽기 전용) | TCC 보안 충돌 방지를 위해 STT 비활성화. 모바일 앱 실제 코칭 환경 테스트용. |

---

## 📋 최근 개선 사항 (Changelog)

### 1. 브랜드 리뉴얼 (Speech Rehab)
- 앱 이름을 "MJ Dialog"에서 "Speech Rehab"으로 변경하고 관련 모든 경로와 메타데이터를 통합했습니다.

### 2. 권한 안내 시스템 (Permission Guide)
- 앱 시작 시 마이크 및 음성 인식 권한 여부를 확인합니다.
- 권한이 없는 경우, 프리미엄 다크 테마 디자인의 `PermissionScreen`을 통해 권한 허용을 유도합니다.

### 3. 히스토리 우선 내비게이션
- 앱의 첫 화면을 대화 목록으로 변경하여 학습 기록 관리가 용이해졌습니다.

### 4. 음성 전용 UI 및 AI 고도화
- 텍스트 입력 없이 오직 음성으로만 상호작용하는 Voice-Only 인터페이스를 완성했습니다.
- AI '영은'이 대화 마지막에 항상 질문을 던져 대화를 지속하도록 유도합니다.

---

## 🚀 실행 방법

### 사전 요구사항
- Flutter 3.38+ 설치
- Gemma 2B 모델 파일 (모바일): `assets/gemma-2b-it-gpu-int4.bin`

### 빌드 & 실행
```bash
# 의존성 설치
flutter pub get

# macOS 실행
flutter run -d macos

# iOS 실행 (권장)
flutter run -d ios

# Android 실행
flutter run -d android
```
