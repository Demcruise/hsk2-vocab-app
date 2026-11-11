// Tests for tiered badges: tier maths, silent baseline for existing progress, unlock popup
// at end of a quiz (not mid-question), queueing, gallery rendering, persistence, counters.
//
// Usage: serve the repo root over http, then
//   node tools/badges.test.js [baseUrl]
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
  const reload = async () => { await page.reload({ waitUntil: 'networkidle2' }); await sleep(1200); };
  await reload();

  console.log('=== tier maths ===');
  const m = await page.evaluate(() => {
    const b = BADGES.find((x) => x.id === 'xp');
    return { t0: badgeTier(b, 99), t1: badgeTier(b, 100), t3: badgeTier(b, 1500), t5: badgeTier(b, 99999),
      clamp: clampTiers([10, 25, 50, 100, 40], 40), all5: BADGES.every((x) => { const t = x.tiers(); return t.length >= 1 && t.length <= 5 && t.every((v, i) => !i || v > t[i - 1]); }) };
  });
  ok('tier counts thresholds reached', m.t0 === 0 && m.t1 === 1 && m.t3 === 3 && m.t5 === 5, JSON.stringify(m));
  ok('word tiers clamp to level size', JSON.stringify(m.clamp) === '[10,25,40]', JSON.stringify(m.clamp));
  ok('every badge has 1-5 strictly rising tiers', m.all5);

  console.log('=== fresh start ===');
  ok('fresh level baseline set with no tiers', await page.evaluate(() => S.ach._b === 1 && BADGES.every((b) => !S.ach[b.id] || b.id === 'streak')));
  ok('no popup on load', await page.evaluate(() => !document.getElementById('badgeView').classList.contains('open')));

  console.log('=== unlock after quiz ===');
  await page.evaluate(() => { switchScreen('quiz'); startQuiz(null, null, 'hz2mn'); const q = S.qList[S.qIdx]; pickMC(q.ansIdx); checkAns(); });
  await sleep(300);
  ok('no popup mid-quiz', await page.evaluate(() => !document.getElementById('badgeView').classList.contains('open')));
  await page.evaluate(() => { S.qList.length = S.qIdx + 1; finishQ(); });
  await sleep(1800);
  const pop = await page.evaluate(() => ({ open: document.getElementById('badgeView').classList.contains('open'), name: document.getElementById('bvName').textContent, tier: document.getElementById('bvTier').textContent, q: BADGE_Q.map((x) => x.b.id), ach: S.ach }));
  ok('popup opens after quiz ends', pop.open, JSON.stringify(pop));
  ok('Quiz Taker level 1 unlocked', pop.ach.quizzes === 1 && (pop.name === 'Quiz Taker' || pop.q.includes('quizzes')), JSON.stringify(pop.ach));
  ok('perfect quiz counted', await page.evaluate(() => S.pf === 1 && S.ach.perfect === 1));
  ok('popup shows level text', /Level 1 of 5/.test(pop.tier), pop.tier);
  // drain the queue
  let shown = 1;
  for (let i = 0; i < 8; i++) {
    const more = await page.evaluate(() => { nextBadge(); return BADGE_Q.length; });
    await sleep(300);
    if (await page.evaluate(() => document.getElementById('badgeView').classList.contains('open'))) shown++;
    if (!more) break;
  }
  await page.evaluate(() => { if (document.getElementById('badgeView').classList.contains('open')) nextBadge(); });
  await sleep(250);
  ok('queued badges shown one by one, then closed', shown >= 2 && await page.evaluate(() => !document.getElementById('badgeView').classList.contains('open') && BADGE_Q.length === 0), String(shown));
  ok('no repeat popup for same tier', await page.evaluate(() => { checkBadges(); return !document.getElementById('badgeView').classList.contains('open'); }));

  console.log('=== multi-tier jump ===');
  await page.evaluate(() => { S.xp = 1200; saveState(); checkBadges(); });
  const xp = await page.evaluate(() => ({ t: S.ach.xp, txt: document.getElementById('bvTier').textContent, n: document.getElementById('bvName').textContent, d: document.getElementById('bvDesc').textContent }));
  ok('jump announces highest tier once', xp.t === 3 && xp.n === 'XP Climber' && /Level 3/.test(xp.txt) && /1000 XP/.test(xp.d), JSON.stringify(xp));
  await page.evaluate(() => nextBadge());

  console.log('=== gallery ===');
  await page.evaluate(() => switchScreen('progress')); await sleep(400);
  const g = await page.evaluate(() => ({ n: document.querySelectorAll('#achievementList .bdg').length, locked: document.querySelectorAll('#achievementList .bdg.locked').length, sum: document.querySelector('.bdg-sum').textContent, xpTxt: [...document.querySelectorAll('.bdg')].find((e) => /XP Climber/.test(e.textContent)).querySelector('.bdg-t').textContent }));
  ok('gallery lists every badge', g.n === 9, JSON.stringify(g));
  ok('locked badges greyed', g.locked >= 1 && g.locked < 9, String(g.locked));
  ok('progress to next tier shown', /1200 \/ 2500 XP/.test(g.xpTxt), g.xpTxt);
  ok('summary counts earned levels', /^\d+ of \d+ badge levels earned$/.test(g.sum), g.sum);
  const over = await page.evaluate(() => { const e = document.documentElement; return e.scrollWidth <= e.clientWidth; });
  ok('no horizontal overflow at 400px', over);

  console.log('=== baseline + persistence ===');
  await reload();
  ok('tiers survive reload, no popup', await page.evaluate(() => S.ach.xp === 3 && S.ach.quizzes === 1 && !document.getElementById('badgeView').classList.contains('open')));
  await page.evaluate(() => { const k = storeKey(); const b = JSON.parse(localStorage.getItem(k)); b.a = { fv: true, fq: true }; b.x = 600; localStorage.setItem(k, JSON.stringify(b)); });
  await reload();
  ok('old achievement data migrated silently', await page.evaluate(() => S.ach._b === 1 && !('fv' in S.ach) && S.ach.xp === 2 && !document.getElementById('badgeView').classList.contains('open')), await page.evaluate(() => JSON.stringify(S.ach)));
  ok('backup includes perfect count', await page.evaluate(() => progressPayload().pf === 1));

  console.log('=== other counters ===');
  await page.evaluate(() => { for (let i = 0; i < 5; i++) markCharPractised('字一二三四五六'[i]); closeWrite(); });
  ok('writing practice unlocks Brush Master on close', await page.evaluate(() => S.ach.chars === 1 && document.getElementById('bvName').textContent === 'Brush Master'));
  await page.evaluate(() => nextBadge());
  const qd = await page.evaluate(() => { const before = DAILY.qdone || 0; DAILY.claimed = {}; DAILY.stats = {}; dailyTrack('xp', 999); return (DAILY.qdone || 0) - before; });
  ok('completed quests are counted', qd >= 1, String(qd));

  ok('no page errors', errors.length === 0, errors.join(' | '));
  await browser.close();
  console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
