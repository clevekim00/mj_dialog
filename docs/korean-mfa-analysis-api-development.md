# 한국어 MFA 발음 분석 API 개발 내역

작성일: 2026-08-26  
대상: 성인 후천성 마비말장애 자음 반복 훈련

## 1. 구현 결과

기존 FastAPI 분석 서버에 한국어 Montreal Forced Aligner(MFA) 백엔드를 추가했다. 앱이 전달한 녹음과 목표 문장을 `mfa align_one`으로 정렬하고, 생성된 Praat TextGrid의 `phones` tier에서 훈련 대상 초성·받침의 시간 구간을 찾아 API 결과로 반환한다.

기본 실행 백엔드는 `mfa`이며, MFA가 설치되지 않았거나 모델이 없으면 서버 기동 자체는 유지하고 분석 작업만 명확한 `unavailable` 결과로 종료한다. 이전 Transformers CTC 백엔드는 `PRONUNCIATION_BACKEND=ctc`로 계속 선택할 수 있다.

## 2. 처리 흐름

1. Flutter 앱이 녹음, 목표 문장, 목표 phone, 초성/받침 위치를 전송한다.
2. 서버가 오디오를 16 kHz mono PCM WAV로 정규화한다.
3. 길이, 음량, clipping 비율을 검사한다.
4. 임시 `.lab` 전사 파일을 만들고 `mfa align_one`을 실행한다.
5. TextGrid의 `phones` tier를 파싱한다.
6. 내부 phone id를 Korean MFA IPA phone set과 비교한다.
7. 일치한 모든 목표 음소 구간을 밀리초 단위로 반환한다.
8. 임시 음성·전사·TextGrid는 작업 종료 시 삭제한다.

## 3. 대상 phone 매핑

앱의 단순 phone id와 Korean MFA dictionary의 IPA를 분리했다. 예시는 다음과 같다.

| 훈련 대상 | 위치 | Korean MFA 후보 |
|---|---|---|
| `k` | 초성 | `k`, `ɡ` |
| `kk` | 초성 | `k͈` |
| `s` | 초성 | `s`, `sʰ`, `ɕʰ` |
| `j` | 초성 | `tɕ`, `dʑ` |
| `kf` | 받침 | `k̚` |
| `tf` | 받침 | `t̚` |
| `pf` | 받침 | `p̚` |
| `ngf` | 받침 | `ŋ` |

전체 매핑은 `app/mfa_backend.py`의 `KOREAN_MFA_PHONE_MAP`에 있으며, 모델 dictionary revision이 바뀔 때 계약 테스트와 함께 갱신해야 한다.

## 4. API 결과 계약

MFA 정렬 성공 예시:

```json
{
  "status": "completed",
  "modelVersion": "mfa-korean-v3.0.0",
  "overallPracticeScore": null,
  "confidence": 0.0,
  "phonemes": [
    {
      "expected": "k",
      "alignedPhone": "k",
      "position": "onset",
      "startMs": 100,
      "endMs": 220,
      "gop": null,
      "practiceScore": null,
      "scoreAvailable": false,
      "status": "aligned"
    }
  ],
  "message": "MFA 음소 정렬을 완료했습니다. 정확도 점수는 CTC/GoP 모델을 연결한 뒤 제공합니다."
}
```

Flutter 모델도 `practiceScore`와 `gop`를 nullable로 변경했다. 점수가 없고 음소 구간이 있으면 `음소 구간 정렬 완료`와 시간 범위를 보여 준다.

## 5. 설치와 실행

MFA는 Kaldi 계열 네이티브 의존성이 있어 일반 pip 환경보다 conda-forge 설치를 기준으로 한다.

```bash
cd server/pronunciation_analysis
conda env create -f environment-mfa.yml
conda activate speech-rehab-mfa
bash scripts/setup_korean_mfa.sh
PRONUNCIATION_BACKEND=mfa uvicorn app.main:app
```

확인:

```bash
curl http://127.0.0.1:8000/ready
```

앱 연결:

```bash
flutter run --dart-define=PRONUNCIATION_ANALYSIS_URL=http://127.0.0.1:8000
```

## 6. 안전성과 실패 처리

- shell 문자열을 사용하지 않고 인자 배열로 MFA를 실행한다.
- 요청마다 별도 MFA `--temporary_directory`를 사용해 동시 분석의 중간 파일 충돌을 막는다.
- 업로드는 20MB로 제한한다.
- MFA 실행 제한 시간 기본값은 45초다.
- 오류 출력은 길이를 제한하고 작업 경로를 제거한다.
- 손상 음성, 무음, 너무 짧거나 긴 음성은 MFA 전에 차단한다.
- 목표 phone 매핑이 없거나 TextGrid에서 구간을 찾지 못하면 점수를 만들지 않는다.

## 7. 검증 범위와 한계

MFA 한국어 모델은 일반 한국어 낭독 음성을 목표로 하는 강제 정렬 모델이다. 마비말장애 발음 정확도를 임상적으로 판정하는 모델이 아니며 TextGrid에는 posterior 또는 GoP 점수가 없다. 따라서 정렬 성공을 정확한 발음으로 해석하지 않는다.

다음 단계는 MFA가 찾은 구간에 한국어 phoneme CTC posterior를 적용하고, 치료사가 평가한 성인 마비말장애 음성으로 GoP 점수와 임계값을 보정하는 것이다. 모델 revision이 달라지면 개인 기준선도 분리한다.

## 8. 추가 테스트

- TextGrid words/phones tier 파싱
- 초성 IPA 변이 매핑
- 대표 받침 불파음 매핑
- MFA 미설치 오류
- MFA 정렬 API의 nullable score 계약
- 기존 CTC 점수 API 회귀 테스트
