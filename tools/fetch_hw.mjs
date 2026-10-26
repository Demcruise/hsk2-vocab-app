// Download hanzi-writer stroke data for all unique chars in HSK1+HSK2 vocab
// → single bundle ../assets/hw.json + ../mobile/assets/data/hw.json
// Also downloads hanzi-writer.min.js → ../assets/
import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { join } from 'path';
import { fileURLToPath } from 'url';

const ROOT = join(fileURLToPath(new URL('.', import.meta.url)), '..');
const v2 = JSON.parse(readFileSync(join(ROOT, 'vocab_data.json'), 'utf8'));
const v1 = JSON.parse(readFileSync(join(ROOT, 'hsk1_data.json'), 'utf8'));
const words = [...(v2.vocab || v2), ...(v1.vocab || v1)];
const chars = [...new Set(words.flatMap(w => [...w.hanzi]))];
console.log('chars:', chars.length);

const out = {};
let fail = [];
const CONC = 12;
for (let i = 0; i < chars.length; i += CONC) {
  await Promise.all(chars.slice(i, i + CONC).map(async c => {
    try {
      const r = await fetch(`https://cdn.jsdelivr.net/npm/hanzi-writer-data@2.0.1/${encodeURIComponent(c)}.json`);
      if (!r.ok) { fail.push(c); return; }
      const j = await r.json();
      out[c] = { s: j.strokes, m: j.medians };
    } catch { fail.push(c); }
  }));
  process.stdout.write(`\r${Math.min(i + CONC, chars.length)}/${chars.length}`);
}
console.log('\nfail:', fail.length, fail.join(''));
if (fail.length) {
  // retry failures once
  for (const c of [...fail]) {
    try {
      const r = await fetch(`https://cdn.jsdelivr.net/npm/hanzi-writer-data@2.0.1/${encodeURIComponent(c)}.json`);
      if (r.ok) { out[c] = await r.json().then(j => ({ s: j.strokes, m: j.medians })); fail = fail.filter(x => x !== c); }
    } catch {}
  }
  console.log('still failing:', fail.join(''));
}

mkdirSync(join(ROOT, 'assets'), { recursive: true });
writeFileSync(join(ROOT, 'assets', 'hw.json'), JSON.stringify(out));
mkdirSync(join(ROOT, 'mobile', 'assets', 'data'), { recursive: true });
writeFileSync(join(ROOT, 'mobile', 'assets', 'data', 'hw.json'), JSON.stringify(out));
console.log('hw.json bytes:', JSON.stringify(out).length);

// hanzi-writer lib
const lib = await fetch('https://cdn.jsdelivr.net/npm/hanzi-writer@3.7.3/dist/hanzi-writer.min.js');
writeFileSync(join(ROOT, 'assets', 'hanzi-writer.min.js'), await lib.text());
console.log('hanzi-writer.min.js saved');
