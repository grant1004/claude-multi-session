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
title: <descriptive title, e.g. "WPF DataTrigger.Value does not bind">
category: <wpf | git | build | progress-md | workflow | language-runtime | ...>
first-seen: YYYY-MM-DD
severity: <low | medium | high>
status: <documented | fix-pending | resolved>
---

# <descriptive title>

## 症狀 / Symptom
<concrete description, with example code or message if applicable>

Example:
```xml
<DataTrigger Binding="{Binding X}" Value="{Binding Y}">
```
→ `Y` is not actually bound; DataTrigger treats `Value` as a literal binding-expression string.

## 根因 / Root cause
<one paragraph: why this happens, not just how to avoid it>

DataTrigger.Value is declared as `object`, and the framework does not invoke the binding pipeline on it — `Value` is meant to be a const compared against the result of `Binding`.

## 修法 / Fix
<concrete approach with code sketch if useful>

Use `IMultiValueConverter` (e.g. `AreEqualConverter`): feed both `X` and `Y` into a `MultiBinding`, output bool, then write `Binding="{MultiBinding ...}" Value="True"` on the DataTrigger.

## 相關規則 / 文件 / Related rules & docs
- [[02-coding-conventions]] §XAML (if relevant)
- [[CLAUDE]] §"WPF-specific patterns" (if relevant)

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
