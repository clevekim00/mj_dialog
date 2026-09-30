# 말이음 · SpeechBridge 브랜드 적용

[한국어](README.md) | [English](README.en.md) | [전체 문서](../README.md)

- 한국어 이름: **말이음**
- 영어 이름: **SpeechBridge**
- 한국어 설명: **마비말장애 말하기 연습**
- 영어 설명: **Speech Practice for Adults with Dysarthria**
- 한국어 슬로건: **생활에 필요한 말, 내 속도로 연습해요.**
- 영어 슬로건: **Everyday words, at your own pace.**

## 적용 범위

앱 내부 제목과 시작 화면은 앱의 언어 설정에 맞춘다. iOS·Android·macOS 런처 이름은 기기의 언어에 따라 한국어 ‘말이음’, 기본 영어 ‘SpeechBridge’를 사용한다. 앱 내부 언어 선택은 OS 런처 이름까지 바꾸지는 않는다. 웹 설치 이름은 SpeechBridge이며 전체 소개 이름은 ‘말이음 · SpeechBridge’다. Windows·Linux 기본 창 이름은 SpeechBridge다.

iOS·Android·macOS·웹·Windows 아이콘과 Linux 창 아이콘, 시작 화면 아이콘, README와 홍보·사용자 문서를 변경했다. 패키지명·번들 ID·저장소 키는 유지한다. macOS 빌드 산출물 이름은 SpeechBridge.app으로 변경했다.

## 아이콘 원본과 재생성

[벡터 원본](../../assets/branding/app-icon.svg) · [미리보기](../../assets/branding/app-icon.png)

짙은 청록색 배경, 밝은 말풍선, 세 개의 둥근 소리 막대. 글자를 넣지 않아 작은 크기에서도 형태를 구별하기 쉽게 한다. 소리 막대는 점수나 향상 그래프가 아니다.

`tools/branding/generate_icons.cjs`를 sharp가 설치된 Node.js로 실행하면 플랫폼별 PNG가 생성된다. iOS는 불투명한 정사각형, macOS·기존 Android 아이콘은 둥근 형태, 웹 maskable 아이콘은 기호를 안전 영역 안으로 축소한다. Windows ICO는 같은 PNG에서 Pillow의 ICO 저장 기능으로 16·24·32·48·64·128·256px 크기를 포함해 내보냈다.

상표 등록·앱스토어 배포·이름 중복 확인은 이번 변경에 포함하지 않는다.

## 검증

Flutter 정적 검사 및 시작 화면·언어 설정 관련 테스트 2개 통과. macOS debug 빌드 성공 후 실행 파일 이름, 기존 번들 ID 유지, 한국어·영어 InfoPlist 리소스와 아이콘 포함을 확인했다. iOS·Android·Windows·Linux는 설정·자산을 변경했으며 해당 플랫폼 실기기 빌드/실행 검증은 수행하지 않았다.
