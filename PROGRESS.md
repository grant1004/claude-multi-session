---
skipped: []
in_progress: [M4.1, M4.2, M4.3]
completed: [M1.1, M1.2, M2.1, M2.2, M3.1, M3.2, M3.3]
---

# PROGRESS

## 現在進度

Phase 2 audit complete — 5 milestones (M4.1–M5.2), codebase-memory MCP integration across workflow. Awaiting dispatch.

## Audit summary

- **Project**: claude-multi-session — Claude Code plugin providing multi-session parallel coding workflow (Reviewer/Worker roles, dispatch protocol, structured logging) over `claude-peers-mcp`
- **Tech stack**: Pure markdown plugin (no build step), PowerShell + bash launcher scripts, Git as synchronization primitive. Depends on `claude-peers-mcp` (Bun/TypeScript, external).
- **Architecture quick-take**: 5 slash commands under `plugins/claude-multi-session/commands/multi-session/` (init, audit, roll-call, bootstrap, status), 11 template files in `plugins/claude-multi-session/templates/.claude-multi-session/` (3 roles, 3 messages, 4 log formats, 1 workflow doc), 2 launcher scripts in `plugins/claude-multi-session/scripts/`. No runtime code — logic lives in command prompt files. Root `.claude-multi-session/` is the dogfood copy for this repo's own workflow.
- **Hotspots** (last 30 commits):
  - `PROGRESS.md` (8 commits) — updated by every milestone + reviewer
  - `plugins/.../commands/multi-session/audit.md` (4 commits) — most-iterated command
  - `plugins/.../templates/.claude-multi-session/messages/dispatch.md` (3 commits)
  - `CHANGELOG.md` (3 commits)
  - `plugins/.../templates/.claude-multi-session/workflow.md` (2 commits)
- **現狀**:
  - **Done**: Plugin scaffolding, 5 commands, all role/message/log templates, cross-platform launchers, worktree isolation model, ADR-001 implemented in audit.md, QUICKSTART, README, CHANGELOG
  - **Half-done**: Root `.claude-multi-session/` templates stuck at v0.1.0 (missing worktree model, updated rules from v0.2.0 plugin source)
  - **Not started**: Automated tests, CI, upgrade path for existing projects, dispatch/review/self-check helper commands
- **已知限制**: None stated by user. Observed: root template drift should be fixed without diverging from plugin source templates.
- **Recommended worker count**: 3 (see parallelism analysis below)

## Milestones

### M1.1 — Sync root `.claude-multi-session/` templates to v0.2.0 plugin source
- [x] <!-- sessionA --> 「註」Copied all 10 template files (not just 6 dispatched) from plugin source to root `.claude-multi-session/`. 4 extra files (daily.md, pitfall.md, reviewer-master.md, completion-report.md) also had WPF→generic example diffs from M2.1. All files now byte-identical (`diff -r` verified).
- **Expected files**: `.claude-multi-session/workflow.md`, `.claude-multi-session/roles/reviewer.md`, `.claude-multi-session/roles/worker.md`, `.claude-multi-session/messages/dispatch.md`, `.claude-multi-session/messages/review-pass.md`, `.claude-multi-session/log-templates/atomic.md`
- **Acceptance**:
  - Each root `.claude-multi-session/` file is byte-identical to its counterpart under `plugins/claude-multi-session/templates/.claude-multi-session/`
  - `diff -r .claude-multi-session/ plugins/claude-multi-session/templates/.claude-multi-session/` returns no differences
  - Files not changed in v0.2.0 (e.g. `project-manager.md`, `completion-report.md`, `daily.md`, `pitfall.md`, `reviewer-master.md`) remain untouched
- **Effort**: S
- **ROI**: high — the repo's own multi-session workflow uses outdated v0.1.0 templates; any future dogfood session will run on stale instructions

### M1.2 — Add `/multi-session:upgrade` command
- [x] <!-- sessionA --> 「註」Slash command at `upgrade.md`. Flow: pre-flight check → diff each file (unchanged/modified/new/removed) → summary table → AskUserQuestion (apply all / review each / cancel) → apply with per-file or bulk overwrite → report. Follows init.md/status.md format conventions. allowed-tools: Read, Bash(diff/ls/test/cp), Write, Edit, AskUserQuestion.
- **Expected files**: `plugins/claude-multi-session/commands/multi-session/upgrade.md`
- **Acceptance**:
  - Command reads both `plugins/claude-multi-session/templates/.claude-multi-session/` (source) and `.claude-multi-session/` (live) directories
  - Shows a diff summary per file (unchanged / modified / new / deleted)
  - Asks user for confirmation before overwriting each changed file (or offers "apply all")
  - Handles edge cases: `.claude-multi-session/` doesn't exist (tell user to run init first), source and live are already identical (report "already up to date")
  - `allowed-tools` frontmatter includes only Read, Bash(diff:*), Write, Edit, AskUserQuestion
- **Effort**: M
- **ROI**: high — without this, users on v0.1.0 scaffolds must manually delete and re-init to get v0.2.0 templates, losing any customizations

### M2.1 — Add template structure validation script
- [x] 「註」Bash script with 6 checks (27 total assertions): command frontmatter, init.md copy-list existence, WPF regression guard, role headings, message code blocks, log-template frontmatter. Chose bash over Node for zero-dep portability. Log-template check validates frontmatter inside code blocks (templates are documentation files, not direct YAML).
- **Expected files**: `tests/validate-templates.sh` (or `tests/validate-templates.js`), `tests/README.md`
- **Acceptance**:
  - Script validates all files under `plugins/claude-multi-session/`: command files have `allowed-tools` + `description` frontmatter, template files have required sections per type, all file paths referenced in `init.md` exist in `templates/`
  - Script detects regression: no WPF/XAML/DataTrigger terms in any template (regression guard from v0.1.0 cleanup)
  - Script exits 0 on pass, non-zero on failure with clear error messages identifying the failing file and reason
  - Running the script against the current repo passes (exit 0)
- **Effort**: M
- **ROI**: medium — catches template structure regressions that code review misses; foundation for CI

### M2.2 — Add GitHub Actions CI workflow for template validation
- [x] 「註」ubuntu-latest, 2 steps: (1) bash tests/validate-templates.sh, (2) diff -r root vs plugin templates. Triggers on push to main + PRs. No deps needed.
- **Expected files**: `.github/workflows/validate.yml`
- **Acceptance**:
  - Workflow triggers on push to `main` and on pull requests
  - Runs the validation script from M2.1 (`tests/validate-templates.sh` or equivalent)
  - Also runs `diff -r .claude-multi-session/ plugins/claude-multi-session/templates/.claude-multi-session/` and fails if root templates drift from plugin source
  - Workflow passes on current repo state (no pre-existing failures)
- **Effort**: S
- **ROI**: medium — prevents template drift from recurring; PR gate catches issues before merge

### M3.1 — Add `/multi-session:dispatch` helper command
- [x] <!-- sessionC --> 「註」Read-only command (allowed-tools: Read, Bash(git:*), AskUserQuestion, list_peers). 10-step flow: parse PROGRESS.md frontmatter + milestone sections → list_peers → AskUserQuestion (milestone + worker pick) → file-region conflict detection against in_progress list → auto-build "don't touch" list → detect first-dispatch via worker summary heuristic → generate complete dispatch.md-format message as fenced code block. Handles edge cases: unmet dependencies (warning), frontmatter/checkbox inconsistency flags, missing worktree (creation hint). Never writes files or sends messages — output only.
- **Expected files**: `plugins/claude-multi-session/commands/multi-session/dispatch.md`
- **Acceptance**:
  - Command reads PROGRESS.md, extracts remaining (unchecked) milestones, and lists them with expected files
  - Checks file-region overlap between remaining milestones and `in_progress:` milestones (from frontmatter); flags conflicts
  - Generates a pre-filled dispatch message (using `dispatch.md` template) for a user-selected milestone + worker, with "don't touch" list auto-populated from in-progress milestones' file regions
  - Does NOT auto-send — outputs the message for Reviewer to review, edit, and manually `send_message`
  - `allowed-tools` includes Read, Bash(git:*), AskUserQuestion, mcp__claude-peers__list_peers (to discover available workers)
- **Effort**: M
- **ROI**: high — reduces Reviewer cognitive load on the most error-prone step (file-region conflict checking is manual and tedious with 3+ workers)

### M3.2 — Add `/multi-session:self-check` worker pre-commit validation command
- [x] <!-- sessionC --> 「註」Read-only command (allowed-tools: Read, Bash(git:*), Bash(test:*)). 6-step flow: determine milestone ID (arg/context/git) → derive session ID from branch → read PROGRESS.md expected files → run 4 validation checks (file scope match, commit message format, PROGRESS.md checkbox, atomic log existence+frontmatter) → output structured pass/fail checklist. Auto-detects pre-commit vs post-commit mode from git state. Special allowances for PROGRESS.md and session-logs (always in scope). Warnings (⚠️) for non-critical issues vs hard fails (❌).
- **Expected files**: `plugins/claude-multi-session/commands/multi-session/self-check.md`
- **Acceptance**:
  - Command reads the most recent dispatch message context (from conversation) or accepts milestone ID as argument
  - Validates: changed files match dispatched scope (`git diff --stat` vs expected files), commit message format matches `^Mx.y: `, PROGRESS.md checkbox updated, atomic log file exists at expected path
  - Outputs a pass/fail checklist matching the auto-pass criteria format from `dispatch.md`
  - `allowed-tools` includes only Read, Bash(git:*), Bash(test:*) — no write access
- **Effort**: S
- **ROI**: medium — catches common Worker mistakes (missing atomic log, wrong commit format) before Reviewer review, reducing review-fail round-trips

### M3.3 — Add `/multi-session:review` helper command
- [x] 「註」9-step flow: select milestone+branch → read acceptance criteria → git log/diff → per-criterion verdict (met/partial/not met) with evidence → recommend pass/fail/hold → generate review-pass.md format message → optional git merge --ff-only with user confirm. Read-only except merge step. Follows dispatch.md pattern (AskUserQuestion for selection, fenced code block output).
- **Expected files**: `plugins/claude-multi-session/commands/multi-session/review.md`
- **Acceptance**:
  - Command accepts a milestone ID and worker session branch (e.g. `session/sessionA`), reads PROGRESS.md acceptance criteria for that milestone
  - Runs `git log main..session/<id> --stat` and `git diff main..session/<id>` and compares against acceptance criteria
  - Generates a pre-filled review verdict message (using `review-pass.md` template) — Reviewer edits and sends manually
  - On pass, offers to run `git merge --ff-only session/<id>` (with user confirmation before executing)
  - `allowed-tools` includes Read, Bash(git:*), AskUserQuestion, mcp__claude-peers__list_peers
- **Effort**: M
- **ROI**: medium — structured review process reduces time per review cycle; merge automation prevents `--ff-only` forgetting (a documented common mistake)

## Parallelism analysis

- Max independent file-region set: **7 milestones** — all milestones touch entirely separate files. No file overlap between any pair.
- Sequencing constraints:
  - M2.2 depends on M2.1: CI workflow runs the validation script that M2.1 creates
  - M1.2 benefits from M1.1 being done first (upgrade command logic is informed by the actual drift pattern), but files are independent
  - All M3.x milestones are fully independent of each other and all M1.x / M2.x milestones
- Wave plan (3 workers):
  - **Wave 1**: M1.1 + M2.1 + M3.1 (3 workers, no overlap, no dependencies)
  - **Wave 2**: M1.2 + M2.2 + M3.2 (3 workers, no overlap; M2.2 satisfied by M2.1 from Wave 1)
  - **Wave 3**: M3.3 (1 worker; or fold into Wave 2 if a worker finishes early)
- **Recommendation**: spin up 3 workers (`claude-peers -id sessionA / sessionB / sessionC`)

### M4.1 — worker.md: add codebase-memory code exploration protocol
- [ ] **Expected files**: `plugins/claude-multi-session/templates/.claude-multi-session/roles/worker.md`, `.claude-multi-session/roles/worker.md`
- **Acceptance**:
  - worker.md has a new responsibility item describing two-tier codebase-memory usage (try via ToolSearch → fallback to Glob/Grep/Read). NOT three-tier — Workers don't ask user to install, they just fallback silently.
  - Setup section includes a step to load codebase-memory tools via ToolSearch (after reading role files, before waiting for dispatch)
  - "Common mistakes" section includes an entry about using Glob/Grep/Read without first trying codebase-memory
  - Root copy `.claude-multi-session/roles/worker.md` is byte-identical to plugin source (`diff` returns 0)
- **Effort**: S
- **ROI**: high — Workers are the primary code readers; codebase-memory gives them architectural context instead of blind file-by-file grep

### M4.2 — workflow.md: add codebase-memory to roles table and tooling note
- [ ] **Expected files**: `plugins/claude-multi-session/templates/.claude-multi-session/workflow.md`, `.claude-multi-session/workflow.md`
- **Acceptance**:
  - "Roles at a glance" table has a new column "Code exploration" showing tool priority per role (Worker: codebase-memory → Glob/Grep/Read, Reviewer: codebase-memory → git diff, PM: N/A)
  - A short paragraph (not a new section) after the table explains the codebase-memory try→fallback pattern and links to audit.md §4a for the full three-tier logic
  - Root copy `.claude-multi-session/workflow.md` is byte-identical to plugin source
- **Effort**: S
- **ROI**: medium — makes the tool priority visible at the workflow overview level so new sessions see it immediately

### M4.3 — dispatch.md (template): add codebase-memory to onboarding pre-block
- [ ] **Expected files**: `plugins/claude-multi-session/templates/.claude-multi-session/messages/dispatch.md`, `.claude-multi-session/messages/dispatch.md`
- **Acceptance**:
  - First-dispatch onboarding pre-block includes a new step (after existing step 5, before "Confirm via send_message"): load codebase-memory tools via ToolSearch — `get_architecture`, `search_graph`, `trace_path`, `search_code`, `get_code_snippet`. If unavailable, note and proceed with Glob/Grep/Read.
  - The step is numbered correctly (existing steps renumbered if needed)
  - Root copy `.claude-multi-session/messages/dispatch.md` is byte-identical to plugin source
- **Effort**: S
- **ROI**: high — every new Worker gets codebase-memory awareness from their very first dispatch, not buried in worker.md prose

### M5.1 — dispatch command: use codebase-memory for dependency analysis
- [ ] **Expected files**: `plugins/claude-multi-session/commands/multi-session/dispatch.md`
- **Acceptance**:
  - `allowed-tools` frontmatter adds ToolSearch and codebase-memory tools (get_architecture, search_graph, trace_path)
  - Step 5 (file-region conflict detection) has an optional sub-step: if codebase-memory available, use `trace_path` on expected files to detect hidden callers/dependencies not captured in PROGRESS.md file lists. Report as ⚠️ advisory (not blocking).
  - Step 8 (generate dispatch message) uses `search_graph` results (if available) to populate better 🎯 technical hints — e.g. "this file imports X, Y is a caller"
  - Two-tier: try codebase-memory, fallback to existing behavior. Command must still work fully without codebase-memory.
- **Effort**: M
- **ROI**: high — hidden file dependencies are the #1 cause of cross-Worker conflicts that file-region partitioning misses

### M5.2 — review command: use codebase-memory for impact analysis
- [ ] **Expected files**: `plugins/claude-multi-session/commands/multi-session/review.md`
- **Acceptance**:
  - `allowed-tools` frontmatter adds ToolSearch and codebase-memory tools (trace_path, search_graph, get_code_snippet)
  - Step 4 (read the diff) has an optional sub-step: if codebase-memory available, use `trace_path` on changed functions/classes to identify callers outside the milestone scope. Report as "impact radius" advisory in the review output.
  - Step 5 (compare acceptance criteria) can use `get_code_snippet` to read relevant source (not just diff) for more accurate criterion evaluation
  - Two-tier: try codebase-memory, fallback to existing git-diff-only behavior. Command must still work fully without codebase-memory.
- **Effort**: M
- **ROI**: medium — improves review quality by catching unintended side-effects, but Reviewer already reads full diffs manually

## Phase 2 parallelism analysis

- Max independent file-region set: **5** — all milestones touch entirely separate files
- Sequencing constraints: none — all M4.x and M5.x are independent
- Wave plan (3 workers):
  - **Wave 1**: M4.1 + M4.2 + M4.3 (3 workers, 3 template files, all S effort)
  - **Wave 2**: M5.1 + M5.2 (2 workers, 2 command files, M effort; 1 worker idle or dismissed)
- **Recommendation**: 3 workers for Wave 1, 2 workers for Wave 2

## 待用戶決定 / Pending user decision

(None.)

## 設計決策變更紀錄 / Decision changelog

- 2026-05-27: Phase 2 milestones added — codebase-memory integration across workflow (M4.1–M5.2). Driven by ADR-001 §3 gap: codebase-memory was only in audit.md, not in Worker/Reviewer daily workflow.
