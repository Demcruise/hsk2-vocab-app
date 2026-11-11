// Build the LOCAL-ONLY app level file for HSK 3.0 (2025) Level 2.
//
// Inputs : local-content/hsk2025.json   (from tools/extract_local_hsk.mjs, personal use only)
//          vocab_data.json, hsk1_data.json (existing app data: topics + own sentences)
//          tools/hsk2025_l2_authoring.json (original topics + sentences for gaps)
// Output : local-content/level-hsk2-2025.json  (gitignored; loaded by index.html when present)
//
// Usage  : node tools/build_local_level.mjs
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join, resolve } from 'path';
import { fileURLToPath } from 'url';

const ROOT = resolve(fileURLToPath(new URL('.', import.meta.url)), '..');
const SRC = join(ROOT, 'local-content', 'hsk2025.json');
const OUT = join(ROOT, 'local-content', 'level-hsk2-2025.json');
const MAX_SENT = 10, MIN_SENT = 3;

if (!existsSync(SRC)) { console.error('Missing ' + SRC + ' — run tools/extract_local_hsk.mjs first.'); process.exit(1); }
const words = JSON.parse(readFileSync(SRC, 'utf8')).words.filter((w) => w.level === '2');
const appHsk2 = JSON.parse(readFileSync(join(ROOT, 'vocab_data.json'), 'utf8')).vocab;
const appHsk1 = JSON.parse(readFileSync(join(ROOT, 'hsk1_data.json'), 'utf8')).vocab;
const authoring = JSON.parse(readFileSync(join(ROOT, 'tools', 'hsk2025_l2_authoring.json'), 'utf8'));
const app = [...appHsk1, ...appHsk2];

// Sentence corpus = the project's own generated sentences, de-duplicated.
const corpus = [];
const seen = new Set();
for (const v of app) for (const s of v.sentences || []) if (!seen.has(s[0])) { seen.add(s[0]); corpus.push(s); }
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

writeFileSync(OUT, JSON.stringify({
  key: 'hsk2b',
  label: 'HSK 2 (2025)',
  edition: 'hsk3.0-2025',
  level: '2',
  store: 'khsk2b',
  license: 'PERSONAL USE ONLY — word list derived from HanziStroke PDFs (L-02). Do not commit or deploy.',
  generatedAt: new Date().toISOString(),
  vocab,
  topics,
}));
console.log(`level-hsk2-2025: ${vocab.length} words`);
console.log(`sentences: own ${report.ownSentences}, corpus ${report.corpusSentences}, authored ${report.authoredSentences}; <${MIN_SENT}: ${report.short.join(' ') || 'none'}`);
console.log(`topics: app ${report.topicFromApp}, authored ${report.topicAuthored}, missing ${report.topicMissing.length} ${report.topicMissing.join(' ')}`);
process.exit(report.short.length || report.topicMissing.length ? 1 : 0);
