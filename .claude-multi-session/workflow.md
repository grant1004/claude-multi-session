# Multi-session parallel workflow

This document describes how N Claude Code sessions cooperate on a single repo: one **Reviewer** dispatches work and reviews commits, one or more **Workers** execute milestones in parallel.

Communication channel: [`louislva/claude-peers-mcp`](https://github.com/louislva/claude-peers-mcp) — `list_peers` / `set_summary` / `send_message`.

## Branch model

```
main ─────────────────────────────────────────────── ● (--no-ff merge)
  │                                                  ↑
  └─ session/<YYYY-MM-DD>-<slug> ──●──●──●──●───────┘
       │         │         │
       ├─ worker/A ──●──●  │
       │  (--ff-only) ↑    │
       ├─ worker/B ──●─────┘
       │  (--ff-only) ↑
       └─ worker/C ──●
          (--ff-only) ↑
```

- **`main`**: untouched during the entire multi-session run. No direct commits.
- **`session/<YYYY-MM-DD>-<slug>`**: created by the Reviewer (via audit) from `main`. All Worker milestones accumulate here via `--ff-only` merges. Merged back to `main` with `--no-ff` when the session concludes.
- **`worker/<id>`**: one per Worker, branched from the session branch. Workers commit here; Reviewer merges to session branch after review pass.

## Roles at a glance

| Role | Writes code? | Maintains `PROGRESS.md`? | Reads | Writes log | Code exploration |
|---|---|---|---|---|---|
| Reviewer | No | `## 現在進度` line only | All worker commits | `docs/review-logs/YYYY-MM-DD.md` | codebase-memory → `git diff` |
| Worker | Yes (own milestone only) | Own checkbox + 「註」 | Own dispatch + own diff | `docs/session-logs/YYYY-MM-DD/sessionN/Mx.y-sessionN.md` + `session-N.md` | codebase-memory → Glob/Grep/Read |
| Project Manager (4+ workers) | No | No (delegates to Reviewer) | Reviewer's master log | Cross-day summary for user | N/A |

Full job descriptions: `roles/reviewer.md`, `roles/worker.md`, `roles/project-manager.md`.

**Tooling note:** codebase-memory MCP (`search_graph`, `trace_path`, `get_code_snippet`, etc.) is the preferred first tool for understanding code structure — use `ToolSearch` to load its schema at session start. If the MCP server is not available, fall back silently to Glob/Grep/Read (Workers) or `git diff`/`git log` (Reviewer). The full three-tier install-or-fallback logic lives in `audit.md` §4a; roles other than audit never ask the user to install.

## State machine

```
[Reviewer init]       set_summary "Reviewer, dispatch + review"
                           │
[Create session branch] git checkout -b session/<YYYY-MM-DD>-<slug> main
                        (one session branch per multi-session run; created by audit)
                           │
[List peers]           list_peers → find sessionA / sessionB / sessionC ...
                           │
[Create worktrees]     git worktree add ../worker-<id> -b worker/<id> session/<slug>
                       (one worktree + branch per Worker, branched from session)
                           │
[Onboard]              send_message to each → "read CLAUDE.md + PROGRESS.md → set_summary"
                       (include worktree path in first message)
                           │
[Workers ack]          each worker send_message back → ready + lists candidate milestones
                       (worker verifies: pwd = ../worker-<id>, branch = worker/<id>)
                           │
[Dispatch wave 1]      Reviewer cross-checks file-region overlap → parallel dispatch
                       (one milestone each, with explicit "don't touch X/Y/Z" list)
                           │
[Execute]              worker writes code in own worktree → build 0 error
                       → commit to worker/<id> branch → send_message done
                           │
[Review]               Reviewer reads `git log session/<slug>..worker/<id> --stat` + `git diff`
                       → pass: git checkout session/<slug> && git merge --ff-only worker/<id>
                       → fail: send_message with fail reason, worker fixes on same branch
                           │
[Pre-next rebase]      worker runs `git rebase session/<slug>` to pick up merged work
                           │
[Dispatch wave 2]      next milestone for each worker (or hold / standby)
                       ... loop ...
                           │
[Wrap up]              all milestones done → Reviewer sends "write daily summary" to each Worker
                       Reviewer writes review-logs/YYYY-MM-DD.md + updates PROGRESS.md
                           │
[Verify logs]          Reviewer checks: does session-N.md exist for each Worker?
                       → yes: proceed to cleanup
                       → no: send_message Worker "missing daily summary, write it before I close your session"
                       (GATE: do NOT proceed to cleanup until all daily summaries exist)
                           │
[Cleanup]              git worktree remove ../worker-<id> && git branch -d worker/<id>
                       (Reviewer runs for each Worker after session close)
                           │
[Finalize]             git checkout main && git merge --no-ff session/<slug>
                       (user confirms — creates merge commit preserving session history)
                       git branch -d session/<slug>
```

## File-region partitioning rule

This is the single most important invariant. Every dispatch:

1. Reviewer consults `PROGRESS.md` + `git status` + already-dispatched manifest.
2. Confirms the new milestone's expected files **do not overlap** any other in-flight milestone.
3. Spells out "don't touch X / Y / Z" in the dispatch message.

Workers prefer to **hold over scope-creep**: if they need to touch a file outside their dispatched range, they `send_message` Reviewer first.

## Worktree lifecycle

Each Worker operates in an isolated git worktree on a dedicated branch. This eliminates the shared-working-tree race condition (see [[progress-md-race]]) and lets Workers commit freely without interfering with each other.

### Setup (Reviewer, before first dispatch)

```bash
# 1. Create the session branch (once per multi-session run)
git checkout -b session/<YYYY-MM-DD>-<slug> main

# 2. Create one worktree + worker branch per Worker
git worktree add ../worker-<id> -b worker/<id> session/<slug>
```

This creates:
- A session branch `session/<YYYY-MM-DD>-<slug>` from `main` (all milestones accumulate here)
- A worktree directory at `../worker-<id>` (sibling to the main repo)
- A worker branch `worker/<id>` branched from the session branch

The Reviewer includes the worktree path in the first dispatch message so the Worker knows where to `cd`.

### Execution (Worker, per milestone)

1. **Pre-milestone rebase:** `git rebase session/<slug>` — pick up other Workers' merged work from the session branch before starting.
2. **Work + commit:** Write code, build, commit to `worker/<id>`. Commits never go directly to the session branch or `main`.
3. **Completion report:** `send_message` Reviewer with commit hash.

### Review + merge (Reviewer, per milestone)

```bash
git checkout session/<slug>
git merge --ff-only worker/<id>
```

`--ff-only` enforces linear history on the session branch — if the merge cannot fast-forward (Worker forgot to rebase), it fails loudly rather than creating a merge commit. Reviewer asks Worker to rebase and re-report.

### Cleanup (Reviewer, after session close)

```bash
git worktree remove ../worker-<id>
git branch -d worker/<id>
```

Use `git worktree list` to audit for leftover worktrees from crashed sessions. Worker branches are deleted after cleanup; the session branch remains until finalize.

### Finalize (Reviewer, after all milestones)

```bash
git checkout main
git merge --no-ff session/<slug>
git branch -d session/<slug>
```

`--no-ff` creates a merge commit that preserves the session's commit history as a group. The user must confirm before this step — it is the only point where `main` is modified during the entire multi-session workflow.

After finalize, the session branch is deleted. All milestone commits are reachable from `main` via the merge commit.

## Design-decision skip-list

`PROGRESS.md` MUST contain a machine-readable skipped-milestones list (YAML frontmatter or a fenced block):

```yaml
skipped:
  - M9.2  # 2026-05-14 user decided to defer, see <log link>
  - M9.3
```

**Reviewer dispatches → check the skip list first.** Don't rely on Worker catching a "wait, isn't this skipped?" moment.

If a skipped item needs to be un-skipped: Reviewer asks user → user confirms → Reviewer updates skip-list and writes an entry in `PROGRESS.md` "設計決策變更紀錄 / Decision changelog" section before dispatching.

## Abort / redirect protocol

If a Worker discovers mid-execution that the spec is wrong, the dispatch was a mistake, or a hidden dependency blocks the milestone:

1. Worker **stops writing code immediately**.
2. Worker sends `send_message` with structured flag:
   ```
   🚩 flag_spec_issue: M<milestone>
   evidence: <file path + line, commit hash, or quoted spec text>
   proposed direction: <one of: defer / change scope / change approach / escalate to user>
   ```
3. Reviewer **must process this flag before dispatching any new work** (to anyone).
4. Resolution either reaches the user (for design decisions) or stays at Reviewer level (for scope adjustment).

## PROGRESS.md write strategy

With worktree isolation, each Worker edits `PROGRESS.md` in their own worktree — no more shared-working-tree race conditions (see [[progress-md-race]]). However, write-ownership rules remain as defense-in-depth:

- **`現在進度 / current` line** — Reviewer-only. Workers do not edit this line.
- **Worker checkbox + 「註」** — each Worker only edits the row(s) for their own milestone. The dispatch message must make ownership clear.
- **Skip-list / Decision changelog** — Reviewer-only.

The Reviewer's `git merge --ff-only` integrates each Worker's `PROGRESS.md` edits into the session branch one at a time, so conflicts surface at merge time (fixable) rather than silently corrupting data.

## Standard pitfalls (and what to do)

| Pitfall | Mitigation |
|---|---|
| Reviewer dispatches a skipped milestone | Reviewer must check skip-list before every dispatch |
| Race on PROGRESS.md | Structurally eliminated by worktree isolation; see [[progress-md-race]]. Write-ownership rules retained as defense-in-depth |
| Worker session crashes mid-milestone | Reviewer re-dispatches with explicit "you are new, previous session died" + full task content |
| Two workers about to modify shared decision-log area | Reviewer broadcasts "X is already editing here" before dispatching the second |
| Reviewer role not understood at session start | Reviewer reads `roles/reviewer.md` and explicitly states role via `set_summary` |
| Message delay (peer message lost or late) | Workers commit before sending; Reviewer fallback via `git log --stat` if message doesn't arrive |
| Reviewer bottleneck (3+ workers) | Bake auto-pass criteria into dispatch (build 0 error + file scope match + commit-message format) — Worker can self-verify before pinging Reviewer |
| Worker rebases from main instead of session branch | Worker must rebase from `session/<slug>`, not `main`. `main` is untouched until finalize |
| Finalize without user confirmation | `--no-ff` merge to main requires explicit user confirmation — never auto-merge |

See `log-templates/pitfall.md` for the structure of permanent pitfall entries.

## Effectiveness baseline (single empirical run, 2026-05-22)

- 3 Worker sessions, 1 Reviewer
- 9 code milestones + 1 user-accepted milestone
- ~1 hour wall time
- 0 git conflicts, 0 reverted commits
- Throughput estimated ~3x single-session

Treat this as one data point, not a guarantee. Effectiveness varies heavily with how well the project's milestones decompose into non-overlapping file regions.
