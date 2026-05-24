# Daily summary template (one per Worker per day)

Path: `docs/session-logs/YYYY-MM-DD/sessionN/session-N.md`

This is a **handoff package**: the next session (this same Worker resurrected, or a different Worker picking up this area) reads only this file to get into the state of play, then drills into atomic logs as needed.

**Length policy:** unbounded. Density > brevity. If a daily summary is under 50 lines, you probably did not capture enough state.

```markdown
---
title: SessionN — YYYY-MM-DD work summary
session: sessionN
date: YYYY-MM-DD
milestones: [Mx.y, Mx.z, ...]
status: closed                       # in-progress / closed
handoff-to: sessionN-next            # or "any-worker", or specific session id
---

# SessionN — YYYY-MM-DD work summary

> **Handoff package.** Read this to enter the project state with minimum onboarding cost.
> Milestone details: see individual atomic logs. Project-wide rules: see `CLAUDE.md` / `PROGRESS.md` / `docs/pitfalls/`.

## 🚀 接手 onboarding 流程 (in order)

1. Read `CLAUDE.md` (architecture, commit rules, absolute prohibitions)
2. Read `PROGRESS.md` 「現在進度」 + 「設計決策變更紀錄」 + 「卡關紀錄」
3. Read **this file** §「絕對不能動」 + 「熱檔狀態」 + 「未完成 / 範圍外」
4. Read task-relevant `docs/0X-*.md` architecture docs as needed
5. Get a dispatch from Reviewer before writing any code

## 📑 今日 milestone 索引 / Today's milestones

- [[Mx.y-sessionN]] — <description> (`<commit hash>`)
- [[Mx.z-sessionN]] — <description> (`<commit hash>`)

## ⛔ 絕對不能動 / Absolute don't-touch (discovered this session)

- **<file or rule>** — <reason, e.g. "Domain layer must not import HTTP framework types, design decision 2026-05-14">
- **<file or pattern>** — <reason>

> If you need to break any of these: `send_message` Reviewer first, evaluate whether to promote the rule into `CLAUDE.md` or `pitfalls/`.

## ✅ 一定要做 / Must-do (environment preparation accumulated this session)

- Before editing `<hot file>`: `git log -p <file> | head -200` to see recent change context
- Before adding a new helper module: check existing shared utilities for already-registered ones (don't duplicate)
- Before editing `PROGRESS.md`: `git diff HEAD -- PROGRESS.md` to confirm no other session is mid-edit (race condition seen → [[progress-md-race-condition]])

(Project-specific. Add anything you learned the hard way this session.)

## 🔥 熱檔 / Hot files & sub-products status

### `<hot file path>`
- **State now:** <key state, e.g. "6 API endpoints defined: list, get, create, update, delete, search">
- **Pattern asymmetry:** <e.g. "list endpoint supports pagination; search endpoint returns all results without limit">
- **Performance note:** <e.g. "search endpoint does full table scan; acceptable under 10k rows, add index or switch to Elasticsearch above that">
- **Upgrade path (in code comment):** <if any>

### `<new sub-product introduced this session>` — sub-product
- **Registered at:** <e.g. `src/utils/index.ts`: `export { formatCurrency } from './formatCurrency'`>
- **Used by:** [[Mx.y-sessionN]], [[Mx.z-sessionM]]
- **Don't recreate.**

## 🌊 工作流程觀察 / Workflow observations (cross-milestone)

1. <observation 1, e.g. "Reviewer's explicit don't-touch list was the single biggest reason 0 conflicts happened">
2. <observation 2, e.g. "Standby + Reviewer-relayed context was faster than re-discovery">
3. <observation 3>

## 🚫 未完成 / 範圍外 / Out of scope

- **<milestone or feature>**: <reason — e.g. "M11 (TCP real impl): pending protocol confirmation, all sessions hold">
- **<deferred quality concern>**: 
  - <item 1, e.g. "M9.2 search query has no result limit → add pagination when row count grows past 10k">
  - <item 2>
```

## Why this template is long

A daily summary is read by a session that has **zero context** about today's work. Short summaries optimize for the author's keystroke count and shift cost onto the reader, who is much more expensive (a Claude Code session burning tokens to re-explore). Write long, write structured, write specific.
