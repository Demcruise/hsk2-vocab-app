// Build a LOCAL-ONLY HSK 3.0 (2025 revision) vocabulary file from the owner's
// personally downloaded HanziStroke PDFs.
//
// Licensing: HanziStroke's terms allow personal, non-commercial learning only.
// The output goes to local-content/ (gitignored) and must never be committed
// or deployed. See docs/content/CONTENT_LICENSE_REGISTER.md (L-02).
//
// Usage (from repo root):
//   cd tools && npm install && cd ..
//   node tools/extract_local_hsk.mjs [--l1 path] [--l2 path] ... [--l7-9 path]
// Output: local-content/hsk2025.json, local-content/validation-report.md
import { getDocument } from 'pdfjs-dist/legacy/build/pdf.mjs';
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import { join, resolve } from 'path';
import { fileURLToPath } from 'url';

const ROOT = resolve(fileURLToPath(new URL('.', import.meta.url)), '..');
const EDITION = 'hsk3.0-2025';
const LEVELS = ['1', '2', '3', '4', '5', '6', '7-9'];
const DEFAULT_PDF = {
  '1': join(ROOT, '..', '..', 'HSK 1.0 V3', 'HSK1-Vocabulary-3.0.pdf'),
  '2': join(ROOT, 'HSK2-Vocabulary-3.0.pdf'),
  '3': join(ROOT, 'all hsk level', 'HSK3-Vocabulary-3.0.pdf'),
  '4': join(ROOT, 'all hsk level', 'HSK4-Vocabulary-3.0.pdf'),
  '5': join(ROOT, 'all hsk level', 'HSK5-Vocabulary-3.0.pdf'),
  '6': join(ROOT, 'all hsk level', 'HSK6-Vocabulary-3.0.pdf'),
  '7-9': join(ROOT, 'all hsk level', 'HSK7-9-Vocabulary-3.0.pdf'),
};

// Column x-boundaries observed in the HanziStroke export layout.
const X_PINYIN = 160;
const X_DEF = 285;

function parseArgs(argv) {
  const pdf = { ...DEFAULT_PDF };
  for (let i = 0; i < argv.length; i += 2) {
    const k = argv[i].replace(/^--l/, '');
    if (!LEVELS.includes(k)) throw new Error('Unknown option ' + argv[i]);
    pdf[k] = resolve(argv[i + 1]);
  }
  return pdf;
}

export async function readEntries(file) {
  const doc = await getDocument({ data: new Uint8Array(readFileSync(file)), verbosity: 0 }).promise;
  let declared = null;
  const entries = [];
  let cur = null;
  for (let pn = 1; pn <= doc.numPages; pn++) {
    const page = await doc.getPage(pn);
    const items = (await page.getTextContent()).items
      .filter((it) => it.str.trim())
      .map((it) => ({ x: it.transform[4], y: it.transform[5], s: it.str.trim() }));
    if (declared === null) {
      const m = items.map((i) => i.s).join(' ').match(/(\d[\d,]*)\s+Vocabulary Entries/);
      if (m) declared = Number(m[1].replace(/,/g, ''));
    }
    // Table body only: below the "Word / Pinyin / Definition" header, above the footer.
    const header = items.find((i) => i.s === 'Word');
    if (!header) continue;
    const body = items
      .filter((i) => i.y < header.y - 2 && i.y > 30)
      .sort((a, b) => b.y - a.y);
    // Cluster into visual rows: the word, pinyin and definition of one entry sit
    // on baselines up to ~2px apart, so sorting by y alone interleaves columns.
    const rows = [];
    for (const it of body) {
      const row = rows[rows.length - 1];
      if (row && Math.abs(row.y - it.y) <= 4) row.items.push(it);
      else rows.push({ y: it.y, items: [it] });
    }
    for (const row of rows) {
      row.items.sort((a, b) => a.x - b.x);
      const word = row.items.find((i) => i.x < X_PINYIN);
      if (word) { cur = { hanzi: word.s, pinyin: '', def: '' }; entries.push(cur); }
      if (!cur) continue;
      for (const it of row.items) {
        if (it === word) continue;
        if (it.x < X_PINYIN) cur.hanzi += it.s;
        else if (it.x < X_DEF) cur.pinyin = (cur.pinyin + ' ' + it.s).trim();
        else cur.def = (cur.def + ' ' + it.s).trim();
      }
    }
  }
  return { declared, entries };
}

export function splitDef(def) {
  const m = def.match(/^\(([^)]*)\)\s*(.*)$/);
  if (!m) return { pos: [], meaning: def.trim() };
  return { pos: m[1].split(/[\/,]/).map((s) => s.trim().replace(/\.$/, '')).filter(Boolean), meaning: m[2].trim() };
}

const TONE = /[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]/g;
const TONE_PLAIN = { ā: 'a', á: 'a', ǎ: 'a', à: 'a', ē: 'e', é: 'e', ě: 'e', è: 'e', ī: 'i', í: 'i', ǐ: 'i', ì: 'i', ō: 'o', ó: 'o', ǒ: 'o', ò: 'o', ū: 'u', ú: 'u', ǔ: 'u', ù: 'u', ǖ: 'ü', ǘ: 'ü', ǚ: 'ü', ǜ: 'ü' };
export const plainPinyin = (p) => (p || '').toLowerCase().replace(TONE, (c) => TONE_PLAIN[c]).replace(/[^a-zü]/g, '');
const HAN = /\p{Script=Han}/u;

export function validate(words) {
  const errors = [], warnings = [];
  const ids = new Set(), sense = new Map(), byHanzi = new Map();
  for (const w of words) {
    if (ids.has(w.id)) errors.push(`E1 duplicate id ${w.id}`);
    ids.add(w.id);
    // The source re-lists a word at a higher level when it introduces a new sense
    // (点 L1 "o'clock" vs L2 "to order"), so a duplicate is an error only when the
    // meaning is identical too.
    const reading = w.hanzi + '|' + w.pinyin;
    const key = reading + '|' + w.meaning_en;
    if (sense.has(key)) errors.push(`E3 duplicate sense ${w.hanzi} ${w.pinyin} (${sense.get(key)} & ${w.id})`);
    else if ([...sense.keys()].some((k) => k.startsWith(reading + '|'))) warnings.push(`W3 new sense ${w.id} ${w.hanzi} ${w.pinyin}: ${w.meaning_en.slice(0, 50)}`);
    sense.set(key, w.id);
    if (!HAN.test(w.hanzi)) errors.push(`E4 no hanzi in ${w.id} "${w.hanzi}"`);
    if (/[A-Za-z]/.test(w.hanzi)) warnings.push(`E4 latin in hanzi ${w.id} "${w.hanzi}"`);
    if (!w.pinyin) errors.push(`E5 empty pinyin ${w.id} ${w.hanzi}`);
    const hanCount = [...w.hanzi].filter((c) => HAN.test(c)).length;
    const syl = w.pinyin.split(/\s+/).filter(Boolean).length;
    if (w.pinyin && syl !== hanCount && !/儿/.test(w.hanzi) && !/[|（(…·]/.test(w.hanzi))
      warnings.push(`E5 syllables ${syl} ≠ hanzi ${hanCount}: ${w.id} ${w.hanzi} [${w.pinyin}]`);
    for (const s of w.pinyin.split(/\s+/)) if ((s.match(TONE) || []).length > 1) errors.push(`E6 >1 tone mark ${w.id} ${s}`);
    if (!w.meaning_en) errors.push(`E7 empty meaning ${w.id} ${w.hanzi}`);
    if (!byHanzi.has(w.hanzi)) byHanzi.set(w.hanzi, []);
    byHanzi.get(w.hanzi).push(w);
  }
  for (const [hz, ws] of byHanzi) {
    const lv = [...new Set(ws.map((w) => w.level))];
    if (lv.length > 1) warnings.push(`W2 ${hz} in levels ${lv.join(', ')}`);
  }
  return { errors, warnings };
}

async function main() {
  const pdf = parseArgs(process.argv.slice(2));
  const words = [], levelInfo = {};
  for (const lv of LEVELS) {
    if (!existsSync(pdf[lv])) { console.log(`L${lv}: missing ${pdf[lv]} — skipped`); levelInfo[lv] = { missing: true }; continue; }
    const { declared, entries } = await readEntries(pdf[lv]);
    entries.forEach((e, i) => {
      const { pos, meaning } = splitDef(e.def);
      // Variant readings appear as "a also: ā" or "shéi/shuí".
      // Source splits the final "üe" as "ü è" (略 lüè → "lü è"); rejoin it.
      const py = e.pinyin.replace(/([lnLN])ü ([eēéěè])/g, '$1ü$2');
      const [pinyin, ...pinyin_alt] = py.split(/\s+also:\s+|\//).map((s) => s.trim()).filter(Boolean);
      const w = { id: `hsk25-${lv}-${String(i + 1).padStart(4, '0')}`, edition: EDITION, level: lv, hanzi: e.hanzi, pinyin: pinyin || '', pos, meaning_en: meaning, source: 'S-10' };
      if (pinyin_alt.length) w.pinyin_alt = pinyin_alt;
      words.push(w);
    });
    levelInfo[lv] = { declared, parsed: entries.length };
    console.log(`L${lv}: declared ${declared}, parsed ${entries.length}${declared === entries.length ? '' : '  <-- MISMATCH'}`);
  }

  const { errors, warnings } = validate(words);
  for (const lv of LEVELS) {
    const i = levelInfo[lv];
    if (!i.missing && i.declared !== i.parsed) errors.push(`COUNT L${lv}: declared ${i.declared}, parsed ${i.parsed}`);
  }

  // Map the existing app vocab (HSK1 300 + HSK2 770, 2021 list) onto 2025 levels.
  const map = { hanziPinyin: {}, hanziOnly: {}, unmatched: [] };
  const idx = new Map();
  for (const w of words) {
    const k = w.hanzi + '|' + plainPinyin(w.pinyin);
    if (!idx.has(k)) idx.set(k, w);
    if (!idx.has(w.hanzi)) idx.set(w.hanzi, w);
  }
  const appSets = [
    ['app-hsk1', JSON.parse(readFileSync(join(ROOT, 'hsk1_data.json'), 'utf8')).vocab],
    ['app-hsk2', JSON.parse(readFileSync(join(ROOT, 'vocab_data.json'), 'utf8')).vocab],
  ];
  const mapping = {};
  for (const [name, list] of appSets) {
    const counts = {}; const unmatched = [];
    for (const v of list) {
      const hit = idx.get(v.hanzi + '|' + plainPinyin(v.pinyin)) || idx.get(v.hanzi);
      if (hit) counts[hit.level] = (counts[hit.level] || 0) + 1; else unmatched.push(`${v.hanzi} ${v.pinyin}`);
    }
    mapping[name] = { total: list.length, byLevel2025: counts, unmatched };
  }

  mkdirSync(join(ROOT, 'local-content'), { recursive: true });
  const out = {
    edition: EDITION,
    generatedAt: new Date().toISOString(),
    license: 'PERSONAL USE ONLY — derived from HanziStroke PDFs (see CONTENT_LICENSE_REGISTER L-02). Do not commit or deploy.',
    levels: levelInfo,
    words,
  };
  writeFileSync(join(ROOT, 'local-content', 'hsk2025.json'), JSON.stringify(out));
  const rep = [
    `# Local HSK 3.0 (2025) extraction report`, '', `Generated ${out.generatedAt}. Personal use only.`, '',
    '## Levels', '', '| Level | Declared | Parsed |', '|---|---|---|',
    ...LEVELS.map((l) => `| ${l} | ${levelInfo[l].declared ?? '—'} | ${levelInfo[l].parsed ?? 'missing'} |`), '',
    `## Errors (${errors.length})`, '', ...errors.slice(0, 200).map((e) => `- ${e}`), '',
    `## Warnings (${warnings.length})`, '', ...warnings.slice(0, 300).map((e) => `- ${e}`), '',
    '## Existing app vocab → 2025 levels', '',
    ...Object.entries(mapping).flatMap(([n, m]) => [
      `### ${n} (${m.total})`, '', `By 2025 level: ${JSON.stringify(m.byLevel2025)}`, '',
      `Unmatched (${m.unmatched.length}): ${m.unmatched.join(', ')}`, '']),
  ].join('\n');
  writeFileSync(join(ROOT, 'local-content', 'validation-report.md'), rep);
  console.log(`\nwords ${words.length} | errors ${errors.length} | warnings ${warnings.length}`);
  for (const [n, m] of Object.entries(mapping)) console.log(`${n}: ${JSON.stringify(m.byLevel2025)} unmatched ${m.unmatched.length}`);
  process.exit(errors.length ? 1 : 0);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
