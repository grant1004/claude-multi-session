# Reviewer master log template (one per day)

Path: `docs/review-logs/YYYY-MM-DD.md`

Reviewer maintains this; one heading per milestone (so atomic logs can wikilink-anchor into it: `[[YYYY-MM-DD#Mx.y-sessionN]]`).

```markdown
---
title: YYYY-MM-DD Reviewer Pass Log
date: YYYY-MM-DD
reviewer: <reviewer session id or name>
sessions: [sessionA, sessionB, sessionC]
milestones-passed: [Mx.y, Mx.z, ...]
milestones-accepted-by-user: [Mu.v]
---

# YYYY-MM-DD Reviewer Pass Log

> N workers in parallel: [[session-A]] / [[session-B]] / [[session-C]].
> Today: <X> code milestones + <Y> user-accepted, <Z> git conflicts, <W> revert commits.

## 📋 Review pass 一覽 / Summary table

| Milestone | Session | Commit | Round | Atomic log |
|---|---|---|---|---|
| Mx.y | A | `<hash>` | 1 (✅) | [[Mx.y-sessionA]] |
| Mx.z | A | `<hash>` | 1 (✅) | [[Mx.z-sessionA]] |
| Mp.q | B | `<hash>` | 2 (❌→✅) | [[Mp.q-sessionB]] |
| ... | | | | |

(Round column counts review attempts: `1 (✅)` = passed first try. `2 (❌→✅)` = failed once, fixed, passed second.)

---

## Mx.y-sessionA
**<one-line description>** · commit `<hash>` · ✅ Pass

> Atomic log: [[Mx.y-sessionA]]

### 做了什麼 / What was done
<one paragraph: the substantive change, ignoring boilerplate>

### 如何驗證 / How verified
- `git log --stat <commit>` → changed files match dispatched scope ✓
- `<build command>` → 0 error ✓
- Acceptance criteria 1: <criterion> → met ✓
- Acceptance criteria 2: <criterion> → met ✓

### 評語 / Evaluation
- <constructive bullet, e.g. "DataTrigger + MultiBinding is the clean demo-stage solution">
- <cross-session observation, e.g. "Worker proactively suggested FooConverter to sessionB for M6.4 — cross-session collaboration bonus">
- <nit (non-blocking), e.g. "could rename SelectGroupCommand to TogglerSelectedGroupCommand for clarity">

(Numbered or bulleted. Concrete and specific; "looks good" is not a review.)

---

## Mp.q-sessionB
... (next milestone heading)

---

## 📊 當日狀態 / Day's state

- `PROGRESS.md` 現在進度: M1 ~ M10 全 `[x]`, 剩 M11
- 設計決策變更紀錄 / Decision changelog: sessionA appended "M9 fully revived after defer"
- 卡關紀錄 / Blocker log: (none new today)
- **新增踩坑庫條目 / New pitfall entries added today**: [[wpf-datatrigger-const-value]] (created by sessionA)

## 📌 剩餘 milestone / Remaining

- **M11** (TCP real impl): pending protocol confirmation
- **M12** (deferred until M11 lands)
```

## Why per-milestone headings (vs. flat journal)

- Atomic log frontmatter `review:` field links to `[[YYYY-MM-DD#Mx.y-sessionN]]` — that anchor only resolves if the heading exists. Without the heading, follow-up navigation breaks.
- Heading per milestone forces Reviewer to actually write a substantive review per milestone (vs. one-line "ok all good").
- Easy to search Obsidian by heading when later looking up "what review feedback did Mx.y get?"
