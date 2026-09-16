# Spec: 영어 버전 출시

## Overview

Speech Rehab을 한국어와 미국 영어를 지원하는 단일 앱으로 확장한다. 앱은 첫 설치 시 OS 언어를 따르고, 사용자가 설정에서 `시스템 설정`, `한국어`, `English (US)` 중 하나를 선택해 덮어쓸 수 있다. 선택한 언어는 화면 번역뿐 아니라 STT, TTS, 훈련 콘텐츠, AI 프롬프트, 발음 분석 모델에 동일하게 적용한다.

1차 영어판의 대상은 미국 영어를 사용하는 성인 후천성 마비말장애 환자와 보호자다. 앱은 치료나 진단을 대체하지 않는 반복 훈련 보조 도구로 유지한다.

## Goals

- 하나의 iOS·Android·macOS 앱과 사용자 기록 체계를 유지한다.
- OS 언어를 자동 적용하되 사용자가 앱 안에서 언제든 변경할 수 있게 한다.
- 분석 API가 요청의 언어에 따라 한국어 또는 영어 MFA 리소스를 선택하게 한다.
- 영어 자음·단어·짧은 문장·기능적 문장을 영어권 임상 맥락에 맞게 제공한다.
- 언어별 모델과 콘텐츠 버전을 기록해 서로 다른 언어의 점수와 기준선을 섞지 않는다.
- 영어권 스토어 심사, 개인정보 고지, 접근성 및 임상 문구를 출시 수준으로 준비한다.

## Scope

### In

- `ko-KR`, `en-US` 앱 현지화
- OS 언어 자동 감지와 앱 내 언어 선택
- 언어별 STT·TTS·AI 프롬프트
- 언어별 내장 콘텐츠 팩과 CDN 업데이트
- 언어 파라미터가 포함된 분석 API v1 확장
- 한국어·영어 MFA 모델 라우팅
- 영어 음소·자음군 훈련, 단어 및 짧은 문장 콘텐츠
- 언어별 기록, 기준선, 모델 버전 관리
- 미국 앱스토어·플레이스토어 출시 준비

### Out

- 1차 출시에서 영국·호주·인도 영어의 별도 채점 기준 제공
- 임상 진단, 장애 등급 판정 또는 치료 효과 보장
- 한국어와 영어가 섞인 한 발화의 코드 스위칭 분석
- MFA 정렬 결과만으로 발음 정확도 점수를 생성하는 기능
- 아동 조음장애 전용 콘텐츠와 평가 기준

## Product Decisions

| 항목 | 확정 방향 |
| --- | --- |
| 앱 구성 | 한국어판과 영어판을 하나의 앱으로 운영 |
| 영어 기준 | 1차 출시 `en-US` |
| 언어 기본값 | 신규 설치는 OS 언어, 미지원 OS 언어는 `en-US` |
| 기존 사용자 | 업데이트 직후 저장값이 없으면 기존 한국어 사용 경험 보존을 위해 `ko-KR`로 1회 마이그레이션 |
| 지원 언어 목록 | 내장 bootstrap catalog를 즉시 사용하고 원격 signed catalog로 활성화·비활성화·순서·팩 버전을 갱신 |
| 수동 선택 | 설정에서 `시스템 설정`과 현재 catalog가 허용한 호환 언어를 제공 |
| API 선택 | 모든 분석 요청에 BCP 47 형식 `language` 전달 |
| 모델 선택 | 서버가 `language`별 MFA dictionary·acoustic model·phone map 선택 |
| 점수 정책 | 언어·모델 revision별 기준선을 분리하고 MFA 정렬만으로 점수를 만들지 않음 |
| UI 번역 | 다운로드 가능한 runtime string pack을 우선 사용하고 앱에 포함된 ARB를 bootstrap·비상 fallback으로 유지 |
| 훈련 리소스 | 필수 core pack과 선택 media pack을 분리하고 설치 완료된 버전만 원자적으로 활성화 |
| 원격 언어 추가 | catalog가 앱 바이너리의 locale·폰트·TTS·STT·분석 capability와 호환될 때만 노출 |

## Language Resolution

언어 결정 우선순위는 다음과 같다.

```text
사용자가 저장한 명시적 언어
→ 없으면 OS locale
→ 정확한 locale 일치
→ language code 일치
→ 미지원 언어는 en-US
```

설정 값은 다음처럼 저장한다.

```text
languagePreference = system | <BCP-47 locale>
resolvedLanguage = <catalog와 client capability가 모두 허용한 BCP-47 locale>
```

`system` 선택 중 OS 언어가 변경되면 앱 재개 또는 재시작 시 다시 해석한다. 명시적 locale을 선택한 경우 OS 변경은 앱 언어에 영향을 주지 않는다. 저장된 locale이 catalog에서 중단되거나 현재 앱 버전과 호환되지 않으면 설치된 fallback locale로 전환하고 사용자에게 사유를 알린다.

Flutter에서는 `flutter_localizations`, `intl`, ARB 파일을 사용한다.

```text
lib/l10n/app_ko.arb
lib/l10n/app_en.arb
lib/l10n/l10n.yaml
```

화면 코드에 직접 들어간 한국어 문자열은 안정적인 메시지 키로 옮긴다. 운동명, 콘텐츠 제목, 오류 문구, 안전 고지, 접근성 레이블, 알림 문구도 번역 대상에 포함한다. Flutter의 생성형 ARB는 bootstrap locale과 framework fallback을 담당하고, 제품 화면의 변경 가능한 문구는 runtime string repository가 제공한다. 원격 catalog는 바이너리가 선언한 `clientSupportedLocales` 범위 안에서 언어를 활성화하므로 native 권한 문구, font shaping, Flutter framework locale처럼 앱 재빌드가 필요한 항목을 우회하지 않는다.

## Settings UX

설정에 `Language / 언어`와 `다운로드 리소스` 메뉴를 둔다. 목록은 하드코딩하지 않고 bootstrap 또는 원격 catalog에서 읽는다.

```text
Language / 언어
├── System Default / 시스템 설정
├── 설치됨: 한국어
├── 다운로드 필요: English (US) · 48 MB
└── 업데이트 가능: <catalog가 허용한 언어>
```

- 현재 적용 중인 실제 언어를 `System Default · English (US)`처럼 함께 표시한다.
- 변경 즉시 앱 전체를 다시 그리되 진행 중 녹음이나 분석 작업이 있으면 완료 또는 취소 후 적용한다.
- 언어 변경 전 “화면, 음성 안내, 연습 콘텐츠와 발음 분석 언어가 함께 변경됩니다”라고 안내한다.
- 기존 기록은 삭제하지 않고 기록마다 언어 배지를 표시한다.
- 연습 중인 언어와 콘텐츠 언어가 다르면 분석 요청을 막고 올바른 콘텐츠 팩을 다시 불러온다.
- 미설치 언어를 선택하면 필수 팩의 용량과 네트워크 조건을 보여주고 `다운로드 후 전환`한다. 다운로드 도중에는 현재 언어를 유지한다.
- 각 언어는 `사용 가능`, `다운로드 필요`, `다운로드 중`, `설치됨`, `업데이트 가능`, `현재 앱과 호환되지 않음`, `일시 중단` 상태를 가진다.
- 리소스 화면에서 자동 업데이트, Wi-Fi에서만 다운로드, 일시정지·재개·재시도, 언어별 사용 용량, 선택 팩 삭제를 제공한다.

## Shared Language Context

앱에는 단일 `AppLanguageController`를 둔다. 각 기능이 OS locale을 직접 읽거나 `ko-KR`을 하드코딩하지 않게 한다.

```text
AppLanguageController
├── LanguageRegistry (catalog와 client capability 교집합)
├── RuntimeLocalizationRepository
├── STT locale
├── TTS voice locale
├── content pack locale
├── AI prompt language
├── pronunciation API language
└── history metadata
```

`AppLanguageController`는 locale 선택만 담당하고 다운로드·검증·활성화는 `ResourcePackManager`에 위임한다. 언어 전환은 필수 UI string pack과 core content pack이 설치되고 검증된 뒤에만 commit한다.

언어별 기능 계약:

| 기능 | ko-KR | en-US |
| --- | --- | --- |
| STT | `ko-KR` | `en-US` |
| TTS | `ko-KR` | `en-US` |
| 콘텐츠 | `ko_consonant_core` | `en_us_consonant_core` |
| MFA dictionary | `korean_mfa` | `english_us_mfa` |
| MFA acoustic | `korean_mfa` | `english_mfa` |
| AI 프롬프트 | 한국어 피드백 | 미국 영어 피드백 |

플랫폼에서 선택한 STT 또는 TTS locale을 지원하지 않으면 해당 기능만 `unavailable`로 표시하고 다른 시각 훈련과 녹음 기능은 계속 제공한다. 자동으로 다른 언어 음성을 사용하는 fallback은 허용하지 않는다.

## Analysis API Contract

기존 `POST /v1/analysis/jobs` multipart form에 필수 `language`를 추가한다.

```text
audio              file, required
text               string, required
language           BCP 47 string, required: ko-KR | en-US
target_phone        language-specific phone id, required
position            onset | medial | coda, required
target_occurrence   integer, optional, default 0
content_version     string, required
baseline_score      number, optional
```

영어는 같은 음소가 한 단어·문장에 여러 번 등장하고 자음군이 많으므로 `target_occurrence`를 추가한다. 기존 한국어 클라이언트는 `position=onset|coda`, `target_occurrence=0`을 사용한다. `medial`은 영어 단어 내부 자음 훈련에 사용한다.

성공 응답에는 요청에 실제 적용된 언어와 모델을 되돌려준다.

```json
{
  "jobId": "...",
  "status": "completed",
  "language": "en-US",
  "modelVersion": "mfa-english-v3.1.0",
  "contentVersion": "en-US-1.0.0",
  "overallPracticeScore": null,
  "phonemes": [],
  "disclaimer": "Automated practice feedback; not a clinical diagnosis."
}
```

검증 규칙:

- 지원하지 않는 언어는 `422 unsupported_language`로 거절한다.
- 콘텐츠 팩 언어와 요청 언어가 다르면 `409 language_content_mismatch`로 거절한다.
- `target_phone`이 해당 언어 phone inventory에 없으면 `422 unsupported_phone`으로 거절한다.
- 서버는 `Accept-Language`나 서버 OS locale로 분석 모델을 추론하지 않는다. 모델 선택은 요청의 `language`만 사용한다.
- 작업 생성 시 해석한 `language`, model revision, dictionary revision을 job에 고정해 처리 중 설정 변경의 영향을 받지 않게 한다.
- 에러 코드는 언어 독립적인 식별자로 반환하고, 앱에서 현지화된 문구로 변환한다.

## Server Architecture

단일 전역 MFA 백엔드 대신 언어별 registry를 둔다.

```text
Analysis request(language)
→ LanguagePolicy validation
→ BackendRegistry.resolve(language)
→ ko-KR: KoreanMfaBackend
→ en-US: EnglishMfaBackend
→ normalized result with language/model metadata
```

권장 환경 변수:

```text
SUPPORTED_ANALYSIS_LANGUAGES=ko-KR,en-US
MFA_KO_KR_DICTIONARY=korean_mfa
MFA_KO_KR_ACOUSTIC_MODEL=korean_mfa
MFA_EN_US_DICTIONARY=english_us_mfa
MFA_EN_US_ACOUSTIC_MODEL=english_mfa
```

`GET /ready`는 전체 상태와 언어별 상태를 반환한다.

```json
{
  "ready": true,
  "languages": {
    "ko-KR": {"ready": true, "modelVersion": "mfa-korean-v3.0.0"},
    "en-US": {"ready": true, "modelVersion": "mfa-english-v3.1.0"}
  }
}
```

한 언어 모델만 실패하면 서버 전체를 내리지 않고 해당 언어 분석만 unavailable 처리한다. 각 요청은 별도 MFA temporary directory를 유지한다.

## English Phoneme and Content Design

영어 콘텐츠는 한국어 콘텐츠를 번역하지 않고 새로 제작한다.

### Target inventory

- 파열음: /p, b, t, d, k, g/
- 마찰음: /f, v, θ, ð, s, z, ʃ, ʒ, h/
- 파찰음: /tʃ, dʒ/
- 비음: /m, n, ŋ/
- 접근음·유음: /w, j, r, l/
- 2차 범위: 자음군, 모음 대비, 강세, 리듬, 말속도

각 목표는 철자와 음소를 분리한다. 예를 들어 `th`는 /θ/와 /ð/를 별도 목표로 관리하고, 같은 철자라도 문맥에 따라 phone이 달라질 수 있음을 콘텐츠 데이터에 명시한다.

### Content pack

```text
assets/pronunciation/content/en_us_consonant_core.json
locale: en-US
version: 1.0.0
targets
words
minimalPairs
shortSentences
functionalSentences
ttsMetadata
clinicalReview
```

목표 음소마다 권장 최소 콘텐츠:

- 단어 위치별 단어 20개: initial, medial, final
- 혼동쌍 10쌍
- 4~8단어의 짧은 문장 20개
- 병원·가정·전화·보호자 상황의 기능적 문장 10개
- 느린 속도와 정상 속도 TTS 메타데이터

문장은 성인에게 자연스럽고 유아용으로 보이지 않게 작성한다. 미국 영어 원어민 언어치료사(SLP)가 음소 위치, 어휘 난이도, 기능성, 문화적 적합성을 검수한다.

## Audio, STT and TTS

- STT는 선택된 `resolvedLanguage`로 인스턴스를 생성한다.
- iOS의 현재 `SFSpeechRecognizer(locale: ko_KR)` 고정값과 native TTS의 `ko-KR` 고정값을 제거한다.
- TTS는 언어별 설치 음성 목록을 확인하고 사용 가능한 voice id를 저장한다.
- 영어 훈련 기본 TTS는 `en-US`, 속도는 치료사가 검수한 느린 속도와 정상 속도를 제공한다.
- TTS 오디오는 정답 음향 분석의 기준 신호로 사용하지 않고 듣기·모방 안내로만 사용한다.
- STT 불일치와 조음 오류를 동일하게 취급하지 않는다. STT 결과는 보조 정보이며 음소 분석 결과와 분리한다.

Apple Speech는 recognizer 생성 시 locale을 지정하고 지원 locale 여부와 일시적인 서비스 가용성을 따로 확인해야 하므로, 설정 목록과 실제 기기 기능 점검을 구분한다.

## Clinical and Scoring Policy

영어 MFA는 transcript와 음성의 단어·음소 시간 정렬에 사용한다. MFA 결과 자체에는 발음 정확도 점수가 없으므로 `practiceScore`와 `gop`는 영어에서도 nullable을 유지한다.

점수 기능을 추가할 때는 다음 조건을 충족해야 한다.

- 성인 후천성 마비말장애 영어 음성 데이터 사용
- 미국 영어 phone별 임상가 평정과 모델 출력의 상관·일치도 평가
- 중증도, 성별, 연령, 억양, 기기 및 소음 환경별 성능 보고
- 언어와 모델 revision별 독립 기준선
- 사용자 간 순위가 아닌 개인 내 변화 중심 표현
- 낮은 신뢰도, OOV, 정렬 실패 시 점수 비노출

비원어민 영어와 지역 억양을 오류로 단정하지 않는다. 초기 제품 문구에는 “accent 평가가 아닌 목표 발화 반복 훈련”임을 명시한다.

## Data and History Migration

기록 모델에 다음 필드를 추가한다.

```text
language
contentLocale
contentVersion
analysisModelVersion
dictionaryVersion
ttsVoiceId (optional)
```

- 기존 기록은 `language=ko-KR`로 마이그레이션한다.
- 기준선과 이전 최고점은 `targetId + language + modelVersion` 단위로 계산한다.
- 언어를 바꿔도 기록은 보존하되 기본 화면은 현재 언어 기록만 보여 준다.
- 통합 기록 화면에서 언어 필터를 제공한다.
- 한국어와 영어의 target id가 충돌하지 않도록 `ko-KR:onset:k`, `en-US:initial:θ`와 같은 namespace를 사용한다.

## Store and Compliance Preparation

- 앱 이름, 부제, 설명, 키워드, 스크린샷, 미리보기 영상, 개인정보 처리방침을 영어로 준비한다.
- 마이크, 음성 인식, 카메라 권한 설명을 영어로 현지화한다.
- 녹음이 서버로 전송되는 시점, 목적, 보관 기간, 삭제 방법을 앱 안에서 명확히 고지한다.
- 분석 서버 전송 전 명시적 동의를 받고 원격 분석을 사용하지 않는 기본 훈련 경로를 유지한다.
- 건강·의료 진단으로 오해할 수 있는 표현과 치료 효과 보장 표현을 피한다.
- 앱 내 안전 고지와 스토어 설명의 문구를 일치시킨다.
- 미국 영어 VoiceOver/TalkBack, 동적 글자 크기, 색 대비, 큰 터치 영역을 검증한다.
- 영어 지원 이메일, FAQ, 분석 실패 및 데이터 삭제 절차를 준비한다.

## Failure Modes

| 상황 | 처리 |
| --- | --- |
| OS 언어 미지원 | `en-US` 적용, 설정에서 지원 언어 안내 |
| 저장된 언어 값 손상 | `system`으로 복구하고 진단 로그 기록 |
| STT locale 미지원 | STT만 비활성화하고 녹음·재생 훈련 유지 |
| TTS voice 미설치 | 설치 안내 또는 다른 동일 locale voice 선택 |
| 영어 MFA만 미준비 | 영어 분석 unavailable, 한국어 분석은 정상 유지 |
| 콘텐츠와 분석 언어 불일치 | 분석 전 차단하고 현재 언어 팩 재로딩 |
| 언어 변경 중 분석 실행 | 기존 job은 생성 시 언어로 완료, 새 화면에는 언어 배지 표시 |
| 사전에 없는 영어 단어 | OOV 안내 후 분석 생략 또는 승인된 보조 사전 사용 |
| 억양·장애로 정렬 신뢰도 낮음 | 점수 비노출, 다시 녹음 및 전문가 상담 안내 |
| CDN 실패 | 해당 언어의 내장 core pack 사용 |

## Test Strategy

### Flutter

- OS `ko`, `en`, 미지원 locale별 초기 해석 테스트
- 시스템 언어와 사용자 선택 우선순위 테스트
- 앱 재시작 후 선택 언어 유지 테스트
- 모든 ARB 키의 한국어·영어 완전성 검사
- locale 변경 시 STT·TTS·콘텐츠·API language가 함께 바뀌는 통합 테스트
- 기존 설치를 `ko-KR`로 마이그레이션하는 테스트
- 기록과 기준선이 언어별로 분리되는 테스트
- 주요 화면의 영어 overflow, 큰 글자, 접근성 semantics 골든 테스트

### Server

- `language` 누락·미지원 값 422 테스트
- `ko-KR`, `en-US` backend routing 테스트
- 언어별 phone inventory와 TextGrid 파싱 테스트
- 콘텐츠 언어 불일치 409 테스트
- `/ready` 언어별 준비 상태 테스트
- 동시에 두 언어를 분석할 때 모델과 임시 파일이 섞이지 않는 테스트
- 응답의 language·modelVersion·disclaimer 계약 테스트
- OOV, timeout, 모델 미설치, 낮은 신호 품질 테스트

### Release QA

- iOS·Android 실제 기기에서 `ko-KR`, `en-US` STT/TTS 확인
- 앱 실행 중 OS 언어 변경과 설정 덮어쓰기 확인
- 미국 영어 원어민 및 성인 마비말장애 사용자 대상 사용성 평가
- SLP가 영어 콘텐츠와 안전 문구를 승인하는 release gate
- 영어 모델 실음성 alignment 샘플의 수동 TextGrid 대조

## Delivery Plan

### Phase 0 — 계약 고정, 1주

- 지원 locale과 언어 해석 정책 확정
- API `language` 및 응답 계약 확정
- 기존 기록·설정 마이그레이션 설계
- 영어 콘텐츠 작성·검수 가이드 확정

완료 조건: 앱·서버·콘텐츠가 같은 locale 식별자를 사용하고 계약 테스트 초안이 승인됨.

### Phase 1 — 앱 국제화 기반, 2주

- ARB 기반 UI 현지화
- `AppLanguageController`와 설정 화면
- STT·TTS 언어 고정값 제거
- 기록 모델 locale 확장

완료 조건: OS 언어와 수동 설정으로 주요 화면·STT·TTS가 일관되게 전환됨.

### Phase 2 — 영어 콘텐츠와 훈련 UX, 3~4주

- 영어 phone inventory와 콘텐츠 팩 제작
- 영어 자음 위치·혼동쌍·짧은 문장 UI
- 영어 기능적 문장과 TTS 검수
- SLP 1차 콘텐츠 검수

완료 조건: 모든 1차 목표 phone에 최소 콘텐츠가 있고 임상 검수 상태가 기록됨.

### Phase 3 — 다국어 분석 API, 2주

- 서버 backend registry와 language validation
- 영어 MFA 모델·사전 설치 자동화
- 영어 phone mapping, occurrence 선택, OOV 처리
- 언어별 ready·관측성·테스트

완료 조건: 한국어와 영어 실음성 정렬이 동시에 동작하고 잘못된 언어 조합을 안전하게 차단함.

### Phase 4 — 검증과 스토어 준비, 3~4주

- 원어민·SLP·대상 사용자 QA
- 개인정보·안전·지원 문서 영어화
- 스토어 메타데이터와 스크린샷 제작
- TestFlight·Play closed testing과 장애 수정

완료 조건: 치명적 결함 0개, locale 관련 주요 결함 0개, SLP·개인정보·스토어 체크리스트 승인.

예상 MVP 기간은 병렬 작업 기준 9~12주다. 영어 임상 점수 모델 개발과 검증은 별도 후속 트랙으로 분리한다.

## Implementation Status

2026-08-26 기준으로 다국어 실행 기반을 구현했다.

- Flutter ARB 기반 `ko`, `en` 현지화 코드 생성과 `supportedLocales` 연결
- 신규 설치의 OS 언어 해석, 미지원 언어의 `en-US` fallback, 기존 한국어 설치 마이그레이션
- 설정의 `시스템 설정`, `한국어`, `English (US)` 선택과 영구 저장
- 선택 언어를 STT, TTS, AI 프롬프트에 전달하고 iOS native STT/TTS의 한국어 고정값 제거
- 언어별 내장 콘텐츠 및 다운로드 저장 경로 분리
- 영어 initial·medial·final 훈련을 확인할 수 있는 `en-US` seed 콘텐츠 팩 내장
- 분석 API의 필수 `language`, 선택 `target_occurrence`, 영어 `medial` 위치 계약
- `ko-KR`, `en-US`별 MFA backend registry, readiness, 모델·사전 설정
- 영어 MFA phone map과 `english_us_mfa`/`english_mfa` 설치 자동화
- 분석 결과와 기준선의 언어 분리 및 언어별 면책·오류 문구
- OS 해석, 기존 설치 마이그레이션, 설정 저장, 콘텐츠 구조, API routing, MFA mapping 테스트

현재 내장 영어 팩은 제품 흐름과 모델 계약을 검증하기 위한 seed 범위다. 전체 phone inventory별 목표 수량, 모든 화면 문자열의 영어 ARB 이전, 미국 SLP 검수, 대상 사용자 평가, 스토어·개인정보 문서는 출시 gate로 남아 있다. 이 항목들은 자동 생성이나 단순 번역으로 완료 처리하지 않는다.

현재 `ConsonantContentRepository`는 언어별 JSON manifest 다운로드, SHA-256 검증, 임시 파일에서 `current.json`으로의 원자적 교체를 지원한다. 그러나 자음 콘텐츠 한 종류에 한정되어 있고 catalog 서명, pack dependency, 이전 버전 rollback, 저장 공간 정책, UI string pack, 대형 미디어의 background resume를 제공하지 않는다. 아래 리소스 팩 플랫폼은 이 구현을 일반화하는 후속 설계다.

## Remote Resource Pack Platform

### 목표와 적용 경계

게임의 추가 데이터 다운로드 방식처럼 작은 앱 본체와 변경 가능한 리소스를 분리한다.

- 앱에 최소 `ko-KR`, `en-US` bootstrap catalog·UI 문구·핵심 훈련 데이터를 포함해 첫 실행과 오프라인 사용을 보장한다.
- CDN에서 지원 언어 목록, UI 문구, 자음·문장·게임 콘텐츠, 이미지·오디오·영상을 독립적으로 갱신한다.
- catalog와 pack은 데이터만 포함한다. Dart/native 실행 코드, 동적 라이브러리, 스크립트, 권한 선언은 다운로드하지 않는다.
- 서버가 임의의 언어를 표시하지 않게 앱의 locale·폰트·plural rule·STT·TTS·분석 capability와 교집합을 구한다.
- 개인정보·동의·치료 안전 고지의 의미가 바뀌는 갱신은 일반 UI 문구와 분리해 법무/임상 revision과 재동의 여부를 기록한다.

원격 언어 추가는 두 단계로 정의한다.

1. `catalog enabled`: 운영자가 특정 언어와 pack version을 원격으로 활성화한다.
2. `client compatible`: 설치된 앱이 그 언어에 필요한 UI 렌더링과 기능 capability를 선언한다.

두 조건이 모두 참이어야 설정에 정상 언어로 노출한다. 이 구조는 문구와 콘텐츠의 앱 업데이트 없는 변경을 허용하지만, 새 MFA 모델 연동이나 native 권한 번역처럼 바이너리 변경이 필요한 기능을 잘못 약속하지 않는다.

### 리소스 분류

| 종류 | 예시 | 설치 정책 | 갱신 특성 |
| --- | --- | --- | --- |
| bootstrap catalog | 언어 목록 fallback, 공개키, schema | 앱 내장 필수 | 앱 업데이트 시 교체 |
| UI string pack | 메뉴, 오류, 접근성 label, 단위·날짜 규칙 | 선택 언어 필수 | 작고 자주 갱신 |
| core content pack | 자음, 모음 결합 단어, 짧은 문장, 임상 metadata | 훈련 언어 필수 | locale·기능별 갱신 |
| game pack | 스테이지, 보상 규칙용 데이터, 문제 목록 | 기능 진입 시 필수/선택 | 실행 코드는 앱에 유지 |
| media pack | 가이드 영상, TTS 검수 음원, 이미지, 애니메이션 | 선택 다운로드 | 크므로 background/resume |
| model pack | 온디바이스 음성/LLM 모델 | 별도 선택 다운로드 | 대용량·기기 요구사항 검증 |

`requiredPacks`는 언어 전환 전에 설치하고 `optionalPacks`는 해당 훈련에 들어갈 때 받는다. 현재 약 1.35 GB인 Gemma 모델과 영상은 UI string/core content와 같은 다운로드 단위로 묶지 않는다.

### Catalog와 manifest 계약

루트 catalog는 작게 유지하고 cache 가능하게 한다.

```json
{
  "schemaVersion": 1,
  "catalogVersion": "2026.09.0",
  "generatedAt": "2026-09-01T00:00:00Z",
  "minClientVersion": "1.4.0",
  "keyId": "catalog-2026-01",
  "languages": [
    {
      "locale": "en-US",
      "nativeName": "English (US)",
      "fallbackLocale": "en",
      "enabled": true,
      "minAppVersion": "1.4.0",
      "capabilities": {
        "ui": true,
        "content": true,
        "tts": true,
        "stt": true,
        "analysis": true
      },
      "requiredPacks": ["ui.en-US", "consonant-core.en-US"],
      "optionalPacks": ["guided-video.en-US"]
    }
  ],
  "signature": "base64-ed25519-signature"
}
```

각 pack manifest는 불변 version URL을 가리킨다.

```json
{
  "schemaVersion": 1,
  "id": "ui.en-US",
  "type": "ui_strings",
  "locale": "en-US",
  "version": "2026.09.2",
  "minAppVersion": "1.4.0",
  "url": "https://cdn.example.com/packs/ui/en-US/2026.09.2.zip",
  "sizeBytes": 48123,
  "sha256": "...",
  "compression": "zip",
  "dependencies": [],
  "files": [{"path": "strings.json", "sizeBytes": 92031, "sha256": "..."}],
  "keyId": "pack-2026-01",
  "signature": "base64-ed25519-signature"
}
```

- catalog와 manifest는 앱에 내장한 Ed25519 공개키로 서명을 검증하고 pack과 내부 파일은 SHA-256으로 검증한다.
- pack URL은 version별 불변 경로를 사용한다. 새 파일을 같은 URL에 덮어쓰지 않는다.
- `minAppVersion`, 지원 schema, dependency가 맞지 않으면 다운로드하지 않는다.
- zip path traversal, symlink, 과도한 압축 해제 크기·파일 수를 차단한다.
- pack에는 HTML이나 실행 가능한 내용을 허용하지 않고 JSON과 허용된 media MIME만 수용한다.

### 앱 내부 구조

```text
Presentation
├── LanguageSettingsScreen
├── ResourceCenterScreen
└── DownloadRequiredSheet
        ↓
Riverpod Controllers
├── AppLanguageController
└── ResourcePackController
        ↓
Domain Services
├── LanguageRegistry
├── RuntimeLocalizationRepository
├── ResourcePackManager
└── ResourceDownloadCoordinator
        ↓
Data
├── ResourceCatalogRepository
├── ResourceIndexStore
├── BundledResourceSource
├── CdnResourceSource
└── SignatureVerifier
```

책임은 다음처럼 나눈다.

- `ResourceCatalogRepository`: 내장 catalog 즉시 로드, 캐시 catalog 검증, CDN 조건부 요청과 fallback.
- `LanguageRegistry`: catalog와 `ClientCapabilities`의 교집합을 계산하고 설정에 표시할 언어·기능 상태를 제공.
- `ResourcePackManager`: dependency 계획, 여유 공간 확인, staging, 검증, 설치, 활성 version 교체, rollback, 삭제.
- `ResourceDownloadCoordinator`: 작은 catalog·문자열은 Dio로 받고 큰 media/model은 직접 의존성으로 등록한 background downloader 계층에서 pause/resume과 OS background 작업 처리.
- `ResourceIndexStore`: 설치/활성/이전 version, 크기, 마지막 사용 시각, pinned session을 SQLite 또는 원자적 index 파일에 저장.
- `RuntimeLocalizationRepository`: 문자열 lookup, placeholder/plural 검증, fallback, pack 변경 알림.
- 기존 `ConsonantContentRepository`: 네트워크와 설치 책임을 제거하고 활성 content pack을 typed model로 decode하는 adapter로 축소.

현재 `AppLanguagePreference` enum은 `system` 또는 임의 BCP-47 문자열을 담는 value object로 교체한다. 값은 `LanguageRegistry`로 검증한다. Flutter 생성형 `AppLocalizations`는 bootstrap fallback으로 유지하되 변경 가능한 화면은 `context.tr('training.start', args)` 같은 runtime lookup으로 단계적으로 이전한다.

문자열 fallback 순서는 아래로 고정한다.

```text
선택 locale의 검증된 다운로드 pack
→ 선택 locale의 내장 pack
→ catalog가 지정한 fallback locale
→ 내장 en-US
→ 개발 빌드는 [missing:key], 릴리스는 안전한 공통 문구
```

placeholder 이름과 타입, plural category를 schema에 선언하고 빌드·배포 시 모든 locale을 기준 locale과 비교한다. 제한된 Markdown만 별도 renderer로 허용하며 서버 문자열을 HTML로 직접 렌더링하지 않는다.

### 저장 구조와 원자적 활성화

```text
Application Support/resource_packs/
├── catalog/
│   ├── active.json
│   └── previous.json
├── locales/<locale>/
│   ├── ui_strings/<version>/
│   ├── content/<pack-id>/<version>/
│   └── media/<pack-id>/<version>/
├── shared/<pack-id>/<version>/
├── staging/<download-task-id>/
└── state/resource_index.json
```

다운로드는 `계획 → 공간 확보 → staging 다운로드 → 서명/해시 검증 → 안전한 압축 해제 → schema 검증 → active pointer 교체` 순서다. 어느 단계든 실패하면 현재 active version을 유지한다. 성공 후에도 직전 known-good version 하나를 보존해 시작 오류나 parsing 오류 시 자동 rollback한다.

저장 공간 정리는 선택 media/model의 LRU부터 수행한다. 현재 언어의 required pack, 진행 중 세션이 pin한 version, bootstrap 리소스는 자동 삭제하지 않는다. 기록에는 `locale`, `contentPackId`, `contentVersion`, `analysisModelRevision`을 보존해 과거 결과의 재현성을 유지한다.

### 시작·언어 전환·훈련 진입 흐름

```text
앱 시작
→ 내장/캐시 catalog와 active pack으로 즉시 화면 표시
→ background에서 catalog 갱신
→ 호환 가능한 업데이트 계산
→ 정책에 따라 자동 다운로드 또는 사용자 알림
```

언어 전환은 `언어 선택 → required pack과 용량 표시 → 다운로드/검증 → 녹음·분석 세션 종료 확인 → locale과 active pack을 한 transaction으로 전환`한다. 실패하면 기존 언어를 그대로 유지한다.

훈련이나 게임 진입 시 optional pack이 없으면 다운로드 sheet를 표시한다. 필수 데이터만으로 가능한 기능은 축소 모드로 계속 제공하고, 미디어가 반드시 필요한 기능만 진입을 막는다. 분석 backend가 없는 언어는 `analysis=false`로 표시하며 읽기·녹음·재생 훈련 자체는 계속 허용한다.

### CDN 배포와 운영

```text
/catalog/v1/stable/catalog.json
/catalog/v1/canary/catalog.json
/packs/ui_strings/en-US/2026.09.2.zip
/packs/content/consonant/en-US/2026.09.0.zip
/packs/media/guided_training/en-US/2026.09.4.zip
```

배포 pipeline은 `pack 생성 → schema·placeholder·MIME·임상 metadata 검사 → 테스트 → 서명 → 불변 경로 업로드 → canary catalog 게시 → 지표 확인 → stable catalog를 마지막에 게시`한다. rollback은 이전 catalog version을 다시 가리키며 손상되거나 철회된 pack ID/version을 deny list에 넣는다. 앱은 ETag/If-None-Match와 지수 backoff를 사용하고 CDN 장애 때 캐시 catalog로 동작한다.

분석 서버의 `/v1/capabilities/languages` 결과와 catalog를 배포 전에 비교한다. `analysis=true`인 언어가 서버에 없거나 model revision이 준비되지 않았으면 게시를 실패시킨다.

### 수정 대상

| 현재 위치 | 변경 내용 |
| --- | --- |
| `lib/services/app_language_service.dart` | 고정 enum을 BCP-47 preference와 catalog 기반 `LanguageRegistry`로 교체 |
| `lib/features/settings/view/language_settings_screen.dart` | 하드코딩 언어를 동적 상태 목록, 다운로드 후 전환 UX로 변경 |
| `lib/l10n/` | ARB를 bootstrap fallback으로 유지하고 runtime string schema·내장 JSON 추가 |
| `lib/main.dart` | 개별 자음 콘텐츠 refresh 대신 중앙 resource bootstrap/background refresh 시작 |
| `lib/features/consonant_training/data/consonant_content_repository.dart` | Dio·설치 로직을 `ResourcePackManager`로 이동하고 typed decoder adapter로 변경 |
| `pubspec.yaml` | 내장 bootstrap pack 등록, 대형 리소스용 background downloader를 필요 시 직접 의존성으로 승격 |
| `tools/pronunciation_content/` | 범용 pack builder, manifest 생성, 서명, placeholder/content lint 도구로 확장 |
| `server/` | 언어 capability endpoint, catalog 게시 전 backend readiness 검증 도구 추가 |
| 설정 메뉴 | `다운로드 리소스` 화면, 자동 업데이트·Wi-Fi·저장 공간 정책 추가 |

### 장애 처리와 보안

- catalog 네트워크 실패·서명 오류: 검증된 캐시, 없으면 내장 catalog 사용.
- pack checksum/schema 오류: staging 삭제, 현재 version 유지, 재시도 가능 상태 표시.
- 다운로드 중 앱 종료: 검증 전 파일은 활성화하지 않고 지원 가능한 대형 다운로드만 resume.
- 디스크 부족: 필요한 용량과 삭제 후보를 보여주고 사용자 확인 없이 required pack을 지우지 않음.
- catalog에서 선택 언어 중단: 기존 설치분을 즉시 파괴하지 않고 사유·fallback을 안내; 보안 철회만 강제 비활성화.
- 동시 다운로드와 언어 전환: locale별 mutex와 install transaction으로 중복 활성화를 방지.
- catalog downgrade/replay: 서명 외에도 최소 허용 catalog version과 발행 시각 정책을 적용.
- 로그에는 URL·version·오류 code만 남기고 녹음·사용자 문장·식별자는 리소스 telemetry에 포함하지 않음.

### 테스트 전략과 완료 기준

단위 테스트:

- catalog/manifest 서명, schema, app version, capability 교집합
- dependency 정렬·순환 탐지, checksum, zip traversal·압축 폭탄 차단
- staging 실패와 이전 version rollback, index 손상 복구
- locale fallback, 누락 key, placeholder 타입, plural category
- 기존 `system|ko-KR|en-US` preference migration

통합·위젯 테스트:

- 미설치 언어의 다운로드 후 전환과 재시작 복원
- CDN offline, 손상 pack, 중단·재개, 디스크 부족, 동시 요청
- Resource Center의 진행률·재시도·삭제 제한
- 게임/훈련 진입 시 required·optional pack gate와 축소 모드
- `analysis=false`, TTS/STT unavailable 상태에서도 비음성 훈련 유지

출시 완료 기준:

- 앱을 비행기 모드에서 처음 실행해 내장 언어로 훈련 가능.
- catalog 또는 pack이 손상되어도 기존 화면과 활성 훈련 데이터가 유지됨.
- 다운로드 중 강제 종료 후 partial pack이 활성화되지 않음.
- 모든 UI key와 placeholder가 기준 locale과 일치하고 누락 key가 0개임.
- 원격에서 언어 순서·활성 상태·UI 문구·콘텐츠 version을 바꿔 앱 재배포 없이 반영됨.
- 앱 capability가 없는 제3언어는 catalog에 있어도 정상 지원 언어로 노출되지 않음.

### 단계별 도입

1. 범용 catalog, index, pack manager와 현재 자음 JSON의 adapter 전환.
2. runtime UI string pack, 동적 Language Registry, 다운로드 후 언어 전환.
3. Resource Center와 게임·영상·음원 optional pack, background/resume, 용량 정책.
4. Ed25519 서명 pipeline, immutable CDN, canary/stable channel, rollback 운영 도구.
5. 제3언어를 capability 검증 후 추가하고 분석 서버 readiness와 배포 gate를 자동화.

첫 구현에서는 `ko-KR`, `en-US`만 catalog에 넣어 원격 활성화·순서·문구·팩 갱신을 검증한다. 제3언어는 runtime UI 번역만 준비됐다는 이유로 출시하지 않고 TTS, STT, 분석, 임상 콘텐츠 capability를 각각 명시적으로 승인한다.

## Launch Metrics

- 언어 해석·전환 오류율
- 영어 콘텐츠 팩 다운로드 및 fallback 성공률
- 언어별 STT·TTS 가용률
- 언어별 MFA alignment 성공률과 OOV 비율
- 첫 훈련 완료율, 7일 재방문율, 반복 훈련 횟수
- 분석 unavailable 이후 훈련 이탈률
- 접근성 기능 사용률과 지원 문의 유형

정확도 점수를 제공하기 전에는 alignment 성공률을 발음 개선 지표로 사용하지 않는다.

## Tradeoffs

- 단일 앱은 코드와 기록을 공유할 수 있지만 locale 경계가 불명확하면 언어가 섞인다. 따라서 모든 콘텐츠와 분석 기록에 locale을 필수 메타데이터로 둔다.
- OS 자동 선택은 진입이 쉽지만 기존 사용자의 언어가 바뀔 수 있다. 신규 설치와 기존 설치의 초기 정책을 분리한다.
- 영어 MFA를 빠르게 적용할 수 있지만 임상 점수로 사용할 수 없다. 1차 출시는 정렬·구간 피드백에 한정한다.
- 영어 전체 변종을 한 번에 지원하면 콘텐츠와 검증 범위가 커진다. `en-US`를 먼저 검증하고 다른 변종은 별도 locale과 모델 계약으로 추가한다.

## Future Extensions

- `en-GB`, `en-AU` 콘텐츠와 dictionary 추가
- 비원어민 영어 훈련 모드
- 영어 음소 CTC posterior와 임상 보정 GoP
- 언어별 치료사 포털 및 리포트
- 사용자 선호 TTS voice와 속도 프로필
- 다국어 CDN manifest와 점진적 콘텐츠 배포

## Open Questions

- 영어판 제품명과 스토어 브랜드를 `Speech Rehab`으로 유지할지
- 녹음 원본과 TextGrid를 서버에 보관할지, 분석 직후 삭제할지
- 미국 내 베타 테스트를 함께할 SLP와 대상 사용자 모집 경로
- 영어 임상 점수 모델을 자체 개발할지 외부 검증 모델과 연동할지

## References

- Flutter internationalization: https://docs.flutter.dev/ui/internationalization
- Apple Speech locale: https://developer.apple.com/documentation/speech/sfspeechrecognizer
- English MFA acoustic models: https://mfa-models.readthedocs.io/en/latest/acoustic/English/index.html
- English MFA dictionaries: https://mfa-models.readthedocs.io/en/latest/dictionary/index.html
