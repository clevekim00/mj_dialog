# 발음 분석 서버

[한국어](README.md) | [English](README.en.md) | [전체 문서](../../docs/README.md)

<!-- reader-link --> [언어 탭으로 읽기](https://clevekim00.github.io/mj_dialog/documents/server/pronunciation_analysis/README.html)

> 최신 메뉴 안내 (2026-10-01): **오늘 → 훈련 → 게임 → 기록 → 설정**. [게임과 현재 진입 경로](../../docs/game-menu.md)를 참고하세요. 아래 과거 기획·검토 내용은 작성 당시의 맥락을 보존합니다.

성인 후천성 마비말장애 자음 훈련을 위한 별도 FastAPI 서버입니다. 앱의 녹음은 서버에서 16 kHz mono WAV로 정규화되고, 신호 품질 검사를 통과한 경우 요청의 `language`에 맞는 Montreal Forced Aligner(MFA) 모델로 목표 문장과 음소 구간을 정렬합니다.

## 한국어·영어 MFA 설치

```bash
cd server/pronunciation_analysis
conda env create -f environment-mfa.yml
conda activate speech-rehab-mfa
bash scripts/setup_korean_mfa.sh
PRONUNCIATION_BACKEND=mfa uvicorn app.main:app
```

`PRONUNCIATION_BACKEND=mfa`가 기본값입니다. 한국어는 `MFA_DICTIONARY`, `MFA_ACOUSTIC_MODEL`, `MFA_MODEL_REVISION`, 영어는 `MFA_EN_US_DICTIONARY`, `MFA_EN_US_ACOUSTIC_MODEL`, `MFA_EN_US_MODEL_REVISION`으로 모델을 바꿀 수 있습니다. 공통 설정은 `MFA_COMMAND`, `MFA_TIMEOUT_SECONDS`입니다. `/ready`는 `ko-KR`, `en-US`별 준비 상태를 반환합니다.

MFA는 강제 정렬기이며 발음 정확도 채점기가 아닙니다. API는 목표 음소의 시작·종료 시각과 실제 MFA phone label을 반환하지만 `practiceScore`와 `gop`는 `null`로 유지합니다. 운영 점수는 언어별 성인 마비말장애 데이터로 검증된 CTC/GoP 모델을 추가한 뒤 제공해야 합니다.

CTC 실험 백엔드는 검증되지 않은 채점을 방지하기 위해 비활성화되어 있습니다. 아래 점수 정책을 참고하세요.

API:

- `POST /v1/analysis/jobs`: audio, text, language, target_phone, position, target_occurrence(optional), content_version, baseline_score(optional)
- `GET /v1/analysis/jobs/{job_id}`
- `DELETE /v1/analysis/jobs/{job_id}`
- `GET /health`, `GET /ready`

테스트: `python -m unittest discover -s tests -v`

상세 개발 내역: [`../../docs/korean-mfa-analysis-api-development.md`](../../docs/korean-mfa-analysis-api-development.md)

## 연결·인증·보관 정책 (2026-09)

개발 실행은 `uvicorn app.main:app --host 127.0.0.1 --workers 1`을 사용합니다. 기본 `PRONUNCIATION_ENV=development`에서는 loopback 클라이언트만 분석 API를 사용할 수 있으며 프록시 전달 헤더가 있는 요청도 거절합니다. 모바일 실기기에서 이 개발 서버에 바로 원격 접속하는 구성은 허용하지 않습니다.

운영 연결에는 다음 설정이 모두 필요합니다. 이 저장소 변경은 외부 서버를 배포하거나 사용자 인증 서비스를 생성하지 않습니다.

- `PRONUNCIATION_ENV=production`과 충분히 무작위인 32바이트 이상의 `PRONUNCIATION_AUTH_SECRET`을 서버 비밀 저장소에서 주입합니다. 앱, Git, `--dart-define`에 서명 비밀을 넣지 않습니다.
- TLS를 사용하는 분석 URL을 앱의 `PRONUNCIATION_ANALYSIS_URL`로 지정합니다. TLS 프록시 뒤에서는 Uvicorn의 `--forwarded-allow-ips`를 실제 신뢰하는 프록시 주소로만 제한하고, 원본 HTTP 포트는 외부에 열지 않습니다. 앱은 개발 loopback을 제외한 HTTP를 거절합니다.
- 로그인된 사용자를 확인한 **신뢰할 수 있는 백엔드**가 `app.security.issue_access_token(subject, lifetime_seconds=300)`과 같은 계약으로 단기 분석 토큰을 발급합니다. 분석 API에는 공개 토큰 발급 endpoint가 없습니다. 반환 토큰은 `base64url(JSON).base64url(HMAC-SHA256)` 형식이며 `sub`, `iat`, `exp`, `aud=speech-rehab-analysis`를 검증합니다. 최대 수명은 15분입니다. 이는 JWT 형식이 아닙니다.
- Flutter의 `PronunciationAnalysisClient(accessTokenProvider: ...)`에 로그인 세션을 통해 받은 단기 토큰 제공 함수를 연결합니다. 외부 서버에는 토큰 없이는 업로드하지 않습니다. 기존 프로젝트에 로그인·토큰 발급 계층이 없으므로 이 연결은 실제 운영 인프라에서 구성해야 합니다.
- 작업 생성·조회·삭제는 같은 토큰 `sub` 소유자만 가능합니다. 다른 소유자에게는 작업의 존재를 노출하지 않는 404를 반환합니다.

결과는 메모리에만 보관하며 기본 300초 뒤 만료합니다. `PRONUNCIATION_RESULT_TTL_SECONDS`는 30~900초 범위입니다. 접근 시 만료 확인과 30초 간격 정리를 병행하므로 TTL 후 조회는 불가하며 메모리 정리는 최대 30초 더 걸릴 수 있습니다. 서버 종료 시 기록은 사라집니다. 클라이언트는 결과 수신·취소·시간초과 뒤 작업 삭제를 시도합니다. 서버는 삭제·만료된 작업을 후속 분석 완료 시 되살리지 않습니다. 처리 중 취소는 결과 보관을 취소하고, 이미 실행 중인 MFA/오디오 변환은 자체 제한시간까지 마무리한 뒤 임시 파일을 제거합니다.

요청 본문은 multipart 파싱 전에 오디오 20 MiB + 폼 64 KiB로 제한하며, 입력 대기 15초·전체 업로드 30초, 사용자별 업로드 6회/분·조회/삭제 180회/분, 사용자별 진행 작업 1개, 전체 실행 작업 2개, 결과 100개 상한을 적용합니다. 오디오는 20초 이내만 분석합니다. 실제 운영 프록시에도 전체 업로드 시간·본문 크기·연결수 제한을 설정해야 합니다. 메모리 작업·요청 제한 저장소이므로 현재 실행은 **단일 worker**를 사용합니다. 다중 서버 운영에는 공통 작업 저장소와 분산 제한기가 추가로 필요합니다.

클라이언트 `timeout`은 토큰 획득·파일 준비·업로드·poll 전체에 적용됩니다. `requestTimeout`은 개별 연결·전송·수신에 적용되며, `analyze(cancelToken: token)`을 호출한 화면은 이탈·사용자 취소 시 `token.cancel()`할 수 있습니다. 취소된 HTTP 요청이 서버에 이미 도착한 경우 작업 ID를 받지 못할 수 있어 서버 TTL을 함께 사용합니다.

## 점수 비활성화

기존 CTC 구현의 '파일 전체에서 대상 토큰의 최고 프레임 확률 × 100'은 위치 정렬과 발음 정확도 검증이 없으므로 중단했습니다. `PRONUNCIATION_BACKEND=ctc` 또는 `transformers`는 모델을 내려받거나 숫자 점수를 생성하지 않고 `/ready`에 준비되지 않음, 분석 결과에 unavailable을 반환합니다. MFA의 음소 구간 정렬은 그대로 제공하며 점수는 null입니다.

향후 별도의 검증을 마친 채점 backend만 `score_validated=True`를 명시할 수 있습니다. 서버는 그 외 backend의 점수를 제거하고, 클라이언트는 `scoreValidated:true`가 없는 과거 결과도 검증된 점수로 표시하지 않습니다. 이 플래그는 검증 자체를 수행하지 않으며 운영자가 검증 근거 없이 켜서는 안 됩니다.

## 훈련 관리 서버와의 구분

이 발음 분석 서버에는 훈련 열기·닫기 관리 API가 구현되어 있지 않습니다. 앱에는 서명된 리소스 카탈로그의 개별 훈련 정책을 적용하는 구조가 있습니다. [관리 API 설계와 서버 기능별 구현 수준](../../docs/training-availability-and-server.md)에서 구현된 부분과 후속 개발 범위를 확인하세요.

## 자유 문장 분석 서버 (2026-10-02)

MFA 음소 정렬과 별도로 faster-whisper 문장 ASR을 제공한다. `score=null`, 녹음 길이, 저에너지 구간 수, 인식 글과 목표 글의 차이, 정해진 연습 안내를 반환한다. 진단/발음 정확도/긴장도 점수가 아니다.

```bash
cd server/pronunciation_analysis
python3 -m venv .venv
source .venv/bin/activate
pip install -e '.[sentence]'
# 운영자가 신뢰하는 faster-whisper 호환 모델을 미리 설치한다.
# 예: hf download Systran/faster-whisper-tiny --local-dir ./models/whisper-tiny
SENTENCE_WHISPER_MODEL="$PWD/models/whisper-tiny" SENTENCE_DATA_DIR="$PWD/sentence_jobs" uvicorn app.main:app --host 127.0.0.1 --port 8001 --workers 1 --no-access-log
```

앱의 개발 기본 주소는 `http://127.0.0.1:8001`이다. `--dart-define=SENTENCE_ANALYSIS_URL=https://...` 또는 문장 화면의 서버 설정으로 변경한다. 개발 loopback 예외는 릴리스 앱에는 적용하지 않는다. 실제 모바일 기기에서는 HTTPS 서버와 소유자별 단기 토큰이 필요하다. 비밀 서명키는 앱에 넣지 않는다. 토큰 발급/로그인 서비스는 아직 별도이며 입력한 토큰은 앱이 영속 저장하지 않는다.

| 경로 | 구현 |
|---|---|
| GET `/v1/sentence-analysis/capabilities` | 준비 상태, 한국어/영어, 버전, 120초·20MB 한도, 900초 보관 정책 |
| POST `/v1/sentence-analysis/jobs` | multipart `audio,recordingId,assessmentId,sentenceRevisionId,confirmedText,language,audioSha256,analysisVersion,consentPolicyVersion`; `Idempotency-Key` 헤더, 202 작업 ID |
| GET `/v1/sentence-analysis/jobs/{id}` | 해당 소유자의 상태·결과만 반환 |
| DELETE `/v1/sentence-analysis/jobs/{id}` | 반복 안전한 204, 파일/결과 삭제, 늦은 결과 차단 |

`analysisVersion=sentence-v1`, `consentPolicyVersion=sentence-local-v1`, 언어 `ko-KR/en-US`, 오디오 mono 16 kHz PCM16 WAV이다. SQLite 영속 큐는 단일 프로세스에서 재시작 시 진행 중 작업을 재개한다. 음성은 종료/취소 후 삭제하고 작업은 15분에 만료한다. 서버 중단 시 청소는 다음 시작 때 재개한다. 이미 추론 메모리에 올라간 음성은 연산 종료까지 남을 수 있다. 만료 파일과 커밋 전 장애로 남은 오래된 파일도 정리한다. 학습/외부 AI 전송은 하지 않는다. 요청 원문/오디오를 애플리케이션 로그에 쓰지 않는다.

테스트: `python -m unittest discover -s tests -v`. tiny 모델로 한국어/영어 합성 음성의 업로드·추론·결과·삭제 흐름을 확인했으며, 마비말장애 임상 정확도를 검증한 것은 아니다. 실서비스 모델 선택/검증, 관리 UI, 외부 인증 발급, 다중 프로세스 작업 큐는 미구현이다. [앱 설계 및 구현 범위](../../docs/sentence-repeat-and-mouth-video-plan.md).
