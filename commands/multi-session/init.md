---
allowed-tools: Bash(mkdir:*), Bash(cp:*), Bash(ls:*), Bash(test:*), Read, Write, Edit
description: Scaffold .claude-multi-session/ + docs/ structure in the current project
---

## Context

- Plugin directory containing templates: `${CLAUDE_PLUGIN_ROOT}` (this command's plugin)
- Target project directory: !`pwd`
- Existing `CLAUDE.md`: !`test -f CLAUDE.md && echo "yes" || echo "no"`
- Existing `.claude-multi-session/`: !`test -d .claude-multi-session && echo "yes" || echo "no"`

## Your task

Set up the multi-session parallel workflow scaffolding in the current project directory.

### 1. Sanity checks
- If `.claude-multi-session/` already exists, **stop and ask the user** before overwriting. Show them what's already there.
- If `claude-peers-mcp` is not in the user's MCP config, warn them at the end that they need to install it for this workflow to work (link: https://github.com/louislva/claude-peers-mcp).

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
```

Add a `.gitkeep` to each so they get committed empty.

### 4. Append to CLAUDE.md

Append the contents of `${CLAUDE_PLUGIN_ROOT}/templates/claude-md-snippet.md` to `./CLAUDE.md` (create it if missing). If a section titled `### Multi-session parallel workflow` already exists in CLAUDE.md, skip the append and tell the user it's already there.

### 5. Report

Summarize for the user:
- Files copied (count + tree)
- Directories created
- Whether CLAUDE.md was created / appended / skipped
- The "next steps" block:
  - Verify `claude-peers-mcp` is installed and broker auto-starts
  - Open N Claude Code sessions in this project root
  - Designate one as Reviewer (must read `.claude-multi-session/roles/reviewer.md` first)
  - Workers read `.claude-multi-session/roles/worker.md`
  - Use `set_summary` to declare your role; use `send_message` to coordinate

Do not do anything other than these steps. Don't try to "improve" the templates — that's the user's job. Don't auto-commit; let the user review the diff first.
