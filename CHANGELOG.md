# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `/multi-session:upgrade` command — diff live `.claude-multi-session/` against plugin source, apply updates with user confirmation (apply all / review each / cancel)
- `/multi-session:dispatch` command — Reviewer dispatch helper with automatic file-region conflict detection, "don't touch" list auto-generation, first-dispatch heuristic, and pre-filled dispatch message output
- `/multi-session:self-check` command — Worker pre-commit validation of auto-pass criteria (file scope, commit message format, PROGRESS.md checkbox, atomic log existence) with pre/post-commit auto-detection
- `/multi-session:review` command — Reviewer review helper: reads git diff, compares per-criterion against acceptance criteria with evidence linking, generates review verdict message, optional `git merge --ff-only` on pass
- `tests/validate-templates.sh` — template structure validation script (6 checks, 27 assertions): command frontmatter, init.md copy-list, WPF regression guard, role headings, message code blocks, log-template frontmatter
- `.github/workflows/validate.yml` — CI workflow running template validation + root-vs-source drift guard on push to main and PRs

### Changed

- Synced root `.claude-multi-session/` templates to match v0.2.0 plugin source (10 files updated, resolving v0.1.0 drift)

## [0.2.0] - 2026-05-26

### Added

- Git worktree + per-worker branch isolation model — each Worker gets a dedicated worktree (`../worker-<id>` path, `session/<id>` branch), Reviewer merges via `--ff-only` after review pass (prevents PROGRESS.md race condition, see `docs/pitfalls/progress-md-race.md`)
- `/multi-session:status` slash command — read-only dashboard showing current phase, milestone table with status icons, and counts
- `docs/pitfalls/progress-md-race.md` — pitfall entry documenting the shared-worktree race condition discovered during Wave 1–2
- ADR-001 (`docs/adr/001-audit-redesign.md`) — audit redesign decision record: grill phase, codebase-memory MCP three-tier integration, catchup vs new-project auto-mode, embedded test specs

### Changed

- **BREAKING**: Workflow now requires per-worker git worktrees. Projects scaffolded with v0.1.0 must opt in by switching to the new dispatch flow (Reviewer creates worktree + branch before first dispatch to each Worker).
- Updated `workflow.md` state machine with worktree lifecycle: create worktree+branch at dispatch, execute on worker branch, merge to main on review pass, cleanup on session close
- Updated `reviewer.md` and `worker.md` role definitions for worktree setup, branch-based commits, and rebase-before-milestone flow
- Updated `dispatch.md` and `review-pass.md` message templates for per-worker branch workflow
- Updated `atomic.md` log template with `branch:` frontmatter field and branch-based compliance check
- Redesigned `/multi-session:audit` per ADR-001: mandatory grill phase via AskUserQuestion (5 user-intent questions), automatic catchup-vs-new-project mode detection from git history, codebase-memory MCP integration (try → ask → fallback), test spec embedded directly in acceptance criteria

### Fixed

- Aligned worktree path convention in `docs/pitfalls/progress-md-race.md` example with `reviewer.md` / `dispatch.md` (`../worker-<id>` instead of `.worktrees/<id>`)

## [0.1.0] - 2026-05-25

### Added

- Initial plugin scaffolding: manifest, MIT license, README, `/multi-session:init` command
- Role definitions (Reviewer, Worker, Project Manager), message templates (dispatch, completion-report, review-pass), log templates (atomic, daily, reviewer-master, pitfall), and workflow state machine
- QUICKSTART.md — zero-baseline Windows setup guide (steps 1-8)
- `claude-peers.ps1` PowerShell launcher script with `-id` flag and env var passthrough
- `.claude-plugin/marketplace.json` for `/plugin marketplace add` resolution
- `/multi-session:audit` and `/multi-session:roll-call` slash commands
- `/multi-session:bootstrap` command with onboarding pre-check on audit/roll-call
- `docs/.obsidian/` directory so `docs/` opens as an Obsidian vault out of the box
- Mandatory git pre-check on `/multi-session:init` with offer to run `git init` when missing
- `.gitignore` covering OS files, Obsidian workspace state, `node_modules/`, and editor configs
- `claude-peers` bash/zsh launcher script for macOS/Linux (mirrors PowerShell launcher behavior)

### Changed

- Restructured plugin from repo root into `plugins/claude-multi-session/` subdirectory
- Baked onboarding flow into audit and dispatch commands (per user feedback — removed separate bootstrap requirement)
- Replaced WPF-specific examples in all templates with framework-agnostic ones (env-var-shadow, Redis cache, REST API patterns)
- Scaffolded multi-session workflow documentation and PROGRESS.md audit structure

### Fixed

- Dropped redundant `[Alias('id')]` in PowerShell launcher that conflicted with case-insensitive parameter matching
- Switched marketplace manifest source from string path to `git-subdir` object form (required by plugin resolver)
- Made git context commands in audit tolerate empty or non-git repositories without erroring
