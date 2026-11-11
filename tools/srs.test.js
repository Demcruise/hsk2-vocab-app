// Tests for spaced repetition: scheduler maths (srsNext), seeding of pre-existing
// progress, grading from quiz/flashcards, due list, review session, weak words,
// review quest metric, UI counters and persistence.
//
// Usage: serve the repo root over http, then
//   node tools/srs.test.js [baseUrl]
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
  await page.goto(BASE, { waitUntil: 'networkidle2' });
  await page.evaluate(async () => {
    localStorage.clear();
    for (const r of await navigator.serviceWorker.getRegistrations()) await r.unregister();
    for (const k of await caches.keys()) await caches.delete(k);
  });
  const reload = async () => { await page.reload({ waitUntil: 'networkidle2' }); await sleep(1200); };
  await reload();

  console.log('=== scheduler (srsNext) ===');
  const r = await page.evaluate(() => {
    const T = '2026-11-11', add = (n) => srsAddDays(T, n);
    let a = srsNext(null, 'good', T); const g1 = { i: a.i, d: a.d };
    let b = srsNext(a, 'good', add(1)); const g2 = { i: b.i, d: b.d };
    let c = srsNext(b, 'good', add(4)); const g3 = { i: c.i, d: c.d };
    const dup = srsNext(a, 'good', T); // same day again
    let e = srsNext(c, 'again', add(12)); const ag = { i: e.i, d: e.d, x: e.x, e: e.e, r: e.r };
    let f = srsNext(e, 'good', add(12)); const back = { i: f.i, d: f.d };
    let z = srsNext(null, 'easy', T);
    return { g1, g2, g3, dupSame: dup.i === a.i && dup.d === a.d, ag, back, easy: { i: z.i, e: z.e }, T, add1: add(1), add3: add(3), add4: add(4), add12: add(12), add13: add(13) };
  });
  ok('1st good → 1 day', r.g1.i === 1 && r.g1.d === r.add1, JSON.stringify(r.g1));
  ok('2nd good → 3 days', r.g2.i === 3, JSON.stringify(r.g2));
  ok('3rd good → interval × ease (8)', r.g3.i === 8, JSON.stringify(r.g3));
  ok('same-day repeat does not advance', r.dupSame);
  ok('again → due now, lapse counted, ease drops', r.ag.i === 0 && r.ag.d === r.add12 && r.ag.x === 1 && r.ag.e === 2.3 && r.ag.r === 0, JSON.stringify(r.ag));
  ok('good after again the same day → tomorrow', r.back.i === 1 && r.back.d === r.add13, JSON.stringify(r.back));
  ok('easy first time → 3 days, ease up', r.easy.i === 3 && r.easy.e === 2.65, JSON.stringify(r.easy));

  console.log('=== seeding existing progress ===');
  const seed = await page.evaluate(() => {
    const T = todayStr();
    const a = srsSeed({ l: 3, c: 3, w: 0 }, 22, T), b = srsSeed({ l: 0, c: 0, w: 0 }, 5, T);
    const spread = new Set(); for (let id = 1; id <= 50; id++) spread.add(srsSeed({ l: 3, c: 3, w: 0 }, id, T).d);
    return { a, b, spread: spread.size, maxDay: srsAddDays(T, 6) };
  });
  ok('mastered word seeded with 7-day interval', seed.a && seed.a.i === 7 && seed.a.d <= seed.maxDay, JSON.stringify(seed.a));
  ok('never-studied word has no state', seed.b === null);
  ok('seeded due dates are spread out', seed.spread === 7, String(seed.spread));

  console.log('=== grading in the app ===');
  await page.evaluate(() => { switchScreen('quiz'); startQuiz(null, null, 'hz2mn'); const q = S.qList[S.qIdx]; pickMC(q.ansIdx); checkAns(); });
  let st = await page.evaluate(() => { const q = S.qList[S.qIdx]; return { s: S.prog[q.id + ''].s, tomorrow: srsAddDays(todayStr(), 1), due: dueWords().some((v) => v.id === q.id) }; });
  ok('correct quiz answer schedules the word for tomorrow', st.s && st.s.d === st.tomorrow && !st.due, JSON.stringify(st.s));
  await page.evaluate(() => nextQuizQ());
  await page.evaluate(() => { const q = S.qList[S.qIdx]; pickMC((q.ansIdx + 1) % q.opts.length); checkAns(); });
  st = await page.evaluate(() => { const q = S.qList[S.qIdx]; return { s: S.prog[q.id + ''].s, due: dueWords().some((v) => v.id === q.id) }; });
  ok('wrong quiz answer makes the word due now', st.s && st.s.x === 1 && st.due, JSON.stringify(st.s));
  const fc = await page.evaluate(() => {
    applyMode(); S.mode = 'all'; applyMode(); showCard(0); const id = vocab[cv[S.idx]].id + ''; rateCard(3);
    return S.prog[id].s;
  });
  ok('flashcard Easy → 3-day interval', fc && fc.i === 3, JSON.stringify(fc));

  console.log('=== review session, quest metric, weak words ===');
  await page.evaluate(() => {
    const y = srsAddDays(todayStr(), -1);
    vocab.slice(0, 12).forEach((v) => { const k = v.id + ''; S.prog[k] = S.prog[k] || { l: 1, c: 1, w: 0, t: '' }; S.prog[k].s = { d: y, i: 1, e: 2.5, r: 1, x: 0, rv: y, lg: 'good' }; });
    saveState();
  });
  const dueN = await page.evaluate(() => dueWords().length);
  ok('words due yesterday show up as due', dueN >= 12, String(dueN));
  ok('Learn button shows due count', await page.evaluate(() => /\d+ due/.test(document.getElementById('reviewBtn').textContent) && document.getElementById('reviewBtn').classList.contains('due')));
  ok('quiz picker has Smart Review tile with count', await page.evaluate(() => { renderQuizPicker(); return /Smart Review/.test(document.getElementById('quizPicker').textContent) && /due today/.test(document.getElementById('quizPicker').textContent); }));
  const before = await page.evaluate(() => DAILY.stats.review || 0);
  await page.evaluate(() => { startReview(); });
  const pool = await page.evaluate(() => { const due = new Set(dueWords().map((v) => v.id)); return S.qList.every((q) => due.has(q.id)); });
  ok('review quiz uses only due words', pool);
  await page.evaluate(() => { const q = S.qList[S.qIdx]; if (q.opts) { pickMC(q.ansIdx); } else if (q.ans) { q.sel = q.ans.map((t) => q.bank.indexOf(t)); } checkAns(); if (!S.qDone) resolveQ(true); });
  ok('reviewing a due word counts toward the review quest', await page.evaluate((b) => (DAILY.stats.review || 0) === b + 1, before));
  await page.evaluate(() => { const v = vocab[30]; const k = v.id + ''; S.prog[k] = { l: 0, c: 0, w: 3, t: '', s: { d: todayStr(), i: 0, e: 1.9, r: 0, x: 3, rv: todayStr(), lg: 'again' } }; });
  ok('weak words list frequently missed words first', await page.evaluate(() => weakWords()[0].id === vocab[30].id));

  console.log('=== persistence ===');
  const snap = await page.evaluate(() => JSON.stringify(S.prog[vocab[30].id + ''].s));
  await page.evaluate(() => saveState()); await reload();
  ok('schedule survives reload', await page.evaluate((x) => JSON.stringify(S.prog[vocab[30].id + ''].s) === x, snap));
  ok('backup file includes schedule', await page.evaluate(() => !!progressPayload().p[vocab[30].id + ''].s));
  await page.evaluate(() => { dueWords().forEach((v) => { S.prog[v.id + ''].s = srsNext(srsState(v, todayStr()), 'good', todayStr()); }); saveState(); });
  ok('empty state when nothing is due', await page.evaluate(() => /caught up/.test(document.getElementById('reviewBtn').textContent)));

  ok('no page errors', errors.length === 0, errors.join(' | '));
  await browser.close();
  console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
