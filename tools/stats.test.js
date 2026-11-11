// Tests for the Progress statistics card: summary tiles, 30-day XP columns + goal line +
// table view, 16-week heatmap levels, word status bar, review forecast, accuracy per
// exercise type (tracked from real answers), tooltip, persistence, dark mode, overflow.
//
// Usage: serve the repo root over http, then
//   node tools/stats.test.js [baseUrl]
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
  await page.setViewport({ width: 390, height: 850 });
  await page.goto(BASE, { waitUntil: 'networkidle2' });
  await page.evaluate(async () => {
    localStorage.clear();
    for (const r of await navigator.serviceWorker.getRegistrations()) await r.unregister();
    for (const k of await caches.keys()) await caches.delete(k);
  });
  const reload = async () => { await page.reload({ waitUntil: 'networkidle2' }); await sleep(1200); };
  await reload();

  console.log('=== empty state ===');
  await page.evaluate(() => switchScreen('progress')); await sleep(300);
  const e = await page.evaluate(() => ({ card: !!document.querySelector('#statsCharts .sx-tiles'), cols: document.querySelectorAll('#statsCharts .sx-plot:not(.sx-fc) .sx-col').length, cells: document.querySelectorAll('.sx-hm-grid i:not(.fut)').length, empties: [...document.querySelectorAll('.sx-empty')].map((x) => x.textContent) }));
  ok('stats card renders on a fresh profile', e.card && e.cols === 30, JSON.stringify(e));
  ok('heatmap covers the last 15-16 weeks up to today', e.cells >= 15 * 7 + 1 && e.cells <= 16 * 7, String(e.cells));
  ok('empty states for forecast and accuracy', e.empties.length === 2, JSON.stringify(e.empties));

  console.log('=== seeded history ===');
  await page.evaluate(() => {
    const t = todayStr();
    DAILY.history = {}; DAILY.goal = 30;
    DAILY.history[t] = 45; DAILY.history[srsAddDays(t, -1)] = 10; DAILY.history[srsAddDays(t, -5)] = 120; DAILY.history[srsAddDays(t, -40)] = 20; DAILY.history[srsAddDays(t, -200)] = 999;
    saveDaily(); renderStats();
  });
  const d = await page.evaluate(() => {
    const D = statsData();
    const cols = [...document.querySelectorAll('#statsCharts .sx-plot:not(.sx-fc) .sx-col')];
    const h = (i) => parseFloat(cols[i].querySelector('i').style.height);
    const cells = [...document.querySelectorAll('.sx-hm-grid i:not(.fut)')];
    return { sum: D.sum, avg: D.avg, best: D.best, active: D.active, sumTxt: document.getElementById('sxSum').textContent, actTxt: document.getElementById('sxActive').textContent,
      hToday: h(29), h5: h(24), h1: h(28), goal: parseFloat(document.querySelector('.sx-goal').style.bottom), todayCls: cols[29].classList.contains('today'),
      last: cells[cells.length - 1].className, lv: [0, 10, 20, 30, 59, 60].map((v) => sxHeatLevel(v, 30)), rows: document.querySelectorAll('.sx-tbl tbody tr').length,
      firstRow: document.querySelector('.sx-tbl tbody tr').textContent };
  });
  ok('tiles: 30-day total excludes older days', d.sum === 175 && d.sumTxt === '175' && d.actTxt === '3 / 30', JSON.stringify(d));
  ok('tiles: average and best day', d.avg === 6 && d.best === 120);
  ok('columns scale to a clean max (200): 120 → 60%, 45 → 22.5%', d.h5 === 60 && d.hToday === 22.5 && d.h1 === 5, JSON.stringify([d.h5, d.hToday, d.h1]));
  ok('goal line at 30/200 = 15% and today highlighted', d.goal === 15 && d.todayCls);
  ok('heatmap levels by goal (0,<half,<goal,<2x,≥2x)', JSON.stringify(d.lv) === '[0,1,2,3,3,4]' && d.last === 'l3', JSON.stringify(d));
  ok('table view lists 30 days, newest first', d.rows === 30 && /45$/.test(d.firstRow), d.firstRow);

  console.log('=== words, forecast, accuracy ===');
  await page.evaluate(() => {
    const t = todayStr();
    vocab.slice(0, 6).forEach((v, i) => { S.prog[v.id + ''] = { l: i < 2 ? 3 : 1, c: 1, w: 0, t: '', s: { d: srsAddDays(t, i < 3 ? 0 : 2), i: 1, e: 2.5, r: 1, x: 0, rv: t, lg: 'good' } }; });
    saveState();
    switchScreen('quiz'); startQuiz(null, null, 'hz2mn');
    let q = S.qList[S.qIdx]; pickMC(q.ansIdx); checkAns(); nextQuizQ();
    q = S.qList[S.qIdx]; pickMC((q.ansIdx + 1) % q.opts.length); checkAns();
    switchScreen('progress');
  });
  await sleep(300);
  const w = await page.evaluate(() => {
    const D = statsData();
    const keys = document.querySelector('.sx-keys').textContent;
    const fc = [...document.querySelectorAll('.sx-fc .sx-col')].map((c) => c.getAttribute('aria-label'));
    const acc = document.querySelector('.sx-acc') && document.querySelector('.sx-acc').textContent;
    return { st: D.st, keys, due: D.due, fc0: fc[0], fc2: fc[2], acc, ty: S.ty };
  });
  ok('word status counts', /Memorized \d+/.test(w.keys) && w.st.m >= 2 && w.st.l >= 3 && w.st.m + w.st.l + w.st.n > 0, JSON.stringify(w.st));
  ok('forecast: due now in Today, later in day 2', w.due[0] >= 3 && w.due[2] >= 3 && /words due/.test(w.fc0), JSON.stringify(w.due));
  ok('accuracy tracked per type from real answers', w.ty.hz2mn && w.ty.hz2mn[0] === 1 && w.ty.hz2mn[1] === 2, JSON.stringify(w.ty));
  ok('accuracy row shows 50% (2)', /Hanzi → meaning50% \(2\)/.test(w.acc), w.acc);

  console.log('=== tooltip ===');
  // Scrolling hides the tooltip by design, so bring the chart into view first.
  await page.evaluate(() => document.querySelector('#statsCharts .sx-plot').scrollIntoView({ block: 'center' })); await sleep(300);
  const col = await page.$('#statsCharts .sx-plot:not(.sx-fc) .sx-col:nth-child(25)');
  await col.hover(); await sleep(150);
  const tt = await page.evaluate(() => { const t = document.getElementById('sxTip'); return t && { v: t.style.display, b: t.querySelector('b').textContent, txt: t.textContent }; });
  ok('hovering a column shows value then day', tt && tt.v === 'block' && tt.b === '120', JSON.stringify(tt));
  await page.evaluate(() => document.querySelector('#statsCharts .sx-col:nth-child(30)').focus({ preventScroll: true })); await sleep(100);
  const kf = await page.evaluate(() => ({ b: document.querySelector('#sxTip b').textContent, d: document.getElementById('sxTip').style.display, a: document.activeElement.className }));
  ok('keyboard focus shows the same tooltip', kf.b === String(await page.evaluate(() => DAILY.history[todayStr()])) && kf.d === 'block', JSON.stringify(kf));

  console.log('=== persistence, dark mode, layout ===');
  await reload();
  ok('accuracy survives reload and is in backup', await page.evaluate(() => S.ty.hz2mn[1] === 2 && progressPayload().ty.hz2mn[1] === 2));
  await page.evaluate(() => { switchScreen('progress'); applyTheme('dark'); }); await sleep(200);
  const dk = await page.evaluate(() => ({ hm0: getComputedStyle(document.documentElement).getPropertyValue('--hm0').trim(), hm4: getComputedStyle(document.documentElement).getPropertyValue('--hm4').trim() }));
  ok('dark mode uses its own ramp (empty dark, top step bright)', dk.hm0 === '#22333B' && dk.hm4 === '#8EE04A', JSON.stringify(dk));
  await page.evaluate(() => applyTheme('light'));
  const over = await page.evaluate(() => { const card = document.getElementById('statsCard'); return document.documentElement.scrollWidth <= document.documentElement.clientWidth && card.scrollWidth <= card.clientWidth; });
  ok('no horizontal overflow at 390px', over);
  ok('switching level keeps XP history, resets per-level accuracy', await page.evaluate(() => { const before = statsData().sum; switchLevel('hsk1'); return before > 0 && statsData().sum === before && statsData().acc.length === 0; }));

  ok('no page errors', errors.length === 0, errors.join(' | '));
  await browser.close();
  console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(1); });
