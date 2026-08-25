# Acquired Dysarthria Daily Rehabilitation Codex Automation Blueprint
> Created: 2026-08-24
> Purpose: Codex implementation blueprint

## 0. Goals and Deliverables

### Primary Goal
현재 Speech Rehab 앱을 성인 후천성 마비말장애 사용자가 집에서 하루 여러 번, 회당 약 15분 동안 안전하게 반복할 수 있는 자가훈련 서비스로 재편한다. 앱은 사용자가 오늘 할 훈련을 즉시 시작하고, 입술·혀 운동을 실제 발음으로 연결하며, 호흡·발성·조음·운율·기능적 말하기를 한 세션 안에서 연습하고, 달력에서 누적 훈련 내역을 확인하도록 지원한다.

### Success Definition
- 사용자는 홈에서 2번 이내의 조작으로 15분 루틴을 시작할 수 있다.
- 하루 완료 횟수 `N`은 1~4회 범위에서 사용자가 설정하며 기본값은 2회이다.
- 같은 날 여러 세션이 각각 저장되고 달력의 일별 횟수, 총 시간, 완료 영역, 피로도 변화로 집계된다.
- 기본 루틴은 호흡·발성·조음·기능적 발화로 이어지며 비말하기 구강운동만으로 완료되지 않는다.
- 통증, 사레, 삼킴 곤란, 호흡 불편, 어지러움, 갑작스러운 말 변화가 있으면 즉시 중단하도록 모든 세션에 안전 장치가 있다.
- 음성 점수는 진단값이나 치료 효과를 단정하는 수치가 아니라 동일 사용자 안에서의 연습 참고값으로 표시된다.
- 기존 혀운동, 얼굴운동, 호흡훈련, 발음 연습, 녹음, 피로도 및 이력 기능을 재사용한다.

### Out of Scope
- 마비말장애의 진단, 유형 분류 또는 중증도 판정
- 언어재활사 처방을 대체하는 개인별 의료 치료 계획
- 삼킴 재활, 음식 섭취 훈련, 흡인 위험 평가
- 압력 역치 기기를 사용하는 EMST/IMST의 무처방 제공
- LSVT LOUD®, SPEAK OUT!® 등 상표화된 임상 프로그램의 무단 복제
- 급성 신경학적 변화나 호흡 응급상황의 원격 판정
- 보호자·치료사용 포털과 원격 처방 기능의 MVP 포함

## 1. Working Context

### Background
현재 앱은 Flutter와 Riverpod을 기반으로 하며 혀운동 루틴, 얼굴운동, 호흡훈련, 단어·문장·자유 발화, STT/TTS, 녹음 재생, 입모양 영상, 피로도, 연습 이력과 대시보드를 이미 제공한다. 그러나 운동별 화면과 이력 저장 방식이 분리되어 있고, 사용자가 매일 수행할 하나의 처방형 루틴과 월간 달력 집계가 없다. 호흡훈련 화면에는 입·입술·혀·볼 동작이 혼합되어 있어 명칭과 실제 콘텐츠의 정합성도 개선해야 한다.

임상 설계 근거는 다음과 같다.

- ASHA는 후천성 마비말장애가 호흡, 발성, 조음, 공명, 운율의 한 가지 이상을 침범하며, 치료는 평가된 결손과 기능적 의사소통 목표에 맞게 개별화해야 한다고 설명한다. [ASHA Dysarthria in Adults](https://www.asha.org/practice-portal/clinical-topics/dysarthria-in-adults/)
- 운동학습 원리에 따라 초기에는 반복적이고 일정한 과제와 수행 피드백을 제공하고, 숙련 후에는 과제를 다양화하며 결과 중심 피드백으로 옮겨가는 구성이 적절하다. 같은 자료는 연습량·일정·가변성·복잡성을 조정하고 특이성, 반복, 강도, 중요성을 고려하도록 권고한다.
- 치료 예시는 편안한 자세와 조절 호흡, 구 단위 호흡, 모음 연장, 호흡-발성 협응, 조음 위치 단서, 명료 발화, 말속도 조절, 강세 및 자연스러운 쉼을 포함한다.
- 빈도와 강도는 질환 유형, 중증도, 에너지와 지원 환경에 따라 달라야 한다. 따라서 본 앱의 15분 루틴은 일반 자가훈련 기본값이고, 치료 용량을 주장하지 않는다.
- 파킨슨병에서는 NICE가 의사소통 문제가 있는 사람에게 언어치료를 제공하고, 노력 기반 말하기와 필요 시 전문가가 관리하는 호기근 훈련 같은 접근을 고려하도록 권고한다. [NICE Parkinson’s disease recommendations](https://www.nice.org.uk/guidance/ng71/chapter/Recommendations)
- 비진행성 후천성 마비말장애 치료 문헌은 개선 가능성을 보여주지만 연구 이질성과 근거 제한이 있으므로 특정 운동의 보편적 효과를 단정하지 않는다. [Systematic review: non-progressive dysarthria](https://pubmed.ncbi.nlm.nih.gov/30286661/)
- 비말하기 구강운동이 말하기 결과를 개선한다는 근거는 제한적이므로 입술·혀 동작은 준비운동으로 짧게 사용하고 즉시 음절·단어·문장 발화로 전이한다. [ASHA evidence review on nonspeech oral motor exercises](https://pubs.asha.org/doi/10.1044/1058-0360%282009/09-0006%29)

### Objective
Codex 구현 워크플로는 현재 기능을 `오늘의 15분 루틴` 중심 정보구조로 통합하고, 사용자의 원인 질환과 어려운 말하기 영역을 진단하지 않는 범위에서 선택받아 적절한 훈련 비중을 구성하며, 통합 세션 기록과 달력 통계를 생성하는 구조를 설계·검증해야 한다.

### Scope
- Included: 성인 후천성 마비말장애, 자가훈련, 15분 기본 루틴, 일일 목표 1~4회, 반복 세션, 입술·혀 준비운동, 호흡-발성, 발음·조음, 운율·기능적 문장, 피로도, 중단 사유, 달력 및 일별 상세, 로컬 우선 저장, 접근성, 안전 고지
- Excluded: 진단·처방·삼킴치료·기기 기반 호흡근 강화·치료사 포털·원격 모니터링·임상 프로그램 복제

### Inputs
| Item | Format | Source | Notes |
|---|---|---|---|
| 재활 프로필 | local JSON | 사용자 온보딩 | 원인 질환은 선택 사항, 진단값으로 사용하지 않음 |
| 일일 목표 횟수 | integer 1~4 | 사용자 설정 | 기본 2회, 같은 날 추가 훈련 허용 |
| 세션 전 상태 | integer/enum | 사용자 | 피로도 1~5, 통증·호흡·삼킴 위험 체크 |
| 훈련 콘텐츠 | versioned local JSON/Dart model | 앱 번들 | 임상 검토 버전과 출처 메타데이터 포함 |
| 음성·녹음 | local audio/STT result | 기기 마이크 | 명시적 권한, 로컬 보관 기본 |
| 세션 이벤트 | structured JSON | 훈련 플레이어 | 시작, 일시정지, 건너뜀, 중단, 완료 |
| 기존 이력 | SharedPreferences JSON | 앱 서비스 | 마이그레이션 후 통합 조회 |

### Outputs
| Item | Format | Destination | Notes |
|---|---|---|---|
| 오늘의 루틴 | runtime model | 홈/루틴 플레이어 | 총 15분 목표, 피로도에 따라 축소 가능 |
| 통합 훈련 세션 | JSON | 로컬 저장소 | 한 날짜에 여러 레코드 허용 |
| 달력 집계 | derived view model | 달력 화면 | 완료 횟수, 시간, 영역, 피로도 표시 |
| 일별 상세 | UI view | 달력 날짜 상세 | 세션별 단계, 점수, 녹음, 중단 이유 |
| 주간 요약 | derived JSON/UI | 홈·대시보드 | 목표 달성일, 총 세션, 총 시간, 연속일 |
| 안전 이벤트 | local log | 세션 이력 | 개인 건강정보 최소화, 외부 전송 없음 |

### Constraints
- 의료 안전: 앱은 보조 도구이며 진단·치료 대체 표현을 금지한다.
- 개인화: 원인 질환만으로 루틴을 자동 처방하지 않고 사용자가 선택한 어려움과 피로도를 활용한다.
- 발성 안전: 통증, 쉰목소리 악화, 목 조임이 있으면 고강도 발성이나 큰 소리를 유도하지 않는다.
- 호흡 안전: 숨 참기 경쟁, 과호흡, 최대 노력 반복 및 저항 기기 훈련을 기본 루틴에 넣지 않는다.
- 구강운동: 비말하기 동작은 2~3분 이하 준비 단계로 제한하고 말소리 과제와 연결한다.
- 저장: MVP는 로컬 우선이며 녹음 삭제, 보존 기간과 내보내기 정책을 명시한다.
- 접근성: 큰 글자, 고대비, 한 화면 한 행동, 음성 안내와 시각 안내 병행, 떨림·편측 약화를 고려한 큰 터치 영역을 제공한다.
- 성능: 오프라인에서도 루틴, 타이머, 기록, 달력 열람이 가능해야 한다.
- 근거 관리: 콘텐츠마다 `clinicalReviewVersion`, `reviewedAt`, `sourceRefs`, `contraindications`를 둔다.

### Terms
| Term | Definition |
|---|---|
| 후천성 마비말장애 | 뇌졸중, 외상성 뇌손상, 파킨슨병 등 후천적 신경학적 원인으로 말운동 실행이 어려워진 상태 |
| 세션 | 사용자가 시작한 한 번의 훈련 기록. 완료·부분완료·중단을 모두 포함 |
| 일일 목표 N | 하루 권장 완료 세션 수. 1~4회에서 설정하며 기본 2회 |
| 준비운동 | 입술·혀·턱의 편안한 움직임을 확인하는 짧은 비말하기 단계 |
| 말하기 전이 | 준비 동작을 관련 음절, 단어, 문장 발화에 즉시 연결하는 과정 |
| 명료 발화 | 평소보다 조음 위치를 분명히 하고 편안한 속도로 말하는 전략 |
| 통합 세션 이력 | 운동 종류에 관계없이 동일 스키마로 저장되는 사용자 훈련 기록 |

## 2. Workflow Definition

### End-to-End Flow
`[프로필/안전 확인] -> [오늘 루틴 구성] -> [15분 훈련 실행] -> [세션 후 상태 확인] -> [통합 기록 저장] -> [달력/주간 요약]`

권장 15분 표준 루틴:

| 구간 | 시간 | 훈련 내용 | 핵심 원칙 |
|---|---:|---|---|
| 준비 및 상태 확인 | 1분 | 자세, 어깨·턱 이완, 피로도, 위험 증상 확인 | 이상 증상 시 시작 차단 |
| 편안한 호흡-발성 | 3분 | 천천히 들이쉬고 내쉬기, 편안한 모음, 짧은 구 호흡 | 최대 노력·숨 참기 금지 |
| 입술·혀와 말소리 연결 | 3분 | 입술 닫기/둥글리기, 혀끝 위치 확인 후 `마·바·파`, `라·나·다`, `가·카` 등 | 비말하기 동작만 반복하지 않음 |
| 조음·발음 및 속도 | 4분 | 개인이 어려워한 음절→단어→짧은 문장, 명료 발화, 탭 기반 속도 조절 | 정확도 우선 후 다양화 |
| 발성·운율·기능 문장 | 3분 | 편안한 크기, 문장 강세, 자연스러운 쉼, 생활 문장 | 소리 크기 경쟁 금지 |
| 마무리 | 1분 | 피로도·불편감·자가평가, 녹음 선택 재생 | 다음 세션 간 휴식 안내 |

피로도 4~5이거나 당일 추가 세션이면 8분 경량 루틴을 제안하되 강제하지 않는다. 사용자는 하루 N회 목표를 넘겨 추가 세션을 시작할 수 있지만, 연속 세션 사이 휴식을 안내한다.

### LLM vs Code Boundary
| LLM handles | Code handles |
|---|---|
| 사용자가 선택한 어려움에 맞는 쉬운 표현의 피드백 생성 | 타이머, 루틴 시간 합산, 상태 전이, 저장, 달력 집계 |
| STT 결과에서 발화 누락·속도·쉼에 대한 비진단적 설명 | 음량·발화시간 등 객관값 계산과 임계값 검증 |
| 콘텐츠 누락·표현 위험성의 임상 검토 보조 | 승인된 콘텐츠만 배포하고 버전·출처 고정 |
| 생활 문장 난이도와 변형 제안 | 개인정보 삭제, 마이그레이션, 중복 방지, 테스트 |

#### Step 01: Profile and Safety Gate
1) Step Goal:
성인 후천성 마비말장애 자가훈련에 필요한 최소 프로필과 안전 상태를 확인한다.

2) Input / Output:
- Input: 기존 `RehabProfile`, 일일 목표 N, 시작 전 피로도, 위험 증상 응답
- Output: 안전 통과 여부와 `RehabTrainingProfile`

3) LLM Decision Area:
사용자가 자유문으로 적은 목표를 호흡·발성·조음·속도·기능적 말하기 범주로 제안하되 진단하지 않는다.

4) Code Processing Area:
필수 동의, 성인 여부, N 범위, 위험 증상, 프로필 스키마를 검증한다.

5) Success Criteria:
안전 고지가 수락되고 위험 증상이 없으며 프로필이 유효하다.

6) Validation Method:
JSON schema, 경계값 테스트, 위험 증상별 UI 차단 테스트, 사용자 확인.

7) Failure Handling:
위험 증상은 세션 시작을 차단하고 전문가·응급 안내를 표시한다. 형식 오류는 1회 자동 복구 후 `NEEDS_USER_INPUT`으로 이동한다.

8) Skills / Scripts:
- Skill: `dysarthria-content-safety` (구현 시 생성)
- Script: `scripts/validate_rehab_profile.dart`

9) Intermediate Artifact Rule:
`output/step01_rehab_profile.json`

#### Step 02: Daily Routine Composition
1) Step Goal:
사용자 목표, 최근 어려움, 피로도와 당일 세션 수를 반영해 15분 또는 8분 루틴을 구성한다.

2) Input / Output:
- Input: 프로필, 승인된 운동 라이브러리, 최근 7일 이력
- Output: 순서와 시간이 고정된 `DailyRoutinePlan`

3) LLM Decision Area:
생활 문장 후보와 쉬운 설명을 제안하고 반복 피로를 줄이기 위한 콘텐츠 변형을 추천한다.

4) Code Processing Area:
총 시간, 단계별 최대 시간, 필수 영역 포함, 금기 태그, 콘텐츠 버전을 결정적으로 검증한다.

5) Success Criteria:
표준 루틴은 14~16분이며 호흡-발성, 말소리 연결, 조음, 기능 발화, 마무리를 모두 포함한다.

6) Validation Method:
규칙 기반 루틴 validator와 golden fixture 테스트를 실행한다.

7) Failure Handling:
개인화 콘텐츠가 부족하면 임상 승인 기본 루틴으로 대체한다. 승인 콘텐츠 자체가 없으면 실행을 중단한다.

8) Skills / Scripts:
- Skill: `dysarthria-routine-planner` (구현 시 생성)
- Script: `scripts/validate_daily_routine.dart`

9) Intermediate Artifact Rule:
`output/step02_daily_routine.json`

#### Step 03: Guided Training Session
1) Step Goal:
큰 화면, 음성·시각 단서와 단계형 타이머로 루틴을 안전하게 실행한다.

2) Input / Output:
- Input: `DailyRoutinePlan`, 마이크 권한, 사용자 제어 이벤트
- Output: 단계별 수행 이벤트와 부분 결과

3) LLM Decision Area:
승인된 범위 안에서 짧고 비판적이지 않은 수행 피드백을 생성한다.

4) Code Processing Area:
타이머, 일시정지, 재개, 건너뜀, 중단, TTS, 녹음, STT, 시각 애니메이션을 처리한다.

5) Success Criteria:
사용자가 언제든 멈출 수 있고, 앱 백그라운드 전환 후 시간과 상태가 일관되며, 모든 이벤트가 기록된다.

6) Validation Method:
Riverpod 상태 전이 테스트, 타이머 fake-clock 테스트, 권한 거부 및 앱 재개 테스트, 접근성 점검.

7) Failure Handling:
STT나 AI 실패 시 타이머와 훈련은 계속하며 자가평가로 대체한다. 녹음 실패는 무음 모드로 계속한다. 안전 중단은 즉시 세션을 종료한다.

8) Skills / Scripts:
- Skill: `dysarthria-session-coach` (구현 시 생성)
- Script: `scripts/check_session_state_machine.dart`

9) Intermediate Artifact Rule:
`output/step03_session_events.json`

#### Step 04: Session Completion and Storage
1) Step Goal:
완료·부분완료·중단을 모두 손실 없이 통합 세션 이력으로 저장한다.

2) Input / Output:
- Input: 세션 이벤트, 전후 피로도, 자가평가, 선택적 음성 지표
- Output: `RehabSession` 레코드

3) LLM Decision Area:
결과를 치료 효과로 단정하지 않는 1~2문장 요약을 생성한다.

4) Code Processing Area:
세션 ID, 날짜, 지속시간, 단계 완료율, 점수 범위, 녹음 경로, 콘텐츠 버전과 중단 사유를 저장한다.

5) Success Criteria:
동일 날짜의 여러 세션이 덮어써지지 않고 앱 재실행 후 동일하게 복원된다.

6) Validation Method:
직렬화 round-trip, 중복 ID, 시간대, 자정 경계, 기존 이력 마이그레이션 테스트.

7) Failure Handling:
저장 실패 시 메모리 큐에 1회 유지하고 재시도한다. 지속 실패 시 사용자에게 알리고 녹음 삭제 여부를 선택하게 한다.

8) Skills / Scripts:
- Skill: none
- Script: `scripts/migrate_rehab_history.dart`

9) Intermediate Artifact Rule:
`output/step04_rehab_session.json`

#### Step 05: Calendar and Daily Detail
1) Step Goal:
월간 달력에서 훈련 여부와 횟수를 확인하고 날짜별 세션 상세로 이동하게 한다.

2) Input / Output:
- Input: 통합 세션 목록, 일일 목표 N, 선택 월/날짜
- Output: `CalendarDaySummary`와 날짜별 세션 목록

3) LLM Decision Area:
주간 경향을 쉬운 말로 요약하되 인과나 임상적 개선을 주장하지 않는다.

4) Code Processing Area:
로컬 날짜 기준 횟수·분·영역·완료율을 집계하고 달성 상태를 계산한다.

5) Success Criteria:
달력 한 칸에 0회, 진행 중, 목표 달성, 목표 초과가 구분되고 날짜 선택 시 모든 세션이 표시된다.

6) Validation Method:
월 경계, 윤년, 시간대 변경, 하루 다중 세션, 삭제 반영 widget/unit 테스트.

7) Failure Handling:
손상 레코드는 달력 합산에서 제외하고 복구 로그에 남긴다. 전체 로드 실패 시 재시도와 데이터 내보내기를 제공한다.

8) Skills / Scripts:
- Skill: none
- Script: `scripts/verify_calendar_aggregation.dart`

9) Intermediate Artifact Rule:
`output/step05_calendar_summary.json`

#### Step 06: Content Governance and Release Validation
1) Step Goal:
재활 콘텐츠, 안전 문구, 데이터 모델과 핵심 사용자 흐름을 출시 전에 검증한다.

2) Input / Output:
- Input: 콘텐츠 라이브러리, 출처, 금기, 앱 테스트 결과
- Output: 출시 승인 체크리스트와 검증 보고서

3) LLM Decision Area:
과장된 의료 표현, 모호한 운동 지시, 자가훈련 범위를 넘는 콘텐츠를 탐지한다.

4) Code Processing Area:
필수 메타데이터, 총 시간, 링크, 테스트 결과, 개인정보 필드를 검사한다.

5) Success Criteria:
모든 운동이 임상 검토 상태이고 자동 테스트가 통과하며 안전 차단 시나리오가 확인된다.

6) Validation Method:
언어재활사 human review, schema validation, `flutter analyze`, `flutter test`, 접근성 수동 QA.

7) Failure Handling:
임상 검토되지 않은 콘텐츠는 비활성화한다. 안전·저장·달력 핵심 테스트 실패 시 출시를 중단한다.

8) Skills / Scripts:
- Skill: `dysarthria-content-safety` (구현 시 생성)
- Script: `scripts/validate_clinical_content.dart`

9) Intermediate Artifact Rule:
`output/step06_release_validation.md`

### State Model
| State | Entry Condition | Exit Condition | Next State |
|---|---|---|---|
| `COLLECTING_REQUIREMENTS` | 대상, 사용 방식, 시간, 이력 요구가 불완전함 | 성인 후천성·자가훈련·15분·N회·달력 요구가 확정됨 | `PLANNING` |
| `PLANNING` | 근거와 현재 앱 구조를 반영해 루틴·모델을 구성함 | 계획 및 승인 콘텐츠가 유효함 | `RUNNING_SCRIPT` or `VALIDATING` |
| `RUNNING_SCRIPT` | 루틴 생성, 마이그레이션, 집계 스크립트 실행 | 스크립트 성공 또는 실패 | `VALIDATING` or `FAILED` |
| `VALIDATING` | 스키마·안전·테스트·임상 검토 수행 | 결과가 확정됨 | `DONE` or `NEEDS_USER_INPUT` or `FAILED` |
| `NEEDS_USER_INPUT` | 위험 증상, 데이터 복구, 설정 선택 등 인간 결정 필요 | 사용자가 답변함 | `PLANNING` or `DONE` |
| `DONE` | 기획·구현·검증 산출물이 승인됨 | Terminal | none |
| `FAILED` | 안전 검토 실패, 복구 불가 저장 오류 등 | Terminal | none |

## 3. Implementation Spec

### Recommended Folder Structure
```text
/project-root
  AGENTS.md
  blueprint-acquired-dysarthria-daily-rehab.md
  /.agents
    /skills
      /dysarthria-content-safety
        SKILL.md
        /references
      /dysarthria-routine-planner
        SKILL.md
        /scripts
        /references
      /dysarthria-session-coach
        SKILL.md
        /references
  /lib
    /features
      /rehab_home
      /daily_routine
        /model
        /provider
        /view
      /rehab_calendar
        /model
        /provider
        /view
      /tongue_exercise
      /face_exercise
      /breathing_training
      /practice
    /services
      rehab_profile_service.dart
      rehab_session_repository.dart
      rehab_calendar_service.dart
      rehab_content_service.dart
  /assets
    /rehab_content
      ko-KR.json
  /output
  /scripts
  /docs
```

### AGENTS.md Responsibilities
- 마비말장애 관련 구현 요청은 본 설계서와 임상 승인 콘텐츠를 우선 참조한다.
- 의료 진단·치료 효과·회복 보장 표현을 금지하고 안전 차단 규칙을 변경하지 않는다.
- 훈련 콘텐츠 변경은 출처, 임상 검토 버전, 금기와 테스트를 함께 갱신한다.
- 로컬 데이터 마이그레이션은 기존 `PracticeSession`과 `TongueExerciseSession`을 보존한다.
- 새 스킬은 반드시 `skill-creator`를 통해 만들고 검증한다.

### Custom Agent Definitions
| Name | Path | Role | Required Fields |
|---|---|---|---|
| none | none | MVP는 단일 Codex agent와 skills/scripts로 충분하며 의료 콘텐츠 판단을 별도 자율 에이전트에 위임하지 않음 | none |

### Skill and Script Inventory
| Name | Type | Role | Trigger Condition |
|---|---|---|---|
| `dysarthria-content-safety` | skill | 의료 표현, 금기, 중단 기준과 자가훈련 범위 검토 | 운동 콘텐츠 또는 안전 문구 추가·변경 |
| `dysarthria-routine-planner` | skill | 승인 콘텐츠로 15분/8분 루틴 설계 | 루틴 규칙 또는 개인화 로직 변경 |
| `dysarthria-session-coach` | skill | 비진단적이고 짧은 한국어 피드백 설계 | 세션 코칭 또는 결과 요약 변경 |
| `validate_daily_routine.dart` | script | 시간, 필수 영역, 금기 태그 검증 | 콘텐츠 빌드 및 CI |
| `migrate_rehab_history.dart` | script | 분산된 기존 이력을 통합 모델로 변환 | 첫 앱 업데이트 및 테스트 |
| `verify_calendar_aggregation.dart` | script | 날짜·시간대·다중 세션 집계 검증 | 달력 로직 변경 및 CI |

### Skill Creation Rules

> 이 설계서에 정의된 모든 스킬은 구현 시 반드시 `skill-creator` 스킬(`/skill-creator`)을 사용하여 생성할 것.
> 직접 SKILL.md를 수동 작성하지 말 것 — 규격 불일치 및 트리거 실패의 원인이 됨.

skill-creator가 보장하는 규격:
1. SKILL.md frontmatter (`name`, `description`) 필수 필드 준수
2. `description`의 트리거 정확도 최적화 (eval 기반 optimization loop)
3. 스킬 저장 위치 `.agents/skills/<skill-name>/` 규격 준수
4. 폴더 구조 (`SKILL.md` + `scripts/` + `references/`) 규격 준수
5. Progressive disclosure: SKILL.md 본문 500줄 이내, 대용량 참조는 `references/`로 분리
6. 테스트 프롬프트 실행 및 품질 검증 완료

### Core Artifacts
| Path | Format | Producer | Purpose |
|---|---|---|---|
| `output/step01_rehab_profile.json` | JSON | Step 01 | 안전 통과 프로필 |
| `output/step02_daily_routine.json` | JSON | Step 02 | 실행 가능한 15분/8분 루틴 |
| `output/step03_session_events.json` | JSON | Step 03 | 훈련 상태와 수행 이벤트 |
| `output/step04_rehab_session.json` | JSON | Step 04 | 통합 세션 영속화 모델 |
| `output/step05_calendar_summary.json` | JSON | Step 05 | 월간·일별 집계 결과 |
| `output/step06_release_validation.md` | Markdown | Step 06 | 임상·기술 출시 검증 결과 |

추가 권장 데이터 모델:

```text
RehabTrainingProfile
  id, acquiredCause?, primaryDifficulties[], dailySessionGoal,
  preferredSessionMinutes=15, fatigueRule, acceptedSafetyNoticeAt

RehabSession
  id, localStartedAt, localEndedAt, timezoneOffset, status,
  routineVersion, completedModules[], durationSeconds,
  fatigueBefore, fatigueAfter?, discomfortFlags[], stopReason?,
  pronunciationSummary?, recordingRefs[]

CalendarDaySummary
  localDate, completedCount, partialCount, totalMinutes,
  goalCount, goalStatus, modulesCompleted[], averageFatigueBefore?
```

핵심 화면 구조:

```text
앱 시작
  -> 오늘의 훈련 홈
      -> 오늘 0/N회 · [15분 훈련 시작]
      -> 빠른 훈련: 호흡 / 입술·혀 / 발음 / 발성
      -> 최근 연속 훈련 및 휴식 안내
  -> 15분 루틴 플레이어
      -> 준비 -> 호흡·발성 -> 말소리 연결 -> 조음 -> 기능 문장 -> 마무리
  -> 달력
      -> 월간 목표 상태
      -> 날짜 선택
      -> 해당 날짜 세션 목록 및 상세
  -> 설정
      -> 하루 목표 N, 알림 시간, 녹음 보관, 안전 고지
```

달력 표시 규칙:

- 빈 날짜: 표시 없음
- 부분 수행만 있음: 회색 점
- 1회 이상 완료했으나 N 미만: 파란 점과 `완료/목표`
- N회 달성: 초록 원
- N회 초과: 초록 원과 `+횟수`
- 날짜 상세: 세션 시작 시각, 15분/8분, 완료·부분·중단, 모듈, 피로도 전후, 녹음 재생/삭제

구현 우선순위:

1. P0: 통합 `RehabSession`, 저장소, 기존 이력 마이그레이션
2. P0: 오늘의 홈과 15분 루틴 오케스트레이터
3. P0: 위험 증상 차단, 피로도 기반 경량 루틴, 중단 기록
4. P0: 월간 달력과 날짜 상세
5. P1: 어려운 발음군 기반 루틴 비중 조절
6. P1: 알림과 목표 달성 리마인더
7. P2: 선택적 백업·내보내기 및 전문가 공유용 PDF/CSV

## 4. Validation Checklist

- [x] Every workflow step has all 9 required fields
- [x] Intermediate artifacts use the `output/stepNN_<name>.<ext>` rule
- [x] LLM vs code responsibilities are separated clearly
- [x] Human review points are explicit where needed
- [x] Codex skill paths use `.agents/skills/...`
- [x] Codex custom subagents use `.codex/agents/*.toml`
- [x] Skill additions or updates mention `skill-creator`
- [ ] 언어재활사가 모든 운동 지시, 금기, 중단 기준을 출시 전에 검토함
- [ ] 일일 목표 N=1,2,3,4 및 목표 초과 세션을 달력에서 검증함
- [ ] 자정, 시간대 변경, 윤년, 앱 강제 종료 후 세션 복구를 검증함
- [ ] STT·AI·마이크 권한 없이도 안전한 자가훈련과 이력 저장이 가능함
- [ ] 비말하기 입술·혀 운동이 관련 말소리 과제로 이어지는지 검증함
- [ ] 큰 글자, 스크린리더, 고대비, 큰 터치 영역을 실제 기기에서 점검함
