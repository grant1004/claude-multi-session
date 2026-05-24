---
allowed-tools: Read, Bash(git:*)
description: Print a concise status dashboard from PROGRESS.md — current phase, milestone table, counts
---

## Context

- Project root: !`pwd`
- `PROGRESS.md` exists: !`test -f PROGRESS.md && echo "yes" || echo "no (run /multi-session:audit first)"`

## Your task

Read `PROGRESS.md` and print a concise status dashboard (~30 lines max). This is a read-only command — do not edit any files or send peer messages.

### 1. Pre-flight

If `PROGRESS.md` does not exist, tell the user to run `/multi-session:audit` first and stop.

### 2. Read and parse

Read `PROGRESS.md` in full. Extract:

- **Phase**: from the `## 現在進度` line (e.g. "audit phase complete", "dispatching", "wrap-up")
- **Skip list**: from YAML frontmatter `skipped:` array
- **Milestones**: each `### Mx.y` section — parse:
  - ID and description from the heading
  - Status: `[x]` = completed, `[ ]` = remaining. If `in_progress:` frontmatter lists the ID, mark as in-progress.
  - Assigned session: extract from `<!-- sessionId -->` comment or 「註」 text if present
- **Decision changelog**: note count of entries (don't dump them)

### 3. Print dashboard

Output in this format (adapt to actual data — don't pad empty sections):

```
📊 Multi-session status — <project name>

Phase: <phase from 現在進度>

Milestones:
  ID     Description                                          Status   Session
  ─────  ───────────────────────────────────────────────────   ──────   ───────
  M1.1   Add .gitignore for repo hygiene                      ✅       ta07g674
  M2.1   Replace WPF examples in templates                    ⬜       —
  M3.1   Add bash/zsh launcher script                         🔄       20c59hcc
  ...

Counts: N completed · N in-progress · N remaining · N skipped
Decisions logged: N

Skipped: (none)
```

Rules for the status column:
- `✅` — checkbox is `[x]`
- `🔄` — listed in `in_progress:` frontmatter
- `⬜` — checkbox is `[ ]` and not in `in_progress:`

If the skip list is non-empty, list the skipped IDs. Otherwise print `(none)`.

### 4. Stop

Print the dashboard and stop. Do not suggest next actions, do not offer to dispatch, do not edit files.

## Behavior rules

- This command is informational only. Never write, edit, or create files.
- Never send peer messages. Never call `set_summary`.
- If `PROGRESS.md` has unexpected format (no frontmatter, no milestones section), print what you can parse and note the anomaly — don't error out.
- Keep total output under 30 lines. If there are many milestones, abbreviate descriptions to fit.
