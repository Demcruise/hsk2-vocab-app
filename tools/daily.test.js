// Tests for the daily system: activity-based streak (K-03), daily goal, rotating
// quests with one-time bonus, quest panel after a quiz, and migration of old streaks.
// Days are simulated by rewriting the stored dates in khsk-daily.
//
// Usage: serve the repo root over http, then
//   node tools/daily.test.js [baseUrl]
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

  console.log('=== streak counts study days, not app opens (K-03) ===');
  let s = await page.evaluate(() => ({ streak: S.streak, ext: extendedToday(), off: document.getElementById('streakSt').classList.contains('off') }));
  ok('fresh user: streak 0, flame off', s.streak === 0 && !s.ext && s.off, JSON.stringify(s));
  await reload(); await reload();
  ok('reloading does not raise the streak', await page.evaluate(() => S.streak === 0));
  await page.evaluate(() => addXP(10)); await sleep(100);
  s = await page.evaluate(() => ({ streak: S.streak, ext: extendedToday(), off: document.getElementById('streakSt').classList.contains('off') }));
  ok('first XP of the day → streak 1, flame lit', s.streak === 1 && s.ext && !s.off, JSON.stringify(s));
  await page.evaluate(() => addXP(10));
  ok('more XP the same day keeps streak at 1', await page.evaluate(() => S.streak === 1));

  console.log('=== day changes ===');
  const ago = (n) => page.evaluate((n) => { const d = new Date(); d.setDate(d.getDate() - n); return todayStr(d); }, n);
  const y1 = await ago(1), y2 = await ago(2);
  await page.evaluate((y) => { DAILY.streak = 4; DAILY.lastActive = y; DAILY.day = y; saveDaily(); }, y1);
  await reload();
  s = await page.evaluate(() => ({ streak: S.streak, ext: extendedToday(), q: DAILY.quests.length, stats: DAILY.stats }));
  ok('studied yesterday: streak kept but not yet extended', s.streak === 4 && !s.ext, JSON.stringify(s));
  ok('new day resets quest counters', s.q === 3 && Object.keys(s.stats).length === 0);
  await page.evaluate(() => addXP(5));
  ok('XP today extends to 5', await page.evaluate(() => S.streak === 5 && DAILY.best >= 5));
  await page.evaluate((y) => { DAILY.streak = 9; DAILY.lastActive = y; DAILY.day = y; saveDaily(); }, y2);
  await reload();
  ok('missed a whole day: streak broken to 0', await page.evaluate(() => S.streak === 0));
  await page.evaluate(() => addXP(5));
  ok('studying again restarts at 1', await page.evaluate(() => S.streak === 1));

  console.log('=== daily goal & quests ===');
  s = await page.evaluate(() => ({ quests: DAILY.quests, same: JSON.stringify(pickQuests(todayStr())) === JSON.stringify(DAILY.quests) }));
  ok('3 quests, first is the XP goal', s.quests.length === 3 && s.quests[0] === 'xp' && new Set(s.quests).size === 3, s.quests.join(','));
  ok('quests are stable for the day (date-seeded)', s.same);
  await page.evaluate(() => setDailyGoal(50));
  ok('goal setting updates the XP quest', await page.evaluate(() => questDef('xp').target === 50 && /50 XP/.test(document.getElementById('goalPick').textContent)));
  const before = await page.evaluate(() => S.xp);
  await page.evaluate(() => addXP(50));
  s = await page.evaluate(() => ({ xp: S.xp, claimed: !!DAILY.claimed.xp }));
  ok('reaching the goal completes the quest with a one-time bonus', s.claimed && s.xp === before + 50 + 5, JSON.stringify(s));
  await page.evaluate(() => addXP(10));
  ok('bonus is not paid twice', await page.evaluate((b) => S.xp === b + 50 + 5 + 10, before));

  console.log('=== quest panel after a quiz, persistence ===');
  await page.evaluate(() => { switchScreen('quiz'); startQuiz(); S.qRight = S.qList.length; finishQ(); });
  ok('quiz complete screen lists daily quests', await page.evaluate(() => document.querySelectorAll('#qdQuests .quest').length === 3 && /left/.test(document.getElementById('qdQuests').textContent)));
  ok('quiz counted for lesson/quiz80 metrics', await page.evaluate(() => DAILY.stats.lessons >= 1 && DAILY.stats.quiz80 >= 1));
  ok('Progress shows daily quests + countdown', await page.evaluate(() => { switchScreen('progress'); renderRail(); return document.querySelectorAll('#dailyQuests .quest').length === 3 && /left/.test(document.getElementById('dqLeft').textContent); }));
  const snap = await page.evaluate(() => JSON.stringify({ g: DAILY.goal, s: DAILY.streak, st: DAILY.stats }));
  await reload();
  ok('daily state survives reload', await page.evaluate((x) => JSON.stringify({ g: DAILY.goal, s: DAILY.streak, st: DAILY.stats }) === x, snap));
  ok('streak shared across levels', await page.evaluate(() => { const a = S.streak; switchLevel('hsk1'); const b = S.streak; switchLevel('hsk2'); return a === b && a > 0; }));

  console.log('=== migration from the old per-level streak ===');
  await page.evaluate(() => { localStorage.removeItem('khsk-daily'); const d = new Date(); d.setDate(d.getDate() - 1); const b = JSON.parse(localStorage.getItem('khsk2') || '{}'); b.s = 7; b.l = d.toDateString(); localStorage.setItem('khsk2', JSON.stringify(b)); });
  await reload();
  ok('alive old streak (yesterday) is carried over', await page.evaluate(() => S.streak === 7 && !extendedToday()));

  ok('no page errors', errors.length === 0, errors.join(' | '));
  await browser.close();
  console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
