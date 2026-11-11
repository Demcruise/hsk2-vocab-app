// Tests for the unit guidebook: Guide button on every unit, key phrases drawn from the
// unit's own words, grammar tips per level, fallback for levels without notes.
//
// Usage: serve the repo root over http, then
//   node tools/guide.test.js [baseUrl]
const puppeteer = require('puppeteer-core');

const BASE = process.argv[2] || 'http://localhost:8734/';
const CHROME = process.env.CHROME_PATH || 'C:/Program Files/Google/Chrome/Application/chrome.exe';

let pass = 0, fail = 0;
const ok = (n, c, x = '') => { if (c) { pass++; console.log('  PASS', n, x); } else { fail++; console.log('  FAIL', n, x); } };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'] });
  const page = await browser.newPage();
  const errors = []; page.on('pageerror', (e) => errors.push(e.message)); page.on('dialog', (d) => d.accept());
  await page.setViewport({ width: 400, height: 850 });
  await page.goto(BASE, { waitUntil: 'networkidle2' });
  await page.evaluate(async () => {
    localStorage.clear();
    for (const r of await navigator.serviceWorker.getRegistrations()) await r.unregister();
    for (const k of await caches.keys()) await caches.delete(k);
  });
  await page.reload({ waitUntil: 'networkidle2' }); await sleep(1200);
  await page.evaluate(() => switchScreen('learn')); await sleep(400);

  ok('every unit banner has a Guide button', await page.evaluate(() => document.querySelectorAll('[data-ug]').length === UNITS.length && UNITS.length > 0));
  await page.evaluate(() => document.querySelector('[data-ug]').click()); await sleep(800);
  let g = await page.evaluate(() => ({
    open: document.getElementById('guideView').classList.contains('open'),
    phrases: document.querySelectorAll('#gdBody > .gd-phrase').length,
    tips: document.querySelectorAll('#gdBody .gd-tip').length,
    title: document.querySelector('.gd-title').textContent,
  }));
  ok('Guide opens for unit 1', g.open && /Unit 1/.test(g.title), g.title);
  ok('key phrases shown (up to 5)', g.phrases >= 3 && g.phrases <= 5, String(g.phrases));
  ok('HSK 2 grammar tips shown', g.tips >= 1, String(g.tips));
  ok('key phrases come from this unit and contain their word', await page.evaluate(() => {
    const u = UNITS[0]; const idx = new Set(u.lessons.flat());
    return keyPhrases(u, 5).every((p) => idx.has(vocab.indexOf(p.word)) && p.s[0].includes(p.word.hanzi));
  }));
  ok('pattern table rendered', await page.evaluate(() => document.querySelectorAll('#gdBody .gd-pat tr').length >= 1));
  await page.evaluate(() => closeGuide());
  ok('Guide closes', await page.evaluate(() => !document.getElementById('guideView').classList.contains('open')));

  ok('every HSK 2 unit has grammar notes', await page.evaluate(async () => { const G = await loadGrammar(); return UNITS.every((u) => (G.hsk2[u.key] || []).length > 0); }));
  await page.evaluate(() => switchLevel('hsk1')); await sleep(300);
  await page.evaluate(() => openGuide(UNITS[0].key)); await sleep(500);
  ok('HSK 1 shows its own grammar', await page.evaluate(async () => { const G = await loadGrammar(); const t = G.hsk1[UNITS[0].key][0].title; return document.getElementById('gdBody').textContent.includes(t); }));
  await page.evaluate(() => closeGuide());
  ok('levels without notes show a fallback', await page.evaluate(() => { LEVEL = 'hsk9x'; const k = grammarKey(); LEVEL = 'hsk1'; return k === null; }));

  ok('no page errors', errors.length === 0, errors.join(' | '));
  await browser.close();
  console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
