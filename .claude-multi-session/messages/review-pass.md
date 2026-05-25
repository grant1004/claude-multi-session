# Review verdict message (Reviewer → Worker)

Copy this block when returning a review verdict.

## Pass

```
Mx.y ✅ Review pass (commit <hash>).

評語 / Evaluation:
- <bullet: what was good>
- <bullet: any nit / suggestion (non-blocking)>
- <bullet: cross-session observation, e.g. "your FooConverter is now used by sessionB's M6.4 — good reuse">

派下一個 / Next:
**Mz.w** <one-line description>

(below: inline the full dispatch using the dispatch.md template, or write "Standby" / "Hold (reason)")
```

## Fail

```
Mx.y ❌ Review fail (commit <hash>).

問題 / Issues (must fix):
- <bullet: concrete issue, with file:line if possible>
- <bullet: another issue>

建議改法 / Suggested fix:
- <one or two sentences — don't write the code for them>

請修正後重 commit。Same milestone, single new commit on top, then send_message me again.

(Update atomic log frontmatter: status `review-fail` → after fix re-submit, status `review-pending`)
```

## Hold / Standby

```
Mx.y Hold — <reason, e.g. "M8.1 (sessionB) might touch your area, waiting on their commit first">

Standby for now; I'll dispatch again in ~<duration> or when blocker clears.
```

## After-pass actions for the Reviewer

1. **Merge the Worker's branch into main:**
   ```bash
   git checkout main
   git merge --ff-only session/<id>
   ```
   If `--ff-only` fails, ask the Worker to rebase onto main first (`git rebase main`), then re-merge.
2. Update `docs/review-logs/YYYY-MM-DD.md`:
   - Add row to "Review pass 一覽" table (milestone | session | commit | round | atomic log wikilink)
   - Add `## Mx.y-sessionN` heading section with: 「做了什麼 / 如何驗證 / 評語」
3. Update Worker's atomic log status field (or remind Worker to do so).
4. Update `PROGRESS.md` 「現在進度」 line.
5. Dispatch next milestone (or Hold) — same message can chain dispatch into review pass.

## Session-close cleanup (after all milestones done)

```bash
git worktree remove ../worker-<id>
git branch -d session/<id>
```

Use `git worktree list` to audit for leftover worktrees from crashed sessions.

## After-fail actions

1. Update Worker's atomic log frontmatter status → `review-fail` (or remind Worker to).
2. Track round count in review-logs (the Reviewer master log table has a `Round` column).
3. Do not dispatch next milestone until fix lands and passes.
