// Browser tests for per-word glosses (B-01), "I can't listen now" (B-02) and the
// listening-exercise settings toggle (B-05).
//
// Usage: serve the repo root over http, then
//   node tools/gloss_listen.test.js [baseUrl]
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
  await page.reload({ waitUntil: 'networkidle2' }); await sleep(1500);

  console.log('=== B-01 per-word glosses ===');
  await page.evaluate(() => { switchScreen('quiz'); startQuiz(null, null, 'bank'); });
  await sleep(200);
  ok('sentence words wrapped as .ex-w with data-w', await page.evaluate(() => {
    const w = document.querySelectorAll('#exSent .ex-w');
    return w.length > 0 && [...w].every((x) => x.getAttribute('data-w') && x.getAttribute('tabindex') === '0' && x.getAttribute('role') === 'button' && x.getAttribute('aria-label'));
  }));
  ok('aria-label carries pinyin + meaning', await page.evaluate(() => {
    const w = document.querySelector('#exSent .ex-w');
    if (!w) return false;
    const v = vocab.find((x) => x.hanzi === w.getAttribute('data-w'));
    return v && w.getAttribute('aria-label').includes(v.pinyin);
  }));
  // Hover a word → hzTip shows the word gloss.
  ok('hover shows word gloss', await page.evaluate(() => {
    const w = document.querySelector('#exSent .ex-w'); if (!w) return false;
    const v = vocab.find((x) => x.hanzi === w.getAttribute('data-w'));
    w.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));
    const tip = document.getElementById('hzTip');
    return tip.style.display === 'block' && tip.textContent.includes(v.pinyin) && tip.textContent.includes(v.meaning.split('•')[0].trim().split(' ')[0]);
  }));
  ok('char tooltip still works', await page.evaluate(() => {
    const h = document.querySelector('.hz'); if (!h) return 'no .hz on page';
    h.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }));
    const tip = document.getElementById('hzTip');
    return tip.style.display === 'block' && tip.querySelector('.hz-head');
  }));
  ok('focus shows gloss (keyboard)', await page.evaluate(() => {
    const w = document.querySelector('#exSent .ex-w'); if (!w) return false;
    w.dispatchEvent(new Event('focusin', { bubbles: true }));
    return document.getElementById('hzTip').style.display === 'block' && w.classList.contains('open');
  }));
  await page.evaluate(() => hzHide());

  console.log('=== B-02 I can\'t listen now ===');
  await page.evaluate(() => { noListen = false; switchScreen('quiz'); startQuiz(null, null, 'listen'); });
  await sleep(200);
  ok('listen question renders + skip link', await page.evaluate(() => S.qList[S.qIdx].type === 'listen' && !!document.querySelector('.lst-skip')));
  ok('skip swaps to a non-listen question', await page.evaluate(() => {
    const before = S.qList[S.qIdx].type;
    cantListen();
    return before === 'listen' && S.qList[S.qIdx].type !== 'listen' && noListen === true;
  }));
  ok('mixed quiz after skip has no listen types', await page.evaluate(() => {
    startQuiz();
    return !S.qList.some((q) => q.type === 'listen');
  }));
  ok('dedicated listen tile still forces listen', await page.evaluate(() => {
    startQuiz(null, null, 'listen');
    return S.qList[S.qIdx].type === 'listen';
  }));
  await page.evaluate(() => { noListen = false; });

  console.log('=== B-05 settings toggle ===');
  ok('toggle exists in settings', await page.evaluate(() => !!document.getElementById('listenOn') && !!document.getElementById('listenOff')));
  ok('setListen(0) filters mixed listens', await page.evaluate(() => {
    setListen(0); startQuiz();
    const noL = !S.qList.some((q) => q.type === 'listen');
    setListen(1);
    return noL && exListen === true && document.getElementById('listenOn').className === 'active';
  }));
  ok('persisted to localStorage', await page.evaluate(() => { setListen(0); const v = localStorage.getItem('khsk-exlisten'); setListen(1); return v === '0'; }));

  console.log('=== errors ===');
  ok('no page errors', errors.length === 0, errors.slice(0, 3).join(' | '));
  await browser.close();
  console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error('FATAL', e); process.exit(1); });
