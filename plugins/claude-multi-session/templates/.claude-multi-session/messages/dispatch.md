# Dispatch message (Reviewer → Worker)

Copy this block into `send_message` to a Worker when assigning a new milestone.

**For the Worker's first dispatch in a session, include the "onboarding pre-block"** so the Worker primes role context before executing. Subsequent dispatches can skip the pre-block.

## First-dispatch pre-block (include only on the worker's first dispatch in this session)

```
👋 First dispatch in this session. Before touching the milestone below, do this onboarding **once**:

0. Verify your worktree: `pwd` should be `../worker-<your-id>`, `git branch --show-current` should show `session/<your-id>`. If either is wrong, stop and tell me.
1. Read .claude-multi-session/roles/worker.md (your job description)
2. Read .claude-multi-session/workflow.md (state machine)
3. Read .claude-multi-session/messages/completion-report.md (the format you'll send back)
4. Read .claude-multi-session/log-templates/atomic.md and .claude-multi-session/log-templates/daily.md (the log artifacts you must produce)
5. set_summary("Worker <your-id> — working on <project basename>")
6. Load codebase-memory tools (optional but recommended): use `ToolSearch` to load `get_architecture`, `search_graph`, `trace_path`, `search_code`, `get_code_snippet`. If unavailable, proceed with Glob/Grep/Read — the tools are helpful but not required.

Your worktree is at ../worker-<your-id>, branch session/<your-id>. All commits go to this branch — never commit directly to main.

Confirm via send_message back: "✅ Onboarded, starting Mx.y" — then start. The dispatch follows.

---
```

## Dispatch block (every dispatch)

```
派工 → sessionN: **Mx.y** <one-line task description> (🤖 / ✍️)

📋 任務範圍 (Task scope):
- <what to build / fix>
- 預期改動檔案 (only touch these):
  - <file path 1>
  - <file path 2>

🎯 技術建議 / Hints (optional):
- <hint 1, e.g. "use the existing FooConverter, don't write a new one">
- <hint 2>

⚠️ 不要動 (don't touch):
- <file / region 1> (sessionM is editing)
- <file / region 2>

🔒 規則提醒 (rules — non-negotiable, all seven required):
1. Only do Mx.y; stop and report when done. No scope creep.
2. Build 0 error required before commit (<build command>).
3. Commit message format: `Mx.y: <description>`.
4. Commits go to `session/<your-id>` branch, not main. Verify with `git branch --show-current` before committing.
5. Same commit must include:
   - `PROGRESS.md` checkbox update (Mx.y `[ ] → [x]`) + 「註」 column with implementation notes
   - **Atomic log file** at `docs/session-logs/YYYY-MM-DD/sessionN/Mx.y-sessionN.md` (use template `.claude-multi-session/log-templates/atomic.md`)
6. Acceptance criteria 含可執行測試（e.g. `npm test`, `curl ...`）→ 測試必須 pass 才能 commit。
7. Before committing: `git rebase main` to ensure your branch is up to date.

If you skip the atomic log or PROGRESS.md update, the review will fail and you'll redo the commit. This is enforced — not optional.

🤖 Auto-pass criteria (optional, for trivial milestones):
If all of the following hold, you may skip waiting for manual review:
- [ ] Build returns 0 error
- [ ] Changed files match the dispatched scope exactly (`git diff --stat` shows only those files)
- [ ] Commit message matches `^Mx.y: ` regex
- [ ] Atomic log written at the path above

If any fail, send normal completion-report and wait for manual review.

開工! Send completion-report when done.
```

## Fields explained

- **🤖 / ✍️**: optional marker. 🤖 = "machinable" (well-spec'd, low judgment); ✍️ = "judgment-heavy" (design decisions involved). Helps the Worker calibrate confidence.
- **預期改動檔案**: tight is better than loose. If you write `src/**/*.ts` you've effectively dispatched nothing.
- **不要動**: must list every file region currently held by other Workers. Reviewer maintains the "in-flight manifest" mentally or in a side file (`.dispatched.md`).
- **Auto-pass criteria**: see `roles/reviewer.md` "Pacing rule". Use sparingly; default to manual review.
