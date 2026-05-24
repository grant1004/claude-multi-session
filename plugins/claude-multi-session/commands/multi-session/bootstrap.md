---
allowed-tools: Bash, Read, mcp__claude-peers__set_summary, mcp__claude-peers__list_peers
description: Auto-detect role from CLAUDE_PEERS_PEER_ID env var and run the matching onboarding ritual (read role file, set_summary, report ready)
---

## Context

- Your env-assigned peer ID: !`echo $env:CLAUDE_PEERS_PEER_ID 2>/dev/null || echo "(not set)"`
- Project root: !`pwd`
- `.claude-multi-session/` exists: !`test -d .claude-multi-session && echo "yes" || echo "no — run /multi-session:init first in this project"`
- `PROGRESS.md` exists: !`test -f PROGRESS.md && echo "yes" || echo "no"`

## Your task

You are a session that just launched (via `claude-peers -id <name>`). Run the matching role onboarding ritual based on `CLAUDE_PEERS_PEER_ID`.

### 1. Determine role

- If `CLAUDE_PEERS_PEER_ID == "reviewer"` → **Reviewer onboarding**
- If `CLAUDE_PEERS_PEER_ID` is set to anything else → **Worker onboarding**
- If `CLAUDE_PEERS_PEER_ID` is unset / empty → **tell the user this session was not launched via `claude-peers`**, suggest exiting and relaunching with `claude-peers -id reviewer` or `-id sessionA`, then stop.

### 2. Sanity check the project

- If `.claude-multi-session/` is missing, the project has not been scaffolded yet. Tell the user to run `/multi-session:init` first. Stop.
- If `PROGRESS.md` is missing **and** role is Reviewer, suggest running `/multi-session:audit` next.
- If `PROGRESS.md` is missing **and** role is Worker, warn that there's nothing to dispatch yet — wait for Reviewer to finish audit.

### 3. Read the role file (mandatory)

This is the single most important step. Read the full file:

- Reviewer → `Read .claude-multi-session/roles/reviewer.md`
- Worker → `Read .claude-multi-session/roles/worker.md`

Also read `Read .claude-multi-session/workflow.md` for the state machine.

Then read the message templates you'll be sending:

- Reviewer → `Read .claude-multi-session/messages/dispatch.md` and `.claude-multi-session/messages/review-pass.md`
- Worker → `Read .claude-multi-session/messages/completion-report.md` and `.claude-multi-session/log-templates/atomic.md` and `.claude-multi-session/log-templates/daily.md`

### 4. set_summary

Reviewer:
```
set_summary("Reviewer — dispatching tasks + reviewing commits on <project basename>. Onboarded against PROGRESS.md.")
```

Worker:
```
set_summary("Worker — awaiting dispatch on <project basename>. Read .claude-multi-session/roles/worker.md.")
```

(Replace `<project basename>` with the actual directory name from `pwd`.)

### 5. Report ready + suggest next step

Print a summary to the user:

**Reviewer**:
```
✅ Reviewer onboarded for <project>.
  - Read roles/reviewer.md + workflow.md + dispatch/review-pass templates
  - set_summary done
  - PROGRESS.md: <present, N milestones | missing — run /multi-session:audit next>

Suggested next:
  - /multi-session:audit (if no PROGRESS.md)
  - /multi-session:roll-call (after audit, once N Worker sessions are up)
```

**Worker**:
```
✅ Worker <id> onboarded for <project>.
  - Read roles/worker.md + workflow.md + completion-report + log templates
  - set_summary done
  - PROGRESS.md: <present, awaiting Reviewer dispatch | missing — Reviewer hasn't audited yet>

Standing by. Reviewer will send_message a dispatch when ready.

Remember:
  - One milestone at a time
  - Stay strictly inside the dispatched file scope
  - Build 0 error before commit
  - Write atomic log to docs/session-logs/<date>/<your-id>/Mx.y-<your-id>.md before reporting completion
  - At end of day write daily summary docs/session-logs/<date>/<your-id>/session-<your-id>.md
```

### 6. Stop

Do not start dispatching, auditing, or coding. The user explicitly invokes the next step.

## Behavior rules

- This command is idempotent — running it twice in the same session is safe (reads the same files, re-sets summary).
- If `claude-peers` MCP is not available (broker not running), `set_summary` will fail — surface this clearly and tell the user to check `claude mcp list` and the broker process.
- The role file content is the source of truth. If anything in this onboarding summary contradicts the role file, the role file wins.
