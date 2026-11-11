// Tests for unit checkpoints and jump-ahead tests: nodes and buttons on the path, intro
// dialog, exam settings (question count, 3 hearts), pass/fail outcomes, path progression,
// retry, persistence and normal quizzes staying unchanged.
//
// Usage: serve the repo root over http, then
//   node tools/checkpoint.test.js [baseUrl]
const puppeteer = require('puppeteer-core');

const BASE = process.argv[2] || 'http://localhost:8734/';
const CHROME = process.env.CHROME_PATH || 'C:/Program Files/Google/Chrome/Application/chrome.exe';

let pass = 0, fail = 0;
const ok = (n, c, x = '') => { if (c) { pass++; console.log('  PASS', n, x); } else { fail++; console.log('  FAIL', n, x); } };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Answer the current question right or wrong through the real check path.
const answer = (page, right) => page.evaluate((right) => {
  if (right) resolveQ(true); else resolveQ(false);
  if (S.qHearts > 0 && S.qIdx < S.qList.length) nextQuizQ(); else if (S.qHearts <= 0) nextQuizQ();
}, right);

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
  const reload = async () => { await page.reload({ waitUntil: 'networkidle2' }); await sleep(1200); };
  await reload();
  await page.evaluate(() => switchScreen('learn')); await sleep(300);

  console.log('=== path ===');
  const p = await page.evaluate(() => ({ units: UNITS.length, cps: document.querySelectorAll('[data-cp]').length, jumps: [...document.querySelectorAll('[data-jump]')].map((b) => +b.dataset.jump), cur: curUnitIdx() }));
  ok('every unit ends with a checkpoint', p.cps === p.units && p.units > 2, JSON.stringify(p));
  ok('fresh user: jump buttons on every later unit only', p.cur === 0 && p.jumps.length === p.units - 1 && p.jumps[0] === 1, JSON.stringify(p.jumps));

  console.log('=== intro dialog ===');
  await page.evaluate(() => document.querySelector('[data-jump="2"]').click()); await sleep(200);
  const intro = await page.evaluate(() => ({ open: document.getElementById('examIntro').classList.contains('open'), t: document.getElementById('eiTitle').textContent, m: document.getElementById('eiMsg').textContent, meta: document.getElementById('eiMeta').textContent }));
  ok('jump intro names target and covered units', intro.open && /Jump to Unit 3/.test(intro.t) && /Units 1–2/.test(intro.m), JSON.stringify(intro));
  ok('intro shows question count and 3 hearts', /15 questions/.test(intro.meta) && /3 hearts/.test(intro.meta), intro.meta);
  await page.evaluate(() => closeExamIntro());
  ok('Not now closes intro', await page.evaluate(() => !document.getElementById('examIntro').classList.contains('open')));

  console.log('=== failing a jump test ===');
  await page.evaluate(() => { openExamIntro('jump', 2); document.getElementById('eiStart').click(); });
  await sleep(300);
  const ex = await page.evaluate(() => {
    const allowed = new Set([...unitWords(0), ...unitWords(1)].map((v) => v.id));
    return { exam: S.qExam && S.qExam.kind, n: S.qList.length, hearts: S.qHearts, pool: S.qList.every((q) => allowed.has(q.id)), hv: !document.getElementById('exHearts').classList.contains('hidden'), ht: document.getElementById('exHearts').textContent };
  });
  ok('jump test: 15 questions from skipped units', ex.exam === 'jump' && ex.n === 15 && ex.pool, JSON.stringify(ex));
  ok('3 hearts shown in the quiz header', ex.hearts === 3 && ex.hv && /3/.test(ex.ht), ex.ht);
  for (let i = 0; i < 3; i++) await answer(page, false);
  await sleep(400);
  const f = await page.evaluate(() => ({ done: !document.getElementById('quizComplete').classList.contains('hidden'), t: document.getElementById('qdTitle').textContent, cp: S.cp || {}, cur: curUnitIdx() }));
  ok('3 misses end the test as failed', f.done && f.t === 'Out of hearts', JSON.stringify(f));
  ok('failed test changes nothing on the path', Object.keys(f.cp).length === 0 && f.cur === 0);
  await page.evaluate(() => retryQuiz()); await sleep(300);
  ok('retry restarts the same exam', await page.evaluate(() => S.qExam && S.qExam.kind === 'jump' && S.qExam.ui === 2 && S.qHearts === 3));

  console.log('=== passing a jump test ===');
  for (let i = 0; i < 2; i++) await answer(page, false);           // 2 misses: still alive
  let guard = 0;
  while (guard++ < 60 && await page.evaluate(() => document.getElementById('quizComplete').classList.contains('hidden'))) await answer(page, true);
  await sleep(400);
  const ps = await page.evaluate(() => ({ t: document.getElementById('qdTitle').textContent, m: document.getElementById('finalMsg').textContent, cp: S.cp, cur: curUnitIdx(), k0: UNITS[0].key, k1: UNITS[1].key, k2: UNITS[2].key, ld: Object.keys(S.ld).length, need: UNITS[0].lessons.length + UNITS[1].lessons.length }));
  ok('pass with 1 heart left', /Jumped to Unit 3/.test(ps.t) && /Units 1–2/.test(ps.m), JSON.stringify(ps));
  ok('skipped units marked complete, path starts at unit 3', ps.cp[ps.k0] && ps.cp[ps.k1] && !ps.cp[ps.k2] && ps.cur === 2 && ps.ld >= ps.need, JSON.stringify(ps));
  await page.evaluate(() => switchScreen('learn')); await sleep(300);
  const after = await page.evaluate(() => ({ jumps: [...document.querySelectorAll('[data-jump]')].map((b) => +b.dataset.jump), passed: document.querySelectorAll('.lesson-node.cp.passed').length, curNode: document.querySelector('.lesson-node.current').dataset.lp }));
  ok('path redraws: 2 gold checkpoints, START in unit 3', after.passed === 2 && after.curNode.startsWith('2_') && after.jumps[0] === 3, JSON.stringify(after));

  console.log('=== checkpoint ===');
  await page.evaluate(() => { openExamIntro('cp', 2); });
  ok('checkpoint intro', await page.evaluate(() => /Unit 3 checkpoint/.test(document.getElementById('eiTitle').textContent)));
  await page.evaluate(() => document.getElementById('eiStart').click()); await sleep(300);
  const cpq = await page.evaluate(() => { const ids = new Set(unitWords(2).map((v) => v.id)); return { n: S.qList.length, max: Math.min(12, ids.size), pool: S.qList.every((q) => ids.has(q.id)) }; });
  ok('checkpoint: up to 12 questions from this unit only', cpq.n === cpq.max && cpq.pool, JSON.stringify(cpq));
  guard = 0;
  while (guard++ < 40 && await page.evaluate(() => document.getElementById('quizComplete').classList.contains('hidden'))) await answer(page, true);
  await sleep(300);
  ok('checkpoint pass completes the unit', await page.evaluate(() => document.getElementById('qdTitle').textContent === 'Checkpoint passed!' && S.cp[UNITS[2].key] === 1 && curUnitIdx() === 3));

  console.log('=== persistence & normal quizzes ===');
  await reload();
  ok('checkpoints survive reload', await page.evaluate(() => S.cp[UNITS[0].key] && S.cp[UNITS[2].key] && curUnitIdx() === 3));
  ok('backup includes checkpoints', await page.evaluate(() => !!progressPayload().cp[UNITS[1].key]));
  await page.evaluate(() => { switchScreen('quiz'); startQuiz(); }); await sleep(200);
  ok('normal quiz: 10 questions, 5 hearts, no exam header', await page.evaluate(() => S.qList.length === 10 && S.qHearts === 5 && !S.qExam && document.getElementById('exHearts').classList.contains('hidden')));
  await page.evaluate(() => { switchScreen('learn'); });
  const over = await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth);
  ok('no horizontal overflow at 400px', over);

  ok('no page errors', errors.length === 0, errors.join(' | '));
  await browser.close();
  console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
