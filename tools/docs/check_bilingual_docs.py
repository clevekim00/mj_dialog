#!/usr/bin/env python3
"""Check bilingual document coverage and navigation using only the standard library."""
from __future__ import annotations

from html.parser import HTMLParser
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[2]
INDEX = ROOT / 'docs/README.md'
ERRORS: list[str] = []


def fail(path: Path, message: str) -> None:
    ERRORS.append(f'{path.relative_to(ROOT)}: {message}')


def inventory() -> list[Path]:
    result = subprocess.run(
        ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'],
        cwd=ROOT, check=True, capture_output=True,
    )
    return sorted({ROOT / name.decode() for name in result.stdout.split(b'\0') if name})


def english(path: Path) -> Path:
    return path.with_name(path.stem + '.en' + path.suffix)


def strip_code(text: str) -> str:
    return re.sub(r'^```[^\n]*\n.*?^```\s*$', '', text, flags=re.M | re.S)


def md_links(text: str) -> list[str]:
    return re.findall(r'!?\[[^\]\n]*\]\(([^\s)]+)\)', strip_code(text))


def heading_ids(text: str) -> set[str]:
    found: set[str] = set()
    for heading in re.findall(r'^#{1,6}\s+(.+?)\s*#*$', strip_code(text), re.M):
        slug = re.sub(r'[^\w\-\s]', '', heading.lower()).replace(' ', '-')
        candidate, index = slug, 0
        while candidate in found:
            index += 1
            candidate = f'{slug}-{index}'
        found.add(candidate)
    return found


class Page(HTMLParser):
    def __init__(self, text: str) -> None:
        super().__init__()
        self.language = ''
        self.links: list[str] = []
        self.ids: set[str] = set()
        self.duplicates: set[str] = set()
        self.feed(text)

    def handle_starttag(self, tag: str, attributes: list[tuple[str, str | None]]) -> None:
        attrs = dict(attributes)
        if tag == 'html':
            self.language = attrs.get('lang') or ''
        if attrs.get('id'):
            identifier = attrs['id']
            if identifier in self.ids:
                self.duplicates.add(identifier)
            self.ids.add(identifier)
        for key in ('href', 'src'):
            if attrs.get(key):
                self.links.append(attrs[key])


def check_link(source: Path, href: str) -> None:
    parts = urlsplit(href)
    if parts.scheme or parts.netloc:
        return  # Network availability is checked separately after publishing.
    target = (source.parent / unquote(parts.path)).resolve() if parts.path else source
    if not target.exists():
        fail(source, f'missing local target: {href}')
        return
    if not parts.fragment:
        return
    fragment = unquote(parts.fragment)
    if target.suffix == '.md':
        if fragment not in heading_ids(target.read_text()):
            fail(source, f'missing Markdown anchor: {href}')
    elif target.suffix == '.html':
        if fragment not in Page(target.read_text()).ids:
            fail(source, f'missing HTML anchor: {href}')
    # Source-code line references are historical evidence, not current-line assertions.


def main() -> int:
    files = inventory()
    markdown = [p for p in files if p.suffix == '.md']
    originals = [p for p in markdown if not p.name.endswith('.en.md')]
    pages = [p for p in files if p.suffix == '.html' and p.is_relative_to(ROOT / 'docs')]
    html_originals = [p for p in pages if not p.name.endswith('.en.html')]
    for collection in (markdown, pages):
        for path in collection:
            if '.en.' in path.name:
                original = path.with_name(path.name.replace('.en.', '.', 1))
                if original not in collection:
                    fail(path, 'English edition has no Korean counterpart')
    for path in originals + html_originals:
        if english(path) not in files:
            fail(path, 'English edition is missing')
    for path in markdown:
        text = path.read_text()
        if not text.startswith('# '):
            fail(path, 'missing document title')
        if len(re.findall(r'^```', text, re.M)) % 2:
            fail(path, 'unclosed code fence')
        if re.search(r'@@\w+@@', text):
            fail(path, 'unresolved translation placeholder')
        ko = path.with_name(path.name.replace('.en.md', '.md'))
        for label, target in [('한국어', ko.name), ('English', english(ko).name)]:
            if f'[{label}]({target})' not in '\n'.join(text.splitlines()[:20]):
                fail(path, f'missing top language link: {label}')
        for href in md_links(text) + Page(strip_code(text)).links:
            check_link(path, href)
    for index in (INDEX, english(INDEX)):
        if not index.exists():
            fail(index, 'index is missing')
            continue
        targets = {(index.parent / urlsplit(href).path).resolve()
                   for href in md_links(index.read_text()) if not urlsplit(href).scheme}
        for path in markdown:
            if path.resolve() not in targets:
                fail(index, f'document missing from index: {path.relative_to(ROOT)}')
    for path in pages:
        page = Page(path.read_text())
        expected = 'en' if path.name.endswith('.en.html') else 'ko'
        if page.language != expected:
            fail(path, f'expected html lang={expected}')
        if page.duplicates:
            fail(path, f'duplicate element IDs: {sorted(page.duplicates)}')
        if not any(href.endswith('.en.html') for href in page.links):
            fail(path, 'missing English navigation')
        if not any(href.endswith('.html') and not href.endswith('.en.html') for href in page.links):
            fail(path, 'missing Korean navigation')
        for href in page.links:
            check_link(path, href)
    for suffix in ('', '.en'):
        landing = ROOT / f'docs/user-materials/index{suffix}.html'
        promotion = ROOT / f'docs/user-materials/promotion{suffix}.html'
        if landing.read_bytes() != promotion.read_bytes():
            fail(landing, 'landing alias differs from promotion page')
    if ERRORS:
        print('\n'.join(ERRORS), file=sys.stderr)
        return 1
    print(f'PASS: {len(originals)} Markdown pairs, {len(html_originals)} HTML pairs; '
          'language navigation, indexes, local links, anchors, and landing aliases verified.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
