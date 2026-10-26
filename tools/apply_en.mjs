// apply_en.mjs — merge tools/en_out/*.json translations into all data files
// + regenerate mobile copies + splice inline data in index.html.
// Run from repo root: node tools/apply_en.mjs
import fs from 'fs';
import path from 'path';

const ROOT = path.resolve(import.meta.dirname, '..');
const OUT = path.join(ROOT, 'tools', 'en_out');
const J = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const W = (p, d) => fs.writeFileSync(p, JSON.stringify(d));
const fail = m => { console.error('FAIL:', m); process.exit(1); };

// ---- 1. collect vocab translations ----
function vocabMap(prefix) {
  const files = fs.readdirSync(OUT).filter(f => f.startsWith(prefix + '_')).sort();
  const map = {};
  for (const f of files) Object.assign(map, J(path.join(OUT, f)));
  return map;
}
const en2 = vocabMap('hsk2');
const en1 = vocabMap('hsk1');
console.log(`translations loaded: hsk1=${Object.keys(en1).length} hsk2=${Object.keys(en2).length}`);

// ---- 2. apply to vocab arrays ----
function applyVocab(vocab, map, tag) {
  let n = 0;
  for (const w of vocab) {
    const t = map[String(w.id)];
    if (!t) fail(`${tag} word ${w.id} missing translation`);
    if (!Array.isArray(t) || t.length !== w.sentences.length)
      fail(`${tag} word ${w.id}: got ${t?.length} translations, need ${w.sentences.length}`);
    w.sentences.forEach((s, i) => { s[2] = t[i]; n++; });
  }
  return n;
}

const vd = J(path.join(ROOT, 'vocab_data.json'));
const h1 = J(path.join(ROOT, 'hsk1_data.json'));
console.log(`hsk2 sentences: ${applyVocab(vd.vocab, en2, 'hsk2')}`);
console.log(`hsk1 sentences: ${applyVocab(h1.vocab, en1, 'hsk1')}`);

// ---- 3. radicals ----
const radEn = J(path.join(OUT, 'radicals.json'));
let rn = 0;
for (const r of vd.radicals) {
  if (!(r.radical in radEn)) fail(`radical ${r.radical} missing`);
  r.explanation = radEn[r.radical]; rn++;
}
console.log(`radical explanations: ${rn}`);

// ---- 4. stories ----
const stEn = J(path.join(OUT, 'stories.json'));
function applyStories(file) {
  const stories = J(path.join(ROOT, file));
  for (const s of stories) {
    const t = stEn[s.id];
    if (!t) fail(`story ${s.id} missing translation`);
    s.title = t.title;
    let ni = 0, ci = 0, qi = 0;
    for (const b of s.beats) {
      if (b.t === 'narrate') { b.en = t.narrate[ni++]; delete b.idn; }
      else if (b.t === 'check') { b.en = t.check[ci++]; delete b.idn; }
      else if (b.t === 'pick') { b.q = t.pick_q[qi++]; delete b.idn; }
      else if (b.t === 'say') { delete b.idn; }
    }
    if (ni !== t.narrate.length || ci !== t.check.length || qi !== t.pick_q.length)
      fail(`story ${s.id}: beat count mismatch (narrate ${ni}/${t.narrate.length}, check ${ci}/${t.check.length}, pick ${qi}/${t.pick_q.length})`);
  }
  W(path.join(ROOT, file), stories);
  console.log(`${file}: ${stories.length} stories translated`);
  return stories;
}
const s1 = applyStories('assets/data/stories_hsk1.json');
const s2 = applyStories('assets/data/stories_hsk2.json');

// ---- 5. write source files ----
W(path.join(ROOT, 'vocab_data.json'), vd);
W(path.join(ROOT, 'hsk1_data.json'), h1);
console.log('vocab_data.json + hsk1_data.json written');

// ---- 6. mobile copies ----
const M = f => path.join(ROOT, 'mobile', 'assets', 'data', f);
W(M('vocab.json'), vd.vocab);
W(M('vocab_hsk1.json'), h1.vocab);
W(M('radicals.json'), vd.radicals);
W(M('stories_hsk1.json'), s1);
W(M('stories_hsk2.json'), s2);
console.log('mobile assets written');

// ---- 7. splice index.html ----
const HTML = path.join(ROOT, 'index.html');
let html = fs.readFileSync(HTML, 'utf8');

function spliceConst(html, name, value) {
  // matches "const NAME = <json>;" or "NAME = <json>;" up to end of line
  const re = new RegExp(`(${name}\\s*=\\s*)(?:\\[|\\{)[\\s\\S]*?;\\s*\\n`);
  const m = html.match(re);
  if (!m) fail(`splice: ${name} not found`);
  return html.replace(re, `$1${JSON.stringify(value)};\n`);
}

// VOCAB_DATA strips 'topic' (PWA uses WORD_TOPIC array instead)
html = spliceConst(html, 'VOCAB_DATA', vd.vocab.map(({ topic, ...w }) => w));
html = spliceConst(html, 'RADICALS_DATA', vd.radicals);
html = spliceConst(html, 'HSK1_VOCAB_DATA', h1.vocab); // keeps 'topic'
fs.writeFileSync(HTML, html);
console.log('index.html spliced');

// ---- 8. verify no Indonesian leakage in written data ----
const probe = JSON.stringify([vd.vocab[0].sentences, h1.vocab[0].sentences, vd.radicals[0].explanation, s1[0].title, s1[0].beats.slice(0, 6)]);
if (/\b(yang|dan|di |ke |dari|untuk|adalah|saya|kamu|dia|tidak|dengan|ini|itu|sudah|belum|sangat)\b/i.test(probe))
  console.warn('WARN: possible Indonesian residue in samples — review manually');
else console.log('sample Indonesian check: clean');
console.log('DONE ✅');
