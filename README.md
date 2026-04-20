# Speech Rehab — AI 언어 재활 코치 앱

> **Gemma 2B 기반 온디바이스 AI**를 활용한 한국어 발음 교정 & 대화 연습 앱

---

## 📌 프로젝트 개요

Speech Rehab은 **언어 재활이 필요한 사용자**를 위한 AI 대화 코치 앱입니다.  
사용자의 발화를 인식하여 Gemma AI가 자연스러운 한국어 대화로 응답하며, **실시간 발음 피드백과 객관적인 점수**를 제공합니다.

### 핵심 특징

- 🏁 **히스토리 우선 진입** — 앱 실행 시 지난 대화 내역이 먼저 표시되어 학습 흐름을 바로 파악 가능
- 🎙 **순수 음성 인터페이스** — 텍스트 입력창 없이 오직 음성으로만 대화하는 몰입형 환경
- 📖 **소리 내어 읽기 연습** — 정해진 문장이나 자유 발화를 통해 발음을 교정받는 전용 훈련 모드
- 🛡 **권한 안내 시스템** — 처음 사용하는 사용자를 위해 마이크/음성 인식 권한 필요성을 친절하게 안내
- 🤖 **객관적인 AI 코칭** — 전문적인 '영은' 페르소나가 객관적인 평가와 문법 교정 팁을 제공
- 🕗 **통합 히스토리 관리** — AI 대화와 읽기 연습 기록을 한데 모아보고 필터링할 수 있는 일원화된 저장소

---

## 🏗 프로젝트 구조

```
lib/
├── main.dart                                    # 앱 진입점 및 권한 기반 조건부 시작(StartupResolver)
├── features/
│   ├── chat/                                    # AI 대화 관련 기능
│   │   ├── provider/
│   │   └── view/
│   └── practice/                                # 읽기 연습 관련 기능
│       ├── provider/                            # 연습 상태 및 녹음/평가 로직
│       └── view/                                # 연습 화면 및 기록 확인 화면
└── services/
    ├── api/
    │   └── ai_service.dart                      # Gemma AI 추론 및 프롬프트 서비스
    ├── audio/
    │   ├── audio_recorder_service.dart          # 로컬 녹음 기능 (record 기반)
    │   ├── audio_player_service.dart            # 오디오 재생 기능 (audioplayers 기반)
    │   ├── stt_service.dart                     # 음성인식 서비스
    │   └── tts_service.dart                     # 음성합성 서비스
    ├── history_service.dart                     # 대화 히스토리 저장소
    ├── practice_history_service.dart            # 읽기 연습 내역 저장소
    ├── practice_sentence_service.dart           # 연습용 문장 라이브러리 서비스
    └── permission_service.dart                  # 멀티 플랫폼 권한 관리 서비스
```

---

## 📋 최근 개선 사항 (Changelog)

### 1. 소리 내어 읽기 연습 (Reading Practice) 추가
- 사용자가 제시된 문장이나 직접 입력한 문장을 읽고 발음 점수와 피드백을 받을 수 있는 기능을 추가했습니다.
- 녹음된 자신의 목소리를 다시 들어보며 AI '영은'의 구체적인 코칭을 확인할 수 있습니다.

### 2. 자유 읽기 (Free Reading) 및 통합 히스토리
- 정해진 문장 없이도 자유롭게 말하고 평가받는 '자유 읽기' 모드를 도입했습니다.
- 메인 히스토리 화면에서 대화 세션과 연습 세션을 통합하여 조회하고 필터링할 수 있는 기능을 완성했습니다.

### 3. 고도화된 UI 및 버그 수정
- 스크롤 뷰 도입을 통해 긴 피드백 카드 노출 시 발생하던 Bottom Overflow 문제를 해결했습니다.
- 발음 연습을 상징하는 전용 아이콘과 프리미엄 뱃지 요소를 적용했습니다.

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
