// Build a LOCAL-ONLY app level file for an HSK 3.0 (2025) level.
//
// Inputs : local-content/hsk2025.json   (from tools/extract_local_hsk.mjs, personal use only)
//          vocab_data.json, hsk1_data.json (existing app data: topics + own sentences)
//          tools/hsk2025_l<N>_authoring.json (original topics + sentences for gaps)
// Output : local-content/level-hsk<N>-2025.json and local-content/levels.json (index)
//          — both gitignored; loaded by index.html when present.
//
// Usage  : node tools/build_local_level.mjs [level]   (default 2)
import { readFileSync, writeFileSync, existsSync, readdirSync } from 'fs';
import { join, resolve } from 'path';
import { fileURLToPath } from 'url';
import { pinyin as pinyinPro } from 'pinyin-pro';

const ROOT = resolve(fileURLToPath(new URL('.', import.meta.url)), '..');
const LEVEL = process.argv[2] || '2';
const DIR = join(ROOT, 'local-content');
const SRC = join(DIR, 'hsk2025.json');
const OUT = join(DIR, `level-hsk${LEVEL}-2025.json`);
const MAX_SENT = 10, MIN_SENT = 3;

if (!existsSync(SRC)) { console.error('Missing ' + SRC + ' — run tools/extract_local_hsk.mjs first.'); process.exit(1); }
const words = JSON.parse(readFileSync(SRC, 'utf8')).words.filter((w) => w.level === LEVEL);
if (!words.length) { console.error('No words for level ' + LEVEL); process.exit(1); }
const appHsk2 = JSON.parse(readFileSync(join(ROOT, 'vocab_data.json'), 'utf8')).vocab;
const appHsk1 = JSON.parse(readFileSync(join(ROOT, 'hsk1_data.json'), 'utf8')).vocab;
const app = [...appHsk1, ...appHsk2];
const allWords = JSON.parse(readFileSync(SRC, 'utf8')).words;

// ---- Pinyin for authored sentences written as [hanzi, english] ----
// Longest match against the word lexicon (authoritative word pinyin from the source
// list and app data, e.g. 一块儿 yíkuàir, 左边 zuǒbian); remaining single characters
// fall back to pinyin-pro, which applies 一/不 tone sandhi.
const wordPinyin = new Map();
for (const w of allWords) if ([...w.hanzi].length > 1 && w.pinyin && !wordPinyin.has(w.hanzi)) wordPinyin.set(w.hanzi, w.pinyin.replace(/\s+/g, ''));
for (const v of app) if ([...v.hanzi].length > 1 && v.pinyin && !wordPinyin.has(v.hanzi)) wordPinyin.set(v.hanzi, v.pinyin.replace(/\s+/g, ''));
// Erhua words whose source pinyin dropped the final r (差点儿 "chàdiǎn" -> "chàdiǎnr").
for (const [hz, py] of wordPinyin) if (hz.endsWith('儿') && !/r$/.test(py) && !/ér$/.test(py)) wordPinyin.set(hz, py + 'r');
// A few proper nouns used in authored sentences.
for (const [hz, py] of Object.entries({ 上海: 'Shànghǎi', 杭州: 'Hángzhōu', 海淀区: 'Hǎidiàn Qū', 英国: 'Yīngguó', 西安: "Xī'ān" })) wordPinyin.set(hz, py);
const MAX_WORD = Math.max(...[...wordPinyin.keys()].map((k) => k.length));
const PUNCT = { '。': '.', '，': ',', '？': '?', '！': '!', '、': ',', '：': ':', '；': ';', '“': '"', '”': '"' };
// target: the vocabulary word the sentence illustrates; it is always kept as one
// segment so greedy matching can't swallow it (要好好 must be 要 + 好好, not 要好 + 好).
function sentencePinyin(hz, target) {
  const out = [];
  const tPy = target && [...target].length > 1 ? wordPinyin.get(target) : null;
  for (let i = 0; i < hz.length;) {
    if (tPy && hz.startsWith(target, i)) { out.push(tPy); i += target.length; continue; }
    let hit = null;
    for (let n = Math.min(MAX_WORD, hz.length - i); n > 1; n--) {
      const w = hz.slice(i, i + n);
      // Don't let a lexicon word straddle the start of the target word.
      if (tPy && target !== w && hz.indexOf(target, i) > i && hz.indexOf(target, i) < i + n) continue;
      if (wordPinyin.has(w)) { hit = w; break; }
    }
    if (hit) { out.push(wordPinyin.get(hit)); i += hit.length; continue; }
    const ch = hz[i];
    if (PUNCT[ch]) { if (out.length) out[out.length - 1] += PUNCT[ch]; i++; continue; }
    if (/\p{Script=Han}/u.test(ch)) out.push(pinyinPro(hz, { type: 'array' })[i]);
    else out.push(ch);
    i++;
  }
  const s = out.join(' ').replace(/\s+([.,?!:;])/g, '$1');
  return s.charAt(0).toUpperCase() + s.slice(1);
}
const normSent = (s, target) => (s.length === 2 ? [s[0], sentencePinyin(s[0], target), s[1]] : s);

// ---- Authoring: every tools/hsk2025_l<N>_authoring*.json file ----
const authFiles = readdirSync(join(ROOT, 'tools')).filter((f) => /^hsk2025_l.+_authoring.*\.json$/.test(f));
const readAuth = (f) => JSON.parse(readFileSync(join(ROOT, 'tools', f), 'utf8'));
const authoring = { topics: {}, sentences: {} };
for (const f of authFiles.filter((f) => f.startsWith(`hsk2025_l${LEVEL}_authoring`))) {
  const a = readAuth(f);
  Object.assign(authoring.topics, a.topics || {});
  // Compact form: { "topicGroups": { "jalan": "车站 机场 ..." } }
  for (const [t, list] of Object.entries(a.topicGroups || {})) for (const hz of list.split(/\s+/).filter(Boolean)) authoring.topics[hz] = t;
  for (const [hz, list] of Object.entries(a.sentences || {})) authoring.sentences[hz] = [...(authoring.sentences[hz] || []), ...list.map((s) => normSent(s, hz.split('|')[0]))];
}
// Guard: an authored sentence must actually contain its word.
const badAuthored = Object.entries(authoring.sentences).flatMap(([hz, list]) => list.filter((s) => !s[0].includes(hz.split('|')[0])).map((s) => `${hz}: ${s[0]}`));
if (badAuthored.length) { console.error('Authored sentences missing their word:\n  ' + badAuthored.join('\n  ')); process.exit(1); }

// Sentence corpus = the project's own sentences: app data + every level's authored sentences.
const corpus = [];
const seen = new Set();
const addSent = (s) => { if (!seen.has(s[0])) { seen.add(s[0]); corpus.push(s); } };
for (const v of app) for (const s of v.sentences || []) addSent(s);
for (const f of authFiles) for (const [hz, list] of Object.entries(readAuth(f).sentences || {})) list.forEach((s) => addSent(normSent(s, hz.split('|')[0])));
const tokens = (s) => s[2].split(/\s+/).filter(Boolean).length;

// A corpus sentence counts for word W only if W occurs outside every longer known
// word that contains it (地 the particle must not match 地方 / 地球).
const lexicon = [...new Set([
  ...allWords.map((w) => w.hanzi),
  ...app.map((v) => v.hanzi),
])];
const longerCache = new Map();
function containsWord(sentence, hz) {
  if (!sentence.includes(hz)) return false;
  if (!longerCache.has(hz)) longerCache.set(hz, lexicon.filter((x) => x.length > hz.length && x.includes(hz)).sort((a, b) => b.length - a.length));
  const longer = longerCache.get(hz);
  let s = sentence;
  for (const x of longer) s = s.split(x).join('□');
  return s.includes(hz);
}

const report = { ownSentences: 0, corpusSentences: 0, authoredSentences: 0, short: [], topicFromApp: 0, topicAuthored: 0, topicMissing: [] };
const vocab = [], topics = [];
words.forEach((w, i) => {
  // Same hanzi AND same (toneless) reading: 重 chóng must not reuse 重 zhòng's data.
  const plainPy = (p) => (p || '').normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z]/gi, '').toLowerCase();
  const own = app.find((v) => v.hanzi === w.hanzi && plainPy(v.pinyin) === plainPy(w.pinyin));
  // Polyphones (还 hái / huán): the corpus can't tell readings apart, so only authored
  // sentences are used. Authoring may key an entry as "hanzi|pinyin" (e.g. "重|chóng");
  // a bare hanzi key applies only when this level has a single entry for that hanzi.
  const compact = w.pinyin.replace(/\s+/g, '');
  const polyphone = [...allWords, ...app].some((x) => x.hanzi === w.hanzi && plainPy(x.pinyin) !== plainPy(w.pinyin));
  const uniqueInLevel = words.filter((x) => x.hanzi === w.hanzi).length === 1;
  const pick = (map) => map[w.hanzi + '|' + compact] || (uniqueInLevel ? map[w.hanzi] : undefined);
  let sents = [];
  if (own && own.sentences && own.sentences.length) { sents = own.sentences.slice(0, MAX_SENT); report.ownSentences++; }
  else {
    const authored = pick(authoring.sentences) || [];
    const fromCorpus = polyphone ? [] : corpus
      .filter((s) => containsWord(s[0], w.hanzi) && !authored.some((a) => a[0] === s[0]))
      .sort((a, b) => Math.abs(tokens(a) - 6) - Math.abs(tokens(b) - 6));
    sents = [...authored, ...fromCorpus].slice(0, MAX_SENT);
    if (authored.length) report.authoredSentences++; else report.corpusSentences++;
  }
  if (sents.length < MIN_SENT) report.short.push(`${w.hanzi} ${compact}(${sents.length})`);

  let topic = own && own.topic;
  if (topic) report.topicFromApp++;
  else if (pick(authoring.topics)) { topic = pick(authoring.topics); report.topicAuthored++; }
  else { topic = 'umum'; report.topicMissing.push(w.hanzi); }

  vocab.push({
    id: i + 1,
    hanzi: w.hanzi,
    traditional: (own && own.traditional) || w.hanzi,
    pinyin: w.hanzi.endsWith('儿') && !/r$/.test(compact) && !/ér$/.test(compact) ? compact + 'r' : compact,
    meaning: w.meaning_en,
    sentences: sents,
    src: w.id,
  });
  topics.push(topic);
});

const key = 'hsk' + LEVEL.replace(/\D.*$/, '') + 'b'; // 2 -> hsk2b (kept stable: it names the storage bucket)
writeFileSync(OUT, JSON.stringify({
  key,
  label: `HSK ${LEVEL} (2025)`,
  edition: 'hsk3.0-2025',
  level: LEVEL,
  store: 'k' + key,
  license: 'PERSONAL USE ONLY — word list derived from HanziStroke PDFs (L-02). Do not commit or deploy.',
  generatedAt: new Date().toISOString(),
  vocab,
  topics,
}));
// Index of every built level, so the app needs a single request to discover them.
const files = readdirSync(DIR).filter((f) => /^level-hsk.+-2025\.json$/.test(f))
  .sort((a, b) => parseInt(a.slice(9)) - parseInt(b.slice(9)));
writeFileSync(join(DIR, 'levels.json'), JSON.stringify({ levels: files }));
console.log(`level-hsk${LEVEL}-2025: ${vocab.length} words | index: ${files.join(', ')}`);
console.log(`sentences: own ${report.ownSentences}, corpus ${report.corpusSentences}, authored ${report.authoredSentences}; <${MIN_SENT}: ${report.short.join(' ') || 'none'}`);
console.log(`topics: app ${report.topicFromApp}, authored ${report.topicAuthored}, missing ${report.topicMissing.length} ${report.topicMissing.join(' ')}`);
process.exit(report.short.length || report.topicMissing.length ? 1 : 0);
