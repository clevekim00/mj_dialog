#!/usr/bin/env python3
"""Validate generated reader links, embedded illustrations, IDs and tab contracts."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit, unquote
import json

ROOT=Path(__file__).resolve().parents[2]/'docs/site'
class Page(HTMLParser):
    def __init__(self,text):
        super().__init__();self.ids=set();self.duplicates=[];self.links=[];self.frames=[];self.tabs=[];self.panels=[];self.lang='';self.feed(text)
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=='html':self.lang=a.get('lang','')
        if a.get('id'):
            if a['id'] in self.ids:self.duplicates.append(a['id'])
            self.ids.add(a['id'])
        for key in ('href','src'):
            if a.get(key):self.links.append(a[key])
        if tag=='iframe' and a.get('srcdoc'):self.frames.append(Page(a['srcdoc']))
        if a.get('role')=='tab':self.tabs.append(a)
        if a.get('role')=='tabpanel':self.panels.append(a)

def main():
    pages={p:Page(p.read_text()) for p in ROOT.rglob('*.html')};errors=[]
    def check_links(source,page,frame=False):
        for href in page.links:
            u=urlsplit(href)
            if u.scheme or u.netloc:
                if 'github.com/clevekim00/mj_dialog/blob/main/' in href and u.path.endswith('.md'):
                    errors.append(f'{source}: Markdown source exposed: {href}')
                continue
            target=(source.parent/unquote(u.path)).resolve() if u.path else source
            if not target.is_relative_to(ROOT):errors.append(f'{source}: escapes site: {href}');continue
            if not target.exists():errors.append(f'{source}: missing {href}');continue
            if u.fragment and target.suffix=='.html':
                target_page=page if frame and not u.path else pages[target]
                ids=target_page.ids | set().union(*(f.ids for f in target_page.frames))
                if unquote(u.fragment) not in ids:errors.append(f'{source}: missing anchor {href}')
        for child in page.frames:check_links(source,child,True)
    for path,page in pages.items():
        if page.duplicates:errors.append(f'{path}: duplicate IDs {page.duplicates}')
        if len(page.tabs)!=2 or len(page.panels)!=2:errors.append(f'{path}: expected two tabs/panels')
        expected='en' if path.name.endswith('.en.html') else 'ko'
        if page.lang!=expected:errors.append(f'{path}: wrong default language')
        selected=[t for t in page.tabs if t.get('aria-selected')=='true']
        if len(selected)!=1 or selected[0].get('data-language')!=expected:errors.append(f'{path}: wrong selected tab')
        if {t.get('aria-controls') for t in page.tabs}!={p.get('id') for p in page.panels}:errors.append(f'{path}: invalid tab relationships')
        if sum('hidden' not in p for p in page.panels)!=1:errors.append(f'{path}: multiple visible panels')
        check_links(path,page)
    if errors:raise SystemExit('\n'.join(errors))
    print(f'PASS: {len(pages)} reader pages, both tabs, all links/assets/anchors and embedded illustrations.')
if __name__=='__main__':main()
