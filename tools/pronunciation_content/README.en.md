# Pronunciation Content Builder

[한국어](README.md) | [English](README.en.md) | [All documents](../../docs/README.en.md)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](../../docs/game-menu.en.md). Earlier plans and reviews below retain their dated context.

`generate_core_pack.py` builds the bundled Korean consonant practice pack. Word and sentence candidates are AI-assisted content that passes structural validation. They must not be represented as clinician-approved until a speech-language pathologist completes the review.

```bash
python3 tools/pronunciation_content/generate_core_pack.py
```

Set the release CDN address with `--download-url`. The script creates both the bundled JSON and a `manifest.json` for SHA-256 verification. With `--dart-define=PRONUNCIATION_CONTENT_MANIFEST_URL=https://.../manifest.json`, the app checks for updates on entry to consonant training and on manual refresh.

The app consumes `assets/pronunciation/content/ko_consonant_core.json`. CDN releases use the same schema with a higher semantic version.

Version `2026.09.2` reads consonant-specific everyday sentence sources from `korean_daily_sentences.json`. It transforms 125 source sentences into four time contexts to create 500 sentences, plus 150 syllables and 150 words, for 800 items total. The previous template attaching words to arbitrary particles was removed. `targetOccurrenceCount` counts target positions in Hangul spelling, not actual acoustic phones after liaison or other rules. Every item is marked `structural_validation_only_review_required`. Naturalness, clinical suitability, and demonstration audio require separate expert review.

```bash
python3 -m unittest discover -s tools/pronunciation_content -p 'test_*.py'
```
