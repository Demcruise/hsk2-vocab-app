# Duolingo Feature Inventory (web, Chinese course)

Status: **Verified** (observed, evidence ID) · **Partial** (surface seen, behaviour not exercised) · **Unavailable** (not reachable in this account/platform) · **Not observed** (pending). Evidence IDs → `DUOLINGO_EVIDENCE_LOG.md`.

## Information architecture

| Area | Route | Status | Evidence | Key mechanics | Kunkwan today |
|---|---|---|---|---|---|
| Learn / path | `/learn` | Verified | E-001–E-005 | Section → Unit → Node → Lesson; node kinds Lesson/Story/Radio/Practice/Character; current-node ring; locked nodes; per-node lesson count + XP preview; jump-ahead test | Unit → node (10 words); no sections, no lock, no per-node lessons |
| Sections overview | `/sections` | Verified | E-006 | CEFR-tagged sections, % progress, review/continue/jump, post-course "Daily Refresh" | None |
| Guidebook | `/guidebook/{lang}/{unit}` | Verified | E-013 | Key phrases + grammar tips per unit | None (no grammar content) |
| Characters | `/characters` | Verified | E-007, E-008 | Pinyin chart (tones/initials/finals) + Hanzi list per unit (introduced vs reused) + practice | Radicals + hanzi tooltip; writing practice; no per-unit char list |
| Practice hub | `/practice-hub` | Partial | E-009 | Target practice (weak areas), listen-only, conversation, mistakes collection, story reread | Practice hub with listen/speak/write/mistakes (similar) |
| Leaderboards | `/leaderboard` | Partial | E-011 | Tiered weekly leagues, promotion/demotion zones, countdown | None (icon only) |
| Quests | `/quests` | Verified | E-010 | 3 rotating daily quests with timers + monthly meta-quest → badge | Static quest widgets |
| Shop | `/shop` | Partial | E-012 | Gems currency, Streak Freeze power-up (max 3) | None |
| Profile | `/profile/{user}` | Not observed | — | (skipped: personal data) | Stats/achievements screen |
| Settings | `/settings/*` | Verified (labels) | E-014 | Lesson-experience toggles, listening-exercise toggle, dark mode, pinyin display level | Dark mode, pinyin toggle in quiz |
| Subscription | `/settings/super` | Partial | E-012 | Super = no ads (+ benefits not inspected) | n/a |
| Lesson engine | `/lesson` | Verified (1 lesson) | E-016–E-029 | See table below | 7 exercise types; re-queue exists; no "previous mistake" label, no alt-answer display, no meta-feedback |
| Stories / Radio | path nodes | Partial (node exists) | E-003 | — | 28 stories; no radio |
| Onboarding / placement | — | Unavailable (existing account) | — | — | None |

## Lesson engine — observed exercise types

| Type | Prompt | Input | Grading | Evidence | Kunkwan equivalent |
|---|---|---|---|---|---|
| Translate ZH→EN | "Write this in English" + audio | English chip bank w/ distractors | Exact token sequence, multiple accepted solutions | E-017, E-018 | `bank` (exists) |
| Translate EN→ZH | "Write this in Chinese" | Free typing ↔ word-segmented chip bank toggle | Punctuation-insensitive, lexical variants accepted | E-023, E-024 | Missing (only ZH→EN bank) |
| Fill in the blank | Sentence with gap | 3 options, keys 1–3 | Single choice | E-022 | Missing |
| Match pairs | 5 + 5 cards | Pairwise selection, keys 1–0 | Graded at end | E-025 | Missing |
| Tap what you hear | Audio (normal/slow) | Word chips ↔ keyboard; "can't listen now" | Token sequence | E-026 | `listen` (exists, MC-based) |
| (not seen this lesson) | — | speaking, character, picture | — | — | `speak`, `write` exist |

Cross-cutting engine rules: CHECK disabled until answer; Enter shortcut; correct/wrong bottom sheet; canonical/alternative answer display; "Meaning:" reveal; per-word hover glosses; "N IN A ROW" combo with gold bar; wrong answer doesn't advance progress; missed items re-queued at end as **PREVIOUS MISTAKE**; personalised results headline + XP + accuracy; quest progress screen after results.

## Design implications for Kunkwan (draft)

1. **Hierarchy:** HSK Level ≈ Section (CEFR-like band tag), Unit = communicative goal, Node = 1 skill with N lessons (2–5), Lesson = 10–15 exercises. Matches master prompt's `HSK Level → Section → Unit → Lesson → Exercise`.
2. **Node types** worth reproducing: lesson, practice (personalised), story, character (hanzi intro/reuse), listening-only. Skip "Radio" until audio content exists.
3. **Characters page** maps directly to existing assets (`hw.json`, `HANZI_DATA`): derive "introduced in this unit / reused" from unit vocabulary.
4. **Guidebook** = new grammar content per unit (HSK 3.0 grammar points) — content gap, not code gap.
5. **Quests** need daily rotation + deadlines; metrics (XP earned, ≥80% lessons, N-in-a-row) are already computable from existing quiz state.
6. **Streak freeze** relevant because K-03 (streak counted on app open) must be fixed first.
7. Leagues need a backend (multi-user) — out of scope until sync/accounts exist; mark Blocked.

## Second pass deltas (2026-11-12, E-031–E-047)

Only rows that changed or were newly observed; everything else above still stands.

| Area | What the second pass adds |
|---|---|
| Learn path | Node set per unit is richer than first pass: **Chest** (disabled reward), **Legendary Level**, **Unit Review** (locked until all levels in the unit are done), plus Story/Radio/Practice/character. Sub-units carry their own topic heading inside one unit. Jump-ahead target is a real route (`/lesson/unit/{n}/test`). |
| Practice hub | "Target Practice" is gone from this account; "Today's Review" is **Unit Rewind** (previous unit, +20 XP). Conversation renders as a heading with no actionable control. |
| Stories | Dedicated hub (`/practice-hub/stories`) with one featured story + ~40-title library. Player: EN narration + ZH bubble with per-word ruby pinyin, tappable words, audio per beat, single Continue. |
| Characters | Pinyin tiles show per-item **mastery** progress; Hanzi tab is per unit with "Introduced in this unit" / "Used in new words" grids and a per-unit Practice that opens `/alphabets/zs/hanzi/group/{n}` ("Select the correct pronunciation", 3 pinyin options). |
| Radio | Completed radio nodes expose `PRACTICE +15 XP` and open an audio-only lesson card ("LUCY IS LISTENING"), not a text transcript. |
| Quests | Accuracy quest threshold observed at **90%**, and "Combo Bonus XP" is its own quest metric. |
| Not on web | Friends/notifications have no entry point (More = English Test, Settings, Help, Log out). |
