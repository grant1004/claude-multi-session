# Atomic log template (one per milestone)

Path: `docs/session-logs/YYYY-MM-DD/sessionN/Mx.y-sessionN.md`

Worker writes this when a milestone is completed (before sending the completion-report). It captures **what was changed**, **why**, and **what pitfalls were hit** — the things a commit message can't carry without becoming a wall of text.

```markdown
---
title: Mx.y — <one-line description>
session: sessionN
milestone: Mx.y
branch: session/<id>
date: YYYY-MM-DD
commit: <hash>
status: review-pending      # in-progress / review-pending / review-pass / review-fail
review: "[[YYYY-MM-DD#Mx.y-sessionN]]"   # anchor into Reviewer master log; filled after pass
daily: "[[session-N]]"                   # back-link to this session's daily summary
---

# Mx.y — <one-line description>

> Commit `<hash>` · sessionN · YYYY-MM-DD

## 📦 變更摘要 / Change summary
- `<file/path>`: <key change>
- `<file/path>`: <key change>
- (only list non-trivial changes; PROGRESS.md tick + boilerplate not needed)

## 🎯 實作要點 / 設計決策 / Implementation notes
1. **<decision title, e.g. "Chose Redis cache over in-memory Map for session storage">**
   - Why: <reason>
   - Alternative considered: <option> — rejected because <reason>

(Numbered list; each decision = one block. Don't bury big decisions in prose.)

## ✅ 驗收條件對照 / Acceptance criteria
- 「<criterion 1>」→ <outcome>
- 「<criterion 2>」→ <outcome>

## 🔍 踩坑 / Pitfalls hit
- [[<pitfall-slug>]] — hit this; (created new entry / updated existing entry / referenced only)

If no pitfalls, write "None for this milestone." Don't omit the section.

## 📐 規則合規 / Rule compliance
- Build 0 error ✓
- Commit message format ✓
- Committed to `session/<id>` branch (not main) ✓
- Didn't touch <other sessions' regions> ✓
- PROGRESS.md `Mx.y [x]` ✓
```

## Frontmatter fields

- `branch`: the Worker's session branch (e.g. `session/sessionA`). Records which branch the commit was made on before Reviewer merged to main.
- `status`: tracks the milestone's review lifecycle. Update to `review-pass` after Reviewer signs off.
- `review`: anchor into Reviewer master log. Format: `[[YYYY-MM-DD#Mx.y-sessionN]]` (Obsidian wikilink with heading anchor). Filled in after review pass.
- `daily`: link back to this session's daily summary. `[[session-N]]` resolves to the sibling `session-N.md`.

## Anti-patterns

- Don't paste the entire `git diff` here; that's what `git show <commit>` is for.
- Don't repeat what `PROGRESS.md` 「註」 column already says.
- Don't write a "weather report" tone ("today I worked on..."). Be terse, structural.
