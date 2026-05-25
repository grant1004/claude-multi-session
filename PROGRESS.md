---
skipped: []
in_progress: []
completed: [M1.1, M2.1, M3.1, M3.2, M4.1, M5.1]
---

# PROGRESS

## 現在進度

M1.1–M5.1 complete. Wave 3 dispatching: M6.1–M6.4 (worktree isolation model).

## Audit summary

- **Project**: claude-multi-session — Claude Code plugin providing a multi-session parallel coding workflow (Reviewer/Worker roles, dispatch protocol, structured logging) over `claude-peers-mcp`
- **Tech stack**: Pure markdown plugin (no build step), PowerShell launcher script, depends on `claude-peers-mcp` (Bun/TypeScript, external). Git as synchronization primitive.
- **Architecture quick-take**: The plugin has 4 slash commands (`init`, `audit`, `roll-call`, `bootstrap`) under `plugins/claude-multi-session/commands/`, 11 template files in `plugins/claude-multi-session/templates/` (3 roles, 3 message formats, 4 log formats, 1 workflow doc), a PowerShell launcher (`scripts/claude-peers.ps1`), and top-level docs (`README.md`, `QUICKSTART.md`). The marketplace manifest at `.claude-plugin/marketplace.json` points at the `plugins/claude-multi-session/` subdirectory via `git-subdir` source. No runtime code — the "logic" lives in command prompt files that instruct Claude Code what to do.
- **Recommended worker count**: 3 (see parallelism analysis below)

## Milestones

### M1.1 — Add `.gitignore` for repo hygiene
- [x] <!-- ta07g674 --> 「註」 Focused gitignore: OS files (.DS_Store, Thumbs.db), Obsidian workspace state (workspace.json, workspace-mobile.json), node_modules/, editor configs (.vscode/, .idea/). Kept minimal — no boilerplate dump.
- **Expected files**: `.gitignore`
- **Acceptance**:
  - `.gitignore` exists at repo root with entries for: OS files (`.DS_Store`, `Thumbs.db`), Obsidian workspace state (`docs/.obsidian/workspace.json`, `docs/.obsidian/workspace-mobile.json`), `node_modules/`, editor configs (`.vscode/`, `.idea/`)
  - `git status` no longer shows untracked noise files (if any existed)
- **Effort**: S
- **ROI**: high — prevents accidental commits of per-user state (Obsidian workspace, OS metadata) that cause noise in diffs and merge conflicts

### M2.1 — Replace WPF-specific examples in templates with framework-agnostic ones
- [x] <!-- uogks3hf --> 「註」Replaced all WPF/XAML/DataTrigger examples with generic ones: env-var-shadow pitfall, Redis cache decisions, REST API pagination patterns. Also cleaned daily.md (DependencyProperty, BeginAnimation, DrawingVisual, App.xaml). Template structure preserved unchanged.
- **Expected files**: `plugins/claude-multi-session/templates/.claude-multi-session/log-templates/pitfall.md`, `plugins/claude-multi-session/templates/.claude-multi-session/log-templates/atomic.md`, `plugins/claude-multi-session/templates/.claude-multi-session/log-templates/reviewer-master.md`, `plugins/claude-multi-session/templates/.claude-multi-session/messages/completion-report.md`
- **Acceptance**:
  - No references to WPF, DataTrigger, MultiBinding, XAML, DependencyProperty, `App.xaml`, or `.csproj` remain in any template file under `plugins/claude-multi-session/templates/`
  - Replacement examples are generic (e.g. a "database connection string stored in env var instead of config file" pitfall, or a "REST API pagination off-by-one" example) and still illustrate the template structure clearly
  - Template markdown structure (frontmatter fields, section headings, placeholder tokens) is unchanged — only the example content differs
- **Effort**: M
- **ROI**: high — current WPF examples confuse users applying the plugin to non-WPF projects and make the plugin look domain-specific rather than general-purpose

### M3.1 — Add bash/zsh launcher script for macOS/Linux
- [x] <!-- 20c59hcc --> 「註」bash launcher `scripts/claude-peers` (no extension) mirrors PS1 behavior: `-id` arg, env var, `exec` passthrough. README § Launcher updated with platform table.
- **Expected files**: `plugins/claude-multi-session/scripts/claude-peers` (no extension, Unix-idiomatic), `README.md`
- **Acceptance**:
  - `claude-peers` (no extension) exists under `scripts/`, is executable (`chmod +x`), accepts `-id <name>` and optional extra args, sets `CLAUDE_PEERS_PEER_ID` env var, launches `claude` with `--dangerously-skip-permissions --dangerously-load-development-channels server:claude-peers`
  - Behavior mirrors `claude-peers.ps1` (same flags, same env var, same passthrough of extra args). User-facing command name is `claude-peers -id reviewer` on both OS.
  - `README.md` § "Launcher" updated to mention both scripts: `.ps1` for Windows, extensionless for macOS/Linux
- **Effort**: S
- **ROI**: high — plugin is currently Windows-only in practice; macOS/Linux users can't use the launcher without writing their own wrapper

### M3.2 — Expand QUICKSTART.md with macOS/Linux sections
- [x] <!-- 20c59hcc --> 「註」All 8 steps updated: platform-split headers for Bun install, Git install, claude-peers-mcp clone/register, launcher install (full macOS/Linux PATH + chmod section). Steps 4/6/7 marked platform-neutral with `sh` blocks. Troubleshooting items split per-platform.
- **Expected files**: `QUICKSTART.md`
- **Acceptance**:
  - Each numbered step (1-8) has a macOS/Linux variant or a note that it's platform-neutral
  - Step 1 (Install Bun) shows `curl -fsSL https://bun.sh/install | bash` for macOS/Linux
  - Step 5 (launcher install) references `claude-peers` (no extension) and explains `PATH` setup for bash/zsh (e.g. `~/bin` or `~/.local/bin`, `chmod +x`)
  - Platform-specific commands (PowerShell syntax, `$HOME` vs `~`, `$env:` vs `export`) are clearly split with headers or tabs
- **Effort**: M
- **ROI**: high — the quickstart is the primary onboarding path; a Windows-only guide blocks half the potential user base

### M4.1 — Add `/multi-session:status` command
- [x] <!-- ta07g674 --> 「註」 Read-only command (allowed-tools: Read, Bash(git:*)). Parses frontmatter skip/in_progress lists + milestone checkboxes + session comments. Outputs ✅/🔄/⬜ table + counts. ~30 line cap enforced in behavior rules.
- **Expected files**: `plugins/claude-multi-session/commands/multi-session/status.md`
- **Acceptance**:
  - Running `/multi-session:status` reads `PROGRESS.md` and prints: current phase (audit / dispatching / wrap-up), milestone summary table (ID, description, status checkbox, assigned session if noted in 「註」), count of completed/in-progress/remaining/skipped
  - Command uses only `Read` and `Bash(git:*)` tools (no code writing, no peer messaging)
  - Output is concise enough to fit in one screen (~30 lines max)
- **Effort**: S
- **ROI**: medium — convenient for Reviewer mid-session but `Read PROGRESS.md` works fine as a manual fallback

### M5.1 — Add CHANGELOG.md covering existing commit history
- [x] <!-- uogks3hf --> 「註」Keep a Changelog format, [Unreleased] + [0.1.0] sections. Covers all 18 commits grouped into Added (11), Changed (4), Fixed (3). Includes M1.1/M2.1/M3.1 wave-1 work.
- **Expected files**: `CHANGELOG.md`
- **Acceptance**:
  - `CHANGELOG.md` exists at repo root, follows Keep a Changelog format (`## [Unreleased]` + `## [0.1.0] - 2026-05-25` or similar)
  - Covers the 14 existing commits grouped by type (Added, Changed, Fixed)
  - Key entries: plugin scaffolding, marketplace manifest, init/audit/roll-call commands, PowerShell launcher, QUICKSTART, git pre-check on init, Obsidian vault support
- **Effort**: S
- **ROI**: medium — provides release context for users and contributors; not blocking but expected for any published plugin

### M6.1 — Add pitfall entry for PROGRESS.md shared-worktree race condition
- [x] <!-- ta07g674 --> 「註」 Pitfall entry: symptom (silent cross-worker PROGRESS.md edit leakage), root cause (shared worktree = no physical file isolation), fix (worktree-per-worker model in M6.2–M6.4). Category workflow, severity high, status resolved.
- **Expected files**: `docs/pitfalls/progress-md-race.md`
- **Acceptance**:
  - Pitfall entry exists with: symptom (concurrent workers on one branch pick up each other's uncommitted PROGRESS.md edits), root cause (shared working tree), fix (worktree-per-worker model), severity high, status resolved
  - Uses the pitfall template format from `.claude-multi-session/log-templates/pitfall.md`
- **Effort**: S
- **ROI**: high — documents the race condition discovered this session; prevents future teams from hitting it

### M6.2 — Update workflow.md + roles (reviewer.md, worker.md) for worktree + per-worker branch model
- [ ] <!-- sessionN -->
- **Expected files**: `plugins/claude-multi-session/templates/.claude-multi-session/workflow.md`, `plugins/claude-multi-session/templates/.claude-multi-session/roles/reviewer.md`, `plugins/claude-multi-session/templates/.claude-multi-session/roles/worker.md`
- **Acceptance**:
  - workflow.md has new "Worktree lifecycle" section: `git worktree add`, branch naming `session/<id>`, Reviewer merge flow, cleanup
  - workflow.md state machine updated: dispatch creates worktree+branch, execute happens on worker branch, review includes merge to main
  - workflow.md pitfall table updated: "Race on PROGRESS.md" row points to structural fix (worktree model)
  - reviewer.md adds: worktree creation before first dispatch, `git merge --ff-only` on review pass, `git worktree remove` + branch delete on session close
  - worker.md adds: step 0 verify worktree (`pwd` check), commit to `session/<id>` branch not main, `git rebase main` before each milestone
  - Language consistent across all 3 files
- **Effort**: M
- **ROI**: high — core workflow change, everything else depends on this being correct

### M6.3 — Update message templates (dispatch.md, review-pass.md) + atomic.md for worktree model
- [ ] <!-- sessionN -->
- **Expected files**: `plugins/claude-multi-session/templates/.claude-multi-session/messages/dispatch.md`, `plugins/claude-multi-session/templates/.claude-multi-session/messages/review-pass.md`, `plugins/claude-multi-session/templates/.claude-multi-session/log-templates/atomic.md`
- **Acceptance**:
  - dispatch.md has new "Worktree setup pre-block" (parallel to first-dispatch pre-block): verify `pwd` is worker's worktree, `git branch --show-current` equals `session/<id>`
  - dispatch.md rules section updated for branch-based commits
  - review-pass.md after-pass actions updated: merge → push → optionally worktree remove + branch delete
  - atomic.md frontmatter gains `branch: session/<id>` field
  - atomic.md rule-compliance block gains "Committed to `session/<id>` branch (not main) ✓"
- **Effort**: S
- **ROI**: high — dispatch/review templates are the primary worker interface

### M6.4 — Update CHANGELOG.md with worktree model changes
- [ ] <!-- sessionN -->
- **Expected files**: `CHANGELOG.md`
- **Acceptance**:
  - `[Unreleased]` section updated with: "Added: git worktree + per-worker branch isolation model (prevents PROGRESS.md race condition)" and lists all changed template files
  - Existing `[0.1.0]` section untouched
- **Effort**: S
- **ROI**: medium — keeps changelog current

## Parallelism analysis (Wave 3)

- Max independent file-region set: **3 milestones** (M6.1, M6.3, M6.4 — separate files)
- Sequencing constraints:
  - M6.3 depends on M6.2: dispatch.md and review-pass.md must reference the same worktree lifecycle defined in workflow.md/roles. M6.2 establishes the model, M6.3 applies it to templates.
  - M6.1 (pitfall) and M6.4 (CHANGELOG) are independent of everything.
- **Recommendation**: Wave 3a: M6.1 + M6.2 in parallel (no overlap). Wave 3b: M6.3 + M6.4 after M6.2 lands.

## 待用戶決定 / Pending user decision

(None.)

## 設計決策變更紀錄 / Decision changelog

- **2026-05-25 — Launcher naming**: bash launcher 用 `claude-peers`（無副檔名，Unix 慣例）；PowerShell 保留 `claude-peers.ps1`。使用者 PATH 看到的命令名一致：`claude-peers -id reviewer`，兩個檔案內部分別處理 OS。
- **2026-05-25 — 版號 scheme**: 0.1.0 起步，SemVer。plugin status 標 `pre-release / iterating`，0.x 階段允許 breaking changes。第一個 stable release 升 1.0.0。
- **2026-05-25 — Worktree isolation model**: 從共用 working tree + 單一 branch 改為 git worktree + per-worker branch。每個 worker 有自己的 worktree（`../worker-<id>`），commit 到 `session/<id>` branch，Reviewer review pass 後 `git merge --ff-only` 回 main。解決 PROGRESS.md race condition（見 [[progress-md-race]]）。Launcher 不自動建 worktree — 由 Reviewer dispatch 時處理。
