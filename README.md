# claude-multi-session

Multi-session parallel coding workflow for Claude Code, built on top of [`louislva/claude-peers-mcp`](https://github.com/louislva/claude-peers-mcp).

One Claude Code session plays **Reviewer** (dispatches tasks + reviews commits), other sessions play **Worker** (write code in non-overlapping file regions). The plugin provides the role definitions, dispatch / review / completion-report message templates, and atomic / daily / reviewer-master / pitfall log structures.

## Quick start

If you're setting this up on a Windows machine where only Claude Code is installed: see **[QUICKSTART.md](QUICKSTART.md)** for the zero-baseline guide (Bun + claude-peers-mcp + plugin install, ~15 minutes).

If you already have Bun + `claude-peers-mcp` working and just want to install the plugin:

```sh
claude /plugin marketplace add grant1004/claude-multi-session
claude /plugin install claude-multi-session
```

Then in a project root:

```sh
claude
```

```
/multi-session:init
```

This scaffolds:

- `.claude-multi-session/` — role definitions, message templates, workflow doc
- `docs/session-logs/`, `docs/review-logs/`, `docs/pitfalls/` — output dirs
- Appends a "Multi-session parallel workflow" section to your `CLAUDE.md`

Then start N Claude Code sessions in the same repo, designate one as Reviewer, the rest as Workers (each reads `.claude-multi-session/roles/<role>.md`), and use `claude-peers` MCP `send_message` / `list_peers` to coordinate.

## Why

A single Claude Code session is bottlenecked by its own context window and reasoning serialization. With `claude-peers-mcp` you can run N sessions on the same repo and have them talk to each other — but without a shared protocol you get race conditions on `PROGRESS.md`, ambiguous task boundaries, dropped review work, and inconsistent log artifacts.

This plugin codifies a workflow that has been battle-tested on a real WPF project (9 code milestones + 1 user acceptance / 1 hour wall time / 0 git conflicts, 3 Worker sessions running in parallel).

## What you get

**Role definitions** (in `.claude-multi-session/roles/`)
- `reviewer.md` — dispatches tasks, file-region partitioning rules, review process, master log maintenance
- `worker.md` — single-milestone execution, build-before-commit, atomic log per milestone
- `project-manager.md` — reserved for 4+ Worker setups

**Message templates** (in `.claude-multi-session/messages/`)
- `dispatch.md` — Reviewer → Worker task assignment
- `review-pass.md` — Reviewer → Worker review verdict + next assignment
- `completion-report.md` — Worker → Reviewer milestone complete

**Log templates** (in `.claude-multi-session/log-templates/`)
- `atomic.md` — one per milestone (frontmatter + change summary + design decisions + acceptance criteria + pitfalls)
- `daily.md` — Worker daily summary, acts as a handoff package for the next session
- `reviewer-master.md` — Reviewer's daily review log, one heading per milestone
- `pitfall.md` — cross-session permanent pitfall knowledge base entry

**Workflow doc** (`.claude-multi-session/workflow.md`)
- Full state machine: dispatch → execute → commit → review → next dispatch / hold / escalate
- Includes design-decision skip-list mechanism, abort/redirect protocol

## Dependencies

- [`claude-peers-mcp`](https://github.com/louislva/claude-peers-mcp) — peer discovery + messaging (on Windows, you may need [this fix](https://github.com/louislva/claude-peers-mcp/pull/62))
- Git (commits are the synchronization primitive; Worker → Reviewer handoff is "commit + send_message")
- Obsidian (optional) — the log templates use wikilink syntax so the whole `docs/` tree can be opened as a vault

## Status

**Pre-release / iterating.** This plugin is not yet on Anthropic's official marketplace; install directly from this repo for now.

## License

MIT. See [LICENSE](LICENSE).
