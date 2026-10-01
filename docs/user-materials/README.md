# 말이음 · SpeechBridge 문서

[한국어](README.md) | [English](README.en.md) | [전체 문서](../README.md)

<!-- reader-link --> [언어 탭으로 읽기](https://clevekim00.github.io/mj_dialog/documents/docs/user-materials/README.html)

> 최신 메뉴 안내 (2026-10-01): **오늘 → 훈련 → 게임 → 기록 → 설정**. [게임과 현재 진입 경로](../game-menu.md)를 참고하세요. 아래 과거 기획·검토 내용은 작성 당시의 맥락을 보존합니다.


## 같은 페이지의 언어 탭

모든 Markdown 문서 34종과 그림 문서 3종을 한국어·영어 탭으로 읽는다. 탭을 눌러도 페이지를 새로 불러오지 않으며, 기본 언어는 한국어다. `.en.html` 링크 또는 `?lang=en`으로 들어가면 영어가 먼저 열린다. 링크와 새로고침도 선택한 언어를 유지한다. 키보드 방향키·Home·End로 탭을 바꿀 수 있다.

| 문서 | 한국어 | English |
|---|---|---|
| 프로젝트 소개 | [페이지](https://clevekim00.github.io/mj_dialog/readme.html) | [Page](https://clevekim00.github.io/mj_dialog/readme.en.html) |
| 전체 문서 | [페이지](https://clevekim00.github.io/mj_dialog/documents.html) | [Page](https://clevekim00.github.io/mj_dialog/documents.en.html) |
| ELI5 홍보 문서 | [앱 소개](https://clevekim00.github.io/mj_dialog/promotion.html) | [Introduction](https://clevekim00.github.io/mj_dialog/promotion.en.html) |
| ELI5 사용자 가이드 | [사용법](https://clevekim00.github.io/mj_dialog/user-guide.html) | [Guide](https://clevekim00.github.io/mj_dialog/user-guide.en.html) |

GitHub README는 HTML 스크립트와 스타일을 제한하므로 표지와 웹페이지 이동 링크를 제공한다. 실제 탭은 생성된 문서 사이트에서 동작한다. [GitHub의 렌더링 설명](https://github.com/github/markup#github-markup).

## 작성·검사·배포

Markdown 원본 두 언어를 함께 수정한다. ELI5 삽화 원본은 이 폴더의 `promotion*.html`, `user-guide*.html`이다. `index*.html`은 홍보 원본과 동일하게 유지한다. 읽기 사이트의 첫 화면 `docs/site/index.html`은 프로젝트 소개다. 생성 파일은 직접 편집하지 않는다.

```bash
python3 -m pip install markdown-it-py==4.2.0
python3 tools/docs/build_docs_site.py
python3 tools/docs/check_bilingual_docs.py
python3 tools/docs/check_docs_site.py
python3 tools/docs/build_docs_site.py --check
python3 -m http.server 8765 --bind 127.0.0.1 --directory docs/site
```

`http://127.0.0.1:8765/`에서 확인한다. 기존 `build_readme_page.py` 명령도 전체 문서 사이트 생성으로 연결된다. GitHub Pages 워크플로는 사이트를 생성·검사한 뒤 `docs/site/`만 배포한다. Markdown 링크는 대응 웹페이지로, 이미지·OpenAPI 등 참조 자료는 사이트 파일로 변환한다. 실제 코드 파일의 참조 링크는 GitHub 코드 보기로 유지한다. 공개 배포에는 승인된 커밋·푸시가 필요하다.

오프라인에서는 생성된 `docs/site/` 폴더 전체를 보관하고 `index.html`을 연다. 네트워크 없이 탭·본문·삽화를 읽을 수 있지만 외부 출처 링크는 인터넷이 필요하다. JavaScript가 꺼져 있으면 두 언어 본문을 함께 표시한다. 인쇄/PDF는 선택한 언어를 대상으로 한다. 이전 그림 가이드는 `/archive/`에 남아 있으며 당시 화면 설명을 보존한다.

[MPT 측정 절차와 제한](../mpt-measurement.md) · [현재 훈련 정책](../training-availability-and-server.md). 삽화는 실제 앱 스크린샷이 아니다.
