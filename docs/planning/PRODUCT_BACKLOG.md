# Product & Technical Backlog

Derived from `FEATURE_PARITY_MATRIX.md` + `KNOWN_ISSUES.md` + `validation-report.md`.
Each item: **Now** (current impl) · **Expected** · **Missing** · **Deps** · **Strategy** · **Verify**.

Priority: **P0** learning-loop parity · **P1** retention/product depth · **P2** content expansion · **P3** infrastructure · **⛔** blocked.

## P0 — learning-loop parity

### B-01 Per-word hover glosses in exercises — ✅ DONE
- Shipped: `segSentence` wraps vocab words as `.ex-w` spans with `data-w` + tabindex/role/aria-label; `hzShow` (overrides section) handles `.ex-w` → pinyin + meaning + Listen/Vocab actions in `#hzTip`. Hover, click and keyboard focus all work.
- Verified: `tools/gloss_listen.test.js` (13 checks).

### B-02 "Can't listen now" affordance — ✅ DONE
- Shipped: `.lst-skip` link on listen questions → `cantListen()` sets the session flag `noListen` and rebuilds the current question as a non-listen type (no penalty). All further mixed quizzes in the session exclude `listen`; dedicated 🎧 tile still forces it (explicit user choice).
- Verified: `tools/gloss_listen.test.js`.

### B-03 Post-results quest card — ✅ DONE (already shipped)
- `finishQ` → `renderQuestList('qdQuests',true)` renders the daily-quest card (progress + countdown) on the results screen. No work needed.

### B-04 Onboarding + placement flow
- **Now**: first visit → default HSK 2; level picker in Settings; jump-ahead checkpoint tests exist.
- **Expected**: first-run flow: goal pick → level pick OR placement test (adapts from jump tests).
- **Missing**: onboarding screen, entry-point placement, goal-set at first run.
- **Deps**: jump-ahead test machinery (exists); daily-goal picker (exists).
- **Strategy**: `onboard` flag in storage; first run shows 3-step screen (goal → "new to Chinese?" → start level or take placement = existing jump test on unit 1).
- **Verify**: fresh profile sees onboarding once; placement routes to correct unit; skip works.

### B-05 Listening-exercise toggle in Settings — ✅ DONE
- Shipped: `exListen` (persisted `khsk-exlisten`, global like `expinyin`) with On/Off buttons in the Settings card; `buildQTyped` falls back `listen`→`bank` in mixed rotation only (forceType bypasses so the dedicated tile still works).
- Verified: `tools/gloss_listen.test.js` — persists across reload.

## P1 — retention & product depth

### B-10 Streak Freeze power-up
- **Now**: activity-based streak (earn XP to extend); no protection.
- **Expected**: freeze preserves streak through one inactive day (E-012 shop item).
- **Missing**: inventory item + auto-consume on missed day.
- **Deps**: streak bookkeeping (exists); decide grant model (earn by quest/badge milestones — no shop/currency).
- **Strategy**: `freeze` count in DAILY state; on new-day init, if yesterday inactive & freeze>0 → consume, streak intact, toast "Streak freeze used"; grant 1 per N-day streak milestone.
- **Verify**: unit test — simulate missed day → streak preserved, count decremented; no freeze → streak resets.

### B-11 Sections/level overview screen
- **Now**: level picker only (buttons in Settings); per-level progress shown in its own path.
- **Expected**: `/sections`-like overview: each level/section, % complete, continue/review/jump (E-006).
- **Missing**: cross-level progress dashboard.
- **Deps**: per-bucket progress reads exist.
- **Strategy**: add "Levels" card on Progress screen: rows per bucket with % done, continue → switch level; jump → existing jump test.
- **Verify**: screen lists all registered levels with correct %; continue switches bucket.

### B-12 Sequential lock model (design decision)
- **Now**: open path — all nodes tappable; checkpoints + hearts gate "completion" but not access.
- **Expected**: Duolingo locks future nodes until current completed (E-004).
- **Missing**: strict sequential gating.
- **Deps**: none — pure state/visual.
- **Strategy**: **decide first** — keep open+checkpoint (current, simpler, suits self-directed learners) vs sequential lock (Duolingo-faithful). If lock: nodes beyond current render grey + tap → toast "finish the unit above"; Jump test still bypasses.
- **Verify**: locked node shows locked style and can't start; completing unit unlocks next.

### B-13 Monthly meta-quest → badge
- **Now**: daily rotating quests only.
- **Expected**: monthly quest (e.g. "30 quests this month") awarding a badge (E-010).
- **Missing**: monthly quest type + badge hook.
- **Deps**: badge system (exists), quest counter.
- **Strategy**: monthly counter in storage; badge tier for 10/20/30 completions; Progress shows one monthly quest card.
- **Verify**: completing daily quests increments monthly counter; threshold → badge unlock popup.

### B-14 "Target practice" tile in Practice hub
- **Now**: hub tiles = listen/speak/write/weak-words/story grid.
- **Expected**: one "Practice" tile that picks exercises targeted at the learner's weakest skill type (E-009).
- **Missing**: auto-targeted practice mode.
- **Deps**: accuracy-per-exercise-type stats (exist since d8061bc).
- **Strategy**: tile → quiz weighted toward lowest-accuracy exercise types + SRS-due words.
- **Verify**: tile launches mixed quiz biased to weakest recorded type.

### B-15 Mistakes collection view
- **Now**: completed stories reopen on tap (reread works); weak-words = SRS mistake queue.
- **Expected**: a "mistakes" tile collecting recently-missed items (E-009).
- **Missing**: explicit mistakes list/practice (weak-words is close — SRS queue, not an explicit mistakes view).
- **Deps**: mistake tracking (exists via skill miss counters + SRS).
- **Strategy**: add "Mistakes" hub tile → filtered quiz of last-N-missed words.
- **Verify**: mistakes quiz uses actually-missed words.

## P2 — content expansion

### B-20 Stories for local 2025 levels
- **Now**: `stories_hsk1/hsk2.json` only; local levels show "No story for this topic yet".
- **Expected**: `stories_<bucket>.json` per level (14 units each).
- **Missing**: story content for hsk2b–hsk6b (5 × 14 = 70 stories).
- **Deps**: local-content pipeline (gitignored output); story JSON schema.
- **Strategy**: author per-unit short stories keyed to unit topic + vocab; store under `local-content/` (never committed); loader already fetches `assets/data/stories_<LEVEL>.json` — needs local-content path resolution for local buckets.
- **Verify**: story tile renders per unit on a local level; open → beat flow; completion saves.

### B-21 Grammar notes for local 2025 levels
- **Now**: `grammar.json` covers hsk1/hsk2 only.
- **Expected**: guidebook notes for all level buckets.
- **Missing**: grammar content for hsk2b–hsk6b units.
- **Deps**: guidebook renderer (exists).
- **Strategy**: author HSK-appropriate grammar per unit topic; local buckets read from `local-content/grammar_<bucket>.json` (private) — keep public grammar.json for public levels.
- **Verify**: guidebook button on a local level shows unit notes.

### B-22 HSK 7–9 build
- **Now**: 5,600 words extracted to `local-content/hsk2025.json`; no level file.
- **Expected**: `level-hsk7-9-2025.json` + levels.json entry + bucket `khsk7b`.
- **Missing**: sentence authoring for ~5,600 words (largest authoring task; min 2 sentences each ≈ 11k sentences) + topics.
- **Deps**: builder (works); MIN_SENT=2 default for L5+.
- **Strategy**: check how many words already share hanzi with L2–L6 (corpus sentences auto-apply); batch-author the rest in s1..sN files like L5/L6. Estimate first, then decide if 7–9 stays out of local scope.
- **Verify**: builder exit 0; app shows the level; `local_level.test.js` passes.

### B-23 Source-data defect fixes
- **Now**: `validation-report.md` — 换乘 empty meaning; duplicate 称 chēng/乘 chéng senses; malformed 高龄 pinyin; 唆 7–9 entry missing a char.
- **Expected**: clean extract or documented overrides.
- **Missing**: patch step in extractor.
- **Deps**: `tools/extract_local_hsk.mjs`.
- **Strategy**: `tools/hsk2025_overrides.json` applied post-extract (hand-fix meanings; dedupe senses); document each override.
- **Verify**: validation-report shows 0 errors; rebuilt levels pick up fixes.

### B-24 Flutter parity for local 2025 levels
- **Now**: PWA loads `local-content/levels.json`; Flutter has no local-level support (LOCAL_CONTENT.md "Not yet").
- **Expected**: mobile app reads the same levels.
- **Missing**: loader + storage buckets + level picker in Flutter.
- **Deps**: local-content is private — decide shipping model (Flutter bundles nothing public; local files via app sandbox/import?).
- **Strategy**: **decide first** — likely: copy `local-content/*.json` into app sandbox via file picker, or dev-only asset bundling for the owner's device. Then mirror PWA bucket/copy-progress logic in Dart.
- **Verify**: level appears in Flutter level picker; quiz runs; progress separate bucket.

### B-25 Corpus sentence quality pass
- **Now**: some older corpus sentences start lowercase or join pinyin oddly (documented known issue).
- **Expected**: all sentences capitalized, natural pinyin spacing.
- **Missing**: one normalization pass over generated level files (or builder post-process).
- **Deps**: builder.
- **Strategy**: add a post-pass in `build_local_level.mjs` (capitalize first letter; re-run sentencePinyin on corpus sentences?) — careful: re-generating pinyin could introduce new misreads; safer = capitalize only + flag odd joins in report for manual fix.
- **Verify**: report lists flagged sentences; spot-check fixed output.

## P3 — infrastructure & quality

### B-30 CI baseline
- **Now**: no `.github/workflows`; tests run locally against `http://localhost:8734` + system Chrome.
- **Expected**: pipeline: install tools deps → serve root → run `tools/*.test.js` (+ `_smoke.js` if headless Chrome works) → upload report.
- **Missing**: workflow file + Chrome install step (`@puppeteer/browsers install chrome` + `CHROME_PATH` env).
- **Deps**: puppeteer-core (installed in tools/).
- **Strategy**: `ci.yml` on push/PR to main+feat branches; `npx @puppeteer/browsers install chrome@stable` then `CHROME_PATH=<path> node tools/local_level.test.js` etc.; serve via `npx http-server -p 8734`.
- **Verify**: green run on a PR; failures surface.

### B-31 Merge `docs/phase0-audit`
- **Now**: audit docs (inventory, evidence log, REA_SETUP, audit, architecture, known issues) live only on `docs/phase0-audit`.
- **Expected**: audit docs part of the deliverable branch.
- **Missing**: merge/cherry-pick into working branch (or main).
- **Deps**: none; docs-only.
- **Strategy**: `git merge docs/phase0-audit` into feature branch — different filenames from `docs/planning/*`, expect clean; or merge both to main when PR opens.
- **Verify**: `docs/reverse-engineering/` present on branch; links resolve.

### B-32 Service-worker version discipline check
- **Now**: `sw.js` bumped manually per AGENTS.md when `index.html` changes.
- **Expected**: can't-forget bump (CI check or version const derived from build).
- **Missing**: automation.
- **Deps**: B-30 CI.
- **Strategy**: CI step: if `index.html` changed in the PR but `sw.js` VERSION didn't → fail.
- **Verify**: PR touching index.html without bump fails CI.

## ⛔ Blocked (backend/accounts)

| Item | Why blocked | Unblocks when |
|---|---|---|
| Leaderboards/leagues (E-011) | multi-user ranking needs server | sync/accounts exist |
| Friend/social quests | same | same |
| Cloud sync across devices | needs accounts + storage API | backend chosen; today: file backup/restore |
| Radio/conversation practice | needs original audio content | audio pipeline exists |
| Duolingo-style shop (gems) | needs economy + persistence model | streak freeze (B-10) ships first |

## Explicit non-goals (by design)

- Ads/subscription — owner decision; free local app.
- Duolingo owl/branding/artwork — must stay original.
- Committing `local-content/` — private per license.
