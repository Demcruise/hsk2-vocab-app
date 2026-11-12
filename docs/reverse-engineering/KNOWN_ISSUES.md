# Known Issues — Baseline (2026-11-11)

Severity: P0 data loss / broken core flow · P1 incorrect behaviour · P2 quality / maintainability · P3 cosmetic.

| ID | Sev | Area | Issue | Evidence | Proposed fix |
|---|---|---|---|---|---|
| K-01 | **P0 — fixed in `fix/k01-persist-lesson-story-progress` (1d3af5d)** | PWA persistence | `saveState()` (`index.html:950`) does not write `st` (stories done) or `ld` (lessons done), although `loadState()` reads them. Lesson-complete marks and story completion are lost on every reload unless restored from a backup file. | Reload probe: stored keys `p,s,l,x,q,a,k,sc,md,vf,kf,wid,sa`; after reload `S.ld={}`, `S.st={}`. | Add `st:S.st, ld:S.ld` to `saveState` payload; add reload regression test. |
| K-02 | P1 | Tests | Smoke check "ld persisted" (`tools/_smoke.js:116`) only checks in-memory `S.ld`, so it passes while K-01 exists. | Code reading | Assert after `page.reload()`. |
| K-03 | P1 | Gamification | Streak increments when the app is **opened** (`loadState`), not when a learning activity is completed. Opening the app without studying keeps the streak. | `index.html:949` | Move streak update to activity completion; store activity dates. |
| K-04 | P1 | Curriculum | **Confirmed edition mixing.** HSK1 (300) matches the 2025 HSK 3.0 revision; HSK2 (770) comes from a 2021-standard list (Khanji School PDF). Under the 2025 revision HSK2 = 200 new words. | `docs/content/HSK_CURRICULUM_SPEC.md`, PDF headers | Decide edition (recommended: 2025 revision), rebuild HSK2, migrate progress. |
| K-16 | P1 | Licensing | Repo PDFs `HSK2-Vocabulary-3.0.pdf` and untracked `all hsk level/*.pdf` are HanziStroke exports; HanziStroke ToS forbid bulk extraction and building a competing dataset. HSK1 data may also derive from a HanziStroke PDF. | `docs/content/CONTENT_LICENSE_REGISTER.md` L-02 | Do not import as app data; source official list instead; review whether to keep the PDF in the repo. |
| K-05 | P1 | Data | 7 duplicate hanzi in HSK2 (倒, 得, 老, 面, 省, 头, 长) — likely legitimate polyphones/separate senses but not modelled (no sense/reading id). 38 words appear in both HSK1 and HSK2 lists. | Dataset script | Add stable word ids keyed by hanzi+pinyin+level; decide overlap policy. |
| K-06 | P1 | Learning path | No locking/prerequisites — any lesson can be started; "current" node = first not-done. | `renderLearnPath` | Spec unlock rules in Phase 2/4. |
| K-07 | P2 | Architecture | Function redefinition (`startQuiz`, `showQ`, `checkAns` declared twice; `// OVERRIDES` reassignment block). Effective code path is non-obvious. | `index.html:1030 vs 1327`, `:1742+` | Remove dead first-generation definitions during modular refactor. |
| K-08 | P2 | Data sync | Vocabulary exists in 3 copies (JSON, inlined in `index.html`, `mobile/assets/data`). `tools/_extract_data.py` referenced by mobile README is missing. | Repo tree | Single source + generator + CI diff check. |
| K-09 | P2 | Persistence | No schema version or migration in localStorage payload; streak date stored as locale `toDateString()`. | `saveState` | Add `v` + migration function. |
| K-10 | P2 | CI | No CI; smoke test hard-codes Chrome path and port; Flutter tests not run automatically. | No `.github/` | Phase M0 CI baseline. |
| K-11 | P2 | Versioning | `APP_VERSION='v10'` and SW `VERSION='v18'` drift independently. | `index.html:931`, `sw.js:11` | Single version source. |
| K-12 | P2 | Hearts | Hearts (5) silently end quizzes while HUD shows ⚡∞. | `index.html:1106, 1199` | Decide hearts policy (Phase 4) and make it visible or remove. |
| K-13 | P2 | Content licensing | PDFs (HSK lists, possibly third-party) committed to repo; example sentences are machine-generated with no review record. | Repo tree | CONTENT_LICENSE_REGISTER; review before redistribution. |
| K-14 | P3 | Repo hygiene | Empty `nul` files in root and `tools/`; `app/` build output committed; `skills-lock.json`, `.agents/`, `agent/` skill dirs untracked/unclear. | `ls` | Clean up in a hygiene commit. |
| K-15 | P3 | Environment | No JDK / Android SDK / ADB on dev machine — no APK builds, no device testing, JADX/Ghidra unusable. | Toolchain check | Install only if binary RE or Android build is approved. |
