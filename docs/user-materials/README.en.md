# Malieum · SpeechBridge Documents

[한국어](README.md) | [English](README.en.md) | [All documents](../README.en.md)

<!-- reader-link --> [Read with language tabs](https://clevekim00.github.io/mj_dialog/documents/docs/user-materials/README.en.html)

> Current navigation (2026-10-01): **Today → Training → Games → Records → Settings**. See [Games and current entry points](../game-menu.en.md). Earlier plans and reviews below retain their dated context.


## Language tabs on the same page

Read all 34 Markdown document pairs and three illustrated document pairs through Korean/English tabs. Switching tabs does not reload the page. Korean is the default; `.en.html` links or `?lang=en` start in English. Links and reloads preserve the selected language. Arrow keys, Home and End move between tabs.

| Document | Korean | English |
|---|---|---|
| Project overview | [페이지](https://clevekim00.github.io/mj_dialog/readme.html) | [Page](https://clevekim00.github.io/mj_dialog/readme.en.html) |
| All documents | [페이지](https://clevekim00.github.io/mj_dialog/documents.html) | [Page](https://clevekim00.github.io/mj_dialog/documents.en.html) |
| ELI5 promotional document | [앱 소개](https://clevekim00.github.io/mj_dialog/promotion.html) | [Introduction](https://clevekim00.github.io/mj_dialog/promotion.en.html) |
| ELI5 user guide | [사용법](https://clevekim00.github.io/mj_dialog/user-guide.html) | [Guide](https://clevekim00.github.io/mj_dialog/user-guide.en.html) |

GitHub README restricts HTML scripts and styling, so it provides a cover and links to the reader. Interactive tabs run in the generated site. [GitHub rendering pipeline](https://github.com/github/markup#github-markup).

## Authoring, validation and publishing

Edit both Markdown source editions together. ELI5 illustration sources are `promotion*.html` and `user-guide*.html` in this directory. Keep source `index*.html` identical to the promotional sources. The generated site's `docs/site/index.html` is the project overview. Do not edit generated pages directly.

```bash
python3 -m pip install markdown-it-py==4.2.0
python3 tools/docs/build_docs_site.py
python3 tools/docs/check_bilingual_docs.py
python3 tools/docs/check_docs_site.py
python3 tools/docs/build_docs_site.py --check
python3 -m http.server 8765 --bind 127.0.0.1 --directory docs/site
```

Preview at `http://127.0.0.1:8765/`. The existing `build_readme_page.py` command now builds the full site too. GitHub Pages generates and checks the site, then deploys only `docs/site/`. Markdown links become reader links; referenced images and OpenAPI files are copied into the site. Actual source-code references remain GitHub code links. Public deployment requires an authorized commit/push.

For offline reading, retain the complete generated `docs/site/` folder and open `index.html`. Tabs, text and illustrations work offline; external references still require a connection. With JavaScript disabled, both language editions are shown. Printing/PDF targets the selected language. The earlier illustrated guide remains under `/archive/`, preserving its historical screen descriptions.

[MPT procedure and limitations](../mpt-measurement.en.md) · [Current training policy](../training-availability-and-server.en.md). Illustrations are not app screenshots.
