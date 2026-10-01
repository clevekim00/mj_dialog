'use strict';
const tabs = [...document.querySelectorAll('[role="tab"]')];
const metadata = JSON.parse(document.getElementById('page-meta').textContent);
function resizeIllustration(frame) {
  if (!frame || frame.closest('[hidden]')) return;
  const doc = frame.contentDocument;
  if (!doc || !doc.body) return;
  const style = frame.contentWindow.getComputedStyle(doc.body);
  const height = doc.body.getBoundingClientRect().height +
    (parseFloat(style.marginTop) || 0) + (parseFloat(style.marginBottom) || 0);
  frame.style.height = `${Math.ceil(height) + 8}px`;
}
window.resizeIllustration = resizeIllustration;
function selectLanguage(language, focus = false, updateUrl = true) {
  if (!['ko', 'en'].includes(language)) language = 'ko';
  for (const tab of tabs) {
    const selected = tab.dataset.language === language;
    tab.setAttribute('aria-selected', String(selected));
    tab.tabIndex = selected ? 0 : -1;
    document.getElementById(tab.getAttribute('aria-controls')).hidden = !selected;
    if (selected && focus) tab.focus();
  }
  document.documentElement.lang = language;
  document.title = `${metadata.titles[language]} | SpeechBridge`;
  for (const node of document.querySelectorAll('[data-ko][data-en]')) node.textContent = node.dataset[language];
  for (const node of document.querySelectorAll('[data-href-ko]')) node.href = node.dataset[language === 'en' ? 'hrefEn' : 'hrefKo'];
  document.querySelector('[role="tablist"]').setAttribute('aria-label', language === 'ko' ? '문서 언어' : 'Document language');
  document.querySelector('.site-nav').setAttribute('aria-label', language === 'ko' ? '문서 바로가기' : 'Document navigation');
  if (updateUrl) {
    const url = new URL(location.href);
    url.searchParams.set('lang', language);
    if (url.hash) url.hash = '';
    try { history.replaceState(null, '', url); } catch (_) { /* file:// readers may restrict history */ }
  }
  requestAnimationFrame(() => {
    document.querySelectorAll(`#panel-${language} iframe`).forEach(resizeIllustration);
    if (updateUrl) document.querySelector('.reader').scrollIntoView({block: 'start'});
  });
}
function followHash() {
  const id = decodeURIComponent(location.hash.slice(1));
  if (!id) return;
  let target = document.getElementById(id);
  if (!target) target = document.getElementById(`${document.documentElement.lang}--${id}`);
  if (target) {
    const panel = target.closest('[role="tabpanel"]');
    if (panel) selectLanguage(panel.lang, false, false);
    target.scrollIntoView();
    return;
  }
  // Preserve older public illustrated-page anchors such as #mpt and #games.
  const frame = document.querySelector('[role="tabpanel"]:not([hidden]) iframe');
  const inner = frame?.contentDocument?.getElementById(id);
  if (inner) {
    resizeIllustration(frame);
    window.scrollTo(0, window.scrollY + frame.getBoundingClientRect().top + inner.getBoundingClientRect().top - 80);
  }
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
for (const frame of document.querySelectorAll('iframe')) {
  frame.addEventListener('load', () => {
    resizeIllustration(frame);
    followHash();
    frame.contentDocument?.fonts.ready.then(() => resizeIllustration(frame));
  });
}
window.addEventListener('resize', () => document.querySelectorAll('iframe').forEach(resizeIllustration));
window.addEventListener('hashchange', followHash);
window.addEventListener('popstate', () => {
  selectLanguage(new URL(location.href).searchParams.get('lang') || document.documentElement.lang, false, false);
  followHash();
});
selectLanguage(new URL(location.href).searchParams.get('lang') || document.documentElement.lang, false, false);
followHash();

function printDocument() {
  const frame = document.querySelector('[role="tabpanel"]:not([hidden]) iframe');
  if (frame?.contentWindow) frame.contentWindow.print();
  else window.print();
}
window.printDocument = printDocument;
