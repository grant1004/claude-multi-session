---
allowed-tools: mcp__claude-peers__list_peers, mcp__claude-peers__send_message, mcp__claude-peers__set_summary
description: Reviewer roll-call — broadcast introduction to all worker peers and collect their acks
---

## Context

- Your env-assigned peer ID: !`echo $env:CLAUDE_PEERS_PEER_ID 2>/dev/null || echo "(not set — are you launched via claude-peers?)"`
- Project root: !`pwd`
- `PROGRESS.md` exists: !`test -f PROGRESS.md && echo "yes" || echo "no (run /multi-session:audit first)"`

## Your task

You are the **Reviewer**. Run a roll-call ceremony: introduce yourself to all worker peers, ask them to ack with their own self-introduction, and produce a roster.

### 1. Sanity check role

- If your `CLAUDE_PEERS_PEER_ID` is not `reviewer` (or you have no env ID at all), warn the user that this command is for the Reviewer session, but proceed if they explicitly tell you to.
- If `PROGRESS.md` doesn't exist or its 「現在進度」 line says audit is incomplete: warn the user that they probably want to run `/multi-session:audit` first so workers have something to dispatch from. Ask whether to proceed anyway.

### 2. Set your own summary

```
set_summary("Reviewer — dispatching tasks + reviewing commits on <project name>. PROGRESS.md ready.")
```

(Replace `<project name>` with the actual project name from `pwd` basename or `package.json` name.)

### 3. Discover peers

```
list_peers({"scope": "machine"})
```

(Use `"directory"` or `"repo"` if `"machine"` returns peers from unrelated projects.)

If 0 peers found: tell the user no workers are visible yet, suggest they open more terminals and run `claude-peers -id sessionA` / `sessionB` / etc., then re-run this command. Stop here.

### 4. Broadcast introduction to each peer

For every peer (excluding yourself), `send_message`:

```
👋 Roll-call — I'm the Reviewer for <project name>.

PROGRESS.md is ready with N milestones (M1.1 ... Mx.y). Recommended worker count: <N>.

Please ack with:
1. Your role declaration (use set_summary to set your own summary to "Worker — awaiting dispatch on <project>")
2. A brief self-introduction message back to me: which milestones you've already glanced at (if any), any preference, or just "ready, no preference"

I'll start dispatching as soon as the roster is complete.

Workflow reference: .claude-multi-session/roles/worker.md
```

Send sequentially (not in a single batch) so each Worker gets a unique addressed message. Track which peers you sent to.

### 5. Collect acks

Wait for inbound `<channel source="claude-peers" ...>` messages from each worker. Each Worker's reply should arrive within ~30 seconds (subject to broker push delay).

Build a roster table as acks come in:

| Peer ID | Summary | Ack received? | Preference (if any) |
|---|---|---|---|
| sessionA | "Worker — awaiting dispatch on cs2-demo-service" | ✅ 14:32:15 | M1.1 |
| sessionB | (unchanged from generated default) | ⏳ pending | — |
| sessionC | "Worker — awaiting dispatch on cs2-demo-service" | ✅ 14:32:18 | no preference |

After ~60 seconds, print the roster + status:
- All peers acked → ready to dispatch
- Some peers pending → name them, suggest user check those terminals are alive (or re-launch with `claude-peers -id <name>`)

### 6. Stop

After roster is printed, stop. **Do not** start dispatching milestones unilaterally — the user picks which Worker gets which milestone (or tells you to use the audit's recommendation).

The dispatch step is intentionally manual (no `/multi-session:dispatch` slash command), because each dispatch carries context-specific "don't touch" lists that the Reviewer must reason about per-event.

## Behavior rules

- Use only the claude-peers MCP tools listed in `allowed-tools`. Do not start writing code, editing files, or doing audit work — those are separate commands.
- If a Worker's ack contradicts the audit (e.g. "I want M1.1 but I'm already in another repo"), surface this to the user before dispatching.
- If a peer's `summary` field still looks like an auto-generated description from `claude-peers-mcp` (not the human-readable role name expected via `CLAUDE_PEERS_PEER_ID`), call this out — the worker's launcher may not have set the env var correctly. Suggest they relaunch with `claude-peers -id <name>`.
