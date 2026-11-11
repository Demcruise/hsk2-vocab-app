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
const authoringFile = (l) => join(ROOT, 'tools', `hsk2025_l${l}_authoring.json`);
const authoring = existsSync(authoringFile(LEVEL)) ? JSON.parse(readFileSync(authoringFile(LEVEL), 'utf8')) : { topics: {}, sentences: {} };
const app = [...appHsk1, ...appHsk2];

// Sentence corpus = the project's own sentences: app data + every level's authored sentences.
const corpus = [];
const seen = new Set();
const addSent = (s) => { if (!seen.has(s[0])) { seen.add(s[0]); corpus.push(s); } };
for (const v of app) for (const s of v.sentences || []) addSent(s);
for (const f of readdirSync(join(ROOT, 'tools')).filter((f) => /^hsk2025_l.+_authoring\.json$/.test(f)))
  for (const list of Object.values(JSON.parse(readFileSync(join(ROOT, 'tools', f), 'utf8')).sentences || {})) list.forEach(addSent);
const tokens = (s) => s[2].split(/\s+/).filter(Boolean).length;

// A corpus sentence counts for word W only if W occurs outside every longer known
// word that contains it (地 the particle must not match 地方 / 地球).
const lexicon = [...new Set([
  ...JSON.parse(readFileSync(SRC, 'utf8')).words.map((w) => w.hanzi),
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
  const own = app.find((v) => v.hanzi === w.hanzi);
  let sents = [];
  if (own && own.sentences && own.sentences.length) { sents = own.sentences.slice(0, MAX_SENT); report.ownSentences++; }
  else {
    const authored = authoring.sentences[w.hanzi] || [];
    const fromCorpus = corpus
      .filter((s) => containsWord(s[0], w.hanzi) && !authored.some((a) => a[0] === s[0]))
      .sort((a, b) => Math.abs(tokens(a) - 6) - Math.abs(tokens(b) - 6));
    sents = [...authored, ...fromCorpus].slice(0, MAX_SENT);
    if (authored.length) report.authoredSentences++; else report.corpusSentences++;
  }
  if (sents.length < MIN_SENT) report.short.push(`${w.hanzi}(${sents.length})`);

  let topic = own && own.topic;
  if (topic) report.topicFromApp++;
  else if (authoring.topics[w.hanzi]) { topic = authoring.topics[w.hanzi]; report.topicAuthored++; }
  else { topic = 'umum'; report.topicMissing.push(w.hanzi); }

  vocab.push({
    id: i + 1,
    hanzi: w.hanzi,
    traditional: (own && own.traditional) || w.hanzi,
    pinyin: w.pinyin.replace(/\s+/g, ''),
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
