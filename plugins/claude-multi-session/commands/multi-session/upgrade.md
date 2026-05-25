---
allowed-tools: Read, Bash(diff:*), Bash(ls:*), Bash(test:*), Bash(cp:*), Write, Edit, AskUserQuestion
description: Upgrade .claude-multi-session/ templates to match the current plugin version
---

## Context

- Plugin directory containing templates: `${CLAUDE_PLUGIN_ROOT}`
- Project root: !`pwd`
- `.claude-multi-session/` exists: !`test -d .claude-multi-session && echo "yes" || echo "no"`
- Source template dir exists: !`test -d "${CLAUDE_PLUGIN_ROOT}/templates/.claude-multi-session" && echo "yes" || echo "no"`

## Your task

Compare the project's live `.claude-multi-session/` templates against the plugin's source templates and apply updates with user confirmation.

### 1. Pre-flight checks

- If `.claude-multi-session/` does not exist, stop and tell the user:
  > `.claude-multi-session/` not found. Run `/multi-session:init` first to scaffold the workflow structure.
- If the plugin's source template directory does not exist, stop and report an internal error.

### 2. Diff each template file

Walk every file under `${CLAUDE_PLUGIN_ROOT}/templates/.claude-multi-session/` (the source of truth). For each file, compare against the corresponding path under `.claude-multi-session/` (the live copy).

Classify each file into one of four categories:

- **unchanged** — source and live are byte-identical (`diff` returns exit 0)
- **modified** — both exist but differ (`diff` returns exit 1)
- **new** — exists in source but not in live (added in a newer plugin version)
- **removed** — exists in live but not in source (deleted in a newer plugin version)

Also check the reverse: walk `.claude-multi-session/` for files that don't exist in the source (these are the "removed" category — the plugin no longer ships them).

### 3. Report summary

Print a summary table:

```
📦 Template upgrade check

  Status      File
  ─────────   ──────────────────────────────────
  ✅ match    roles/project-manager.md
  🔄 modified workflow.md
  🔄 modified roles/reviewer.md
  ➕ new      messages/new-template.md
  ➖ removed  messages/old-deprecated.md

  N unchanged · N modified · N new · N removed
```

If all files are unchanged, print:

> ✅ Already up to date — all templates match the plugin source. No changes needed.

Then stop. Do not ask the user anything.

### 4. Ask user how to proceed

Only reach this step if there are modified, new, or removed files. Use `AskUserQuestion`:

> N file(s) differ from the plugin source. How would you like to proceed?
>
> (a) Apply all changes (overwrite modified + copy new + leave removed files alone)
> (b) Review each file individually (show diff, confirm per file)
> (c) Cancel — make no changes

### 5. Apply changes

**If "Apply all":**
- Overwrite each modified file with the source version.
- Copy each new file from source to the live directory (create subdirectories as needed).
- Do NOT delete "removed" files automatically — only warn the user that they exist in live but not in source. The user may have intentionally added them.

**If "Review each":**
- For each modified file: show the diff output (source vs live), then ask:
  > Apply this change to `<path>`? (yes / no / show full file)
- For each new file: show the file contents, then ask:
  > Copy this new file to `.claude-multi-session/<path>`? (yes / no)
- For each removed file: mention it exists only in live, ask:
  > `<path>` exists in your project but not in the plugin source (may have been removed in a newer version). Delete it? (yes / no)
- Skip unchanged files silently.

**If "Cancel":**
- Print "No changes made." and stop.

### 6. Report results

After applying changes, print a summary:

```
✅ Upgrade complete

  Applied:
  - roles/reviewer.md (overwritten)
  - workflow.md (overwritten)
  - messages/new-template.md (new file added)

  Skipped:
  - roles/worker.md (user declined)

  Removed files (user confirmed):
  - (none)
```

Suggest the user review the diff and commit:

```
git diff .claude-multi-session/
git add .claude-multi-session/
git commit -m "chore: upgrade .claude-multi-session/ templates to v<version>"
```

## Behavior rules

- This command only modifies files under `.claude-multi-session/`. Never touch `plugins/`, `tests/`, `docs/`, `CLAUDE.md`, or `PROGRESS.md`.
- Never auto-commit. The user decides when to commit.
- Never overwrite without user confirmation (step 4 is mandatory when changes exist).
- Preserve directory structure when copying new files.
- When showing diffs, use the format: source (plugin) on the left, live (project) on the right. Label clearly which is which.
