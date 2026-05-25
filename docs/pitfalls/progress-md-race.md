---
title: PROGRESS.md shared-worktree race condition
category: workflow
first-seen: 2026-05-25
severity: high
status: resolved
---

# PROGRESS.md shared-worktree race condition

## 症狀 / Symptom

Worker A edits `PROGRESS.md` to tick their milestone checkbox (e.g. M5.1 `[ ] → [x]`). Before Worker A commits, Worker B runs `git add` for their own milestone commit (e.g. M3.2). Worker B's commit silently includes Worker A's PROGRESS.md edit — the M5.1 checkbox appears in Worker B's commit diff even though Worker B never touched that line.

No error, no warning. The commit looks clean in `git diff --stat` because PROGRESS.md is an expected changed file for every milestone. The corruption is only visible when inspecting the diff line-by-line.

Observed: uogks3hf's M5.1 completion (commit `1352917`) included PROGRESS.md edits from commit `1575032`'s working tree.

## 根因 / Root cause

All worker sessions share one working directory and one git branch (`main`). `git add <file>` stages the current on-disk state of a tracked file — it has no concept of "which session modified this line." When multiple workers edit the same tracked file (`PROGRESS.md`) in the same working tree, any `git add` that includes that file picks up **all** pending modifications, not just the current worker's.

This is not a bug in git — it's a fundamental property of a shared working tree. The multi-session workflow's "each worker only edits their own milestone row" convention provides **logical** isolation but not **physical** isolation. Git operates at the file level, not the line level, during staging.

## 修法 / Fix

Each worker gets their own git worktree on a dedicated branch (`session/<id>`). The Reviewer merges completed branches into `main` after review pass.

```
git worktree add .worktrees/sessionA -b session/sessionA
git worktree add .worktrees/sessionB -b session/sessionB
```

With separate worktrees:
- Worker A's `git add PROGRESS.md` only sees Worker A's edits (different filesystem directory)
- Worker B's `git add PROGRESS.md` only sees Worker B's edits
- Merge conflicts surface at merge time (Reviewer's job), not silently at commit time

Implementation: M6.2 (workflow.md + role docs), M6.3 (launcher scripts), M6.4 (init command).

## 相關規則 / 文件 / Related rules & docs
- [[workflow]] §"File-region partitioning rule" — the logical isolation that this pitfall proves insufficient
- [[workflow]] §"PROGRESS.md write strategy" — the race condition mitigation that failed under concurrent edits
- [[worker]] §"Stay inside dispatched file scope" — workers followed this rule correctly; the issue is physical, not procedural

## 出現紀錄 / Occurrence record

(Obsidian auto-populates this section via backlinks.)
