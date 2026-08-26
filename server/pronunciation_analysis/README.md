# Pronunciation analysis server

성인 후천성 마비말장애 자음 훈련을 위한 별도 FastAPI 서버입니다. 앱의 녹음은 서버에서 16 kHz mono WAV로 정규화되고, 신호 품질 검사를 통과한 경우 한국어 Montreal Forced Aligner(MFA)로 목표 문장과 음소 구간을 정렬합니다.

## 한국어 MFA 설치

```bash
cd server/pronunciation_analysis
conda env create -f environment-mfa.yml
conda activate speech-rehab-mfa
bash scripts/setup_korean_mfa.sh
PRONUNCIATION_BACKEND=mfa uvicorn app.main:app
```

`PRONUNCIATION_BACKEND=mfa`가 기본값입니다. `MFA_COMMAND`, `MFA_DICTIONARY`, `MFA_ACOUSTIC_MODEL`, `MFA_MODEL_REVISION`, `MFA_TIMEOUT_SECONDS`로 설치 경로와 모델을 바꿀 수 있습니다. `/ready`에서 MFA 실행 파일 탐지 상태를 확인할 수 있습니다.

MFA는 강제 정렬기이며 발음 정확도 채점기가 아닙니다. API는 목표 음소의 시작·종료 시각과 실제 MFA phone label을 반환하지만 `practiceScore`와 `gop`는 `null`로 유지합니다. 운영 점수는 한국어 성인 마비말장애 데이터로 검증된 CTC/GoP 모델을 추가한 뒤 제공해야 합니다.

기존 CTC 백엔드는 다음처럼 선택할 수 있습니다.

```bash
pip install -e '.[ml,test]'
PRONUNCIATION_BACKEND=ctc \
PRONUNCIATION_MODEL_ID=<validated-korean-phoneme-model> \
uvicorn app.main:app
```

API:

- `POST /v1/analysis/jobs`: audio, text, target_phone, position, content_version, baseline_score(optional)
- `GET /v1/analysis/jobs/{job_id}`
- `DELETE /v1/analysis/jobs/{job_id}`
- `GET /health`, `GET /ready`

테스트: `python -m unittest discover -s tests -v`

상세 개발 내역: [`../../docs/korean-mfa-analysis-api-development.md`](../../docs/korean-mfa-analysis-api-development.md)
