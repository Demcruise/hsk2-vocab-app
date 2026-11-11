// Regression test for K-01: lesson-complete (S.ld) and story-complete (S.st)
// must survive a page reload and stay isolated per HSK level.
//
// Usage: serve the repo root over http, then
//   node tools/persistence.test.js [baseUrl]
// Env: CHROME_PATH overrides the Chrome executable.
const puppeteer = require('puppeteer-core');

const BASE = process.argv[2] || 'http://localhost:8734/';
const CHROME = process.env.CHROME_PATH || 'C:/Program Files/Google/Chrome/Application/chrome.exe';

let pass = 0, fail = 0;
function ok(name, cond, extra = '') {
  if (cond) { pass++; console.log('  PASS', name, extra); }
  else { fail++; console.log('  FAIL', name, extra); }
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox'] });
  const page = await browser.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(e.message));
  page.on('dialog', (d) => d.accept());

  await page.goto(BASE, { waitUntil: 'networkidle2' });
  await page.evaluate(async () => {
    localStorage.clear();
    for (const r of await navigator.serviceWorker.getRegistrations()) await r.unregister();
    for (const k of await caches.keys()) await caches.delete(k);
  });
  await page.reload({ waitUntil: 'networkidle2' });
  await sleep(1000);

  // Real flow: finish lesson node 0_0 through the session-complete path.
  await page.evaluate(() => {
    if (LEVEL !== 'hsk2') switchLevel('hsk2');
    openLesson(0, 0);
    sessionComplete();
    sessDoneClose();
    S.st['hsk2-dasar'] = 1;
    saveState();
  });

  const stored = await page.evaluate(() => JSON.parse(localStorage.getItem('khsk2')));
  ok('saveState writes ld', stored && stored.ld && stored.ld['0_0'] === 1, JSON.stringify(stored && stored.ld));
  ok('saveState writes st', stored && stored.st && stored.st['hsk2-dasar'] === 1, JSON.stringify(stored && stored.st));

  await page.reload({ waitUntil: 'networkidle2' });
  await sleep(1000);
  const after = await page.evaluate(() => ({ ld: S.ld, st: S.st }));
  ok('ld survives reload', after.ld && after.ld['0_0'] === 1, JSON.stringify(after.ld));
  ok('st survives reload', after.st && after.st['hsk2-dasar'] === 1, JSON.stringify(after.st));

  // Level isolation: HSK1 must not inherit HSK2 completion, and HSK2 must come back intact.
  const hsk1 = await page.evaluate(() => { switchLevel('hsk1'); return { ld: S.ld, st: S.st }; });
  ok('hsk1 has no hsk2 ld', Object.keys(hsk1.ld || {}).length === 0, JSON.stringify(hsk1.ld));
  ok('hsk1 has no hsk2 st', Object.keys(hsk1.st || {}).length === 0, JSON.stringify(hsk1.st));
  const back = await page.evaluate(() => { switchLevel('hsk2'); return { ld: S.ld, st: S.st }; });
  ok('hsk2 ld restored after level round-trip', back.ld && back.ld['0_0'] === 1);
  ok('hsk2 st restored after level round-trip', back.st && back.st['hsk2-dasar'] === 1);

  ok('no page errors', errors.length === 0, errors.join(' | '));

  await browser.close();
  console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
