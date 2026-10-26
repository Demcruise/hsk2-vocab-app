// Generate translation chunk files for subagent batches.
// Output: tools/en_chunks/{hsk1_NN|hsk2_NN|rad_NN|story_hsk1|story_hsk2}.json
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = path.join(root, 'tools', 'en_chunks');
fs.mkdirSync(out, { recursive: true });

const PER = 25; // words per chunk (~250 sentences)

function vocabChunks(src, prefix) {
  const data = JSON.parse(fs.readFileSync(src, 'utf8'));
  const words = data.vocab;
  let n = 0;
  for (let i = 0; i < words.length; i += PER) {
    n++;
    const chunk = words.slice(i, i + PER).map(v => ({
      id: v.id, hanzi: v.hanzi, pinyin: v.pinyin, meaning: v.meaning,
      idn: v.sentences.map(s => s[2]),
    }));
    const name = `${prefix}_${String(n).padStart(2, '0')}.json`;
    fs.writeFileSync(path.join(out, name), JSON.stringify(chunk, null, 0));
    console.log(name, chunk.length, 'words');
  }
  return n;
}

const n1 = vocabChunks(path.join(root, 'vocab_data.json'), 'hsk2');
const n2 = vocabChunks(path.join(root, 'hsk1_data.json'), 'hsk1');

// radicals (from vocab_data.json .radicals)
const vd = JSON.parse(fs.readFileSync(path.join(root, 'vocab_data.json'), 'utf8'));
const rads = vd.radicals.map(r => ({ radical: r.radical, pinyin: r.pinyin, meaning: r.meaning, idn: r.explanation }));
for (let i = 0; i < rads.length; i += 75) {
  const idx = Math.floor(i / 75) + 1;
  const name = `rad_${String(idx).padStart(2, '0')}.json`;
  fs.writeFileSync(path.join(out, name), JSON.stringify(rads.slice(i, i + 75), null, 0));
  console.log(name);
}

// stories — extract translatable fields only
for (const lv of ['hsk1', 'hsk2']) {
  const stories = JSON.parse(fs.readFileSync(path.join(root, 'assets', 'data', `stories_${lv}.json`), 'utf8'));
  const slim = stories.map(s => ({
    id: s.id, title_idn: s.title,
    narrate_idn: s.beats.filter(b => b.t === 'narrate').map(b => b.idn),
    check_idn: s.beats.filter(b => b.t === 'check').map(b => b.idn),
    pick_q_idn: s.beats.filter(b => b.t === 'pick').map(b => b.q),
  }));
  fs.writeFileSync(path.join(out, `story_${lv}.json`), JSON.stringify(slim, null, 0));
  console.log(`story_${lv}.json`, stories.length, 'stories');
}
console.log('done:', n1 + n2, 'vocab chunks');
