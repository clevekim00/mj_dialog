# Malieum · SpeechBridge Documents

[한국어](README.md) | [English](README.en.md) | [All documents](../README.en.md)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](../game-menu.en.md). Earlier plans and reviews below retain their dated context.

| Document | Korean (default) | English |
| --- | --- | --- |
| Promotional document | [Open page](https://clevekim00.github.io/mj_dialog/promotion.html) | [About the app](https://clevekim00.github.io/mj_dialog/promotion.en.html) |
| User guide | [Open page](https://clevekim00.github.io/mj_dialog/user-guide.html) | [User guide](https://clevekim00.github.io/mj_dialog/user-guide.en.html) |

`index.html` and HTML filenames without a language suffix are Korean. Language is not auto-detected; use the links at the top. Links between English documents stay in English. Each file includes CSS and SVG, so it can be read and printed offline.

GitHub Pages deploys this folder's HTML and the archived user guides from `docs/user-guide*.html` (under `/archive/`) through `.github/workflows/docs-pages.yml`. Do not put app files, recordings, or internal implementation documents in the deployment folder. Pushing document changes to main automatically redeploys. GitHub repository HTML links show source, so use the Pages URLs above for external instructions.

[Implementation basis](../implementation-2026-09-30/README.en.md). Illustrations are not app screenshots. Voice play is not an MPT test; newly reviewed demonstration videos are not yet connected.

The `readme.html` / `readme.en.html` pages contain both README editions. Their buttons switch panels in place, support arrow/Home/End keys, and default to Korean or English respectively. With JavaScript disabled, both editions remain readable. Regenerate after editing either README:

```bash
python3 -m pip install markdown-it-py==4.2.0
python3 tools/docs/build_readme_page.py
```

[MPT procedure and limitations](../mpt-measurement.en.md): the current guide and promotional page include a separate observer-timed MPT mode. Voice play remains distinct.
