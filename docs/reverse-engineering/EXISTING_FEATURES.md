# Existing Features — Inventory

Status legend: **Working** (verified by test or probe this audit) · **Partial** (works but incomplete / not per spec) · **Broken** (verified defect) · **Unverified** (code exists, not exercised this audit).

Evidence: `S` = `tools/_smoke.js` run 2026-11-11, `P` = reload probe, `F` = `flutter test`, `C` = code reading (`index.html:line`).

| # | Feature | PWA | Flutter | Evidence | Notes / gap vs. target |
|---|---|---|---|---|---|
| 1 | Level picker HSK1/HSK2, separate progress buckets (`khsk1`/`khsk2`) | Working | Working | S, F | Only 2 of 7 HSK 3.0 bands. No onboarding / placement. |
| 2 | Learning path: 14 thematic units, ~10-word lesson nodes, winding layout, current node ring | Working | Working | S, C `index.html:1185-1187` | Unit = topic, Lesson = word chunk. No Section layer, no checkpoints, **no locking** (every node clickable), no unit test/legendary. |
| 3 | Lesson completion mark (`S.ld`) | **Broken** | Working | P | Not persisted on PWA reload (K-01). |
| 4 | Flashcard sessions with Hard/Good/Easy rating (levels 0–3) | Working | Working | S, C `:978` | Rating is a 4-step counter, not a spaced-repetition schedule (no due dates). |
| 5 | Exercise types: hz→pinyin, pinyin→hz, hz→meaning (MC), word-bank sentence translation, listening, speaking (Web Speech ASR + self-check), writing (stroke tracing) | Working | Working | S (first 5 types), F | Speaking/writing not covered by automated tests. Missing: match pairs, fill-blank, dictation, picture, reading comprehension, error correction, tone exercises. |
| 6 | Quiz feedback band, wrong-answer re-queue, PERFECT overlay, streak-in-a-row bar, confetti, SFX | Working | Working | S | Hearts tracked internally (5) but HUD shows ⚡∞; hearts end the quiz silently. |
| 7 | Topic quiz + Practice Hub (listening / speaking / writing / mistakes pool) | Working | Working | S, C `:1629-1644` | Mistake pool = any word ever wrong, never decays. |
| 8 | Stories (28) with narration, dialog bubbles, comprehension checks, +20 XP | Working | Working | S, F | Story completion `S.st` **not persisted on PWA reload** (K-01). |
| 9 | Vocabulary list, A–Z grouping, search (hanzi / toneless pinyin / meaning), filters | Working | Working | S | No favourites / custom lists. |
| 10 | "Memorized" (known) page, per-word/per-letter marking | Working | Working | S | — |
| 11 | Radicals screen (149 HSK2; HSK1 derived) | Working | Working | S | — |
| 12 | Hanzi tooltip: pinyin, meaning, radical, stroke count, related words, listen, practice writing | Working | Working | S | — |
| 13 | TTS (zh-CN `speechSynthesis` / `flutter_tts`), normal + slow | Unverified | Unverified | C | Depends on device voice; no fallback audio. |
| 14 | XP | Partial | Partial | C | XP awarded per action; no daily goal, no ledger/history. |
| 15 | Streak | Partial | Partial | C `:949` | Incremented on **app open**, not on learning activity (K-03). No freeze/repair. |
| 16 | Achievements | Partial | Partial | C `:1118` | Computed badges; no notification flow. |
| 17 | Quests (rail) | Partial | Partial | C | Static progress widgets, no daily/weekly reset. |
| 18 | Stats / progress screen | Working | Working | S | Counts only; no time series, accuracy trends, study time. |
| 19 | Backup: export/import JSON per level, copy-to-clipboard | Working | Working | S (payload), F | Import of other level rejected. Export includes `ld`/`st` (only place they survive). |
| 20 | Dark mode (system + toggle) | Working | Working | S | — |
| 21 | Responsive desktop (sidebar+rail ≥1024px) / mobile (topbar+bottom nav) | Working | Working | C, prior screenshots | — |
| 22 | PWA install + offline | Unverified | n/a | C `sw.js` | Offline not covered by tests. |
| 23 | Force-update button / version indicator | Unverified | n/a | C `:957` | — |
| 24 | Stickers (fun-isometric, attribution required) | Working | Working | C | — |

## Not present (confirmed by code search)

Accounts/login/sync, onboarding & placement test, daily goal, leagues/leaderboard (icon only), gems/shop (icon only), friends, notifications/reminders, spaced-repetition scheduler with due dates, grammar lessons, reading passages beyond stories, HSK 3–9 content, Indonesian meanings (UI was converted to English in `e9a56ee`), analytics dashboard over time, CI.
