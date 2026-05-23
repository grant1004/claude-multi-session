# claude-peers -id <name> [...extra claude args]
#
# Launcher for Claude Code wired into the claude-peers MCP channel network.
#
# What it does:
#   1. Sets $env:CLAUDE_PEERS_PEER_ID = <name> for the launched process so
#      server.ts (branch feat/desired-peer-id of grant1004/claude-peers-mcp)
#      asks the broker to register the peer under that ID. `list_peers` then
#      shows "reviewer" / "sessionA" instead of an 8-char random ID.
#   2. Launches `claude` with:
#        --dangerously-skip-permissions             no permission prompts
#        --dangerously-load-development-channels    enable inbound channel push
#          server:claude-peers                      from the claude-peers MCP
#   3. Passes any extra args through to claude verbatim.
#
# Examples:
#   claude-peers -id reviewer
#   claude-peers -id sessionA --resume abc123
#
# On older claude-peers-mcp versions (without the CLAUDE_PEERS_PEER_ID patch)
# the env var is silently ignored and the broker assigns a random ID.

[CmdletBinding(PositionalBinding = $false)]
param(
    [Alias('id')]
    [Parameter(Mandatory = $true)]
    [string]$Id,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

$env:CLAUDE_PEERS_PEER_ID = $Id

$claudeArgs = @(
    '--dangerously-skip-permissions',
    '--dangerously-load-development-channels', 'server:claude-peers'
)
if ($ExtraArgs) { $claudeArgs += $ExtraArgs }

& claude @claudeArgs
exit $LASTEXITCODE
