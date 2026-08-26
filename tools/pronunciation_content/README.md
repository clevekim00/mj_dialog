# Pronunciation content builder

`generate_core_pack.py` builds the bundled Korean consonant practice pack. The
word and sentence candidates are AI-assisted content that passes structural
validation, but it must not be represented as clinician-approved until a
speech-language pathologist completes the review.

```bash
python3 tools/pronunciation_content/generate_core_pack.py
```

배포할 CDN 주소는 `--download-url`로 지정합니다. 스크립트는 앱 내장 JSON과 SHA-256 검증용 `manifest.json`을 함께 만듭니다. 앱은 `--dart-define=PRONUNCIATION_CONTENT_MANIFEST_URL=https://.../manifest.json` 설정 시 자음 훈련 화면 진입과 수동 새로고침에서 업데이트를 확인합니다.

The app consumes the generated JSON from
`assets/pronunciation/content/ko_consonant_core.json`. CDN releases use the
same schema and a higher semantic version.
