# Local-only HSK 3.0 (2025) content

Owner decision 2026-11-11: use the personally downloaded HanziStroke vocabulary PDFs **locally and privately only**. HanziStroke's terms allow personal, non-commercial learning and forbid republishing or building a competing dataset, and this repository and its GitHub Pages site are public. So:

- PDFs stay in `all hsk level/` (gitignored); HSK 1 PDF stays outside the repo.
- Generated data goes to `local-content/` (gitignored). Never commit it, never copy it into `index.html`, `assets/`, `app/` or `mobile/assets/`.
- Source ID: **S-10** (HanziStroke 2025 lists, personal use) — see CONTENT_SOURCE_REGISTER / LICENSE_REGISTER L-02.

## Build

```bash
cd tools && npm install && cd ..
node tools/extract_local_hsk.mjs
```

Outputs `local-content/hsk2025.json` (records per DATA_QUALITY_RULES: id, edition, level, hanzi, pinyin, pinyin_alt, pos, meaning_en, source) and `local-content/validation-report.md`. Exit code 1 when blocking errors exist.

## Result of first run (2026-11-11)

| Level | Declared in PDF | Parsed |
|---|---|---|
| 1 | 300 | 300 |
| 2 | 200 | 200 |
| 3 | 500 | 500 |
| 4 | 1,000 | 1,000 |
| 5 | 1,600 | 1,600 |
| 6 | 1,800 | 1,800 |
| 7–9 | 5,600 | 5,600 |

Validation: 3 errors, all defects in the source PDFs (换乘 has no definition; 称 chēng and 乘 chéng listed twice with identical meaning). Notable warnings: 高龄 has garbled pinyin in the source; one 7–9 entry " 唆" is missing a character; 40 words re-listed at a higher level with a new sense (expected, e.g. 点 L1 "o'clock" / L2 "to order"); 71 hanzi appear in several levels.

## Existing app vocabulary mapped to 2025 levels

| App set | Total | L1 | L2 | L3 | L4 | L5 | L6 | Not in 2025 lists |
|---|---|---|---|---|---|---|---|---|
| App HSK 1 | 300 | 300 | — | — | — | — | — | 0 |
| App HSK 2 (2021 list) | 770 | 38 | 84 | 258 | 227 | 56 | 7 | 100 |

So the current "HSK 2" set covers only 84 of the 200 words of 2025 HSK 2; most of it belongs to 2025 HSK 3–4. The 100 unmatched words are mostly compounds absent from the 2025 lists (e.g. 公共汽车, 比如说) — keep them as extra practice, not as curriculum.

## Local level in the PWA: HSK 2 (2025)

```bash
node tools/extract_local_hsk.mjs     # PDFs -> local-content/hsk2025.json
node tools/build_local_level.mjs     # -> local-content/level-hsk2-2025.json
```

Serve the repo root over http (e.g. `npx http-server -p 8734 .`) and open it. When `local-content/level-hsk2-2025.json` is present, a third level button **🎯 HSK 2 (2025) · local** appears; the public GitHub Pages build has no such file and is unchanged.

- 200 words; storage bucket `khsk2b` (separate from `khsk1`/`khsk2`).
- First visit copies progress (level, counts, memorized flag) for the same hanzi from the HSK 1 and HSK 2 buckets; those buckets are not modified.
- Sentences: 84 words keep their own 10 sentences, 101 use matching sentences from the project's own corpus (occurrences inside longer known words are ignored, so 地 "de" does not match 地方), 15 use hand-written sentences in `tools/hsk2025_l2_authoring.json`. Every word has ≥3 sentences.
- Topics: 84 from existing data, 116 hand-assigned in the authoring file.
- The service worker never caches `local-content/`.
- Not yet: stories for this level (story nodes show "No story for this topic yet"), Flutter app support, levels 3–9.

Tests: `node tools/local_level.test.js` (part A runs when the local file exists; part B simulates the public site).

## Local level: HSK 3 (2025)

```bash
node tools/build_local_level.mjs 3   # -> local-content/level-hsk3-2025.json + levels.json index
```

The builder now takes the level as an argument and writes `local-content/levels.json`, which the app reads to discover every built level (one button per level, storage bucket `khsk<N>b`).

- 500 words; 264 keep their own sentences/topics from the old app data (they were in the 2021 HSK 2 list).
- 148 use corpus sentences; 88 use hand-written sentences in `tools/hsk2025_l3_authoring.json` (all words ≥3 sentences). 236 topics hand-assigned.
- Known source defects carried into the data: some pinyin split mid-syllable in the PDF (宾馆 "bīng uǎn") — harmless once compacted to "bīnguǎn"; a few meanings merged with the next field (短裤, 遇见); 园 has no part of speech.

## Progress from the public site

Progress saved on demcruise.github.io lives in that origin's browser storage and is not visible on `localhost`. To carry it over: on the public site use **Save to File** on HSK 2, open the local app, switch to HSK 2, **Load from File**, then open the 2025 levels for the first time (carry-over only runs when a 2025 level's bucket is still empty).

## Local level: HSK 4 (2025) and builder changes

```bash
node tools/build_local_level.mjs 4
```

- 1,000 words: 229 reuse old app data, 240 use corpus sentences, 531 use original sentences (`tools/hsk2025_l4_authoring_s1..s4.json`; topics in `hsk2025_l4_authoring_topics.json`). Every word has ≥3 sentences and a topic.
- Authored sentences may be written as `[hanzi, english]`; pinyin is generated by longest match against the 11k-word lexicon (word-level pinyin from the source lists and app data), keeping the illustrated word as one segment, with remaining characters from `pinyin-pro` (MIT; handles 一/不 sandhi). Erhua words whose source pinyin dropped the final r are repaired (差点儿 → chàdiǎnr).
- Guard: the build fails if an authored sentence doesn't contain its word (it caught 打…招呼, 举…例子, 打…针, which were rewritten).
- Polyphones: old app data is reused only when hanzi **and** reading match (重 chóng no longer borrows 重 zhòng's sentences). Polyphones skip corpus sentences and use hand-written sentences with hand-written pinyin, keyed `hanzi|pinyin` in the `hsk2025_l<N>_authoring_poly.json` files (L2 地 de, 着 zhe; L3 得 děi, 地 dì, 还 huán, 行 xíng; L4 重 chóng/zhòng, 落 luò, 熟 shú, 着 zháo, 空 kōng/kòng).
- Known: some older corpus sentences (from the original app generator) start lowercase or join words oddly in pinyin; unchanged here.

## Local level: HSK 5 (2025)

```bash
node tools/build_local_level.mjs 5
```

- Owner decision (2026-11-11): minimum **2** example sentences per word from level 5 up (3 for levels 1–4). Override with `MIN_SENT=3`.
- 1,600 words: 70 reuse old app data, 318 use corpus sentences, 1,212 use original sentences (`tools/hsk2025_l5_authoring_s1..s7.json`, ≈2,150 sentences; topics in `hsk2025_l5_authoring_topics.json`; polyphones 传 chuán, 调 diào/tiáo, 行 háng, 系 jì/xì in `hsk2025_l5_authoring_poly.json`).
- Pinyin generator rules added after reviewing output: standalone 得 → "de" (complement), or "děi" right after a subject or 还/就/也/都; 地 after an adjective (source POS data) or a reduplicated word → "de" (also stops 乐观地面对 being read as 地面); 们 attaches to the previous word (孩子们 → háizimen); 长得 → zhǎngde.
- Known: greedy word matching can still put a space in the wrong place when two words overlap (这本书写得 → "shūxiě de"); syllables and tones are correct.
