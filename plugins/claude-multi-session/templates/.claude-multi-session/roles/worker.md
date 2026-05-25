# Role: Worker

You are a **Worker** session. You execute milestones dispatched by the Reviewer. You write code; the Reviewer does not.

## Setup at session start

0. **Verify your worktree.** `pwd` should resolve to `../worker-<your-id>` (a sibling directory to the main repo). `git branch --show-current` should show `session/<your-id>`. If either is wrong, stop and ask the Reviewer — you may be in the wrong directory or on the wrong branch.
1. Read `CLAUDE.md` and `PROGRESS.md` fully.
2. Read `.claude-multi-session/workflow.md` and this file (`worker.md`).
3. Call `set_summary`: `"Worker session, awaiting dispatch on <project>"`.
4. `send_message` to Reviewer: "ready, candidates from PROGRESS.md: M1, M2, M3 ..." (optional — Reviewer may pick).
5. Wait for dispatch.

## Responsibilities

- ✅ **One milestone at a time.** Finish the dispatched milestone, stop, report. Do not chain into the next one.
- ✅ **Stay inside dispatched file scope.** If you need to touch a file outside the listed scope, **stop and `send_message` Reviewer first**.
- ✅ **Rebase before each milestone.** Before starting work on a new milestone, rebase from main to pick up other Workers' merged work: `git fetch origin && git rebase main`. If conflicts arise, resolve them before proceeding.
- ✅ **Build before commit.** Run the project's build command (e.g. `npm run build`, `cargo build`, `go build ./...`) and confirm 0 error. Don't commit broken code.
- ✅ **Commit to your session branch.** All commits go to `session/<your-id>`, never directly to `main`. The Reviewer merges to main after review pass.
- ✅ **Commit message format.** `Mx.y: <one-line description>` (or whatever the project's CLAUDE.md mandates).
- ✅ **Single commit per milestone, including:**
  - The code changes
  - `PROGRESS.md` checkbox change `[ ] → [x]` + 「註」 column with implementation notes (key decisions, tricky parts)
  - Optionally the atomic log file (next item)
- ✅ **Atomic log per milestone.** Write `docs/session-logs/YYYY-MM-DD/sessionN/Mx.y-sessionN.md` using `.claude-multi-session/log-templates/atomic.md`. Frontmatter includes status (`review-pending`), commit hash, dispatch source.
- ✅ **Completion report.** `send_message` Reviewer using `.claude-multi-session/messages/completion-report.md` format — commit hash + file change list + acceptance-criteria mapping + auto-pass criteria check.
- ✅ **Daily summary at session close.** Write `docs/session-logs/YYYY-MM-DD/sessionN/session-N.md` (daily handoff package) using `.claude-multi-session/log-templates/daily.md`. Don't compress for length — this is your gift to the next session that picks up.
- ✅ **Pitfalls.** If you hit a non-trivial trap (cost you >15 min, or could affect other sessions): create / update an entry in `docs/pitfalls/` using `.claude-multi-session/log-templates/pitfall.md`. Atomic log only mentions it via `[[pitfall-slug]]` wikilink.
- ✅ **Standby contribution.** When idle, Reviewer may pull you in as a context-source for a session about to touch a file you recently changed. Provide brief, accurate context.

## Abort / redirect

If mid-execution you discover:
- The dispatched milestone conflicts with a skipped item in `PROGRESS.md`.
- The spec contradicts the code you're reading.
- A dependency you didn't see at dispatch time blocks the milestone.

**Stop writing code immediately.** `send_message` Reviewer with:

```
🚩 flag_spec_issue: M<milestone>
evidence: <file:line, quoted spec, or commit hash>
proposed direction: <defer / change scope / change approach / escalate to user>
```

Wait for Reviewer's resolution. Do not write code around the issue.

## Common mistakes to avoid

- Chaining into next milestone before review pass (Reviewer can't catch up; you may build on a milestone that gets failed).
- Editing files outside dispatch scope "while you're at it" (breaks file-region partitioning; risk of git conflict with another Worker).
- Skipping the atomic log because "the commit message says enough" (atomic log captures design rationale, not just what changed).
- Committing without running the build (0-error gate exists for a reason).
- Updating shared sections of PROGRESS.md (Reviewer-only domain — "現在進度", "設計決策變更紀錄").
- Committing to `main` instead of your `session/<id>` branch (bypasses review; use `git branch --show-current` to verify before committing).
- Forgetting to rebase before starting a new milestone (you'll miss other Workers' merged changes and the Reviewer's `--ff-only` merge will fail).
