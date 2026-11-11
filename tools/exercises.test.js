// Browser tests for the quiz engine additions: fill-in-the-blank, match pairs,
// English→Chinese (chips + typing), PREVIOUS MISTAKE re-queue, progress that only
// moves on correct answers, and the "Meaning:" line.
//
// Usage: serve the repo root over http, then
//   node tools/exercises.test.js [baseUrl]
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
  const start = (t) => page.evaluate((t) => { switchScreen('quiz'); startQuiz(null, null, t); }, t);
  const state = () => page.evaluate(() => {
    const q = S.qList[S.qIdx];
    return { type: q && q.type, idx: S.qIdx, len: S.qList.length, right: S.qRight, bar: document.getElementById('quizBarFill').style.width,
      badge: document.getElementById('exBadge').textContent.trim(), band: document.getElementById('quizBand').className,
      result: document.getElementById('quizResult').textContent };
  });

  console.log('=== mixed quiz contains the new types ===');
  ok('Q_MIX has fill, match, zh', await page.evaluate(() => ['fill', 'match', 'zh'].every((t) => Q_MIX.includes(t))));
  await page.evaluate(() => { switchScreen('quiz'); startQuiz(); });
  const types = await page.evaluate(() => S.qList.map((q) => q.type));
  ok('mixed quiz builds fill/match/zh', ['fill', 'match', 'zh'].every((t) => types.includes(t)), types.join(','));

  console.log('=== fill in the blank ===');
  await start('fill');
  let s = await state();
  ok('fill rendered', s.type === 'fill' && await page.evaluate(() => !!document.querySelector('.ex-blank') && document.querySelectorAll('#exBank .ex-mc-opt').length === 3));
  ok('blank hides the target word', await page.evaluate(() => { const q = S.qList[S.qIdx]; return document.getElementById('exSent').textContent.indexOf(q.word.hanzi) < 0; }));
  // Wrong answer via keyboard: progress must not move, item re-queued.
  const wrongKey = await page.evaluate(() => { const q = S.qList[S.qIdx]; return String(((q.ansIdx + 1) % 3) + 1); });
  await page.keyboard.press(wrongKey); await page.keyboard.press('Enter'); await sleep(200);
  s = await state();
  ok('wrong fill → bad band', s.band.includes('bad'));
  ok('wrong answer does not advance progress', s.bar === '0%', s.bar);
  ok('Meaning line shown', /Meaning:/.test(s.result), s.result.slice(0, 60));
  ok('missed item re-queued', s.len === 11, String(s.len));
  // Correct answer on the next one.
  await page.evaluate(() => nextQuizQ()); await sleep(150);
  await page.evaluate(() => { const q = S.qList[S.qIdx]; pickMC(q.ansIdx); checkAns(); }); await sleep(150);
  s = await state();
  ok('correct fill → good band', s.band.includes('good'));
  await page.evaluate(() => nextQuizQ()); await sleep(150);
  s = await state();
  ok('progress moves after a correct answer', s.bar === '10%', s.bar);
  // Jump to the re-queued copy at the end.
  await page.evaluate(() => { S.qIdx = S.qList.length - 2; nextQuizQ(); }); await sleep(150);
  s = await state();
  ok('re-queued item shows PREVIOUS MISTAKE', /PREVIOUS MISTAKE/.test(s.badge), s.badge);

  console.log('=== match pairs ===');
  await start('match');
  s = await state();
  ok('match rendered with 5+5 cards', s.type === 'match' && await page.evaluate(() => document.querySelectorAll('.ex-match-btn').length === 10));
  // One wrong pair, then all correct → graded wrong (miss > 0).
  await page.evaluate(() => { const q = S.qList[S.qIdx]; pickMatch('L', q.pairs[0].id); pickMatch('R', q.pairs[1].id); });
  ok('wrong pair flagged', await page.evaluate(() => document.querySelectorAll('.ex-match-btn.miss').length === 2));
  await page.evaluate(() => { const q = S.qList[S.qIdx]; q.pairs.forEach((w) => { pickMatch('L', w.id); pickMatch('R', w.id); }); });
  s = await state();
  ok('all matched → graded (with a miss = bad)', s.band.includes('bad'));
  await page.evaluate(() => nextQuizQ()); await sleep(150);
  await page.evaluate(() => { const q = S.qList[S.qIdx]; q.pairs.forEach((w) => { pickMatch('R', w.id); pickMatch('L', w.id); }); });
  s = await state();
  ok('clean match → good', s.band.includes('good'));

  console.log('=== English → Chinese ===');
  await start('zh');
  s = await state();
  ok('zh rendered with English prompt', s.type === 'zh' && await page.evaluate(() => /[A-Za-z]/.test(document.getElementById('exSent').textContent)));
  await page.evaluate(() => { const q = S.qList[S.qIdx]; q.ans.forEach((t) => { const i = q.bank.findIndex((b, k) => b === t && !q.sel.includes(k)); tapBank(i); }); });
  ok('keyboard toggle survives chip taps', await page.evaluate(() => !!document.querySelector('#exBank .ex-zh-toggle')));
  await page.evaluate(() => checkAns()); await sleep(100);
  s = await state();
  ok('correct chips → good', s.band.includes('good'), s.result.slice(0, 40));
  await page.evaluate(() => nextQuizQ()); await sleep(150);
  await page.evaluate(() => toggleZhInput()); await sleep(100);
  ok('typing mode shows textarea', await page.evaluate(() => !!document.getElementById('zhInput')));
  await page.evaluate(() => { const q = S.qList[S.qIdx]; const inp = document.getElementById('zhInput'); inp.value = q.sent[0].replace(/[。！？]/g, ''); inp.dispatchEvent(new Event('input')); });
  await page.evaluate(() => checkAns()); await sleep(100);
  s = await state();
  ok('typed answer without punctuation accepted', s.band.includes('good'));
  await page.evaluate(() => nextQuizQ()); await sleep(150);
  await page.evaluate(() => { toggleZhInput(); const inp = document.getElementById('zhInput'); inp.value = '我不知道'; inp.dispatchEvent(new Event('input')); checkAns(); });
  s = await state();
  ok('wrong typed answer → bad + correct sentence shown', s.band.includes('bad') && /Correct answer/.test(s.result));

  ok('no page errors', errors.length === 0, errors.join(' | '));
  await browser.close();
  console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
