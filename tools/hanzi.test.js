// Tests for the Hanzi screen: tabs, per-unit introduced/reused characters, practised
// marking from writing practice, pinyin chart, radicals tab still working.
//
// Usage: serve the repo root over http, then
//   node tools/hanzi.test.js [baseUrl]
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

  ok('nav says Hanzi', await page.evaluate(() => /Hanzi/.test(document.querySelector('.bottom-nav [data-screen="radicals"]').textContent)));
  await page.evaluate(() => switchScreen('radicals')); await sleep(1500);

  console.log('=== characters per unit ===');
  const u = await page.evaluate(() => {
    const units = unitCharacters();
    const all = units.flatMap((x) => x.intro);
    const uniqueIntro = new Set(all).size === all.length;
    // every reused char must have been introduced in an earlier unit
    let reusedOk = true; const seen = new Set();
    units.forEach((x) => { x.reused.forEach((c) => { if (!seen.has(c)) reusedOk = false; }); x.intro.forEach((c) => seen.add(c)); });
    const levelChars = new Set(vocab.flatMap((v) => [...v.hanzi].filter((c) => /[\u4e00-\u9fff]/.test(c))));
    return { units: units.length, intro: all.length, uniqueIntro, reusedOk, covers: all.length === levelChars.size };
  });
  ok('each character introduced exactly once', u.uniqueIntro, String(u.intro));
  ok('reused characters were introduced earlier', u.reusedOk);
  ok('introduced set covers every character in the level', u.covers);
  const r = await page.evaluate(() => ({ cards: document.querySelectorAll('#hzPaneChars .hz-unit').length, tiles: document.querySelectorAll('#hzPaneChars .hz-ch').length, sum: document.querySelector('.hz-sum').textContent }));
  ok('unit cards rendered with tiles', r.cards >= 10 && r.tiles > 100, JSON.stringify(r));
  ok('summary shows count and practised', /characters · 0 practised/.test(r.sum), r.sum);

  console.log('=== practised marking ===');
  const ch = await page.evaluate(() => { const b = [...document.querySelectorAll('#hzPaneChars .hz-ch:not(.nostroke)')][0]; return b.querySelector('b').textContent; });
  await page.evaluate((c) => { markCharPractised(c); closeWrite(); }, ch); await sleep(1200);
  ok('practised char turns green and count updates', await page.evaluate((c) => {
    const t = [...document.querySelectorAll('#hzPaneChars .hz-ch')].find((b) => b.querySelector('b').textContent === c);
    return t.classList.contains('done') && /1 practised/.test(document.querySelector('.hz-sum').textContent);
  }, ch));
  await page.evaluate((c) => { const t = [...document.querySelectorAll('#hzPaneChars .hz-ch')].find((b) => b.querySelector('b').textContent === c); t.click(); }, ch); await sleep(1200);
  ok('tapping a character opens writing practice', await page.evaluate(() => document.getElementById('writeView').classList.contains('open')));
  await page.evaluate(() => closeWrite());

  console.log('=== pinyin & radicals tabs ===');
  await page.evaluate(() => setHanziTab('pinyin')); await sleep(200);
  const py = await page.evaluate(() => ({ vis: !document.getElementById('hzPanePinyin').classList.contains('hidden'), cells: document.querySelectorAll('#hzPanePinyin .py-cell').length, hid: document.getElementById('hzPaneChars').classList.contains('hidden') }));
  ok('pinyin tab shows tones, initials and finals', py.vis && py.hid && py.cells === 5 + 21 + 35, JSON.stringify(py));
  await page.evaluate(() => setHanziTab('radicals')); await sleep(200);
  ok('radicals tab still lists radicals', await page.evaluate(() => !document.getElementById('hzPaneRadicals').classList.contains('hidden') && document.querySelectorAll('#radicalGrid .radical-card').length > 10));
  await page.evaluate(() => { switchLevel('hsk1'); setHanziTab('chars'); }); await sleep(1500);
  ok('switching level rebuilds characters', await page.evaluate(() => /HSK 1/.test(document.querySelector('.hz-sum').textContent)));

  ok('no page errors', errors.length === 0, errors.join(' | '));
  await browser.close();
  console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
