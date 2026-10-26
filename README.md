# Kunkwan HSK — Vocabulary (HSK 1 & HSK 2)

An **HSK 3.0** vocabulary-learning app — **HSK 1 (300 words)** and **HSK 2 (770 words)** in one app, each **fully separate**: learning path, progress, XP, streak, achievements, and storage each have their own bucket (`khsk1` / `khsk2`). A single HTML file — usable on a phone as an installable app (PWA) or opened directly in a browser.

## Features

- **Level picker** — HSK 1 🐣 / HSK 2 🚀 buttons on the Learn screen (plus a header pill). Switching levels swaps all content & progress — never mixed.
- **300 HSK 1 words** & **770 HSK 2 words** with hanzi, tone-marked pinyin, traditional forms, and meanings.
- **10 example sentences per word** (3,000 HSK 1 + 7,700 HSK 2 sentences) with hanzi + pinyin + English translation.
- **TTS audio** for words and every sentence, two speeds (normal / slow) via the browser's `speechSynthesis`.
- **Per-hanzi tooltips** — tap/hover any character in an example sentence for pinyin, meaning, radical, stroke count, and related words.
- **Radicals** — 149 explained entries for HSK 2; the HSK 1 radical list is derived automatically from the hanzi map.
- **Duolingo-style learning path** — words grouped into **thematic units** (Greetings, Numbers & Time, Family, Health, Food, Home, School & Work, Transport, Shopping, Hobbies, Nature, Adjectives, etc.), each unit a winding path of lesson nodes (~10 words/node). Finished nodes show ✓, the active node has a progress ring.
- **Flashcards** with Not Memorized / Learning / New / Review / Mastered modes — full-screen lesson sessions with instant **✅ Memorized** marking.
- **"Memorized" & "Vocab" pages** — words **grouped by pinyin initial (A–Z)**, per-word/per-letter mark buttons, filters, and hanzi/pinyin/meaning search.
- **Progressive quiz exercises** — recognition first (choose the pinyin / hanzi / meaning), then word-bank sentence translation, listening, speaking (ASR zh-CN with self-check fallback), and writing (stroke-by-stroke tracing with validation). 拼音 toggle, ✦ NEW WORD / ⚑ HARD EXERCISE badges, gold "N IN A ROW" progress bar, ⚡∞, PERFECT overlay, correct/wrong band + CONTINUE, wrong questions re-queued, confetti + SFX.
- **Practice Hub** — targeted practice for weak skills: listening, speaking, writing, and all mistaken words.
- **Storybook** — 28 interactive stories (14 per level, one per unit topic): narration, dialog bubbles with audio + pinyin, and comprehension checks (+20 XP).
- **Lesson-complete celebrations** — finishing a lesson shows a "Lesson complete!" overlay; the node is permanently marked done (`ld`).
- **Two layouts**: desktop ≥1024px gets a left sidebar + right rail; mobile gets a green topbar + bottom navigation.
- **Dark mode** following the system plus a manual toggle (🌙).
- **Auto-saved progress** per level in the browser, plus **Save/Load to File** (JSON). Backup files record their level (`hsk1-...json` / `hsk2-...json`) — importing another level's file is rejected with instructions to switch first.
- **Installable PWA** and **works offline**.

## Usage

### In a browser (fastest)
Open `index.html` with Chrome/Safari/Edge — it just works, offline-capable, no server needed.

### Install on Android (recommended)
1. Open **https://demcruise.github.io/hsk2-vocab-app/** in **Chrome on Android**.
2. Wait for the page to fully load.
3. Tap the **⋮** menu (top right) → **"Add to Home screen"**.
4. Confirm — the **Kunkwan HSK** icon appears on your home screen.
5. Launch it from the icon: no address bar (app mode), and it still works **offline**.

> Note: install requires **https** (GitHub Pages) — it isn't available when the file is opened via `file://`.

## Structure

| File | Description |
|---|---|
| `index.html` | The complete app (HTML + CSS + JS + all embedded data, including HSK 1) |
| `vocab_data.json` | HSK 2 data source: 770 words + 149 radicals |
| `hsk1_data.json` | HSK 1 data source: 300 words (PDF extraction + generated sentences) |
| `assets/data/` | Stories (14 per level), hanzi map, stroke-order data (`hw.json`) |
| `manifest.webmanifest` | PWA manifest (name, icons, theme colors) |
| `sw.js` | Service worker — offline caching |
| `icons/` | App icons |
| `assets/` | UI assets (SVG, feedback audio, Nunito font) — precached for offline |
| `mobile/` | **Flutter** version (Android/iOS/Web), see `mobile/README.md` |
| `tools/apply_en.mjs` | Merges `tools/en_out/` translations into all data files + app copies |
| `tools/en_chunks/` `tools/en_out/` | Sentence-translation pipeline (chunked, validated) |
| `tools/assign_topics*.mjs` | Thematic-unit classification for both levels |
| `tools/extract_hsk1.py` | Extracts the 300 HSK 1 words from the PDF |

## Notes

- Progress is stored in browser `localStorage`, **per level** (`khsk1` / `khsk2`) — the last selected level is remembered (`khsk-level`).
- Audio depends on a Mandarin voice (`zh-CN`) being available on the device.
- After changing `index.html`, the new version is picked up automatically while online. To refresh the **offline** copy too, bump `VERSION` in `sw.js`. On mobile: **Progress → 🔄 Update App**.
