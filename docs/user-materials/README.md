# 말이음 · SpeechBridge 문서

[한국어](README.md) | [English](README.en.md) | [전체 문서](../README.md)

> 최신 메뉴 안내 (2026-10-01): **오늘 → 훈련 → 게임 → 기록 → 설정**. [게임과 현재 진입 경로](../game-menu.md)를 참고하세요. 아래 과거 기획·검토 내용은 작성 당시의 맥락을 보존합니다.

| 문서 | 한국어 (기본) | English |
| --- | --- | --- |
| 홍보 문서 | [페이지 열기](https://clevekim00.github.io/mj_dialog/promotion.html) | [About the app](https://clevekim00.github.io/mj_dialog/promotion.en.html) |
| 사용자 가이드 | [페이지 열기](https://clevekim00.github.io/mj_dialog/user-guide.html) | [User guide](https://clevekim00.github.io/mj_dialog/user-guide.en.html) |

`index.html`과 확장 언어 표기가 없는 HTML은 한국어다. 언어는 자동 감지하지 않으며 페이지 위의 언어 링크로 바꾼다. 영문 문서에서 다른 문서를 열면 영문을 유지한다. CSS와 SVG가 각 파일에 포함되어 오프라인에서도 읽고 인쇄할 수 있다.

GitHub Pages는 `.github/workflows/docs-pages.yml`로 이 폴더의 HTML과 `docs/user-guide*.html`의 이전 사용자 가이드만 배포한다. 이전 가이드는 `/archive/`에서 제공한다. 앱·녹음·내부 구현 문서는 배포 폴더에 넣지 않는다. 문서 변경을 main에 푸시하면 자동 재배포한다. GitHub 저장소의 HTML 파일 링크는 소스 보기이므로 외부 안내에는 위 Pages URL을 사용한다.

[구현 기준](../implementation-2026-09-30/README.md). 삽화는 실제 앱 스크린샷이 아니다. 발성 놀이는 MPT 검사가 아니며 신규 검수 영상은 아직 연결되지 않았다.

`readme.html` / `readme.en.html`은 README 두 언어 본문을 포함합니다. 버튼을 누르면 페이지 이동 없이 본문을 전환하며 방향키·Home·End 키를 지원합니다. 각각 한국어·영어로 시작하고, JavaScript가 꺼져 있으면 두 언어를 함께 보여줍니다. README 수정 후 다음 명령으로 갱신합니다:

```bash
python3 -m pip install markdown-it-py==4.2.0
python3 tools/docs/build_readme_page.py
```

[MPT 측정 절차와 제한](../mpt-measurement.md): 최신 가이드와 홍보 페이지에 별도 관찰자 타이머 MPT 모드를 안내한다. 기존 발성 놀이와 구분한다.
