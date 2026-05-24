---
allowed-tools: Bash(mkdir:*), Bash(cp:*), Bash(ls:*), Bash(test:*), Bash(git:*), Read, Write, Edit
description: Scaffold .claude-multi-session/ + docs/ structure in the current project (auto-checks git, offers git init if missing)
---

## Context

- Plugin directory containing templates: `${CLAUDE_PLUGIN_ROOT}` (this command's plugin)
- Target project directory: !`pwd`
- Git repository: !`git rev-parse --git-dir 2>/dev/null && echo "yes" || echo "no"`
- Existing `CLAUDE.md`: !`test -f CLAUDE.md && echo "yes" || echo "no"`
- Existing `.claude-multi-session/`: !`test -d .claude-multi-session && echo "yes" || echo "no"`

## Your task

Set up the multi-session parallel workflow scaffolding in the current project directory.

### 1. Sanity checks
- If `.claude-multi-session/` already exists, **stop and ask the user** before overwriting. Show them what's already there.
- If `claude-peers-mcp` is not in the user's MCP config, warn them at the end that they need to install it for this workflow to work (link: https://github.com/louislva/claude-peers-mcp).

### 1.5 Git pre-check (mandatory — workflow needs git)

The multi-session workflow uses git commits as the worker→reviewer synchronization primitive. `PROGRESS.md`, atomic logs, `.claude-multi-session/` scaffolding — all must be version-controlled or workers can't see each other's work and a session restart loses everything.

Check if the project is a git repo (`git rev-parse --git-dir`). Branch on result:

**Not a git repo**

Ask the user explicitly:

> This directory is not a git repository. The multi-session workflow requires git — commits are how workers signal completion to the reviewer, and PROGRESS.md / atomic logs need to be version-controlled. How do you want to handle this?
>
> (a) Run `git init` here now (recommended — default branch `main`, no initial commit yet)
> (b) Cancel init, you'll set up the repo yourself first
> (c) Proceed without git (NOT recommended — workflow will break on first dispatch)

If (a): run `git init -b main`. Confirm success.
If (b): stop here, do not scaffold further.
If (c): proceed but loudly warn in the final report.

**Git repo with uncommitted changes**

Note in the final report:

> Working tree had N uncommitted changes when init ran. Consider committing your existing work before workers start, so the workflow's commit history is clean.

Don't block; just inform.

**Clean git repo**

Proceed silently.

### 2. Copy templates

Copy the **entire contents** of `${CLAUDE_PLUGIN_ROOT}/templates/.claude-multi-session/` into `./.claude-multi-session/`.

Files to expect in templates:
- `workflow.md`
- `roles/reviewer.md`, `roles/worker.md`, `roles/project-manager.md`
- `messages/dispatch.md`, `messages/review-pass.md`, `messages/completion-report.md`
- `log-templates/atomic.md`, `log-templates/daily.md`, `log-templates/reviewer-master.md`, `log-templates/pitfall.md`

Preserve directory structure. Don't flatten.

### 3. Create output directories
```sh
mkdir -p docs/session-logs docs/review-logs docs/pitfalls
mkdir -p docs/.obsidian
```

Add a `.gitkeep` to each `session-logs/`, `review-logs/`, `pitfalls/` so they get committed empty.

Add a `.gitkeep` to `docs/.obsidian/` too so the Obsidian vault marker survives `git add`. The empty `.obsidian/` is enough for Obsidian to open `docs/` as a vault without prompting — Obsidian will fill in its own defaults on first launch. Users can then customize (graph view, hotkeys, themes) per-project.

### 4. Append to CLAUDE.md

Append the contents of `${CLAUDE_PLUGIN_ROOT}/templates/claude-md-snippet.md` to `./CLAUDE.md` (create it if missing). If a section titled `### Multi-session parallel workflow` already exists in CLAUDE.md, skip the append and tell the user it's already there.

### 5. Report

Summarize for the user:
- Git status (existing repo / newly initialized / proceeded without git — flag the last loudly)
- Files copied (count + tree)
- Directories created (including `docs/.obsidian/` for Obsidian vault use)
- Whether CLAUDE.md was created / appended / skipped
- Recommended `.gitignore` additions (informational, don't auto-edit):
  - `docs/.obsidian/workspace.json` — per-user Obsidian state, shouldn't be committed
  - `docs/.obsidian/workspace-mobile.json` — same reason
- Recommended first commit (don't auto-commit; let user review):
  ```
  git add .claude-multi-session/ docs/ CLAUDE.md
  git commit -m "chore: scaffold multi-session workflow"
  ```
- The "next steps" block:
  - Verify `claude-peers-mcp` is installed and broker auto-starts
  - Open `docs/` as an Obsidian vault if you want graph view / backlinks (log templates use wikilink syntax)
  - In the Reviewer terminal: `claude-peers -id reviewer` → `/multi-session:audit` (primes role + produces PROGRESS.md)
  - In each Worker terminal: `claude-peers -id sessionA` / `sessionB` / ... → say "standing by"
  - Back in Reviewer: `/multi-session:roll-call` then dispatch via `send_message` (use `dispatch.md` template, include first-dispatch pre-block on each worker's first task)

Do not do anything other than these steps. Don't try to "improve" the templates — that's the user's job. Don't auto-commit; let the user review the diff first.
