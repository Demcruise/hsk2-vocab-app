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
