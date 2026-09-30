# 발음 콘텐츠 생성 도구

[한국어](README.md) | [English](README.en.md) | [전체 문서](../../docs/README.md)

`generate_core_pack.py`는 앱에 포함되는 한국어 자음 연습 팩을 생성합니다. 단어와 문장 후보는 AI의 도움으로 만들고 구조 검증을 통과한 콘텐츠입니다. 언어재활사의 검수가 끝나기 전에는 임상 검수를 받은 콘텐츠로 표시하면 안 됩니다.

```bash
python3 tools/pronunciation_content/generate_core_pack.py
```

배포할 CDN 주소는 `--download-url`로 지정합니다. 스크립트는 앱 내장 JSON과 SHA-256 검증용 `manifest.json`을 함께 만듭니다. 앱은 `--dart-define=PRONUNCIATION_CONTENT_MANIFEST_URL=https://.../manifest.json` 설정 시 자음 훈련 화면 진입과 수동 새로고침에서 업데이트를 확인합니다.

앱은 `assets/pronunciation/content/ko_consonant_core.json`의 생성된 JSON을 읽습니다. CDN 배포는 같은 스키마와 더 높은 시맨틱 버전을 사용합니다.

버전 `2026.09.2`는 자음별 생활문장 원문을
`korean_daily_sentences.json`에서 읽습니다. 원문 125개를 네 가지 시간 문맥으로
변형해 문장 500개를 만들며, 음절 150개·단어 150개와 합쳐 총 800개입니다.
단어를 임의 조사에 붙이는 이전 템플릿을 제거했습니다. `targetOccurrenceCount`는
한글 표기의 목표 위치 개수이고, 연음 등을 적용한 실제 음향 음소 수가 아닙니다.
모든 항목은 `structural_validation_only_review_required`로 표시합니다.
자연스러움·임상 적합성·시범 음성은 전문가 검수가 별도로 필요합니다.

```bash
python3 -m unittest discover -s tools/pronunciation_content -p 'test_*.py'
```
