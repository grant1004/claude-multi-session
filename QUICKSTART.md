# Quickstart (Windows, zero-baseline)

For a fresh Windows machine where only Claude Code is installed. End state: you can run `/multi-session:init` in any project and spin up parallel Worker sessions.

Estimated time: ~15 minutes.

## Prerequisites you'll install

1. **Bun** (JS runtime, needed by `claude-peers-mcp`)
2. **Git for Windows** (likely already there — verify)
3. **claude-peers-mcp** (peer messaging MCP server)
4. **claude-multi-session** (this plugin)

## 1. Install Bun

PowerShell as a regular user (no admin needed):

```powershell
powershell -c "irm bun.sh/install.ps1 | iex"
```

Restart PowerShell, then verify:

```powershell
bun --version
```

You should see a version string. If `bun` is not recognized, add `%USERPROFILE%\.bun\bin` to `PATH` manually (Bun installer usually does this, but a session restart is needed for it to apply).

## 2. Verify Git

```powershell
git --version
```

If not installed: download from <https://git-scm.com/download/win> and install with defaults.

## 3. Install claude-peers-mcp (with the Windows broker fix)

The upstream `louislva/claude-peers-mcp` repo has a known Windows bug — the broker daemon does not auto-spawn (see [PR #62](https://github.com/louislva/claude-peers-mcp/pull/62)). Until that PR is merged, clone the fork that includes the fix.

```powershell
cd $HOME
git clone https://github.com/grant1004/claude-peers-mcp.git
cd claude-peers-mcp
git checkout fix/windows-broker-autospawn
bun install
```

Then register the MCP server with Claude Code (user scope, so it works in any project):

```powershell
claude mcp add --scope user claude-peers bun "$HOME\claude-peers-mcp\server.ts"
```

Verify:

```powershell
claude mcp list
```

You should see `claude-peers` listed without a ✗ Failed-to-connect status. (If you see ✗ on the first try, kill any orphan `bun` processes in Task Manager and try again.)

## 4. Install the claude-multi-session plugin

Add the marketplace and enable the plugin:

```powershell
claude /plugin marketplace add grant1004/claude-multi-session
claude /plugin install claude-multi-session
```

(If the slash-command form doesn't work in your terminal, open Claude Code and run `/plugin marketplace add grant1004/claude-multi-session` then `/plugin install claude-multi-session` inside it.)

Verify `~/.claude/settings.json` has:

```json
"enabledPlugins": {
  ...,
  "claude-multi-session@<source>": true
}
```

## 5. First project setup

Pick a real project you want to try this on (or `mkdir test-multi-session` for a sandbox).

```powershell
cd <project root>
claude
```

Inside Claude Code:

```
/multi-session:init
```

This will:
- Create `.claude-multi-session/` with role definitions, message templates, and log templates
- Create `docs/session-logs/`, `docs/review-logs/`, `docs/pitfalls/` (empty, with `.gitkeep`)
- Append a "Multi-session parallel workflow" section to your project's `CLAUDE.md` (creates the file if missing)

Review the diff before committing. If anything looks wrong, you can `git restore .` to revert and re-run with adjustments.

## 6. Start a multi-session session

Now you spin up N Claude Code sessions in this project root. Each terminal:

```powershell
cd <project root>
claude
```

In session 1 (the **Reviewer**):
> Read `.claude-multi-session/roles/reviewer.md` and act as Reviewer for this project. Use `set_summary` to declare your role, then `list_peers` to see Worker sessions.

In sessions 2-3+ (each a **Worker**):
> Read `.claude-multi-session/roles/worker.md` and act as a Worker. Use `set_summary` to declare your role, then wait for the Reviewer to dispatch a milestone.

From there, the Reviewer drives. It dispatches via `send_message`; Workers execute one milestone each, commit, and report.

For the full state machine and message formats, the Reviewer / Workers will read the files under `.claude-multi-session/` themselves.

## 7. Troubleshooting

**`claude mcp list` shows `claude-peers ✗ Failed to connect`**
- Make sure you used the fork with the Windows fix (step 3). The upstream repo will reproduce this exact symptom.
- Kill orphan `bun` processes in Task Manager and try opening Claude Code again.
- Manually start the broker once with `bun "$HOME\claude-peers-mcp\broker.ts"` and check `Invoke-WebRequest http://127.0.0.1:7899/health` returns 200.

**`list_peers` returns empty inside Claude Code**
- The peer needs to be in the same `--scope`. Defaults are usually fine; if not, try `list_peers` with explicit `scope: "machine"`.
- Other sessions might not have called `set_summary` yet — they won't show up as peers until they do.

**`/multi-session:init` complains "no plugin found"**
- Re-check `~/.claude/settings.json` has the plugin under `enabledPlugins`.
- Try `claude /plugin list` to confirm.

**`send_message` between sessions is delayed**
- Known limitation of the broker. Fallback: Reviewer can `git log --oneline` to see whether a Worker has actually committed even if the message hasn't arrived yet.

**A Worker session crashes mid-milestone**
- Re-open the session. The replacement session reads `CLAUDE.md` + `PROGRESS.md` + `.claude-multi-session/roles/worker.md` and waits for a fresh dispatch from the Reviewer.

## 8. What to read next

- `.claude-multi-session/workflow.md` — full state machine and invariants
- `.claude-multi-session/roles/reviewer.md` and `worker.md` — role-specific job descriptions
- `.claude-multi-session/log-templates/*.md` — log structure for sessions
