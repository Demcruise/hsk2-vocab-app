# REA Setup Log

## 2026-11-11 — attempt 1: blocked

| Step | Result |
|---|---|
| Package | `rea-agents@6.8.0` (npm), source `github.com/morluto/rea`, MIT |
| Coding agent | Claude Code (desktop app, Code tab) → REA client id `claude_code` |
| Dry run | `npx rea-agents@latest setup --dry-run --client claude_code` → `status: needs_human`, `plannedActions: []` |
| Blocker | Node.js v24.14.0 installed; REA requires `^22.23.4 \|\| ^24.22.1 \|\| >=26.12.1`. Remediation from REA: "Install Node.js 22.x (>=22.23.4), 24.x (>=24.22.1), or 26.12.1+ and rerun setup." |
| Files setup would touch (from doctor report) | MCP registration in `C:\Users\PC\.claude.json`; skill copy at `C:\Users\PC\.claude\skills\reverse-engineer-anything` |
| Backup taken | `C:\Users\PC\.claude\backups\claude.json.pre-rea-20261111` |
| Changes applied | None — REA is **not installed** |

## 2026-11-11 — attempt 2: installed

| Step | Result |
|---|---|
| Node upgrade | `winget install OpenJS.NodeJS.LTS --version 24.22.1` (user approved UAC) → `node -v` = v24.22.1 |
| Dry run | `status: planned`, 2 actions: `configure_client:claude_code` (update `~/.claude.json`, backup `~/.claude.json.rea.backup`), `install_skill:claude_code` |
| Apply | `npx rea-agents@6.8.0 setup --yes --client claude_code` → `status: ready`, applied `configured_claude_code`, `installed_skill` |
| Registration | `~/.claude.json` → `mcpServers.rea = cmd.exe /d /c npx -y rea-agents@6.8.0 mcp`; doctor state `aligned` |
| Skill | `~/.claude/skills/reverse-engineer-anything` — skill v49, 229 tools, state `aligned`; skill visible in Claude Code session |
| Doctor (claude_code scope, from setup) | `healthy: true` |
| Doctor (all clients) | `healthy: false` — only because other agents (Cursor, VS Code, Codex, …) are not registered and optional providers (Ghidra, JADX, IDA, Kuna, Hopper) are unconfigured. Expected; not needed. |
| MCP connectivity | **Verified** after Claude app restart: `mcp__rea__*` tools (≈230) loaded in session. Live call `inspect_adb_client` returned a structured REA response (`capability_unavailable`: adb binary not found — expected, ADB not installed; set `REA_ADB_PATH` if ever needed). |
| `adb devices` | Not runnable — no ADB / Android SDK on this machine. No device or emulator. |

Backups: `~/.claude/backups/claude.json.pre-rea-20261111` (manual), `~/.claude.json.rea.backup` (REA).

### Optional analysis providers (doctor report, all unconfigured)

| Provider | Requirement | Needed for this project? |
|---|---|---|
| Ghidra | `GHIDRA_INSTALL_DIR` → Ghidra 12.1.x release (needs JDK 21) | No — binary RE of Duolingo excluded (ToS); not needed for own PWA |
| JADX | `REA_JADX_MCP_JAR` → jadx-headless-mcp 0.7.1 JAR (needs JDK) | No, same reason |
| IDA / Kuna | Commercial / external | No |

REA's browser-side commands (`capture-browser-scenario`, `analyze-web-bundle`, `capture-web-screenshot`, `compare-web-captures`) need no provider and cover the product-RE scope.

## Reverse/ working directory

`Reverse/` is gitignored (nested clones). Shallow clones taken 2026-11-11:

| Repo | Commit | License | Purpose | Build needed? |
|---|---|---|---|---|
| `morluto/rea` | `43588f0` | MIT | Source/docs of the REA CLI + MCP | No — use npm package |
| `storytold/craft-anything` | `4d87c5e` | MIT / Apache-2.0 | Rust "clean-room" study-and-rebuild engine (early alpha) | No — reference only; would need Rust toolchain |
| `skylot/jadx` | — | — | Skipped: Android decompiler, needs JDK; no APK target in scope | — |
| `NationalSecurityAgency/ghidra` | — | — | Skipped: very large source tree, needs JDK 21 + Gradle; release build used if ever required | — |
