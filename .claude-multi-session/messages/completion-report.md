# Completion report (Worker → Reviewer)

Copy this block when reporting milestone completion via `send_message`.

```
✅ Mx.y completed → commit <hash>

📦 變更 / Changes (N files):
1. <file 1>: <key change>
2. <file 2>: <key change>
3. PROGRESS.md (Mx.y → [x] + 「註」)
4. docs/session-logs/<date>/sessionN/Mx.y-sessionN.md (atomic log)

🎯 實作要點 / Implementation notes:
- <design decision 1: e.g. "chose Redis cache over in-memory Map because session data must survive process restarts">
- <design decision 2>

✅ 驗收條件對照 / Acceptance criteria:
- 「<criterion 1>」→ <outcome>
- 「<criterion 2>」→ <outcome>

🔍 規則合規 / Rule compliance:
- Build 0 error ✓
- Commit message format ✓ (`Mx.y: ...`)
- Committed to `worker/<id>` branch (not session branch or main) ✓
- Didn't touch <other sessions' regions> ✓
- PROGRESS.md updated ✓
- Atomic log written ✓

🤖 Auto-pass criteria check (if dispatch included):
- [ ] Build 0 error
- [ ] Changed files match dispatched scope exactly
- [ ] Commit message regex match
- [ ] Atomic log written
(If all four ✓: I'll proceed assuming auto-pass; please send fail message if you disagree.)

🔍 踩坑 / Pitfalls hit (if any):
- [[env-var-shadow]] — hit this one; updated the pitfall entry with my workaround.

📝 Daily summary status:
- [ ] session-N.md written (if this is my last milestone — Reviewer will block cleanup until this exists)
- [ ] Not my last milestone — will write at session close

待 review.
```

## Fields explained

- **驗收條件對照**: copy the criteria from the dispatch message verbatim; map each to "達成 (met)" / "部分達成 (partial)" / "未達成 (failed)" + brief reason if partial/failed.
- **規則合規**: explicit checkbox audit. Catching a missed rule yourself is much cheaper than Reviewer catching it.
- **踩坑**: link to `docs/pitfalls/<slug>.md` entries via wikilink. If you created a new pitfall entry, mention "new pitfall entry created" so Reviewer knows.
- **Auto-pass check**: only fill in if the dispatch included auto-pass criteria. Honest reporting; lying here destroys the value of the mechanism.
