# Feature Parity Matrix — Duolingo (web, Chinese) vs Kunkwan

Companion to `docs/reverse-engineering/DUOLINGO_FEATURE_INVENTORY.md` (evidence log on
branch `docs/phase0-audit`). The inventory's "Kunkwan today" column was written before the
2025-level content work and several engine features landed; this matrix is the refreshed,
code-verified picture (checked against `index.html` on `feat/local-hsk2025-content`).

Verdict legend: **✅ Equivalent** · **🟡 Partial** · **❌ Missing** · **⛔ Blocked** (needs backend/out of scope) · **— N/A**

## Information architecture

| Duolingo | Evidence | Kunkwan today (verified) | Verdict | Gap |
|---|---|---|---|---|
| Learn path `/learn` | E-001–E-005 | Unit → node path (14 units/level); lesson + checkpoint nodes; current-node ring; progress %; Jump-ahead tests; heart-gated checkpoints | 🟡 | No Sections tier; nodes not strictly locked (checkpoint model instead); 1 node = 1 lesson (no per-node lesson count) |
| Sections overview `/sections` | E-006 | Level picker (hsk1, hsk2, local hsk2b–6b) | 🟡 | No per-section progress overview/review/continue screen; no CEFR band tags; no "Daily Refresh" |
| Guidebook per unit | E-013 | Unit guidebook: key phrases + grammar notes, `assets/data/grammar.json` (14 units × hsk1/hsk2) | 🟡 | Local 2025 levels have no grammar notes (content gap) |
| Characters `/characters` | E-007, E-008 | Hanzi screen: pinyin chart (initials/finals), per-unit character list with introduced/reused, stroke-order practice via Hanzi Writer | ✅ | — |
| Practice hub `/practice-hub` | E-009 | Practice hub: listen/speak/write skill tiles, weak-words (SRS), story collection (completed stories reopen = reread) | 🟡 | No "target practice" picker, no conversation, no mistakes collection view |
| Leaderboards `/leaderboard` | E-011 | Icon asset only (`assets/leaderboard.svg` used for Progress nav) | ⛔ | Weekly leagues need multi-user backend — Blocked until sync/accounts |
| Quests `/quests` | E-010 | Daily quests with countdown (`dqLeft`/`hoursLeftText`), daily goal, streak | 🟡 | Rotating quest set exists; no monthly meta-quest → badge chain |
| Shop `/shop` | E-012 | None (no currency) | ❌ | Gems + Streak Freeze; freeze needs streak model — see backlog P1 |
| Profile `/profile` | not observed | Progress screen: stats, badges gallery, achievements, save/restore | 🟡 | Public profile N/A (no accounts) |
| Settings `/settings` | E-014 | Dark mode, pinyin display toggle, level picker, backup/restore | 🟡 | No lesson-experience toggles (listening exercise toggle, etc.) |
| Subscription `/settings/super` | E-012 | n/a | — | No ads by design |
| Stories / Radio nodes | E-003 | 28 beat-based stories (14 × hsk1, 14 × hsk2), `assets/data/stories_*.json`; story completion tracked | 🟡 | No stories for local 2025 levels (content gap); no Radio |
| Onboarding / placement | unavailable | None — level picker in Settings; Jump-ahead checkpoint tests act as placement | 🟡 | No first-run onboarding flow or placement quiz |

## Lesson engine — exercise types

| Duolingo type | Evidence | Kunkwan | Verdict |
|---|---|---|---|
| Translate ZH→EN (chip bank) | E-017, E-018 | `bank` | ✅ |
| Translate EN→ZH (chips ↔ typing) | E-023, E-024 | `zh` (chip bank + `typed` free-input mode) | ✅ |
| Fill in the blank (3 options) | E-022 | `fill` | ✅ |
| Match pairs | E-025 | `match` | ✅ |
| Tap what you hear | E-026 | `listen` (chip-arrange translation of audio via `renderBankQ`; slow voice via `speakSlow`) | 🟡 arranges translation, not heard transcript; no "can't listen now" |
| Speaking | — | `speak` (Web Speech API + self-score fallback) | ✅ |
| Character/writing | — | `write` (Hanzi Writer stroke-order) | ✅ |
| Hanzi↔pinyin↔meaning drills | — | `hz2py`, `py2hz`, `hz2mn` (Kunkwan-specific) | ✅ extra |

## Lesson engine — cross-cutting rules

| Duolingo rule | Evidence | Kunkwan | Verdict |
|---|---|---|---|
| CHECK disabled until answer | E-016 | ✅ | ✅ |
| Enter shortcut | E-016 | ✅ | ✅ |
| Correct/wrong bottom sheet + canonical/alt answer | E-020, E-021 | ✅ incl. "Alternative:" display | ✅ |
| "Meaning:" reveal | E-021 | 🟡 (answer + pinyin shown; no separate gloss reveal) | 🟡 |
| Per-word hover glosses | E-019 | ❌ | ❌ |
| "N IN A ROW" combo | E-027 | ✅ ("in a row" streak in quiz) | ✅ |
| Wrong answer doesn't advance progress | E-016 | ✅ | ✅ |
| Missed items re-queued as PREVIOUS MISTAKE | E-028 | ✅ label exists | ✅ |
| Results: personalised headline + XP + accuracy | E-029 | ✅ XP + accuracy stats per exercise type | ✅ |
| Quest progress screen after results | E-029 | 🟡 (quest state updates; no dedicated post-results quest card) | 🟡 |

## Gamification & retention

| Feature | Kunkwan | Verdict | Note |
|---|---|---|---|
| XP | ✅ per-answer, per-level | ✅ | |
| Streak | ✅ activity-based (earn XP to extend; `dqLeft` countdown) | ✅ | |
| Daily goal | ✅ 10/20/30/50 XP pick | ✅ | |
| Daily quests | ✅ rotating + countdown | ✅ | No monthly/meta-quest |
| Achievements/badges | ✅ tiered, unlock popup + gallery | ✅ | |
| Streak Freeze | ❌ | ❌ | P1 — needs shop or direct power-up model |
| Leagues | ❌ | ⛔ | Backend required |
| Friend quests / social | ❌ | ⛔ | Backend required |

## Content coverage

| Area | Duolingo C1–A1 Chinese | Kunkwan | Verdict |
|---|---|---|---|
| Vocabulary corpus | ~2–3k words | hsk1 300 + hsk2 770 public; local 2025: L2 200, L3 500, L4 1,000, L5 1,600, L6 1,800 = 5,100 (private/local) | ✅ breadth; depth per-word lower |
| Sentence audio | TTS per sentence | Web Speech TTS zh-CN (+slow) | ✅ |
| Grammar curriculum | per-unit tips | 28 unit grammar notes (2 public levels) | 🟡 local levels missing |
| Stories | hundreds | 28 (2 public levels) | 🟡 local levels missing |
| HSK 7–9 | n/a | extracted (5,600 words), not built | ❌ build pending |
| Character stroke data | per char | `assets/hw.json` + Hanzi Writer | ✅ |

## Summary

- **Core learning loop**: at functional parity — 10 exercise types cover every observed Duolingo type plus hanzi drills; engine rules (CHECK/Enter/sheet/re-queue/results/combo/alt-answer) verified present.
- **Remaining product gaps**: Sections/CEFR overview, sequential lock model (open-path + checkpoints instead), per-word glosses, "can't listen now", post-results quest card, streak freeze, onboarding/placement flow.
- **Content gaps**: stories + grammar notes for local 2025 levels; HSK 7–9 build; 3 source defects from `validation-report.md`.
- **Blocked by design**: leagues, social, cloud sync (all need backend/accounts); subscription/ads (rejected by design).
