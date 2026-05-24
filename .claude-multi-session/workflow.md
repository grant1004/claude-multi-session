# Multi-session parallel workflow

This document describes how N Claude Code sessions cooperate on a single repo: one **Reviewer** dispatches work and reviews commits, one or more **Workers** execute milestones in parallel.

Communication channel: [`louislva/claude-peers-mcp`](https://github.com/louislva/claude-peers-mcp) — `list_peers` / `set_summary` / `send_message`.

## Roles at a glance

| Role | Writes code? | Maintains `PROGRESS.md`? | Reads | Writes log |
|---|---|---|---|---|
| Reviewer | No | `## 現在進度` line only | All worker commits | `docs/review-logs/YYYY-MM-DD.md` |
| Worker | Yes (own milestone only) | Own checkbox + 「註」 | Own dispatch + own diff | `docs/session-logs/YYYY-MM-DD/sessionN/Mx.y-sessionN.md` + `session-N.md` |
| Project Manager (4+ workers) | No | No (delegates to Reviewer) | Reviewer's master log | Cross-day summary for user |

Full job descriptions: `roles/reviewer.md`, `roles/worker.md`, `roles/project-manager.md`.

## State machine

```
[Reviewer init]   set_summary "Reviewer, dispatch + review"
                       │
[List peers]       list_peers → find sessionA / sessionB / sessionC ...
                       │
[Onboard]          send_message to each → "read CLAUDE.md + PROGRESS.md → set_summary"
                       │
[Workers ack]      each worker send_message back → ready + lists candidate milestones
                       │
[Dispatch wave 1]  Reviewer cross-checks file-region overlap → parallel dispatch
                   (one milestone each, with explicit "don't touch X/Y/Z" list)
                       │
[Execute]          worker writes code → build 0 error → commit → send_message done
                       │
[Review]           Reviewer reads `git log --stat` + `git diff` → pass / fail
                       │
[Dispatch wave 2]  next milestone for each worker (or hold / standby)
                   ... loop ...
                       │
[Wrap up]          all milestones done → each worker writes session-N.md daily summary
                   Reviewer writes review-logs/YYYY-MM-DD.md + updates PROGRESS.md
```

## File-region partitioning rule

This is the single most important invariant. Every dispatch:

1. Reviewer consults `PROGRESS.md` + `git status` + already-dispatched manifest.
2. Confirms the new milestone's expected files **do not overlap** any other in-flight milestone.
3. Spells out "don't touch X / Y / Z" in the dispatch message.

Workers prefer to **hold over scope-creep**: if they need to touch a file outside their dispatched range, they `send_message` Reviewer first.

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

Race conditions on `PROGRESS.md` are the most common parallel coordination failure. Mitigation:

- **`現在進度 / current` line** — Reviewer-only. Workers do not edit this line.
- **Worker checkbox + 「註」** — each Worker only edits the row(s) for their own milestone. The dispatch message must make ownership clear.
- **Skip-list / Decision changelog** — Reviewer-only.

If you want stronger isolation, use the `.progress/sessionN.md` pattern: each Worker writes only to their own file under `.progress/`, Reviewer merges into `PROGRESS.md` "現在進度" on review pass. Adds latency but zero conflict probability.

## Standard pitfalls (and what to do)

| Pitfall | Mitigation |
|---|---|
| Reviewer dispatches a skipped milestone | Reviewer must check skip-list before every dispatch |
| Race on PROGRESS.md | Reviewer-only edits to shared lines; Worker edits scoped to own rows |
| Worker session crashes mid-milestone | Reviewer re-dispatches with explicit "you are new, previous session died" + full task content |
| Two workers about to modify shared decision-log area | Reviewer broadcasts "X is already editing here" before dispatching the second |
| Reviewer role not understood at session start | Reviewer reads `roles/reviewer.md` and explicitly states role via `set_summary` |
| Message delay (peer message lost or late) | Workers commit before sending; Reviewer fallback via `git log --stat` if message doesn't arrive |
| Reviewer bottleneck (3+ workers) | Bake auto-pass criteria into dispatch (build 0 error + file scope match + commit-message format) — Worker can self-verify before pinging Reviewer |

See `log-templates/pitfall.md` for the structure of permanent pitfall entries.

## Effectiveness baseline (single empirical run, 2026-05-22)

- 3 Worker sessions, 1 Reviewer
- 9 code milestones + 1 user-accepted milestone
- ~1 hour wall time
- 0 git conflicts, 0 reverted commits
- Throughput estimated ~3x single-session

Treat this as one data point, not a guarantee. Effectiveness varies heavily with how well the project's milestones decompose into non-overlapping file regions.
