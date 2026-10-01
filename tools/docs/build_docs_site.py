#!/usr/bin/env python3
"""Build a bilingual static reader for every repository document pair."""
from __future__ import annotations
import argparse
import html
import json
import posixpath
import re
import shutil
from pathlib import Path
from urllib.parse import unquote, urlsplit, urlunsplit
from markdown_it import MarkdownIt
from check_bilingual_docs import inventory, english

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/site'
PUBLIC = 'https://clevekim00.github.io/mj_dialog/'
REPO = 'https://github.com/clevekim00/mj_dialog/blob/main/'
SOURCE_HTML = ['docs/user-materials/promotion.html', 'docs/user-materials/user-guide.html', 'docs/user-guide.html']


def ko_path(path):
    return path.with_name(path.name.replace('.en.', '.', 1))


def route(path):
    original = ko_path(path).relative_to(ROOT).as_posix()
    en = '.en.' in path.name
    special = {'README.md': 'readme.html', 'docs/README.md': 'documents.html',
               'docs/user-materials/promotion.html': 'promotion.html',
               'docs/user-materials/index.html': 'promotion.html',
               'docs/user-materials/user-guide.html': 'user-guide.html',
               'docs/user-materials/readme.html': 'readme.html',
               'docs/user-guide.html': 'archive/user-guide.html'}
    name = special.get(original, 'documents/' + original.removesuffix('.md') + '.html')
    return name.replace('.html', '.en.html') if en else name


def rel(target, page):
    return posixpath.relpath(target, posixpath.dirname(page) or '.')


def slug(text):
    return re.sub(r'[^\w\-\s]', '', text.lower()).replace(' ', '-')


class Builder:
    def __init__(self):
        self.markdown = [p for p in inventory() if p.suffix == '.md']
        self.sources = self.markdown + [ROOT / p for p in SOURCE_HTML] + [english(ROOT / p) for p in SOURCE_HTML]
        self.mapping = {p.resolve(): route(p) for p in self.sources}
        for name in ('index', 'readme'):
            for suffix in ('', '.en'):
                p = ROOT / f'docs/user-materials/{name}{suffix}.html'
                self.mapping[p] = route(p)
        self.outputs: dict[str, bytes] = {}
        self.titles = {}
        for source in self.markdown:
            text = source.read_text()
            match = re.search(r'<h1[^>]*>(.*?)</h1>', text[:1000]) or re.match(r'# (.+)', text)
            self.titles[source] = match.group(1) if match else source.stem

    def link(self, value, source, page, language, framed=False):
        parts = urlsplit(html.unescape(value))
        if parts.scheme or parts.netloc:
            if value.startswith(PUBLIC):
                rest = value[len(PUBLIC):]
                url = urlsplit(rest)
                frag = unquote(url.fragment)
                target_lang = 'en' if '.en.html' in url.path else 'ko'
                if frag and not url.path.startswith(('promotion', 'user-guide', 'archive/')):
                    frag = f'{target_lang}--{frag}'
                return urlunsplit(('', '', rel(url.path, page), url.query, frag))
            return value
        if not parts.path:
            if framed or not parts.fragment:
                return value
            return '#' + language + '--' + unquote(parts.fragment)
        target = (source.parent / unquote(parts.path)).resolve()
        fragment = unquote(parts.fragment)
        if target in self.mapping:
            if fragment and target.suffix == '.md':
                fragment = ('en' if '.en.' in target.name else 'ko') + '--' + fragment
            return urlunsplit(('', '', rel(self.mapping[target], page), parts.query, fragment))
        if target.is_file() and target.is_relative_to(ROOT) and target.suffix.lower() in {'.png', '.jpg', '.jpeg', '.svg', '.webp', '.gif', '.pdf', '.json'}:
            dest = 'files/' + target.relative_to(ROOT).as_posix()
            self.outputs[dest] = target.read_bytes()
            return urlunsplit(('', '', rel(dest, page), parts.query, fragment))
        if target.is_relative_to(ROOT):
            return REPO + target.relative_to(ROOT).as_posix() + (('#' + fragment) if fragment else '')
        raise ValueError(f'Outside-repository link in {source}: {value}')

    def rewrite(self, text, source, page, language, framed=False):
        def attr(match):
            name, quote, value = match.groups()
            value = self.link(value, source, page, language, framed)
            return f'{name}={quote}{html.escape(value, quote=True)}{quote}'
        return re.sub(r'\b(href|src)=([\"\'])(.*?)\2', attr, text)

    def markdown_body(self, source, page, language):
        text = source.read_text()
        if source.parent == ROOT and source.name in ('README.md', 'README.en.md'):
            text = text.split('<!-- document-body -->', 1)[1]
        else:
            text = re.sub(r'^# .+\n', '', text, count=1)
        text = '\n'.join(line for line in text.splitlines()
                         if not ('[한국어](' in line and '[English](' in line and not line.startswith('|'))
                         and '<!-- reader-link -->' not in line)
        md = MarkdownIt('commonmark', {'html': True}).enable('table')
        tokens = md.parse(text)
        seen = set()
        for i, token in enumerate(tokens):
            if token.type == 'heading_open':
                base = slug(tokens[i+1].content)
                candidate, n = base, 0
                while candidate in seen:
                    n += 1
                    candidate = f'{base}-{n}'
                seen.add(candidate)
                token.attrSet('id', f'{language}--{candidate}')
        rendered = md.renderer.render(tokens, md.options, {})
        rendered = self.rewrite(rendered, source, page, language)
        rendered = re.sub(r'<table>(.*?)</table>', r'<div class="table-scroll" tabindex="0"><table>\1</table></div>', rendered, flags=re.S)
        return rendered

    def illustrated_body(self, source, page, language):
        text = source.read_text()
        text = re.sub(r'<nav class="language".*?</nav>', '', text, flags=re.S)
        text = re.sub(r'<link\b[^>]*rel="alternate"[^>]*>', '', text)
        text = self.rewrite(text, source, page, language, framed=True)
        # Local section links stay within the illustration. Other pages open in
        # the surrounding reader rather than nesting another reader in a frame.
        text = re.sub(r'<a\b([^>]*href="(?!#)[^"]+"[^>]*)>', r'<a target="_parent"\1>', text)
        title = '그림으로 보는 문서' if language == 'ko' else 'Illustrated document'
        return f'<iframe class="illustrated" title="{title}" srcdoc="{html.escape(text, quote=True)}" onload="resizeIllustration(this)"></iframe>'

    def build_page(self, original, initial):
        page = route(english(original) if initial == 'en' else original)
        root = original == ROOT / 'README.md'
        titles = {lang: self.titles.get(english(original) if lang == 'en' else original,
                         ('그림으로 보는 앱 소개' if 'promotion' in original.name else '그림으로 보는 사용법') if lang == 'ko' else
                         ('Illustrated app introduction' if 'promotion' in original.name else 'Illustrated user guide')) for lang in ('ko','en')}
        if root:
            titles = {'ko': '프로젝트 소개', 'en': 'Project overview'}
        nav = []
        for target, ko, en in [('readme','프로젝트 소개','Overview'),('documents','전체 문서','All documents'),('promotion','그림으로 보는 앱 소개','Illustrated introduction'),('user-guide','그림으로 보는 사용법','Illustrated guide')]:
            nav.append(f'<a href="{rel(target + (".en" if initial == "en" else "") + ".html", page)}" data-href-ko="{rel(target+".html",page)}" data-href-en="{rel(target+".en.html",page)}" data-ko="{ko}" data-en="{en}">{ko if initial == "ko" else en}</a>')
        panels=[]
        for lang in ('ko','en'):
            source=english(original) if lang == 'en' else original
            body=self.markdown_body(source,page,lang) if source.suffix == '.md' else self.illustrated_body(source,page,lang)
            heading='' if root else f'<h2 class="document-title" id="{lang}--{slug(titles[lang])}">{html.escape(titles[lang])}</h2>'
            panels.append(f'<section role="tabpanel" id="panel-{lang}" aria-labelledby="tab-{lang}" lang="{lang}" tabindex="0" {"hidden" if lang != initial else ""}>{heading}{body}</section>')
        buttons=''.join(f'<button type="button" role="tab" id="tab-{lang}" data-language="{lang}" aria-controls="panel-{lang}" aria-selected="{str(lang == initial).lower()}" tabindex="{0 if lang == initial else -1}">{label}</button>' for lang,label in [('ko','한국어'),('en','English')])
        text=lambda ko,en: ko if initial=='ko' else en
        meta=json.dumps({'titles':titles},ensure_ascii=False).replace('<','\\u003c')
        output=f'''<!doctype html>
<html lang="{initial}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="dark light"><title>{html.escape(titles[initial])} | SpeechBridge</title><link rel="stylesheet" href="{rel('assets/reader.css',page)}"><noscript><style>[role=tabpanel][hidden]{{display:block!important}}.tabs{{display:none}}</style></noscript></head>
<body><a class="skip" href="#reader" data-ko="본문 바로가기" data-en="Skip to content">{text('본문 바로가기','Skip to content')}</a>
<header class="brand {'hero' if root else 'compact'}"><img src="{rel('assets/app-icon.png',page)}" width="128" height="128" alt="SpeechBridge"><h1 data-ko="말이음 · SpeechBridge" data-en="SpeechBridge">{text('말이음 · SpeechBridge','SpeechBridge')}</h1><p class="subtitle" data-ko="성인 후천성 마비말장애를 위한 말하기 재활 연습" data-en="Speech practice for adults with acquired dysarthria">{text('성인 후천성 마비말장애를 위한 말하기 재활 연습','Speech practice for adults with acquired dysarthria')}</p><p class="tagline" data-ko="생활에 필요한 말, 내 속도로 연습해요." data-en="Everyday words, at your own pace.">{text('생활에 필요한 말, 내 속도로 연습해요.','Everyday words, at your own pace.')}</p><div class="badges"><span>Flutter</span><span>한국어 · English</span><span>MIT</span></div></header>
<nav class="site-nav" aria-label="Documents">{''.join(nav)}</nav>
<main id="reader"><div class="reader"><div class="tabs" role="tablist" aria-label="{text('문서 언어','Document language')}">{buttons}</div>{''.join(panels)}</div><footer><span data-ko="탭을 누르면 같은 페이지에서 언어가 바뀝니다." data-en="Choose a tab to change language on this page.">{text('탭을 누르면 같은 페이지에서 언어가 바뀝니다.','Choose a tab to change language on this page.')}</span><button type="button" onclick="printDocument()" data-ko="인쇄 / PDF 저장" data-en="Print / Save PDF">{text('인쇄 / PDF 저장','Print / Save PDF')}</button></footer></main>
<script type="application/json" id="page-meta">{meta}</script><script src="{rel('assets/reader.js',page)}"></script></body></html>'''
        self.outputs[page]=output.encode()

    def build(self):
        for source in self.sources:
            if '.en.' not in source.name:
                for lang in ('ko','en'):
                    self.build_page(source,lang)
        self.outputs['index.html']=self.outputs['readme.html']
        self.outputs['index.en.html']=self.outputs['readme.en.html']
        self.outputs['assets/app-icon.png']=(ROOT/'assets/branding/app-icon.png').read_bytes()
        for name in ('reader.css','reader.js'):
            self.outputs['assets/'+name]=(ROOT/'tools/docs'/name).read_bytes()
        self.outputs['.nojekyll']=b''
        return self.outputs


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    outputs=Builder().build()
    if args.check:
        for name,data in outputs.items():
            p=OUT/name
            if not p.exists() or p.read_bytes()!=data:
                raise SystemExit(f'Outdated {p}; run python3 tools/docs/build_docs_site.py')
        existing={p.relative_to(OUT).as_posix() for p in OUT.rglob('*') if p.is_file()}
        if existing != set(outputs): raise SystemExit('Unexpected files in generated site; rebuild')
    else:
        if OUT.exists(): shutil.rmtree(OUT)
        for name,data in outputs.items():
            p=OUT/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    # Keep the previous local README entry paths usable without maintaining a
    # second renderer. They reference the same generated site resources/pages.
    for name in ('readme.html', 'readme.en.html'):
        text = outputs[name].decode()
        def local_entry(match):
            attr, quote, value = match.groups()
            if not urlsplit(value).scheme and not value.startswith('#'):
                value = '../site/' + value
            return f'{attr}={quote}{value}{quote}'
        text = re.sub(r'\b(href|src|data-href-ko|data-href-en)=([\"\'])(.*?)\2', local_entry, text)
        path = ROOT / 'docs/user-materials' / name
        if args.check:
            if path.read_text() != text: raise SystemExit(f'Outdated {path}')
        else:
            path.write_text(text)
    print(f'PASS: generated reader covers {len(outputs)} files, all document pairs and illustrated pages.')

if __name__=='__main__':main()
