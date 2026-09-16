# 마비말장애 훈련 앱 검토 및 개선안

검토일: 2026-09-13 · 소스 기준: `1bc2f6b` · 대상: Speech Rehab

후속 구현은 [2026-09-15 구현 기록](dysarthria-implementation-2026-09-15.md)에 정리했다. 아래 관찰과 줄 번호는 구현 전 검토 시점의 기록이다.

**우선 해결할 과제는 평가 결과의 신뢰성, 사용자가 선택한 훈련량의 준수, 피로도에 맞는 연습 흐름이다.** 문장 반복, 녹음 비교, 구강·호흡 안내, 자음별 콘텐츠 등 기능의 기반은 충분하다. 이 기능들이 하나의 개인화된 연습 세션으로 연결되면 활용도가 높아질 수 있다.

이 문서는 구현 사실, 이번에 직접 관찰한 화면, 제품 설계 제안을 구분한다. 임상 효과를 판정하거나 개인에게 훈련을 처방하는 문서는 아니다.

## 1. 검토 범위와 검증 결과

- Flutter 앱의 홈·온보딩·문장 연습·게임·구강훈련·기록·음성 분석·저장 구조와 Python 발음 분석 서버를 검토했다.
- 현재 소스로 macOS debug 앱을 빌드하고, 기존 로컬 설정을 유지한 상태에서 홈 → 추천 긴 문장 → 녹음 준비 화면을 직접 확인했다. 캡처 크기는 800×632이다.
- 최초 온보딩은 소스로 확인했다. 실제 음성 녹음·카메라 촬영·환자 음성 분석·iOS/Android 실기기·스크린리더 사용성은 이번 실행에서 검증하지 않았다.
- 문장 화면에서 뒤로가기·기록 버튼을 조작했으나 자동화 도구에서는 화면 전환을 확인하지 못했다. 앱 결함과 도구의 제약을 구분할 수 없어 확정 결함으로 분류하지 않았다. 이후 게임·구강훈련·결과 화면은 소스 검토 범위다.
- 기존 graphify 자료는 구조 추출 파일만 있고 완성된 `graph.json`이 없다. 과거 구조 자료를 최신 구현의 증거로 간주하지 않고 현재 소스를 확인했다.

| 검증 | 결과 | 의미와 한계 |
|---|---|---|
| `flutter build macos --debug` | 성공 | 현재 소스의 macOS 빌드 가능 |
| `flutter analyze --no-pub` | 오류 없음 | 정적 분석 통과 |
| `flutter test --no-pub --reporter expanded` | 71개 통과 | 일부 게임 테스트에서 탭 위치 hit-test 경고가 있어 실제 조작 검증 보완 필요 |
| 서버 `python3 -B -m unittest discover -s tests -v` | 14개 통과 | 가짜 backend/runner 중심. 실제 환자 음성 정확도를 입증하지 않음 |

앱 기능 코드는 변경하지 않았다. 이 검토서와 현재 실행의 화면 캡처만 추가했다.

## 2. 유지하고 발전시킬 부분

1. **같은 문장 재녹음과 이전 녹음 비교:** 환자가 자신의 변화를 직접 듣는 흐름으로 발전시키기 좋다.
2. **생활 문장과 개인 문장:** 병원·가족·전화 상황에서 실제로 필요한 말을 연습할 기반이 있다.
3. **다양한 안내 방식:** 구강훈련에 음성·자막·속도 조절·진동·영상 실패 시 대체 안내가 있다.
4. **일부 안전 장치:** 전문가 지도가 필요한 운동의 실행 제한과 백그라운드 이동 시 일시정지가 구현돼 있다.
5. **분석 불확실성 표현의 선례:** 기본 MFA 분석은 정렬이 끝났다고 정확도 점수를 만들어내지 않고 `null`을 유지한다. 이 구조를 일반 연습에도 적용할 수 있다.

## 3. 우선순위

아래 우선순위는 제품 개선 순서다. **최우선**은 환자에게 잘못된 평가·훈련량·상태 기록을 제공하는 문제, **다음**은 지속 사용과 운영 신뢰성을 높이는 문제다.

| 순서 | 우선순위 | 확인한 문제 | 개선 방향 |
|---|---|---|---|
| 1 | 최우선 | 자유 말하기 인식 실패에도 임의 문장과 85점 생성 가능 | 분석 불가 상태와 점수 없음 도입 |
| 2 | 최우선 | 텍스트 일치·길이를 발음 점수로 표시 | 인식 일치도와 원음 기반 평가 구분 |
| 3 | 최우선 | 온보딩 목표가 훈련에 연결되지 않고 종료 피로도가 추정값으로 저장됨 | 공통 프로필과 실제 전후 상태 입력 |
| 4 | 최우선 | 준비에서 5회를 선택해도 다음 운동부터 기본 20회로 변경 가능 | 세션 시작 시 운동별 반복·속도 계획 확정 |
| 5 | 최우선 | 중단하거나 완료 후 저장 전에 나가면 진행 소실 | 단계별 자동 저장·부분완료·이어하기 |
| 6 | 다음 | 시간 초과 게임을 무발화 0점으로 저장하고 평균에 포함 | 게임 이벤트와 평가 가능한 발화 분리 |
| 7 | 다음 | 홈 시간 불일치, 문장과 녹음 버튼 분리, 음성 의존 조작 | 일관된 간편 연습 화면과 대체 입력 |
| 8 | 다음 / 외부 배포 전 | 요청 제한시간·음성 전송·파일 삭제 계약 미완성 | 취소·타임아웃·동의·인증·보관 정책 |

### 1) 인식 실패를 성공적인 발화로 저장하지 않기

**확인한 사실:** 자유 말하기에서 인식 텍스트가 비면 `오늘 있었던 일을 편하게 말했습니다.`를 넣는다. 이후 대체 평가 로직은 비어 있지 않은 자유 발화에 85점과 “전체적으로 명확하게 들립니다”를 반환한다. iOS에서는 Gemma가 비활성화되어 이 대체 로직을 사용한다. 녹음 파일이 존재하는 경우 이 결과가 기록과 연속 성공 횟수에 반영될 수 있다.

근거: [임의 발화 대입](/Users/youngwhankim/Project/mj_dialog/lib/features/practice/provider/practice_provider.dart:1214), [iOS 모델 비활성화](/Users/youngwhankim/Project/mj_dialog/lib/services/api/ai_service.dart:160), [85점 반환](/Users/youngwhankim/Project/mj_dialog/lib/services/api/ai_service.dart:319), [기록 저장](/Users/youngwhankim/Project/mj_dialog/lib/features/practice/provider/practice_provider.dart:1281).

**개선:** `녹음 완료`, `인식 확인 필요`, `분석 가능`, `분석 불가`를 구분한다. 원문이 없으면 만들어 넣지 않는다. 점수는 nullable로 하고 분석 불가 기록을 평균·연속 성공·취약 발음 판정에서 제외한다. 화면은 “녹음은 저장됐어요. 이번에는 말을 확인하지 못했어요”와 `들어보기 / 다시 시도 / 마치기`를 제공한다.

**완료 기준:** 무음·인식 실패·모델 오류 상황에서 임의 문장이나 유효한 발음 점수가 생성되지 않는다. 실패해도 저장된 녹음을 다시 들을 수 있다.

### 2) 인식 결과와 발음 평가를 구분하기

**확인한 사실:** 일반 연습은 원음을 평가 서비스에 전달하지 않고 인식 텍스트를 전달한다. 대체 로직은 텍스트 길이·완전 일치로 점수를 만들고, 단어 게임은 완전 일치 100점/불일치 40점을 사용한다. 자유대화의 대체 피드백은 특정 단어가 포함됐다는 이유로 혀 위치 조언을 만들기도 한다.

근거: [일반 평가 호출](/Users/youngwhankim/Project/mj_dialog/lib/features/practice/provider/practice_provider.dart:1242), [대화 대체 평가](/Users/youngwhankim/Project/mj_dialog/lib/services/api/ai_service.dart:298), [텍스트 채점](/Users/youngwhankim/Project/mj_dialog/lib/services/api/ai_service.dart:329), [단어 채점](/Users/youngwhankim/Project/mj_dialog/lib/services/api/ai_service.dart:377).

**개선:** 현 지표는 의미를 제한해 `목표 문장 인식 일치도`로 표시한다. 텍스트만 보고 조음·혀 위치·음량·명료도를 평가하는 피드백을 제거한다. 실제 말 명료도는 청자가 이해하는 정도를 포함하므로, ASR 문자열 일치와 같은 지표로 볼 수 없다. [ASHA의 평가 관점](https://www.asha.org/practice-portal/clinical-topics/dysarthria-in-adults/)에 비추어 사람 평가와의 일치 정도를 별도로 검증해야 한다.

**자음 분석의 별도 문제:** 선택형 CTC 백엔드는 전체 녹음에서 목표 토큰 확률이 가장 높은 프레임을 골라 점수로 만든다. 목표 위치와 실제 음소 구간을 평가하는 방식으로 교체하기 전에는 정확도 지표로 공개하지 않는 편이 좋다. 이는 점수를 비워 두는 기본 MFA 경로와 다른 문제다. [CTC 계산](/Users/youngwhankim/Project/mj_dialog/server/pronunciation_analysis/app/acoustic.py:50), [결과 표시](/Users/youngwhankim/Project/mj_dialog/lib/features/consonant_training/view/consonant_training_screens.dart:587).

**완료 기준:** 결과에 평가 방법·모델/콘텐츠 버전·분석 가능 여부를 저장한다. 한국어 마비말장애 음성에서 중증도·기기·환경별 오류와 사람 평가의 차이를 확인하기 전에는 치료 효과를 점수로 단정하지 않는다.

### 3) 프로필·피로도를 실제 세션 계획에 연결하기

**확인한 사실:** 온보딩은 목표·기간·일일 연습시간·보호자 여부를 저장하지만 `loadProfile()`을 사용하는 곳이 `lib`에 없다. 홈 목표는 5분으로 고정돼 있고 추천 모드는 최근 점수와 마지막 모드로 정해진다. 종료 후 피로도 설정 함수도 호출되지 않으며, 미입력 시 시작 전 값을 종료 후 값으로 저장한다.

근거: [프로필 읽기](/Users/youngwhankim/Project/mj_dialog/lib/services/rehab_profile_service.dart:49), [홈 목표](/Users/youngwhankim/Project/mj_dialog/lib/features/practice/view/practice_mode_selection_screen.dart:169), [추천 규칙](/Users/youngwhankim/Project/mj_dialog/lib/features/practice/view/practice_mode_selection_screen.dart:929), [종료 피로도 대입](/Users/youngwhankim/Project/mj_dialog/lib/features/practice/provider/practice_provider.dart:1305).

**개선:** 공통 프로필을 읽어 목표·문장·분량에 반영한다. 시작 전에는 오늘 상태를 확인하고, 종료 때 실제 피로도와 “말하기가 편했는지”를 짧게 묻는다. 미응답은 미기록으로 유지한다. 피로가 높으면 짧은 과제·휴식 선택을 먼저 제안하고 자동 증량은 피한다. 질환명만으로 운동을 자동 처방하지 않는다. 개인의 어려움과 생활 의사소통 목표에 맞춘 조절은 [ASHA의 개별화 원칙](https://www.asha.org/practice-portal/clinical-topics/dysarthria-in-adults/)에 근거한 설계 제안이다.

**완료 기준:** 온보딩에서 선택한 목표와 시간이 재실행·홈·훈련 준비에서 일관된다. 종료 후 미응답을 “피로 변화 없음”으로 집계하지 않는다.

### 4) 선택한 훈련량이 유지되도록 고치기

**확인한 사실:** 준비 화면의 5회 선택은 현재 상태만 바꾼다. 다음 운동으로 넘어가면 운동별 저장 설정을 다시 읽어 덮어쓰며, 별도 설정이 없으면 기본값은 20회다. 예상 소요시간은 재생속도를 반영하지 않는다.

근거: [준비의 반복 선택](/Users/youngwhankim/Project/mj_dialog/lib/features/guided_training/view/guided_training_player_screen.dart:378), [운동 전환 시 덮어쓰기](/Users/youngwhankim/Project/mj_dialog/lib/features/guided_training/view/guided_training_player_screen.dart:276), [기본 반복 수](/Users/youngwhankim/Project/mj_dialog/lib/services/training/training_settings_service.dart:14), [시간 추정](/Users/youngwhankim/Project/mj_dialog/lib/features/guided_training/view/guided_training_player_screen.dart:342).

**개선:** 시작 전에 운동별 반복 횟수·속도를 포함하는 세션 계획을 확정한다. 예상시간과 플레이어가 같은 계획을 사용하게 한다. `모든 운동 5회씩`과 `운동별 설정 사용`의 의미도 명시한다.

**완료 기준:** 운동 4개를 5회씩 선택하면 모든 운동이 5회로 진행된다. 느린 속도를 선택하면 예상시간도 늘어난다. 중간에 임의로 반복 수가 증가하지 않는다.

### 5) 쉬거나 중단한 기록도 보존하기

**확인한 사실:** 구강훈련 중도 종료는 진행 내용을 저장하지 않는다. 완료 화면에서도 저장 버튼을 누르기 전에 닫으면 확인 없이 나간다.

근거: [종료 처리](/Users/youngwhankim/Project/mj_dialog/lib/features/guided_training/view/guided_training_player_screen.dart:715), [명시적 저장 버튼](/Users/youngwhankim/Project/mj_dialog/lib/features/guided_training/view/guided_training_player_screen.dart:645).

**개선:** 시작·단계 전환·중단 때 자동 저장하고 `완료 / 부분완료 / 쉬는 중 / 중단`을 구분한다. 중단 사유는 선택 사항으로 남기고 재진입하면 이어하기를 제공한다. 쉬었다는 이유로 실패나 기록 소실을 경험하지 않게 한다.

발성 피로 때 휴식이 필요하다는 [NIDCD 안내](https://www.nidcd.nih.gov/health/taking-care-your-voice)를 고려하면, 인식 실패에 일괄적으로 “더 크게 말하세요”를 제시하는 흐름도 바꾸는 편이 좋다. 먼저 마이크 확인·편안한 재시도·쉬기를 제안하고, 훈련 강도 관련 안내는 사용자에게 맞게 검토한다.

**완료 기준:** 중도 종료·완료 직후 닫기·백그라운드 이동 후 복귀에서 진행 기록이 보존된다. 휴식·분석 대기시간은 실제 연습시간과 분리된다.

### 6) 게임과 성과 지표를 환자 경험에 맞추기

**확인한 사실:** 낙하 단어가 바닥에 닿으면 게임이 끝나며, 발화하지 않은 항목도 0점·0초 세션으로 저장된다. 대시보드는 모든 세션 점수를 평균내므로 게임 반응 지연이 발음 저하처럼 반영될 수 있다. 녹음·분석 중에는 낙하가 멈추지만 준비하고 생각하는 시간에는 움직인다.

근거: [무발화 0점 기록](/Users/youngwhankim/Project/mj_dialog/lib/features/practice/provider/practice_provider.dart:945), [전체 평균](/Users/youngwhankim/Project/mj_dialog/lib/features/practice/view/dashboard_screen.dart:20), [게임 종료](/Users/youngwhankim/Project/mj_dialog/lib/features/practice/provider/practice_provider.dart:737).

**개선:** 기본 단어 연습은 한 단어를 고정해서 보여주고 준비 후 말하게 한다. 낙하 게임은 선택형으로 두고 시간제한 없음·일시정지·이동 정지를 제공한다. `실패 녹음`, `틀린 단어`는 `다시 들어볼 녹음`, `다시 연습할 단어`로 바꾼다. 충분한 시간과 시간 제한 조절은 [W3C 시간 제한 지침](https://www.w3.org/WAI/WCAG22/Understanding/timing-adjustable.html)을 참고할 수 있다.

대시보드는 연습한 날·실제 연습시간·생활 문장 수행·체감 부담을 우선 보여준다. 비교 가능한 점수는 동일 문장·같은 분석 방식·분석 가능한 시도끼리 비교한다. `세션`, `발화 시도`, `게임 이벤트`를 데이터에서 구분한다.

**완료 기준:** 아무 말도 하지 않은 게임 시간 초과가 발음 평균·취약 발음·연습 횟수를 바꾸지 않는다.

### 7) 첫 연습을 간단하게 만들고 대체 조작 제공하기

**직접 확인:** 홈에는 목표와 배지가 5분인데 추천 제목은 긴 문장 10분이다. 문장 화면 첫 화면은 목표·피로도·모드·문장 관리로 채워지고, 실제 문장과 녹음 버튼은 아래에 있다. 녹음 버튼까지 내리면 긴 문장의 앞부분이 화면에서 사라진다. 화면 근거는 다음 절에 있다.

**개선:** 홈은 `오늘 할 연습 하나`, `시작하기`, `최근 녹음 비교`를 중심으로 구성하고 전체 메뉴는 별도 탐색으로 둔다. 시간은 하나의 세션 계획에서 가져온다. 연습 화면은 한 문장 또는 의미 단위의 문구를 크게 보여주고 `예시 듣기 / 녹음 / 쉬기`를 고정한다. 목표·문장 관리는 접거나 별도 설정으로 이동한다.

핵심 조작에 큰 고정 버튼과 명시적 접근성 이름을 사용한다. 음성 입력이 실패해도 준비된 답 선택·텍스트 수정·건너뛰기가 가능하게 한다. [W3C의 말장애 접근성 설명](https://www.w3.org/WAI/people-use-web/abilities-barriers/speech/)은 음성인식에만 의존하는 서비스의 장벽을 지적한다.

추가로 최초 온보딩 완료는 연습 선택 화면으로 직접 이동하지만 재실행은 공통 탐색 셸을 사용한다. 최종 진입점을 `/app`으로 통일한다. [온보딩 완료](/Users/youngwhankim/Project/mj_dialog/lib/features/onboarding/view/rehab_onboarding_screen.dart:34), [공통 시작 화면](/Users/youngwhankim/Project/mj_dialog/lib/main.dart:234).

**완료 기준:** 작은 화면·글자 200%에서도 현재 문구와 핵심 조작을 찾을 수 있다. VoiceOver/TalkBack·키보드·필요한 대체 입력으로 시작·정지·재시도·마치기가 가능하다. 화면 캡처만으로 접근성 준수를 판정하지 않는다.

### 8) 분석·저장·외부 전송의 계약 정리하기

| 항목 | 확인한 사실 | 개선 및 검증 |
|---|---|---|
| iOS 최종 인식 | 네이티브 종료 직후 Dart 이벤트 구독을 취소한다. 뒤늦은 최종 결과를 놓칠 수 있다. | 최종 결과/완료 이벤트 또는 제한시간을 기다린 뒤 구독 종료. 긴 쉼·느린 발화·종료 직전 음절로 실기기 검증. [STT 종료](/Users/youngwhankim/Project/mj_dialog/lib/services/audio/stt_service.dart:188) |
| 분석 요청 | 30초 제한은 POST 완료 후 폴링 루프에만 적용된다. 요청 하나가 멈추면 전체 시간이 제한되지 않는다. | 연결·전송·수신과 전체 작업에 타임아웃 적용, 사용자 취소·재시도·녹음 보존. [클라이언트](/Users/youngwhankim/Project/mj_dialog/lib/features/consonant_training/services/pronunciation_analysis_client.dart:34) |
| 원음 전송 | 자음 분석은 녹음 후 업로드하며 앱 기본 URL은 로컬 HTTP다. 코드상 서버 인증·작업 소유권 검사가 없다. | 외부 서버 운영 전 전송 대상·항목·보관 조건 안내 및 선택, HTTPS·인증·소유권 검사·요청 제한. 실제 공개 배포 여부는 확인하지 않았다. [업로드](/Users/youngwhankim/Project/mj_dialog/lib/features/consonant_training/view/consonant_training_screens.dart:447), [서버](/Users/youngwhankim/Project/mj_dialog/server/pronunciation_analysis/app/main.py:47) |
| 파일 수명 | 음성 분석 WAV는 임시 디렉터리에 저장된다. 해당 기록 삭제는 메타데이터만 제거한다. 자음 기록 수 제한으로 탈락한 원음 정리도 필요하다. | 보관할 녹음은 지속 저장소에 두고, 관련 파일과 메타데이터 삭제를 일관되게 처리. [WAV 저장](/Users/youngwhankim/Project/mj_dialog/lib/services/audio_analysis/wav_file_service.dart:16), [삭제](/Users/youngwhankim/Project/mj_dialog/lib/services/audio_analysis/voice_analysis_repository.dart:38) |
| 로컬 개인정보 | 일부 발화·피로도·점수는 SharedPreferences JSON, 원음은 Documents 파일로 저장한다. 이 경로의 별도 앱 수준 암호화는 확인되지 않는다. | OS 저장 보호·백업 범위·보관 기간·전체 삭제 정책과 발화 디버그 로그를 검토한다. OS 보호가 전혀 없다는 뜻은 아니다. [저장](/Users/youngwhankim/Project/mj_dialog/lib/services/practice_history_service.dart:117) |

서버 원음은 임시 디렉터리에서 처리 후 제거된다. 원음을 서버에 영구 저장한다고 단정하면 안 된다. 메모리의 분석 작업 결과에는 자동 만료 정책을 추가할 필요가 있다.

발성 분석에서는 전체 녹음 경과 시간을 발성시간으로 표시하는 점, 피치 미검출을 그래프의 60Hz로 그리는 점도 수정 대상이다. 녹음 시간·유성 발성 시간·피치 추정 품질을 구분하고 미검출은 선을 끊어서 보여준다. [지표](/Users/youngwhankim/Project/mj_dialog/lib/features/voice_analysis/model/voice_analysis_models.dart:127), [그래프](/Users/youngwhankim/Project/mj_dialog/lib/features/voice_analysis/view/voice_analysis_screens.dart:734).

## 4. 이번 실행의 화면 검토

### 1단계 — 오늘의 연습: 진입은 명확하지만 정보 일관성 개선 필요

큰 추천 시작 버튼은 잘 보인다. 그러나 같은 화면에서 목표 5분과 추천 10분이 충돌하며, 현재 상태를 새로 확인하지 않은 상태에서 피로도 1/5·상태 양호가 표시된다. 추천이 어떤 근거로 정해졌는지 설명하고, 미입력 상태와 실제 응답을 구분하는 편이 좋다. 보조 설명의 작은 회색 글자는 가독성을 추가 확인할 대상이다.

![1단계 오늘의 연습](/Users/youngwhankim/Project/mj_dialog/docs/review-2026-09-13/01-home.png)

### 2단계 — 긴 문장 준비: 설정은 있으나 시작 부담이 큼

목표·피로도 입력은 좋은 기반이다. 다만 이 창 크기에서는 연습할 문장과 녹음 버튼이 첫 화면에 나타나지 않는다. 목표 선택·모드 변경·내 문장 관리는 보조 기능으로 접고 현재 수행할 문장부터 보여주는 구성이 적합하다. 슬라이더 외에 큰 선택 버튼을 제공하는 방안도 검토한다.

![2단계 긴 문장 준비](/Users/youngwhankim/Project/mj_dialog/docs/review-2026-09-13/02-reading-setup.png)

### 3단계 — 녹음 준비: 버튼은 명확하지만 읽을 내용과 떨어져 있음

녹음 시작 버튼은 크고 라벨이 있다. 그러나 버튼까지 스크롤하면 긴 문장 앞부분은 보이지 않는다. 중앙의 장식 영역을 줄이고, 현재 읽을 의미 단위와 녹음·정지·휴식 버튼을 함께 보여주면 화면을 오가는 부담을 줄일 수 있다. 실제 녹음·분석·완료까지의 동작은 이번 화면 검토에서 수행하지 않았다.

![3단계 녹음 준비](/Users/youngwhankim/Project/mj_dialog/docs/review-2026-09-13/03-reading-controls.png)

## 5. 권장하는 연습 흐름

1. **오늘 상태:** 피로도와 불편함을 짧게 확인하고, 필요한 경우 쉬기·분량 줄이기를 제안한다.
2. **오늘 할 연습:** 사용자가 선택한 목표와 생활 문장을 연결해 하나의 계획을 보여준다.
3. **듣고 말하기:** 예시 듣기 → 현재 문구 보기 → 충분히 준비 → 녹음. 시간 경쟁은 기본값으로 두지 않는다.
4. **한 가지 피드백:** 녹음 재생과 확인 가능한 피드백 하나를 제공한다. 분석 불가는 별도로 안내한다.
5. **선택:** 같은 문장 다시 하기 / 다음 / 쉬기. 모든 단계에서 진행을 보존한다.
6. **마무리:** 실제 종료 피로도와 체감 난이도를 기록하고 다음 시작 시 이어갈 지점을 남긴다.

훈련 시간·횟수는 제품 예시값과 임상 권고를 혼동하지 않도록 조절 가능하게 둔다. 구강 준비운동은 목표 발화와 어떻게 연결되는지 설명하고, 생활 문장 연습까지 이어지는 하나의 흐름을 우선 완성한다.

## 6. 구현 순서와 완료 확인

### 첫 번째 묶음 — 신뢰할 수 없는 결과 제거

- 임의 발화·기본 고득점 제거, 점수 nullable 및 분석 상태 도입.
- 무발화 게임 이벤트를 발음 통계에서 제외.
- 종료 후 피로도 미입력은 미기록으로 저장.
- 반복 횟수·속도를 세션 계획으로 확정.
- 중단·완료 자동 저장.

기존 기록에는 평가 출처/버전이 없는 값이 섞여 있으므로 새 지표와 그대로 비교하지 않는다. 과거 기록은 삭제하거나 임의 재채점하지 않고 `이전 평가 방식`으로 구분하는 방안을 권장한다.

### 두 번째 묶음 — 매일 쓰기 쉬운 흐름

- 프로필 → 오늘 계획 → 수행 → 전후 상태 → 기록을 공통 세션으로 연결.
- 홈 시간 통일, 문장·녹음 컨트롤 동시 표시, 진입점 통일.
- 시간제한 없는 단어 연습과 음성 외 대체 조작 제공.
- 실제 마비말장애 사용자와 함께 시작·녹음·재시도·휴식·재진입 과제를 관찰. 버튼 위치 설명이 필요했던 순간, 실수, 포기, 피로를 기록해 개선.

### 세 번째 묶음 — 분석과 운영 검증

- iOS STT 최종 결과·분석 취소·타임아웃 검증.
- 외부 분석 전송·접근권한·보관 정책 완성.
- 한국어 환자 음성과 사람 평가를 이용해 자동 지표의 유효 범위 검증.
- 동의한 녹음·목표 문장·피로도·체감 난이도를 선택적으로 내보내는 간단한 공유 기능 검토. 별도 치료사 포털은 MVP 범위를 늘리므로 후순위로 유지.

회귀 검증은 정상 경로 외에 **무음, STT 불가, 마지막 음절 지연, 높은 피로도, 반복 수 변경, 중도 종료, 앱 재진입, 파일 소실, 서버 무응답, 큰 글자**에 집중해야 한다. 현재 테스트 통과만으로 이 문제들이 해결됐다고 볼 수 없다.

## 7. 후속 제안 — 원하는 자음을 지정하는 연습

사용자 제안: “자음을 지정해서 발음 연습하는 기능이 있으면 좋겠다.”

**현재 이미 있는 기능:** 홈의 `자음 집중 훈련`에서 초성/받침을 선택하고 자음 카드를 누르면 해당 자음의 음절·단어·짧은 문장을 연습할 수 있다. 기준 발음 듣기(TTS), 녹음, 내 발음 재생, 다시 연습, 다음, 이력 저장도 있다. 한국어 내장 콘텐츠 `2026.08.1`은 초성 목표 18개·받침 목표 7개, 총 800항목이며 이는 콘텐츠 개수이지 임상 검수 완료를 의미하지 않는다.

근거: [홈 진입](/Users/youngwhankim/Project/mj_dialog/lib/features/practice/view/practice_mode_selection_screen.dart:99), [자음 선택과 훈련 화면](/Users/youngwhankim/Project/mj_dialog/lib/features/consonant_training/view/consonant_training_screens.dart:12), [한국어 내장 콘텐츠](/Users/youngwhankim/Project/mj_dialog/assets/pronunciation/content/ko_consonant_core.json).

**개선 목표:** 기존 기능을 `자음 골라 연습하기`라는 쉽게 이해되는 이름과 눈에 띄는 홈 진입점으로 제공하고, 선택한 자음의 짧은 반복 세션을 완성한다. 별도 자음 메뉴를 중복해서 만들 필요는 없다.

예시 흐름: `ㅅ 선택 → 사·서·소·수·스·시 → 사과·소리·수건 → “수건을 주세요.” → 내 녹음 듣기 → 같은 항목 반복 또는 마치기`. 마지막 문장은 개선 콘텐츠 예시이며 현재 내장 문장이라는 뜻은 아니다.

| 보완 항목 | 구체적인 동작 |
|---|---|
| 선택 명확화 | `단어 앞소리(초성)` / `받침`을 구분하고 큰 자음 버튼 제공. 선택한 자음과 위치를 훈련 중 계속 표시 |
| 목표 강조 | 단어·문장에서 목표 자음이 있는 음절을 강조하고, 소리 설명은 짧고 쉬운 말로 제공 |
| 반복 세션 | 같은 항목 반복 횟수와 남은 항목을 표시. 다음 단계는 사용자가 선택하고 시간제한 없이 진행 |
| 이어하기 | 최근 선택한 자음·위치·단계를 기억하고 홈에 `ㅅ 이어 연습하기` 표시 |
| 비교 기록 | 자음·위치·동일 항목별 녹음을 다시 듣고 비교. 분석 실패를 발음 실패로 취급하지 않음 |
| 콘텐츠 품질 | 현재 내장 문장의 `시간를`, `수건와`, `사람예요` 같은 조사·어미 오류 수정. 자연스러운 생활 문장과 실제 목표 발음 여부를 검수 |
| 기준 음성 | 현재 듣기는 TTS 기반임을 구분. 검수된 예시 음성을 연결하는 방안을 후속 검토 |
| 녹음 상태 보호 | 녹음·분석 중 단계와 항목 이동을 막거나 명시적으로 취소. 시작 시 목표 항목을 고정해 결과가 다른 문장 기록으로 저장되지 않게 함 |

현재 `다음`은 마지막 항목에서 처음으로 순환하므로 명시적인 세션 완료 화면을 추가할 필요가 있다. 또한 단어 게임의 자음 필터는 초성·받침을 함께 검색하고 조건에 맞는 항목이 없으면 다른 단어로 대체할 수 있어, 정확한 위치를 지정하는 자음 집중 훈련과 기능을 구분해야 한다. [항목 순환](/Users/youngwhankim/Project/mj_dialog/lib/features/consonant_training/view/consonant_training_screens.dart:479), [게임 필터](/Users/youngwhankim/Project/mj_dialog/lib/services/practice_content_service.dart:424).

자음별 자동 점수 고도화보다 먼저 **선택 → 듣기 → 녹음 → 자기 비교 → 반복 → 저장**이 안정적으로 이어지는지 확인한다. 이번 후속 검토에서는 기능 코드를 변경하지 않았다.
