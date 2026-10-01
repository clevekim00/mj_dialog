#!/usr/bin/env python3
"""Render both README editions into a self-contained page with real language tabs."""
from pathlib import Path
import argparse
import base64
from markdown_it import MarkdownIt
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[2]
SITE = ROOT / 'docs/user-materials'
REPO = 'https://github.com/clevekim00/mj_dialog/blob/main/'
CSS = '''
*{box-sizing:border-box}body{margin:0;background:#f5f7f6;color:#203730;font:18px/1.75 system-ui,-apple-system,"Apple SD Gothic Neo",sans-serif}main{max-width:1040px;margin:32px auto;padding:0 24px 64px}.brand{text-align:center;padding:28px 0}.brand img{border-radius:26px;width:112px;height:112px}h1{font-size:32px;margin:12px 0 0}.document{background:white;border:1px solid #d6e0da;border-radius:18px;overflow:hidden}.tabs{display:flex;gap:8px;padding:0 24px;border-bottom:1px solid #d6e0da;background:#f9fbfa}.tabs button{font:inherit;font-weight:650;min-height:60px;padding:12px 24px;border:0;border-bottom:4px solid transparent;background:transparent;color:#61736b;cursor:pointer}.tabs button[aria-selected="true"]{color:#175a43;border-bottom-color:#217756;background:#eaf3ee}.panel{padding:28px 36px}a{color:#16664a;text-underline-offset:4px}a:focus-visible,button:focus-visible,[tabindex]:focus-visible{outline:3px solid #b76515;outline-offset:3px}h2{font-size:27px;line-height:1.4;margin:36px 0 16px;border-bottom:1px solid #e0e7e3;padding-bottom:10px}h3{font-size:21px;line-height:1.5}pre{overflow-x:auto;padding:18px;background:#f1f5f3;border-radius:10px;font-size:14px;line-height:1.6}code{overflow-wrap:anywhere}pre code{overflow-wrap:normal}blockquote{border-left:4px solid #95bbaa;margin:20px 0;padding:8px 18px;background:#f4f8f5}table{border-collapse:collapse;width:100%;font-size:16px}th,td{border:1px solid #d6e0da;padding:10px;text-align:left;overflow-wrap:anywhere}th{background:#edf4ef}li{margin:6px 0}.links{display:flex;flex-wrap:wrap;gap:18px;margin:0 0 26px}.hint{font-size:15px;color:#5c6f65;margin-top:8px}[hidden]{display:none!important}@media(max-width:600px){main{margin:8px auto;padding:0 12px 32px}.panel{padding:18px}.tabs{padding:0 10px}.tabs button{flex:1;padding:12px}h1{font-size:27px}h2{font-size:23px}body{font-size:17px}table{font-size:14px}th,td{padding:7px}}@media(prefers-color-scheme:dark){body{background:#0d1512;color:#e5eee9}.document{background:#15221b;border-color:#354a3d}.tabs,th{background:#1c2d24}.tabs button{color:#becdc4}.tabs button[aria-selected="true"]{background:#243e30;color:#c9f1de;border-color:#79c5a1}a{color:#a0ddbd}pre,blockquote{background:#1d3025}.hint{color:#a9bcb0}th,td,h2,.tabs{border-color:#354a3d}}@media print{.brand{padding:0}.tabs,.links,.hint{display:none}main{margin:0;padding:0}.document{border:0}.panel{padding:0}pre{white-space:pre-wrap}body,.document{background:white;color:black}}
'''
JS = '''
const tabs = [...document.querySelectorAll('[role="tab"]')];
function selectLanguage(language, moveFocus = false) {
  for (const tab of tabs) {
    const selected = tab.dataset.language === language;
    tab.setAttribute('aria-selected', String(selected));
    tab.tabIndex = selected ? 0 : -1;
    document.getElementById(tab.getAttribute('aria-controls')).hidden = !selected;
    if (selected && moveFocus) tab.focus();
  }
  document.documentElement.lang = language;
  document.title = language === 'ko' ? '말이음 · SpeechBridge | 프로젝트 소개' : 'SpeechBridge | Project overview';
  document.getElementById('brand-name').textContent = language === 'ko' ? '말이음 · SpeechBridge' : 'SpeechBridge';
  document.getElementById('app-icon').alt = language === 'ko' ? '말이음 앱 아이콘' : 'SpeechBridge app icon';
  document.getElementById('tab-hint').textContent = language === 'ko' ? '탭을 누르면 페이지 이동 없이 언어가 바뀝니다.' : 'Choose a tab to change language without leaving this page.';
  document.querySelector('[role="tablist"]').setAttribute('aria-label', language === 'ko' ? '문서 언어' : 'Document language');
}
for (const tab of tabs) {
  tab.addEventListener('click', () => selectLanguage(tab.dataset.language));
  tab.addEventListener('keydown', event => {
    let index = tabs.indexOf(tab);
    if (event.key === 'ArrowRight') index = (index + 1) % tabs.length;
    else if (event.key === 'ArrowLeft') index = (index + tabs.length - 1) % tabs.length;
    else if (event.key === 'Home') index = 0;
    else if (event.key === 'End') index = tabs.length - 1;
    else return;
    event.preventDefault();
    selectLanguage(tabs[index].dataset.language, true);
  });
}
'''


def content(language):
    source = ROOT / ('README.md' if language == 'ko' else 'README.en.md')
    text = source.read_text()
    # The README header supplies repository navigation; the page supplies its own tabs.
    text = text[text.index('\n**') + 1:]
    md = MarkdownIt('commonmark', {'html': False}).enable('table')
    tokens = md.parse(text)
    for block in tokens:
        for token in block.children or []:
            if token.type == 'link_open':
                href = token.attrGet('href') or ''
                if not urlsplit(href).scheme and not href.startswith('#'):
                    token.attrSet('href', REPO + href)
    return md.renderer.render(tokens, md.options, {})


def build(language):
    ko = language == 'ko'
    icon = base64.b64encode((ROOT / 'assets/branding/app-icon.png').read_bytes()).decode()
    panels = []
    for lang in ('ko', 'en'):
        selected = lang == language
        english = lang == 'en'
        suffix = '.en' if english else ''
        links = [('About the app' if english else '앱 소개', f'promotion{suffix}.html'),
                 ('User guide' if english else '사용자 가이드', f'user-guide{suffix}.html'),
                 ('All documents' if english else '전체 문서', REPO + f'docs/README{suffix}.md')]
        nav = '<nav class="links">' + ''.join(f'<a href="{href}">{label}</a>' for label, href in links) + '</nav>'
        panels.append(f'<section class="panel" id="panel-{lang}" role="tabpanel" aria-labelledby="tab-{lang}" lang="{lang}" tabindex="0"'+('' if selected else ' hidden')+'>'+nav+content(lang)+'</section>')
    buttons = ''.join(f'<button type="button" role="tab" id="tab-{lang}" data-language="{lang}" aria-controls="panel-{lang}" aria-selected="{str(lang == language).lower()}" tabindex="{0 if lang == language else -1}">{label}</button>' for lang,label in [('ko','한국어'),('en','English')])
    title = '말이음 · SpeechBridge' if ko else 'SpeechBridge'
    hint = '탭을 누르면 페이지 이동 없이 언어가 바뀝니다.' if ko else 'Choose a tab to change language without leaving this page.'
    return f'''<!doctype html>
<html lang="{language}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title} | {'프로젝트 소개' if ko else 'Project overview'}</title><style>{CSS}</style><noscript><style>.panel[hidden]{{display:block!important}}.tabs,.hint{{display:none}}</style></noscript></head><body><main><header class="brand"><img id="app-icon" src="data:image/png;base64,{icon}" alt="{'말이음 앱 아이콘' if ko else 'SpeechBridge app icon'}" width="112" height="112"><h1 id="brand-name">{title}</h1><p class="hint" id="tab-hint">{hint}</p></header><div class="document"><div class="tabs" role="tablist" aria-label="{'문서 언어' if ko else 'Document language'}">{buttons}</div>{''.join(panels)}</div></main><script>{JS}</script></body></html>
'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    for language, name in [('ko','readme.html'),('en','readme.en.html')]:
        path = SITE / name
        output = build(language)
        if args.check:
            if not path.exists() or path.read_text() != output:
                raise SystemExit(f'Outdated: {path.relative_to(ROOT)}; run python3 tools/docs/build_readme_page.py')
        else:
            path.write_text(output)
    print('PASS: both README tab pages are up to date.')


if __name__ == '__main__':
    main()
