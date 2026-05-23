# Dispatch message (Reviewer → Worker)

Copy this block into `send_message` to a Worker when assigning a new milestone.

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

🔒 規則提醒 (rules):
- Only do Mx.y; stop and report when done
- Build 0 error required before commit (<build command>)
- Commit message: `Mx.y: <description>`
- Same commit must include `PROGRESS.md` checkbox update (M x.y `[ ] → [x]`) + 「註」 column
- Write atomic log to `docs/session-logs/YYYY-MM-DD/sessionN/Mx.y-sessionN.md`

🤖 Auto-pass criteria (optional, for trivial milestones):
If all of the following hold, you may skip waiting for manual review:
- [ ] Build returns 0 error
- [ ] Changed files match the dispatched scope exactly (`git diff --stat` shows only those files)
- [ ] Commit message matches `^Mx.y: ` regex
- [ ] Atomic log written

If any fail, send normal completion-report and wait for manual review.

開工! Send completion-report when done.
```

## Fields explained

- **🤖 / ✍️**: optional marker. 🤖 = "machinable" (well-spec'd, low judgment); ✍️ = "judgment-heavy" (design decisions involved). Helps the Worker calibrate confidence.
- **預期改動檔案**: tight is better than loose. If you write `src/**/*.ts` you've effectively dispatched nothing.
- **不要動**: must list every file region currently held by other Workers. Reviewer maintains the "in-flight manifest" mentally or in a side file (`.dispatched.md`).
- **Auto-pass criteria**: see `roles/reviewer.md` "Pacing rule". Use sparingly; default to manual review.
