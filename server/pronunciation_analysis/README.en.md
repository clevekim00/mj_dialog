# Pronunciation Analysis Server

[한국어](README.md) | [English](README.en.md) | [All documents](../../docs/README.en.md)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](../../docs/game-menu.en.md). Earlier plans and reviews below retain their dated context.

A separate FastAPI server for consonant training for adults with acquired dysarthria. App recordings are normalized to 16 kHz mono WAV. When signal-quality checks pass, a Montreal Forced Aligner (MFA) model matching the request's `language` aligns target text and phoneme intervals.

## Install Korean and English MFA

```bash
cd server/pronunciation_analysis
conda env create -f environment-mfa.yml
conda activate speech-rehab-mfa
bash scripts/setup_korean_mfa.sh
PRONUNCIATION_BACKEND=mfa uvicorn app.main:app
```

`PRONUNCIATION_BACKEND=mfa` is the default. Korean models can be changed with `MFA_DICTIONARY`, `MFA_ACOUSTIC_MODEL`, and `MFA_MODEL_REVISION`; English models with `MFA_EN_US_DICTIONARY`, `MFA_EN_US_ACOUSTIC_MODEL`, and `MFA_EN_US_MODEL_REVISION`. Shared settings are `MFA_COMMAND` and `MFA_TIMEOUT_SECONDS`. `/ready` returns readiness separately for `ko-KR` and `en-US`.

MFA is a forced aligner, not a pronunciation-accuracy scorer. The API returns target-phone start/end times and actual MFA labels, while keeping `practiceScore` and `gop` as `null`. Production scores require an additional CTC/GoP model validated on adult dysarthria data in each language.

The experimental CTC backend is disabled to prevent unvalidated scoring. See the scoring policy below.

API:

- `POST /v1/analysis/jobs`: audio, text, language, target_phone, position, target_occurrence(optional), content_version, baseline_score(optional)
- `GET /v1/analysis/jobs/{job_id}`
- `DELETE /v1/analysis/jobs/{job_id}`
- `GET /health`, `GET /ready`

Tests: `python -m unittest discover -s tests -v`

Development details: [`../../docs/korean-mfa-analysis-api-development.en.md`](../../docs/korean-mfa-analysis-api-development.en.md)

## Connection, authentication, and retention policy (2026-09)

Run development with `uvicorn app.main:app --host 127.0.0.1 --workers 1`. Under the default `PRONUNCIATION_ENV=development`, only loopback clients can use the analysis API, and requests containing proxy-forwarding headers are rejected. Direct remote access to this development server from physical mobile devices is not allowed.

Production connections require all of the following. These repository changes do not deploy an external server or create a user-authentication service.

- Inject `PRONUNCIATION_ENV=production` and a sufficiently random `PRONUNCIATION_AUTH_SECRET` of at least 32 bytes from the server's secret store. Never put the signing secret in the app, Git, or `--dart-define`.
- Set the app's `PRONUNCIATION_ANALYSIS_URL` to a TLS URL. Behind a TLS proxy, restrict Uvicorn's `--forwarded-allow-ips` to actual trusted proxy addresses and do not expose the origin HTTP port publicly. The app rejects HTTP except for development loopback.
- A **trusted backend** verifies the signed-in user and issues a short-lived analysis token under a contract such as `app.security.issue_access_token(subject, lifetime_seconds=300)`. The analysis API has no public token-issuing endpoint. Tokens use `base64url(JSON).base64url(HMAC-SHA256)` and validate `sub`, `iat`, `exp`, and `aud=speech-rehab-analysis`. Maximum lifetime is 15 minutes. This is not JWT format.
- Connect a short-lived token provider obtained through the login session to Flutter's `PronunciationAnalysisClient(accessTokenProvider: ...)`. Do not upload to external servers without a token. The existing project has no login/token-issuance layer, so this integration must be configured in real production infrastructure.
- Only the same token `sub` owner can create, read, or delete a job. Other owners receive 404, without disclosure that a job exists.

Results are held only in memory and expire after 300 seconds by default. `PRONUNCIATION_RESULT_TTL_SECONDS` accepts 30–900 seconds. Expiry is checked on access and cleanup runs every 30 seconds: results cannot be read after TTL, but memory cleanup can take up to 30 seconds longer. Records disappear on server shutdown. The client attempts job deletion after receiving results, cancellation, or timeout. The server never revives deleted/expired jobs when later analysis finishes. Cancelling an active job cancels result retention; already-running MFA/audio conversion finishes within its own timeout and then removes temporary files.

Before multipart parsing, the request body is limited to 20 MiB of audio plus 64 KiB of form data. Limits are: 15-second input wait, 30-second total upload, 6 uploads/minute/user, 180 reads/deletes/minute/user, one active job/user, two executing jobs overall, and at most 100 results. Only audio of up to 20 seconds is analyzed. Production proxies must also limit total upload time, body size, and connection count. Because jobs and rate limits are stored in memory, run with **one worker**. Multiple servers require a shared job store and distributed rate limiter.

Client `timeout` covers token acquisition, file preparation, upload, and polling. `requestTimeout` applies to each connection/send/receive operation. Screens calling `analyze(cancelToken: token)` may call `token.cancel()` on exit or user cancellation. If a cancelled HTTP request already reached the server, the client may not receive its job ID; server TTL is therefore also required.

## Scoring disabled

The former CTC implementation used “maximum target-token frame probability over the entire file × 100.” It was stopped because it lacked position alignment and pronunciation-accuracy validation. `PRONUNCIATION_BACKEND=ctc` or `transformers` downloads no model and generates no numerical score; `/ready` reports not ready and analysis returns unavailable. MFA phoneme alignment remains available with null scores.

Only a separately validated future scoring backend may explicitly declare `score_validated=True`. The server removes scores from other backends, and the client does not present older results lacking `scoreValidated:true` as validated scores. This flag does not perform validation itself and must not be enabled without supporting evidence.

## Training management

This analysis server does not implement training availability administration. The app supports per-exercise policies in signed resource catalogs. See [the management API design and server capability inventory](../../docs/training-availability-and-server.en.md) for implemented versus planned functionality.
