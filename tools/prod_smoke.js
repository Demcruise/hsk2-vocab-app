const puppeteer = require('puppeteer-core');
(async () => {
  const b = await puppeteer.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: 'new', args: ['--no-sandbox'] });
  const p = await b.newPage();
  const errs = [];
  p.on('pageerror', e => errs.push(e.message.slice(0, 100)));
  p.on('requestfailed', r => { if (!/favicon/.test(r.url())) errs.push('REQ FAIL ' + r.url().slice(-60)); });
  await p.setViewport({ width: 400, height: 850 });
  // PWA
  await p.goto('https://demcruise.github.io/hsk2-vocab-app/', { waitUntil: 'networkidle2', timeout: 45000 });
  await new Promise(r => setTimeout(r, 2500));
  const pwa = await p.evaluate(() => ({ words: vocab.length, units: UNITS.length, sent: vocab[0].sentences[0][2] }));
  console.log('PWA:', JSON.stringify(pwa));
  // Flutter app
  await p.goto('https://demcruise.github.io/hsk2-vocab-app/app/', { waitUntil: 'networkidle2', timeout: 60000 });
  await new Promise(r => setTimeout(r, 9000));
  const flt = await p.evaluate(() => {
    const fv = document.querySelector('flutter-view');
    const canvas = document.querySelector('canvas');
    return { view: !!fv, canvas: !!canvas, w: canvas ? canvas.width : 0 };
  });
  console.log('FLUTTER:', JSON.stringify(flt));
  console.log('ERRORS:', errs.length ? errs.slice(0, 8) : 'none');
  await b.close();
})();
