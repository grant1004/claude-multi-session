---
allowed-tools: Read, Bash(git:*), AskUserQuestion, mcp__claude-peers__list_peers, ToolSearch, mcp__codebase-memory-mcp__trace_path, mcp__codebase-memory-mcp__search_graph, mcp__codebase-memory-mcp__get_code_snippet
description: Reviewer review helper — reads git diff, compares against acceptance criteria, generates review verdict message, optionally merges on pass
---

## Context

- Project root: !`pwd`
- `PROGRESS.md` exists: !`test -f PROGRESS.md && echo "yes" || echo "no (run /multi-session:audit first)"`
- Session branches: !`git branch --list 'session/*' 2>/dev/null || echo "(no session branches)"`
- Worker branches: !`git branch --list 'worker/*' 2>/dev/null || echo "(no worker branches)"`
- Worktree list: !`git worktree list 2>/dev/null || echo "(not a git repo)"`

## Your task

You are the **Reviewer** conducting a structured review of a Worker's completed milestone. This command automates: reading the diff, extracting acceptance criteria, comparing them, and generating a review verdict message. You still make the pass/fail judgment and edit the message before sending.

**This command generates output you review and copy into `send_message`.** The only write actions it can take are `git merge --ff-only` (worker → session branch) and `git merge --no-ff` (session → main, finalize) on explicit user confirmation.

### 1. Pre-flight checks

- If `PROGRESS.md` doesn't exist, tell the user to run `/multi-session:audit` first. Stop.
- Read `PROGRESS.md` in full before proceeding.
- **Detect session branch**: run `git branch --list 'session/*'`. If exactly one exists, use it as the merge target. If multiple exist, ask the user which one. If none exist, fall back to `main` as the base branch (legacy mode).

### 2. Load codebase-memory tools (optional)

Try to load codebase-memory tools via `ToolSearch` (query: `select:mcp__codebase-memory-mcp__trace_path,mcp__codebase-memory-mcp__search_graph,mcp__codebase-memory-mcp__get_code_snippet`).

- **Available**: note this for steps 5 and 6 — you can use `trace_path` for impact analysis and `get_code_snippet` for deeper criterion checks.
- **Unavailable** (ToolSearch returns nothing or calls error): proceed without it. All subsequent steps work fully with git-diff-only. Do not ask the user to install — just fall back silently.

### 3. Select milestone and worker branch

Check if the user provided arguments (milestone ID and/or branch). If not, use `AskUserQuestion` to select:

**Question 1 — "Which milestone to review?"**
- Build the option list from milestones in `in_progress:` frontmatter (these are the ones awaiting review).
- If `in_progress:` is empty, check for worker branches with commits ahead of the session branch (`git log <session-branch>..worker/<id> --oneline` for each `worker/*` branch). List milestones whose `[x]` checkbox is set but are still in `in_progress:`.
- Each option label: `Mx.y — <short description>`
- Each option description: session assignment if known from `<!-- sessionId -->` comment

**Question 2 — "Which worker branch?"**
- Options: `worker/*` branches that have commits ahead of the session branch
- Derive from `git branch --list 'worker/*'` + `git log <session-branch>..<branch> --oneline` (skip branches with 0 commits ahead)
- Each option label: branch name (e.g. `worker/sessionA`)
- Each option description: `N commits ahead of session branch`

If only one worker branch has commits ahead of the session branch, auto-select it and skip the question.

### 4. Read acceptance criteria

From PROGRESS.md, extract the selected milestone's `**Acceptance**:` section. Parse each bullet as an individual criterion.

Also extract:
- `**Expected files**:` — the files the milestone was supposed to touch
- The `「註」` content if the checkbox is `[x]` (Worker's implementation notes)

### 5. Read the diff

Run these commands and capture output (using the session branch detected in step 1):

```bash
git log <session-branch>..<worker-branch> --stat --oneline
git diff <session-branch>..<worker-branch>
```

Also check:
- **File scope compliance**: compare actually-changed files (from `git diff --name-only <session-branch>..<worker-branch>`) against the expected files list. Flag any unexpected files or missing expected files.
- **Commit message format**: check that commit messages match `Mx.y: <description>` pattern.
- **PROGRESS.md updated**: verify the diff includes a change to the milestone's checkbox line.
- **Atomic log present**: check if `docs/session-logs/*/session*/Mx.y-session*.md` exists in the diff.

**Impact analysis (if codebase-memory available from step 2):**

Use `trace_path` on key functions/classes changed in the diff (extract names from `git diff --name-only` + diff hunks) to identify callers or dependents **outside** the milestone's expected file scope. Report results as an advisory block:

```
🔬 Impact radius (codebase-memory):
- `functionX` (changed in file.md) → called by: <caller list or "no external callers">
- `classY` (changed in other.md) → referenced by: <reference list>
⚠️ Potential cross-scope impact: <summary, or "none detected">
```

This is advisory — it informs the Reviewer's judgment but does not auto-fail the review. If codebase-memory is unavailable, skip this block entirely.

### 6. Compare against acceptance criteria

For each acceptance criterion bullet:
1. Read the criterion text
2. Look for evidence in the diff that it's satisfied. If codebase-memory is available (step 2), use `get_code_snippet` to read surrounding source context when the diff alone doesn't show enough to judge a criterion — e.g. verifying a function signature matches a spec, or confirming an import was added correctly.
3. Assign a verdict: **met** / **partial** / **not met**

Present the results in a structured block:

```
🔍 Acceptance criteria review:

1. 「<criterion text>」
   Verdict: ✅ met / ⚠️ partial / ❌ not met
   Evidence: <file:line or diff excerpt that proves/disproves>

2. 「<criterion text>」
   ...
```

Also run the rule compliance checks:

```
📐 Rule compliance:
- Commit message format (Mx.y: ...): ✅ / ❌
- File scope matches dispatch: ✅ / ❌ <list unexpected files if any>
- PROGRESS.md checkbox updated: ✅ / ❌
- Atomic log written: ✅ / ❌
- Branch is worker/<id> (not main or session branch): ✅ / ❌
```

### 7. Recommend verdict

Based on the acceptance criteria results:
- **All met + all rules pass** → recommend PASS
- **Any "not met" or critical rule failure** → recommend FAIL
- **Partial results only** → present both options, let Reviewer decide

Use `AskUserQuestion`:
- "Review verdict for Mx.y?"
- Options: "Pass" (with summary of what's good) / "Fail" (with summary of issues) / "Hold" (with option to explain reason)

### 8. Generate verdict message

Based on the Reviewer's choice, generate the message using `.claude-multi-session/messages/review-pass.md` format.

**On PASS**, output:

```
Mx.y ✅ Review pass (commit <hash>).

評語 / Evaluation:
- <auto-generated from acceptance criteria results>
- <any nits from diff review — non-blocking>

派下一個 / Next:
(Reviewer: replace with next dispatch or "Standby")
```

**On FAIL**, output:

```
Mx.y ❌ Review fail (commit <hash>).

問題 / Issues (must fix):
- <from "not met" criteria, with file:line>

建議改法 / Suggested fix:
- <brief suggestion based on diff analysis>

請修正後重 commit。Same milestone, single new commit on top, then send_message me again.
```

**On HOLD**, output:

```
Mx.y Hold — <reason from Reviewer>

Standby for now; I'll dispatch again when blocker clears.
```

Output the message as a **fenced code block** the Reviewer can copy into `send_message`.

### 9. Offer merge (pass only)

If verdict is PASS, ask the Reviewer:

"Merge `<worker-branch>` into `<session-branch>` now? (`git merge --ff-only`)"
- Options: "Yes — merge now" / "No — I'll merge manually later"

If yes:
```bash
git checkout <session-branch>
git merge --ff-only <worker-branch>
```

If `--ff-only` fails, report the error and suggest the Worker rebase: "Ask the Worker to run `git rebase <session-branch>` on their branch, then re-merge."

After merge (or skip), check if **all milestones in PROGRESS.md are now completed** (no unchecked `- [ ]` milestones remain, and `in_progress:` frontmatter is empty or will be after this one). If so, offer finalization:

"All milestones complete. Finalize session — merge `<session-branch>` into main? (`git merge --no-ff`)"
- Options: "Yes — finalize now" / "No — I'll finalize later"

If yes:
```bash
git checkout main
git merge --no-ff <session-branch>
```

After merge (or skip), remind:

```
📝 Post-review actions (in order):
1. send_message the verdict to the Worker (copy the block above)
2. Update docs/review-logs/<today>.md: add row to "Review pass 一覽" table + add Mx.y-sessionN heading section
3. Update Worker's atomic log status: review-pending → review-pass
4. Update PROGRESS.md: move Mx.y from in_progress to completed, update 「現在進度」 line
5. Dispatch next milestone to the Worker (use /multi-session:dispatch), or send "Standby"
```

If finalization was executed, add:

```
📝 Post-finalize actions:
1. Delete worker branches: `git branch -d worker/<id>` for each worker
2. Delete session branch: `git branch -d <session-branch>`
3. Remove worktrees: `git worktree remove ../worker-<id>` for each worker
```

### 10. Stop

After outputting the verdict message and post-review reminders, stop. Do not:
- Send the message yourself (Reviewer sends manually)
- Edit PROGRESS.md (Reviewer edits manually)
- Start reviewing another milestone
- Dispatch the next milestone (that's `/multi-session:dispatch`)

## Behavior rules

- This command is **read-only** except for the optional merge steps: `git merge --ff-only` (worker → session branch) and `git merge --no-ff` (session → main, finalize). Both require explicit user confirmation via `AskUserQuestion`.
- Never `send_message` to workers. The Reviewer reviews the generated message, edits it, and sends manually.
- Be honest in acceptance criteria verdicts. If the diff doesn't clearly prove a criterion is met, say "partial" or "not met" — don't assume.
- When reading diffs, focus on substance over formatting. A criterion about "file X has property Y" should be checked by reading the actual file content in the diff, not just the filename.
- If the diff is very large (>500 lines), summarize by file and focus acceptance criteria checking on the most critical items. Note that you skimmed some areas.
- If `PROGRESS.md` has unexpected format, parse what you can and note anomalies — don't error out silently.
