---
allowed-tools: Read, Bash(git:*), AskUserQuestion, mcp__claude-peers__list_peers, ToolSearch, mcp__codebase-memory-mcp__search_graph, mcp__codebase-memory-mcp__trace_path, mcp__codebase-memory-mcp__get_architecture
description: Reviewer dispatch helper — generates a pre-filled dispatch message with automatic file-region conflict detection
---

## Context

- Project root: !`pwd`
- `PROGRESS.md` exists: !`test -f PROGRESS.md && echo "yes" || echo "no (run /multi-session:audit first)"`
- Worktree list: !`git worktree list 2>/dev/null || echo "(not a git repo)"`

## Your task

You are the **Reviewer** preparing a dispatch message for a Worker. This command automates the tedious parts — parsing milestones, detecting file-region conflicts, building the "don't touch" list — and outputs a ready-to-review dispatch message. You still review, edit, and `send_message` it yourself.

**This command does NOT send the message.** It generates output you copy into `send_message`.

### 1. Pre-flight checks

- If `PROGRESS.md` doesn't exist, tell the user to run `/multi-session:audit` first. Stop.
- Read `PROGRESS.md` in full before proceeding.

### 2. Load codebase-memory tools (two-tier)

Try to load codebase-memory tools via `ToolSearch`:
- `mcp__codebase-memory-mcp__get_architecture`
- `mcp__codebase-memory-mcp__search_graph`
- `mcp__codebase-memory-mcp__trace_path`

If ToolSearch returns the tools successfully, set `codebase_memory_available = true` for later steps. If ToolSearch returns nothing or the tools error on first use, set `codebase_memory_available = false` and proceed — all subsequent steps that use codebase-memory have fallback behavior.

### 3. Parse PROGRESS.md

Extract from **YAML frontmatter**:
- `skipped:` — milestones excluded from dispatch
- `in_progress:` — milestones currently being worked on (their file regions are "held")
- `completed:` — already done

Extract from **milestone sections** (each `### Mx.y` heading):
- ID and description (from the heading)
- Checkbox state: `[x]` = completed, `[ ]` = remaining
- **Expected files**: the file list under `- **Expected files**:`
- **Effort**: S / M / L
- Sequencing notes: check the `## Parallelism analysis` section for dependencies (e.g. "M1.2 depends on M1.1")

Build two lists:

| List | Criteria |
|---|---|
| **Dispatchable** | Unchecked `[ ]`, not in `skipped:`, not in `in_progress:` |
| **In-flight** | Listed in `in_progress:` — extract their expected file sets (these regions are "held") |

**Edge cases:**
- If a milestone is `[x]` but NOT in `completed:` frontmatter, flag the inconsistency but treat it as completed (checkbox wins).
- If a milestone is in `in_progress:` but also `[x]`, flag this — someone forgot to move it to `completed:`.
- If no dispatchable milestones remain, report "all milestones dispatched or completed" and stop.
- If a dependency is unmet (e.g. M1.2 depends on M1.1 which is not yet completed), still show it as dispatchable but add a ⚠️ warning.

### 4. Discover workers

Call `list_peers` (scope: `machine`). From the results:
- Exclude yourself (peer ID `reviewer` or matching your own ID)
- For each remaining peer, note: peer ID, current summary, working directory

If 0 peers found: tell the user no workers are visible. Suggest they launch workers with `claude-peers -id sessionA` etc. Stop.

### 5. Reviewer chooses milestone + worker

Use `AskUserQuestion` with **2 questions in a single call**:

**Question 1 — "Which milestone to dispatch?"**
- Options: up to 4 dispatchable milestones, ordered by priority:
  1. Milestones whose dependencies are all met (ready now)
  2. S-effort before M-effort before L-effort
  3. Higher ROI first
- Each option label: `Mx.y — <short description>` (truncate description to fit)
- Each option description: `Effort: <S/M/L> · Files: <file count> · <dependency note if any>`
- If >4 dispatchable milestones, show the top 4 and let user type "Other" for the rest

**Question 2 — "Which worker?"**
- Options: visible peers (up to 4)
- Each option label: peer ID (e.g. `sessionA`)
- Each option description: current summary text from `list_peers`

### 6. File-region conflict detection

Compare the chosen milestone's expected files against **all in-flight milestones'** file sets:

- **No overlap** → clean dispatch. Proceed silently.
- **Overlap detected** → print a warning block:
  ```
  ⚠️ File-region conflict detected:
    Mx.y expects: <file>
    My.z (in-flight, sessionN) holds: <same file>
  ```
  Then ask via `AskUserQuestion`: "Proceed despite overlap? The generated dispatch will include a warning." Options: "Yes, proceed" / "No, pick a different milestone" (if "No", loop back to step 5).

#### 6a. Hidden dependency detection (codebase-memory, optional)

If `codebase_memory_available`:

For each file in the milestone's expected files list, call `trace_path(function_name=<file>, mode="calls")` to discover callers and importers outside the milestone's scope. Compare these against in-flight milestones' file sets.

If hidden dependencies are found (a file not in the milestone's expected list imports or calls into a file that IS in scope, and that external file is held by another in-flight milestone):

```
⚠️ Hidden dependency detected (via codebase-memory):
  <external_file> (held by My.z, sessionN) imports/calls into <scoped_file> (Mx.y scope)
  This won't cause a git conflict, but changes to <scoped_file> may affect <external_file>'s behavior.
```

Report as **advisory only** (⚠️, not blocking). The Reviewer decides whether to adjust scope or proceed.

If `codebase_memory_available = false`: skip this sub-step silently. The explicit file-region check in step 6 still runs.

### 7. Build the "don't touch" list

Aggregate expected files from **all in-flight milestones** (those in `in_progress:`). Group by session if the `<!-- sessionId -->` comment is present in PROGRESS.md:

```
⚠️ 不要動 (don't touch):
- `<file>` (sessionA is editing — Mx.y)
- `<file>` (sessionB is editing — My.z)
```

If no milestones are in-flight, the "don't touch" section should say:

```
⚠️ 不要動 (don't touch):
- (no other milestones in-flight — but still don't touch files outside your scope)
```

Additionally, scan the dispatch hints for this milestone in PROGRESS.md — if the `## Parallelism analysis` section mentions specific files to avoid, include those too.

### 8. Detect first-dispatch + worktree info

**First-dispatch detection** — a worker needs the onboarding pre-block on their first dispatch in a session. Heuristics:
- Worker's summary contains "awaiting dispatch" or "standing by" → likely first dispatch
- Worker's summary contains "working on" or mentions a milestone ID → likely subsequent dispatch

Ask the Reviewer: "Include first-dispatch onboarding pre-block?" with `AskUserQuestion`:
- Options: "Yes — first dispatch for this worker" (include heuristic result) / "No — worker already onboarded"
- Default the first option to match the heuristic

**Worktree info** — derive from git worktree list or from naming convention:
- Worker worktree path: `../worker-<sessionId>` (relative to project root), or use absolute path from `git worktree list` if available
- Worker branch: `session/<sessionId>`

If the worktree for this worker is not visible in `git worktree list`, note this in the generated message — the Reviewer may need to create it first:
```
⚠️ Worktree for <sessionId> not found. Create it before sending:
  git worktree add ../worker-<sessionId> -b session/<sessionId>
```

### 9. Generate the dispatch message

Build a complete dispatch message following the format in `.claude-multi-session/messages/dispatch.md`. Output it as a **fenced code block** the Reviewer can copy.

#### 9a. Enrich technical hints with codebase-memory (optional)

If `codebase_memory_available`:

Before generating the `🎯 技術建議 / Hints` section, call `search_graph` on the milestone's expected files to discover:
- What modules/functions each file imports or exports
- Known callers of functions defined in the expected files
- Architectural role of the file (e.g. "this is a command file", "this is a template consumed by init.md")

Weave these findings into the hints section as concrete, actionable context — e.g.:
- "This file imports `X` from `Y` — read `Y` first for context"
- "`functionZ` in this file is called by `A`, `B`, `C` — changes may affect those callers"
- "This module sits in the `commands/` layer — it should only use tools listed in its `allowed-tools` frontmatter"

If `codebase_memory_available = false`: generate hints from PROGRESS.md content only (existing behavior). The hints section still exists — it just won't have graph-derived context.

#### 9b. Message structure

**Structure of the generated message:**

If first-dispatch, prepend the onboarding pre-block:
```
👋 First dispatch in this session. Before touching the milestone below, do this onboarding **once**:

0. Switch to your worktree: `cd <worktree-path>` — verify `git branch --show-current` shows `session/<sessionId>`. If either is wrong, stop and tell me.
1. Read .claude-multi-session/roles/worker.md (your job description)
2. Read .claude-multi-session/workflow.md (state machine)
3. Read .claude-multi-session/messages/completion-report.md (the format you'll send back)
4. Read .claude-multi-session/log-templates/atomic.md and .claude-multi-session/log-templates/daily.md (the log artifacts you must produce)
5. set_summary("Worker <sessionId> — working on <project basename>")

Your worktree is at `<worktree-path>`, branch `session/<sessionId>`. All commits go to this branch — never commit directly to main.

Confirm via send_message back: "✅ Onboarded, starting Mx.y" — then start. The dispatch follows.

---
```

Then the dispatch block:
```
派工 → <sessionId>: **Mx.y** <description> (🤖 / ✍️)

📋 任務範圍 (Task scope):
- <from PROGRESS.md acceptance criteria — summarize what to build/fix>
- 預期改動檔案 (only touch these):
  - <file 1>
  - <file 2>

🎯 技術建議 / Hints:
- <from PROGRESS.md hints, Reviewer's knowledge, and codebase-memory graph context (if available)>

⚠️ 不要動 (don't touch):
- <auto-generated from step 7>

🔒 規則提醒 (rules — non-negotiable):
1. Only do Mx.y; stop and report when done. No scope creep.
2. No build step — but verify the command file has valid YAML frontmatter (the `---` delimiters and required fields).
3. Commit message format: `Mx.y: <description>`.
4. Commits go to `session/<sessionId>` branch, not main. Verify with `git branch --show-current` before committing.
5. Same commit must include:
   - `PROGRESS.md` checkbox update (Mx.y `[ ] → [x]`) + 「註」 column with implementation notes
   - **Atomic log file** at `docs/session-logs/<today>/sessionN/Mx.y-sessionN.md` (use template `.claude-multi-session/log-templates/atomic.md`)
6. Before committing: `git rebase main` to ensure your branch is up to date.

開工! Send completion-report when done.
```

**Adaptive fields:**
- **🤖 / ✍️ marker**: use 🤖 for S-effort milestones with clear spec, ✍️ for M/L or milestones requiring design judgment. Let the Reviewer override.
- **Rule 2 (build)**: adapt to the project. If `package.json` exists, use `npm run build` or `npm test`. If no build step (pure markdown projects), say "No build step — but verify <appropriate check>". Read from PROGRESS.md audit summary or `CLAUDE.md` for the project's build command.
- **Auto-pass criteria**: include for 🤖-marked milestones only. Omit the section entirely for ✍️ milestones.

### 10. Suggest in_progress update

After outputting the dispatch message, remind the Reviewer:

```
📝 After sending, update PROGRESS.md frontmatter:
  in_progress: [<existing>, Mx.y]
```

This ensures subsequent `/multi-session:dispatch` calls detect the correct held file regions.

### 11. Stop

After outputting the dispatch message and the reminder, stop. Do not:
- Send the message yourself
- Edit any files
- Start generating a second dispatch
- Dispatch additional milestones

## Behavior rules

- This command is **read-only**. It reads PROGRESS.md and peer state, asks questions, and prints output. It never writes files or sends peer messages.
- Never `send_message` to workers. The Reviewer reviews, edits, and sends manually.
- If PROGRESS.md has unexpected format (no frontmatter, missing milestone sections), parse what you can and note anomalies — don't error out silently.
- The "don't touch" list must be **comprehensive**. A missing in-flight file region is the most dangerous error this command can make — it leads to git conflicts between workers.
- Keep the generated dispatch message faithful to the `dispatch.md` template format. Don't invent new sections or drop required ones (scope, don't-touch, rules, log requirement).
- If all remaining milestones have unmet dependencies, report which dependencies block them and suggest the Reviewer wait or re-sequence.
- If a milestone's expected files list is missing or empty in PROGRESS.md, flag this — the Reviewer must specify files before dispatching (file-region partitioning requires explicit file lists).
