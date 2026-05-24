# Quickstart (Windows, zero-baseline)

For a fresh Windows machine where only Claude Code is installed. End state: you can run `/multi-session:init` in any project and spin up parallel Worker sessions with `claude-peers -id <name>`.

Estimated time: ~15 minutes.

## Prerequisites you'll install

1. **Bun** (JS runtime, needed by `claude-peers-mcp`)
2. **Git for Windows** (likely already there — verify)
3. **claude-peers-mcp** (peer messaging MCP server, patched fork)
4. **claude-multi-session** (this plugin)
5. **claude-peers launcher** (the `claude-peers.ps1` shipped in this plugin's `scripts/`)

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

## 3. Install claude-peers-mcp (patched fork)

The upstream `louislva/claude-peers-mcp` has two issues this workflow depends on fixing:

- **Windows broker bug** — the broker daemon doesn't auto-spawn (see [PR #62](https://github.com/louislva/claude-peers-mcp/pull/62))
- **No user-supplied peer ID** — `list_peers` shows opaque 8-char random IDs instead of nicknames like `reviewer` / `sessionA`

Both fixes live in the `feat/desired-peer-id` branch of `grant1004/claude-peers-mcp` (which is built on top of the Windows fix branch).

```powershell
cd $HOME
git clone https://github.com/grant1004/claude-peers-mcp.git
cd claude-peers-mcp
git checkout feat/desired-peer-id
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

You should see `claude-peers` listed without a ✗ Failed-to-connect status. (If you see ✗ on the first try, kill any orphan `bun` processes in Task Manager and try opening Claude Code again.)

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

## 5. Install the `claude-peers` launcher

The plugin ships a PowerShell launcher in `scripts/claude-peers.ps1` that wraps `claude` with the right flags and the `CLAUDE_PEERS_PEER_ID` env var.

### 5a. Put the script in your PATH

Easiest: copy it to a directory already in `PATH`. Most setups use `%USERPROFILE%\bin` (create it if missing):

```powershell
$bin = "$HOME\bin"
if (-not (Test-Path $bin)) { New-Item -ItemType Directory $bin | Out-Null }
# Locate the installed plugin (the path depends on your marketplace source);
# easiest is to clone the repo too if you don't want to dig:
git clone https://github.com/grant1004/claude-multi-session.git "$HOME\claude-multi-session"
Copy-Item "$HOME\claude-multi-session\scripts\claude-peers.ps1" $bin
```

### 5b. Ensure `~/bin` is in PATH and `.PS1` runs without `.ps1`

PowerShell will execute `~/bin/claude-peers.ps1` as `claude-peers` only if:
1. `~/bin` (or wherever you put the script) is on `PATH`
2. `PATHEXT` includes `.PS1`

Check `PATH`:

```powershell
$env:PATH -split ';' | Select-String 'bin'
```

If `~/bin` is missing, add it (per-user, permanent):

```powershell
[Environment]::SetEnvironmentVariable(
  'PATH',
  "$([Environment]::GetEnvironmentVariable('PATH','User'));$HOME\bin",
  'User'
)
```

Check `PATHEXT`:

```powershell
$env:PATHEXT
```

If `.PS1` is missing, add it:

```powershell
[Environment]::SetEnvironmentVariable(
  'PATHEXT',
  "$([Environment]::GetEnvironmentVariable('PATHEXT','User'));.PS1",
  'User'
)
```

**Restart PowerShell** for both changes to apply.

### 5c. Verify

```powershell
claude-peers -id reviewer
```

Inside the spawned Claude Code, call `list_peers` — you should see the peer registered with `id: reviewer` (not a random string).

## 6. First project setup

Pick a real project to try this on (or `mkdir test-multi-session` for a sandbox).

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

## 7. Start a multi-session session

The flow has two onboarding paths baked into the workflow itself — you don't run a separate "bootstrap" step:

- **Reviewer** primes itself when it runs `/multi-session:audit` (the audit command's step 0 forces it to read its role file, workflow, and message templates before producing PROGRESS.md).
- **Worker** is primed by the Reviewer's first dispatch message, which carries an explicit "first-dispatch pre-block" telling the worker to read `roles/worker.md`, the log templates, and set_summary before touching code.

This means: don't ask Reviewer / Workers to manually `Read roles/...` — the commands and messages handle it.

### 7a. Reviewer terminal

```powershell
cd <project root>
claude-peers -id reviewer
```

Inside Claude Code:

```
/multi-session:audit
```

This (a) primes the Reviewer with role context, (b) walks the project, and (c) produces `PROGRESS.md` with milestone candidates + a recommended worker count. Review the output and decide how many workers to spin up.

### 7b. Worker terminals (one per parallel worker)

Open another terminal for each worker:

```powershell
cd <project root>
claude-peers -id sessionA
```

Then inside that Claude Code, just say:

> Standing by. Waiting for the Reviewer to dispatch.

No manual file reads needed — the Reviewer's first dispatch will include the onboarding pre-block. Repeat for `sessionB`, `sessionC`, etc. up to the recommended count.

### 7c. Back in the Reviewer terminal — roll-call + dispatch

```
/multi-session:roll-call
```

This broadcasts an introduction to each worker peer, collects acks, and prints a roster. After the roster is complete, decide which milestones go to which worker (based on the audit's parallelism analysis) and dispatch each manually via `send_message` using the `dispatch.md` template — including the first-dispatch pre-block for each worker on their first task.

From there the Reviewer drives: dispatch → Worker executes → Worker `send_message` completion-report → Reviewer reviews via `git log --stat` + `git diff` → pass or fail → next dispatch.

From there, the Reviewer drives. It dispatches via `send_message`; Workers execute one milestone each, commit, and report.

## 8. Troubleshooting

**`claude mcp list` shows `claude-peers ✗ Failed to connect`**
- Make sure you used the patched fork (step 3). The upstream repo will reproduce this exact symptom on Windows.
- Kill orphan `bun` processes in Task Manager and try opening Claude Code again.
- Manually start the broker once with `bun "$HOME\claude-peers-mcp\broker.ts"` and check `Invoke-WebRequest http://127.0.0.1:7899/health` returns 200.

**`claude-peers` command not recognized**
- Step 5b not complete: either `~/bin` is not on `PATH` or `PATHEXT` does not include `.PS1`. Restart PowerShell after env var changes.
- As a workaround: invoke with full path, `& "$HOME\bin\claude-peers.ps1" -id reviewer`.

**`list_peers` shows random ID instead of the requested name**
- Either the broker is from the un-patched upstream (step 3 was skipped or pointed at the wrong branch), or another live session already holds that ID.
- Check stderr: server.ts logs a warning when it had to fall back to a random ID. Pick a different `-id`.

**`list_peers` returns empty inside Claude Code**
- Other sessions might not have called `set_summary` yet — they won't show up until they do (actually they show up at register, but `list_peers` filters require some context). Try `list_peers` with explicit `scope: "machine"`.

**`/multi-session:init` complains "no plugin found"**
- Re-check `~/.claude/settings.json` has the plugin under `enabledPlugins`.
- Try `claude /plugin list` to confirm.

**`send_message` between sessions is delayed**
- Known limitation of the broker. Fallback: Reviewer can `git log --oneline` to see whether a Worker has actually committed even if the message hasn't arrived yet.

**A Worker session crashes mid-milestone**
- Re-open the session with the same `claude-peers -id sessionN`. The new instance registers under the same ID (the dead-pid takeover branch kicks in), then reads `CLAUDE.md` + `PROGRESS.md` + `.claude-multi-session/roles/worker.md` and waits for a fresh dispatch.

## 9. What to read next

- `.claude-multi-session/workflow.md` — full state machine and invariants
- `.claude-multi-session/roles/reviewer.md` and `worker.md` — role-specific job descriptions
- `.claude-multi-session/log-templates/*.md` — log structure for sessions
