# Pronunciation analysis server

성인 후천성 마비말장애 자음 훈련을 위한 별도 FastAPI 서버입니다. 앱의 녹음은 서버에서 16 kHz mono WAV로 정규화되고, 신호 품질 검사를 통과한 경우에만 설정된 CTC 음소 모델로 분석합니다.

```bash
cd server/pronunciation_analysis
python -m venv .venv
source .venv/bin/activate
pip install -e '.[ml,test]'
PRONUNCIATION_MODEL_ID=<validated-korean-phoneme-model> uvicorn app.main:app
```

모델을 설정하지 않으면 서버는 임의 점수를 만들지 않고 `unavailable`을 반환합니다. 운영 전에는 한국어 성인 마비말장애 음성으로 모델·임계값을 별도 검증해야 합니다.

API:

- `POST /v1/analysis/jobs`: audio, text, target_phone, position, content_version, baseline_score(optional)
- `GET /v1/analysis/jobs/{job_id}`
- `DELETE /v1/analysis/jobs/{job_id}`
- `GET /health`, `GET /ready`

테스트: `python -m unittest discover -s tests -v`
