# Pitfall entry template (cross-session permanent knowledge base)

Path: `docs/pitfalls/<slug>.md`

A pitfall entry captures **a trap that more than one session could fall into**, with the remedy worked out. Slug must be unique vault-wide (so atomic logs can `[[<slug>]]` without ambiguity).

## When to create a pitfall entry

- Multiple Workers (or Worker-then-Reviewer) hit the same trap.
- A trap cost a single Worker > 15 min of debugging.
- Reviewer spots a near-miss and predicts other Workers will hit it too.

If a trap is genuinely one-time (specific to a single milestone, unlikely to recur), keep it in that milestone's atomic log only.

## Template

```markdown
---
title: <descriptive title, e.g. "Environment variable silently ignored when .env file shadows it">
category: <git | build | progress-md | workflow | language-runtime | config | api | ...>
first-seen: YYYY-MM-DD
severity: <low | medium | high>
status: <documented | fix-pending | resolved>
---

# <descriptive title>

## 症狀 / Symptom
<concrete description, with example code or message if applicable>

Example:
```bash
# .env file (committed to repo)
DATABASE_URL=postgres://localhost/myapp_dev

# shell (set before launch)
export DATABASE_URL=postgres://prod-host/myapp_prod
```
→ App reads `postgres://localhost/myapp_dev` because the `.env` loader runs after shell env is already set, overwriting the intended production value.

## 根因 / Root cause
<one paragraph: why this happens, not just how to avoid it>

The `.env` loading library (e.g. `dotenv`) defaults to **overwrite** mode. When `.env` is committed with dev defaults, it silently replaces any value already set in the shell environment — the opposite of what most developers expect.

## 修法 / Fix
<concrete approach with code sketch if useful>

Configure the `.env` loader to skip variables already present in the environment (e.g. `dotenv` with `override: false`, or `python-dotenv` default behavior). Alternatively, remove `.env` from version control and use `.env.example` as the template.

## 相關規則 / 文件 / Related rules & docs
- [[02-coding-conventions]] §environment-config (if relevant)
- [[CLAUDE]] §"deployment patterns" (if relevant)

## 出現紀錄 / Occurrence record

(Obsidian auto-populates this section via backlinks. **Do not hand-edit.** Whenever another file links `[[<slug>]]`, it appears here automatically.)
```

## Status field workflow

- `documented` — pitfall written but the underlying issue has not been fixed (can't be fixed, or fix is out of scope).
- `fix-pending` — fix is queued but not yet committed.
- `resolved` — fix has landed; entry retained as a historical record so future workers see the previous pitfall and the resolution.

## Promotion mechanism

Reviewer scans atomic logs during review. If a Worker mentions a trap but doesn't promote it to `docs/pitfalls/`, Reviewer suggests promotion in the review verdict:

> "M3.2 §踩坑 mentions <X>; this will affect anyone touching <Y>. Please promote to `docs/pitfalls/<slug>.md` and link from this atomic log on next pass."

The Worker can do this in their next commit (or the same commit if review is fail/redo).

## What is NOT a pitfall

- "I had to read the docs for 5 minutes" — that's normal, not a pitfall.
- "The compiler error message was unclear at first" — atomic log it, don't escalate.
- "I made a typo and it took me a minute to find" — your problem, not the project's.

A pitfall is something **structurally surprising** about the codebase, framework, or workflow — something a smart person could reasonably do wrong without knowing the trap.
