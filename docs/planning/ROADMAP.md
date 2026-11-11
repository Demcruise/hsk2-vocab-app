# Roadmap — re-estimated after audit + 2025-content work

Backlog milestone model M0–M7, annotated with verified status on `feat/local-hsk2025-content`.
Backlog item IDs refer to `PRODUCT_BACKLOG.md`.

Legend: ✅ done · 🟡 partial · ⬜ remaining · ⛔ blocked

## M0 — foundation & audit

| Item | Status | Note |
|---|---|---|
| Repository audit, existing-features doc, architecture doc, known-issues doc | ✅ | `docs/reverse-engineering/*` on `docs/phase0-audit` — needs merge (B-31) |
| Environment setup, REA install + verify | ✅ | REA_SETUP.md: installed, ~230 tools, connectivity verified |
| Authorized Duolingo investigation + evidence log + feature inventory | ✅ | read-only web pass; E-001–E-029 |
| Feature-parity matrix | ✅ | `FEATURE_PARITY_MATRIX.md` (this refresh) |
| Product backlog + roadmap | ✅ | this doc + `PRODUCT_BACKLOG.md` |
| Regression test suite | 🟡 | 10 `tools/*.test.js` + `_smoke.js` exist — not automated |
| CI baseline | ⬜ | B-30 |

## M1 — learning loop

| Item | Status | Note |
|---|---|---|
| Curriculum navigation (Level → Unit → Node → Lesson) | ✅ | path, 14 units/level, unit guidebook |
| Exercise engine + answer validation | ✅ | 10 types in Q_MIX |
| Lesson results (XP + accuracy) | ✅ | plus per-type accuracy stats |
| Progress persistence | ✅ | per-level buckets + backup/restore |
| Checkpoints / jump-ahead | ✅ | heart-gated exams |
| Per-word glosses · "can't listen now" · post-results quest card · onboarding/placement | ⬜ | B-01, B-02, B-03, B-04 |

## M2 — curriculum content

| Item | Status | Note |
|---|---|---|
| HSK 1 + legacy HSK 2 (public) | ✅ | 300 + 770 words, own sentences |
| HSK 2025 levels 2–6 (local) | ✅ | 200/500/1000/1600/1800 words, all ≥2 sentences + topics (L6 completed this branch) |
| Content validation pipeline | ✅ | `extract_local_hsk.mjs` + `validation-report.md` + builder guards |
| HSK 7–9 (5,600 words) | ⬜ | B-22 — extracted, not built; largest authoring task |
| Source defects (换乘, 称/乘, 高龄, 唆) | ⬜ | B-23 |
| Grammar notes for local levels | ⬜ | B-21 |
| Stories for local levels | ⬜ | B-20 |

## M3 — skill practice

| Item | Status | Note |
|---|---|---|
| Flashcards (flashcard session + hafal) | ✅ | |
| Listening | ✅ | `listen` + TTS + slow voice |
| Reading (sentences, bank builder) | ✅ | |
| Writing (stroke order) | ✅ | Hanzi Writer + hw.json |
| Dictation | 🟡 | covered by `listen`/`zh` typed mode — a dedicated dictation type optional |
| Speaking | ✅ | Web Speech API + fallback |
| Grammar | 🟡 | unit guidebook (2 public levels); B-21 for local |

## M4 — gamification

| Item | Status | Note |
|---|---|---|
| XP, streak, daily goal | ✅ | activity-based streak + countdown |
| Daily quests | ✅ | rotating + timer |
| Achievements/badges | ✅ | tiered, unlock popup, gallery |
| Streak freeze | ⬜ | B-10 |
| Monthly meta-quest → badge | ⬜ | B-13 |
| Leaderboards/leagues | ⛔ | backend-dependent |

## M5 — adaptation

| Item | Status | Note |
|---|---|---|
| Spaced repetition | ✅ | SRS review queue |
| Weakness detection | ✅ | per-skill miss counters + weak-words practice |
| Personalized review / recommendations | 🟡 | accuracy-per-type stats exist; "target practice" tile B-14 |
| Placement/adaptive start | ⬜ | B-04 (jump tests as placement) |

## M6 — UX quality

| Item | Status | Note |
|---|---|---|
| Responsive layout | ✅ | mobile-first; layout stress scripts exist |
| Accessibility | ✅ | reduced-motion, ARIA landmarks, contrast passes |
| Animation/polish | ✅ | fun-isometric stickers, node animations |
| Offline behavior | ✅ | service worker + version discipline (B-32 automates the check) |
| Settings | 🟡 | dark mode, pinyin toggle, levels; lesson-experience toggles B-05 |
| Sections overview | ⬜ | B-11 |

## M7 — release & ops

| Item | Status | Note |
|---|---|---|
| Backup/restore | ✅ | file export/import + auto-save |
| Deployment | ✅ | GitHub Pages (public levels only, by design) |
| CI/CD | ⬜ | B-30 (+ B-32 SW-version gate) |
| Monitoring | ⬜ | prod_smoke.js exists; no alerting |
| Security | ✅ (local) | no secrets; local-only content isolated |
| Regression validation | 🟡 | manual test runs; automate via B-30 |

## Sequencing (next 3 work items)

1. **P0 engine gaps** — B-01 glosses, B-02 can't-listen, B-03 quest card, B-05 settings toggle (small, surgical, visible parity).
2. **P1 retention** — B-10 streak freeze, B-13 monthly quest, B-14 target practice, B-15 reread/mistakes.
3. **P2 content** — B-20/B-21 stories+grammar for local levels (authoring-heavy), then B-22 L7–9 feasibility pass (estimate before committing), B-23 source fixes, B-25 corpus polish.

Re-estimate note: the audit showed the codebase is well past "clone the UI" — core engine and gamification are already at functional parity. Remaining effort is concentrated in **content authoring volume** (L7–9 ≈ 11k sentences; 70 stories; 70 grammar units) and **backend-dependent features** (explicitly deferred). Order items by learning impact first, authoring volume second.
