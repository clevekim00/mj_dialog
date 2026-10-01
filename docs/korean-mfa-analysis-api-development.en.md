# Korean MFA Pronunciation Analysis API Development

[한국어](korean-mfa-analysis-api-development.md) | [English](korean-mfa-analysis-api-development.en.md) | [All documents](README.en.md)

<!-- reader-link --> [Read with language tabs](https://clevekim00.github.io/mj_dialog/documents/docs/korean-mfa-analysis-api-development.en.html)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](game-menu.en.md). Earlier plans and reviews below retain their dated context.

Date: 2026-08-26
Target: repeated consonant practice for adults with acquired dysarthria.

## 1. Implementation result

Added a Korean Montreal Forced Aligner (MFA) backend to the existing FastAPI analysis server. It aligns the submitted recording and target text with `mfa align_one`, finds the target onset/coda intervals in the generated Praat TextGrid `phones` tier, and returns them through the API.

The default backend is `mfa`. If MFA or its models are missing, the server still starts and only analysis jobs finish with an explicit `unavailable` result. The earlier Transformers CTC backend remains selectable with `PRONUNCIATION_BACKEND=ctc`.

## 2. Processing flow

1. Flutter sends the recording, target text, target phone, and onset/coda position.
2. The server normalizes audio to 16 kHz mono PCM WAV.
3. Check duration, level, and clipping ratio.
4. Create a temporary `.lab` transcript and run `mfa align_one`.
5. Parse the TextGrid `phones` tier.
6. Compare internal phone IDs with the Korean MFA IPA phone set.
7. Return all matching target-phone intervals in milliseconds.
8. Delete temporary audio, transcript, and TextGrid files when the job ends.

## 3. Target phone mapping

Separate the app's simple phone IDs from IPA labels in the Korean MFA dictionary. Examples:

| Target | Position | Korean MFA candidates |
|---|---|---|
| `k` | onset | `k`, `ɡ` |
| `kk` | onset | `k͈` |
| `s` | onset | `s`, `sʰ`, `ɕʰ` |
| `j` | onset | `tɕ`, `dʑ` |
| `kf` | coda | `k̚` |
| `tf` | coda | `t̚` |
| `pf` | coda | `p̚` |
| `ngf` | coda | `ŋ` |

The full mapping is `KOREAN_MFA_PHONE_MAP` in `app/mfa_backend.py`. Update it together with contract tests when the model dictionary revision changes.

## 4. API response contract

Example of successful MFA alignment:

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

The example's message says that phoneme alignment is complete and accuracy scores will be provided after connecting a CTC/GoP model.

Flutter's `practiceScore` and `gop` fields are now nullable. If intervals exist without scores, the UI shows “Phoneme alignment complete” and the time range.

## 5. Installation and execution

MFA has Kaldi-based native dependencies, so installation is based on conda-forge rather than a plain pip environment.

```bash
cd server/pronunciation_analysis
conda env create -f environment-mfa.yml
conda activate speech-rehab-mfa
bash scripts/setup_korean_mfa.sh
PRONUNCIATION_BACKEND=mfa uvicorn app.main:app
```

Check readiness:

```bash
curl http://127.0.0.1:8000/ready
```

Connect the app:

```bash
flutter run --dart-define=PRONUNCIATION_ANALYSIS_URL=http://127.0.0.1:8000
```

## 6. Safety and failure handling

- Execute MFA with an argument array, not a shell string.
- Use a separate MFA `--temporary_directory` per request to prevent collisions between concurrent analyses.
- Limit uploads to 20 MB.
- Default MFA execution timeout: 45 seconds.
- Limit error-output length and remove job paths.
- Reject corrupt, silent, too-short, or too-long audio before MFA.
- Do not invent a score if no target mapping or TextGrid interval is found.

## 7. Validation scope and limitations

The Korean MFA model is a forced aligner intended for ordinary Korean read speech. It is not a clinical judge of dysarthric pronunciation accuracy, and TextGrid contains no posterior or GoP scores. Successful alignment must not be interpreted as correct pronunciation.

The next step is to apply Korean phoneme CTC posteriors to MFA intervals and calibrate GoP scores and thresholds against clinician-rated adult dysarthric speech. Keep personal baselines separate when the model revision changes.

## 8. Additional tests

- Parse TextGrid words/phones tiers.
- Map onset IPA variants.
- Map representative unreleased codas.
- Report missing MFA installation.
- Verify the nullable-score contract of the MFA API.
- Run regression tests for the earlier CTC-score API.
