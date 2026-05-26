---
skipped: []
in_progress: [M6.1, M6.2, M6.5]
completed: [M1.1, M1.2, M2.1, M2.2, M3.1, M3.2, M3.3, M4.1, M4.2, M4.3, M5.1, M5.2]
---

# PROGRESS

## 現在進度

Phase 2 complete (M4.1–M5.2). Phase 3 doc-consistency fixes: Wave 3a dispatching (M6.1, M6.2, M6.5).

## Audit summary

- **Project**: claude-multi-session — Claude Code plugin providing multi-session parallel coding workflow (Reviewer/Worker roles, dispatch protocol, structured logging) over `claude-peers-mcp`
- **Tech stack**: Pure markdown plugin (no build step), PowerShell + bash launcher scripts, Git as synchronization primitive. Depends on `claude-peers-mcp` (Bun/TypeScript, external).
- **Architecture quick-take**: 9 slash commands under `plugins/claude-multi-session/commands/multi-session/` (init, audit, roll-call, bootstrap, status, upgrade, dispatch, self-check, review), 11 template files in `plugins/claude-multi-session/templates/.claude-multi-session/` (3 roles, 3 messages, 4 log formats, 1 workflow doc), 2 launcher scripts in `plugins/claude-multi-session/scripts/`. No runtime code — logic lives in command prompt files. Root `.claude-multi-session/` is the dogfood copy for this repo's own workflow.
- **Hotspots** (last 30 commits):
  - `PROGRESS.md` (8 commits) — updated by every milestone + reviewer
  - `plugins/.../commands/multi-session/audit.md` (4 commits) — most-iterated command
  - `plugins/.../templates/.claude-multi-session/messages/dispatch.md` (3 commits)
  - `CHANGELOG.md` (3 commits)
  - `plugins/.../templates/.claude-multi-session/workflow.md` (2 commits)
- **現狀**:
  - **Done**: Plugin scaffolding (9 commands), all role/message/log templates, cross-platform launchers, worktree isolation model, ADR-001 in audit.md, QUICKSTART, README, CHANGELOG, root template sync (M1.1), upgrade command (M1.2), validation script + CI (M2.1/M2.2), dispatch/self-check/review helper commands (M3.1-M3.3), codebase-memory integration in templates (M4.1-M4.3)
  - **In progress**: codebase-memory in dispatch + review commands (M5.1-M5.2)
  - **Known gaps**: Documentation cross-consistency issues (dispatch command/template rule mismatch, roll-call.md stale claims, daily.md broken wikilink) — tracked as Phase 3 milestones (M6.x)
- **已知限制**: Documentation accumulated drift from rapid multi-phase development. Phase 3 addresses cross-file consistency.
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
- [x] <!-- sessionA --> 「註」Added two-tier codebase-memory protocol: Setup step 3 loads tools via ToolSearch (silent fallback if unavailable), new responsibility item describes five core tools + fallback logic, new "Common mistakes" entry. Root copy byte-identical to plugin source. **Expected files**: `plugins/claude-multi-session/templates/.claude-multi-session/roles/worker.md`, `.claude-multi-session/roles/worker.md`
- **Acceptance**:
  - worker.md has a new responsibility item describing two-tier codebase-memory usage (try via ToolSearch → fallback to Glob/Grep/Read). NOT three-tier — Workers don't ask user to install, they just fallback silently.
  - Setup section includes a step to load codebase-memory tools via ToolSearch (after reading role files, before waiting for dispatch)
  - "Common mistakes" section includes an entry about using Glob/Grep/Read without first trying codebase-memory
  - Root copy `.claude-multi-session/roles/worker.md` is byte-identical to plugin source (`diff` returns 0)
- **Effort**: S
- **ROI**: high — Workers are the primary code readers; codebase-memory gives them architectural context instead of blind file-by-file grep

### M4.2 — workflow.md: add codebase-memory to roles table and tooling note
- [x] <!-- sessionB --> 「註」Added "Code exploration" column to Roles table (Worker: codebase-memory → Glob/Grep/Read, Reviewer: codebase-memory → git diff, PM: N/A). Added tooling-note paragraph after table explaining ToolSearch loading, silent fallback, and audit.md §4a reference. Root copy byte-identical to plugin source.
- **Expected files**: `plugins/claude-multi-session/templates/.claude-multi-session/workflow.md`, `.claude-multi-session/workflow.md`
- **Acceptance**:
  - "Roles at a glance" table has a new column "Code exploration" showing tool priority per role (Worker: codebase-memory → Glob/Grep/Read, Reviewer: codebase-memory → git diff, PM: N/A)
  - A short paragraph (not a new section) after the table explains the codebase-memory try→fallback pattern and links to audit.md §4a for the full three-tier logic
  - Root copy `.claude-multi-session/workflow.md` is byte-identical to plugin source
- **Effort**: S
- **ROI**: medium — makes the tool priority visible at the workflow overview level so new sessions see it immediately

### M4.3 — dispatch.md (template): add codebase-memory to onboarding pre-block
- [x] <!-- SessionC --> 「註」Added step 6 to first-dispatch onboarding pre-block: load codebase-memory tools via ToolSearch (get_architecture, search_graph, trace_path, search_code, get_code_snippet). Marked optional — Workers fall back to Glob/Grep/Read if unavailable. Kept tone consistent with existing steps (imperative, brief). Root copy byte-identical to plugin source.
- **Expected files**: `plugins/claude-multi-session/templates/.claude-multi-session/messages/dispatch.md`, `.claude-multi-session/messages/dispatch.md`
- **Acceptance**:
  - First-dispatch onboarding pre-block includes a new step (after existing step 5, before "Confirm via send_message"): load codebase-memory tools via ToolSearch — `get_architecture`, `search_graph`, `trace_path`, `search_code`, `get_code_snippet`. If unavailable, note and proceed with Glob/Grep/Read.
  - The step is numbered correctly (existing steps renumbered if needed)
  - Root copy `.claude-multi-session/messages/dispatch.md` is byte-identical to plugin source
- **Effort**: S
- **ROI**: high — every new Worker gets codebase-memory awareness from their very first dispatch, not buried in worker.md prose

### M5.1 — dispatch command: use codebase-memory for dependency analysis
- [x] <!-- sessionA --> 「註」Added codebase-memory two-tier integration: new step 2 (load tools via ToolSearch, flag availability), step 6a (trace_path for hidden dependency detection, advisory only), step 9a (search_graph to enrich technical hints). All steps 2-10 renumbered to 3-11. Frontmatter adds ToolSearch + 3 codebase-memory tools. All codebase-memory steps have silent fallback when unavailable. **Expected files**: `plugins/claude-multi-session/commands/multi-session/dispatch.md`
- **Acceptance**:
  - `allowed-tools` frontmatter adds ToolSearch and codebase-memory tools (get_architecture, search_graph, trace_path)
  - Step 5 (file-region conflict detection) has an optional sub-step: if codebase-memory available, use `trace_path` on expected files to detect hidden callers/dependencies not captured in PROGRESS.md file lists. Report as ⚠️ advisory (not blocking).
  - Step 8 (generate dispatch message) uses `search_graph` results (if available) to populate better 🎯 technical hints — e.g. "this file imports X, Y is a caller"
  - Two-tier: try codebase-memory, fallback to existing behavior. Command must still work fully without codebase-memory.
- **Effort**: M
- **ROI**: high — hidden file dependencies are the #1 cause of cross-Worker conflicts that file-region partitioning misses

### M5.2 — review command: use codebase-memory for impact analysis
- [x] <!-- sessionB --> 「註」Added step 2 (load codebase-memory via ToolSearch, silent fallback). Step 5 (was 4): added impact analysis sub-block using `trace_path` on changed functions, advisory-only. Step 6 (was 5): `get_code_snippet` for deeper criterion evaluation. Steps renumbered 1–10 (was 1–9). `allowed-tools` adds ToolSearch + 3 codebase-memory tools. Two-tier: all steps work fully without codebase-memory.
- **Expected files**: `plugins/claude-multi-session/commands/multi-session/review.md`
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

### M6.1 — daily.md template: fix broken wikilink + stale PROGRESS.md section reference
- [x] <!-- SessionC --> 「註」Two fixes: (1) `[[progress-md-race-condition]]` → `[[progress-md-race]]` to match actual pitfall filename, (2) removed 「卡關紀錄」 from onboarding step 2 — PROGRESS.md has no such section; kept 「現在進度」+「設計決策變更紀錄」 which are the actual sections.
- **Expected files**: `plugins/claude-multi-session/templates/.claude-multi-session/log-templates/daily.md`, `.claude-multi-session/log-templates/daily.md`
- **Acceptance**:
  - `[[progress-md-race-condition]]` replaced with `[[progress-md-race]]` (matching actual pitfall filename `docs/pitfalls/progress-md-race.md`)
  - Onboarding step referencing PROGRESS.md 「卡關紀錄」 removed or updated (PROGRESS.md has no such section; the actual section names are 「現在進度」「設計決策變更紀錄」)
  - Root copy byte-identical to plugin source
- **Effort**: S
- **ROI**: medium — broken wikilinks break Obsidian navigation for future sessions reading handoff packages

### M6.2 — roll-call.md: remove stale "no dispatch command" claim
- [x] <!-- sessionA --> 「註」Rewrote §6 paragraph to acknowledge `/multi-session:dispatch` exists. Changed from "intentionally manual (no command)" to "assisted via /multi-session:dispatch, Reviewer reviews before sending". One sentence replacement, no other changes. **Expected files**: `plugins/claude-multi-session/commands/multi-session/roll-call.md`
- **Acceptance**:
  - The paragraph claiming dispatch is "intentionally manual (no /multi-session:dispatch slash command)" is removed or rewritten to acknowledge the command exists
  - No other functional changes to roll-call.md behavior
- **Effort**: S
- **ROI**: medium — stale claim directly contradicts M3.1's work; confuses Reviewers reading the command

### M6.3 — dispatch command: align rules + onboarding with template
- [ ] **Expected files**: `plugins/claude-multi-session/commands/multi-session/dispatch.md`
- **Acceptance**:
  - Generated dispatch message's rule 6 matches template's rule 6 (acceptance criteria with executable tests → must pass before commit)
  - Generated onboarding pre-block includes all steps from template (including step 6 codebase-memory, matching template's `messages/dispatch.md`)
  - Generated dispatch message includes Auto-pass criteria section (for 🤖-marked milestones, matching template)
  - "rebase main" rule preserved — either as rule 7 or moved to 🔒 section preamble
- **Effort**: M
- **ROI**: high — dispatch command generates messages that don't match the template format, which defeats the purpose of having a template
- **Dependency**: M5.1 must be merged first (SessionA is currently editing this file)

### M6.4 — review command: align post-review steps with template
- [ ] **Expected files**: `plugins/claude-multi-session/commands/multi-session/review.md`
- **Acceptance**:
  - Post-review actions list matches review-pass.md template's "After-pass actions": merge → update review-logs → update atomic log status → update PROGRESS.md → dispatch next (or standby)
  - "send_message the verdict" step is included (command-specific, not in template — that's fine, but ordering should be explicit: send verdict THEN do post-review housekeeping)
- **Effort**: S
- **ROI**: medium — mismatched step lists between command output and template confuse Reviewers following the process
- **Dependency**: M5.2 must be merged first (SessionB is currently editing this file)

### M6.5 — README.md + CHANGELOG.md: fix minor reference errors
- [x] <!-- sessionB --> 「註」README.md: `scripts/` → `plugins/claude-multi-session/scripts/`. CHANGELOG.md: "steps 1-8" → "steps 1-9" (QUICKSTART has §1–§9). Both verified against actual file structure.
- **Expected files**: `README.md`, `CHANGELOG.md`
- **Acceptance**:
  - README.md `scripts/` reference corrected to `plugins/claude-multi-session/scripts/` or made unambiguous
  - CHANGELOG.md "steps 1-8" corrected to match actual QUICKSTART.md section count
- **Effort**: S
- **ROI**: low — cosmetic but misleading for new users reading the README

## Phase 3 parallelism analysis

- Source: documentation cross-audit (2026-05-27)
- Sequencing constraints:
  - M6.3 depends on M5.1 (both touch `commands/multi-session/dispatch.md`)
  - M6.4 depends on M5.2 (both touch `commands/multi-session/review.md`)
  - M6.1, M6.2, M6.5 have no dependencies — can dispatch immediately
- Wave plan (3 workers):
  - **Wave 3a** (now): M6.1 + M6.2 + M6.5 (3 workers, no overlap, all S effort)
  - **Wave 3b** (after M5.1 + M5.2 merge): M6.3 + M6.4 (2 workers, M + S effort)
- **Recommendation**: dispatch Wave 3a immediately to idle workers

## 待用戶決定 / Pending user decision

(None.)

## 設計決策變更紀錄 / Decision changelog

- 2026-05-27: Phase 3 milestones added — documentation cross-consistency fixes (M6.1–M6.5). Source: automated cross-audit of all md files.
- 2026-05-27: Phase 2 milestones added — codebase-memory integration across workflow (M4.1–M5.2). Driven by ADR-001 §3 gap: codebase-memory was only in audit.md, not in Worker/Reviewer daily workflow.
