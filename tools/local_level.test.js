// Tests for the optional local-only level (local-content/level-hsk2-2025.json).
// Part A runs only when the local file exists; part B simulates the public site
// (file absent) via request interception and must always pass.
//
// Usage: serve the repo root over http, then
//   node tools/local_level.test.js [baseUrl]
const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer-core');

const BASE = process.argv[2] || 'http://localhost:8734/';
const CHROME = process.env.CHROME_PATH || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const LOCAL = path.join(__dirname, '..', 'local-content', 'level-hsk2-2025.json');

let pass = 0, fail = 0;
const ok = (n, c, x = '') => { if (c) { pass++; console.log('  PASS', n, x); } else { fail++; console.log('  FAIL', n, x); } };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function fresh(page) {
  await page.goto(BASE, { waitUntil: 'networkidle2' });
  await page.evaluate(async () => {
    localStorage.clear();
    for (const r of await navigator.serviceWorker.getRegistrations()) await r.unregister();
    for (const k of await caches.keys()) await caches.delete(k);
  });
}

(async () => {
  const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'] });

  if (fs.existsSync(LOCAL)) {
    console.log('=== A. local file present ===');
    const local = JSON.parse(fs.readFileSync(LOCAL, 'utf8'));
    const page = await browser.newPage();
    const errors = []; page.on('pageerror', (e) => errors.push(e.message)); page.on('dialog', (d) => d.accept());
    await fresh(page);
    // Pre-existing HSK2 progress for a word shared by both lists, to verify carry-over.
    const shared = await page.evaluate((lv) => { const hz = new Set(lv.vocab.map((v) => v.hanzi)); return VOCAB_DATA.find((v) => hz.has(v.hanzi)); }, local);
    await page.evaluate((w) => {
      localStorage.setItem('khsk2', JSON.stringify({ p: { [w.id]: { l: 3, c: 4, w: 1, t: '2026-11-01T00:00:00Z' } }, k: { [w.id]: 1 }, s: 5, l: new Date().toDateString(), x: 100 }));
    }, shared);
    await page.reload({ waitUntil: 'networkidle2' }); await sleep(1500);

    ok('local level registered', await page.evaluate(() => !!LEVELS.hsk2b && LEVELS.hsk2b.local === true));
    ok('local level button shown', await page.evaluate(() => !!document.querySelector('#levelSwitch [data-lv="hsk2b"]')));
    await page.evaluate(() => document.querySelector('#levelSwitch [data-lv="hsk2b"]').click()); await sleep(800);
    const st = await page.evaluate(() => ({ lv: LEVEL, n: vocab.length, units: UNITS.length, key: storeKey() }));
    ok('switched to hsk2b', st.lv === 'hsk2b');
    ok('200 words', st.n === local.vocab.length, String(st.n));
    ok('units built', st.units > 0, String(st.units));
    ok('own storage bucket', st.key === 'khsk2b');
    const carried = await page.evaluate((hz) => { const v = vocab.find((x) => x.hanzi === hz); return { p: S.prog[v.id + ''], k: !!S.known[v.id + ''] }; }, shared.hanzi);
    ok('progress carried over from HSK2', carried.p && carried.p.l === 3 && carried.k, `${shared.hanzi} ${JSON.stringify(carried)}`);
    ok('hsk2 bucket untouched', await page.evaluate(() => JSON.parse(localStorage.getItem('khsk2')).x === 100));

    await page.evaluate(() => { switchScreen('quiz'); startQuiz(); }); await sleep(500);
    ok('quiz runs on hsk2b', await page.evaluate(() => S.qList.length > 0 && S.qList.every((q) => vocab.some((v) => v.id === q.id))));
    await page.evaluate(() => { openLesson(0, 0); sessionComplete(); sessDoneClose(); }); await sleep(300);

    await page.reload({ waitUntil: 'networkidle2' }); await sleep(1500);
    const re = await page.evaluate(() => ({ lv: LEVEL, ld: S.ld }));
    ok('hsk2b restored after reload', re.lv === 'hsk2b');
    ok('hsk2b lesson completion persisted', re.ld && re.ld['0_0'] === 1, JSON.stringify(re.ld));

    // Every other level listed in local-content/levels.json.
    const ixPath = path.join(__dirname, '..', 'local-content', 'levels.json');
    const files = fs.existsSync(ixPath) ? JSON.parse(fs.readFileSync(ixPath, 'utf8')).levels : [];
    for (const f of files.filter((x) => x !== 'level-hsk2-2025.json')) {
      const d = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'local-content', f), 'utf8'));
      const r = await page.evaluate((k) => {
        if (!LEVELS[k]) return { reg: false };
        // Plant HSK2 progress for a word this level shares with the built-in HSK2 list.
        const hz = new Set(LEVELS[k].vocab.map((v) => v.hanzi));
        const w = VOCAB_DATA.find((v) => hz.has(v.hanzi));
        const b = JSON.parse(localStorage.getItem('khsk2') || '{}');
        b.p = b.p || {}; b.p[w.id] = { l: 2, c: 3, w: 0, t: '2026-11-02T00:00:00Z' };
        localStorage.setItem('khsk2', JSON.stringify(b));
        localStorage.removeItem(LEVELS[k].store);
        switchLevel(k); switchScreen('quiz'); startQuiz();
        const mine = vocab.find((v) => v.hanzi === w.hanzi);
        return { reg: true, lv: LEVEL, n: vocab.length, units: UNITS.length, key: storeKey(), q: S.qList.length,
          seeded: (S.prog[mine.id + ''] || {}).l, word: w.hanzi };
      }, d.key);
      ok(`${d.key} registered`, r.reg);
      ok(`${d.key} loads ${d.vocab.length} words in ${r.units} units`, r.lv === d.key && r.n === d.vocab.length && r.units > 0, JSON.stringify(r));
      ok(`${d.key} own bucket ${d.store}`, r.key === d.store);
      ok(`${d.key} quiz runs`, r.q > 0);
      ok(`${d.key} carried progress from HSK2 where hanzi overlap`, r.seeded === 2, `${r.word} l=${r.seeded}`);
    }
    const btns = await page.evaluate(() => [...document.querySelectorAll('#levelSwitch button')].map((b) => b.dataset.lv));
    ok('one button per level', btns.length === 2 + files.length, btns.join(','));
    ok('no page errors (A)', errors.length === 0, errors.join(' | '));
    await page.close();
  } else {
    console.log('=== A. skipped (no local-content/level-hsk2-2025.json) ===');
  }

  console.log('=== B. public site (local file absent) ===');
  const page = await browser.newPage();
  const errors = []; page.on('pageerror', (e) => errors.push(e.message)); page.on('dialog', (d) => d.accept());
  await page.setRequestInterception(true);
  page.on('request', (r) => (r.url().includes('/local-content/') ? r.respond({ status: 404, body: 'not found' }) : r.continue()));
  await fresh(page);
  await page.evaluate(() => localStorage.setItem('khsk-level', 'hsk2b'));
  await page.reload({ waitUntil: 'networkidle2' }); await sleep(1500);
  const b = await page.evaluate(() => ({ lv: LEVEL, has: !!LEVELS.hsk2b, btn: !!document.querySelector('[data-lv="hsk2b"]'), n: vocab.length }));
  ok('falls back to hsk2', b.lv === 'hsk2' && b.n === 770, JSON.stringify(b));
  ok('no local level registered', !b.has && !b.btn);
  ok('level picker lives in Settings, not on Learn', await page.evaluate(() => !!document.querySelector('#screenProgress #levelSwitch') && !document.querySelector('#screenLearn #levelSwitch')));
  ok('header pill opens Settings', await page.evaluate(() => { document.getElementById('lvlPill').click(); return S.screen === 'progress' || document.getElementById('screenProgress').classList.contains('active'); }));
  ok('picking a level in Settings switches it', await page.evaluate(() => { document.querySelector('#levelSwitch [data-lv="hsk1"]').click(); const r = LEVEL; switchLevel('hsk2'); return r === 'hsk1'; }));
  ok('no page errors (B)', errors.length === 0, errors.join(' | '));

  await browser.close();
  console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
