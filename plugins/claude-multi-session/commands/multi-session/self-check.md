---
allowed-tools: Read, Bash(git:*), Bash(test:*)
description: Worker pre-commit validation — checks auto-pass criteria before sending completion report
---

## Context

- Project root: !`pwd`
- Current branch: !`git branch --show-current`
- Staged changes: !`git diff --cached --stat 2>/dev/null || echo "(nothing staged)"`
- `PROGRESS.md` exists: !`test -f PROGRESS.md && echo "yes" || echo "no"`

## Your task

You are a **Worker** about to commit a milestone. This command validates all auto-pass criteria so you can catch mistakes before the Reviewer does — reducing review-fail round-trips.

**This command is read-only.** It checks state and reports pass/fail. It never edits files, creates commits, or sends messages.

### 1. Determine milestone ID

The milestone ID can come from:
- **Explicit argument**: if the user typed `/multi-session:self-check M3.1`, use `M3.1`
- **Conversation context**: if no argument, look for the most recent dispatch message in conversation — extract the milestone ID from the `派工 → sessionN: **Mx.y**` line
- **Git state**: if neither above works, check `git log --oneline -1` — if the most recent commit message starts with `Mx.y:`, use that ID (for post-commit validation)

If the milestone ID cannot be determined, ask: "Which milestone are you checking? (e.g. M3.1)" and stop until the user answers.

### 2. Determine session ID and session branch

Derive your session ID from:
- Branch name: `worker/<id>` → extract `<id>`
- If branch doesn't match `worker/*` pattern, fall back to worktree directory name (e.g. `worker-sessionA` → `sessionA`)
- If neither works, use "unknown" and note this in the output

Detect the session branch (used as diff target in step 4):
- Run `git branch --list 'session/*'` — if exactly one result, use it
- If multiple session branches exist, pick the one that is an ancestor of HEAD (`git merge-base --is-ancestor`)
- If no session branch found, fall back to `main` and report ⚠️ "no session branch detected, using main as diff target"

### 3. Read PROGRESS.md

Read `PROGRESS.md` in full. Find the milestone section (`### Mx.y`) and extract:
- **Expected files**: the file list under `- **Expected files**:`
- **Checkbox state**: is it already `[x]` or still `[ ]`?

If the milestone ID is not found in PROGRESS.md, report error and stop.

### 4. Run validation checks

Perform these 4 checks. Each check produces ✅ (pass) or ❌ (fail) with details.

#### Check 1: File scope match

Compare actual changes against expected files:

- **Pre-commit** (changes staged but not committed): use `git diff --cached --stat` + `git diff --stat` (staged + unstaged)
- **Post-commit** (milestone already committed): use `git diff --stat HEAD~1` or `git diff --stat <session-branch>..HEAD` (where `<session-branch>` is the branch detected in step 2)

**Pass criteria**: every changed file (excluding PROGRESS.md and `docs/session-logs/`) appears in the expected files list. No unexpected files changed.

**Special allowances** (always pass even if not in expected files):
- `PROGRESS.md` — required by workflow rules
- `docs/session-logs/**` — atomic log, required by workflow rules

**Fail examples**:
- Changed `src/foo.ts` but expected files only lists `src/bar.ts`
- No changes at all (nothing to commit)

Report: list each changed file with ✓ (in scope) or ✗ (out of scope).

#### Check 2: Commit message format

- **Pre-commit**: check if there's a prepared commit message (may not exist yet — report as ⚠️ "cannot verify pre-commit, will check format on commit")
- **Post-commit**: read `git log --format=%s -1` and verify it matches `^Mx.y: .+` (the milestone ID prefix + colon + space + description)

**Pass criteria**: message starts with `Mx.y: ` (exact milestone ID, colon, space, then non-empty description).

**Fail examples**:
- `fix: some bug` (wrong prefix)
- `M3.1 add dispatch` (missing colon+space)
- `M3.1: ` (empty description)

#### Check 3: PROGRESS.md checkbox updated

Read the current state of `PROGRESS.md` (working tree version, not committed):
- Find the `### Mx.y` section
- Check if the checkbox is `[x]`

**Pass criteria**: checkbox shows `[x]` (not `[ ]`).

**Fail if**: checkbox still shows `[ ]` — the worker forgot to update it.

Also verify the `<!-- sessionId -->` comment is present after `[x]` (per convention). If missing, report as ⚠️ (warning, not fail).

#### Check 4: Atomic log exists

Check for file at: `docs/session-logs/<today>/<sessionId>/Mx.y-<sessionId>.md`

Where:
- `<today>` = current date in `YYYY-MM-DD` format
- `<sessionId>` = from step 2
- `Mx.y` = milestone ID
- Use `test -f <path>` to verify existence

**Pass criteria**: file exists.

**Fail if**: file does not exist at the expected path.

If the file exists, also do a quick frontmatter check:
- Has `---` delimiters (valid YAML frontmatter)
- Contains `milestone:` field matching the milestone ID
- Contains `status:` field

Report any frontmatter issues as ⚠️ (warnings, not hard fail).

### 5. Output results

Print a structured checklist matching the auto-pass criteria format from `dispatch.md`:

```
🔍 Self-check results for Mx.y (sessionN)

- [✅/❌] File scope: changed files match dispatched scope
  <detail: list of files with ✓/✗ marks>
- [✅/❌/⚠️] Commit message: format matches `^Mx.y: .+`
  <detail: actual message or "not yet committed">
- [✅/❌] PROGRESS.md: checkbox updated to [x]
  <detail: current state>
- [✅/❌] Atomic log: exists at docs/session-logs/<date>/<session>/Mx.y-<session>.md
  <detail: path checked + frontmatter status>

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Result: ALL PASS ✅ — safe to commit and send completion report
         or
Result: FAIL ❌ — fix the issues above before committing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 6. Stop

After printing results, stop. Do not:
- Fix any issues (that's the Worker's job to do manually)
- Create commits
- Send messages
- Suggest running the check again

## Behavior rules

- This command is **strictly read-only**. It uses `Read` and `Bash(git:*, test:*)` only. Never write, edit, or create files.
- The command is **for Workers**, not Reviewers. It validates the Worker's own work before reporting completion.
- Report results honestly. A false "ALL PASS" is worse than a false fail — it leads to review-fail round-trips that waste everyone's time.
- If a check cannot be performed (e.g. checking commit message pre-commit), report ⚠️ with explanation rather than skipping silently.
- If PROGRESS.md has unexpected format or the milestone section is missing, report the error clearly — don't guess or assume pass.
- Date format for atomic log path is always `YYYY-MM-DD`. Use the system date (from `date` command or equivalent).
- The command should work both **pre-commit** (most checks on staged/unstaged changes) and **post-commit** (all checks on the latest commit). Detect which mode automatically based on git state: if HEAD commit message matches `^Mx.y:`, assume post-commit; otherwise assume pre-commit.
