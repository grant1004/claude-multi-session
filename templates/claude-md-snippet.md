
### Multi-session parallel workflow (via claude-peers MCP)

When the user spins up multiple Claude Code sessions in this repo and designates one as **Reviewer** dispatching tasks to other **Worker** sessions:

- **Reviewer** sessions read `.claude-multi-session/roles/reviewer.md` first. Do not write code. Dispatch + review only.
- **Worker** sessions read `.claude-multi-session/roles/worker.md` first. Execute one milestone at a time within the dispatched file scope.
- All sessions use `claude-peers` MCP `set_summary` / `send_message` / `list_peers` to coordinate.
- Communication templates: `.claude-multi-session/messages/{dispatch,review-pass,completion-report}.md`.
- Log artifacts go to `docs/session-logs/`, `docs/review-logs/`, `docs/pitfalls/`. Templates: `.claude-multi-session/log-templates/{atomic,daily,reviewer-master,pitfall}.md`.
- Full state machine + invariants: `.claude-multi-session/workflow.md`.

If you are unsure which role you are: ask the user. If running solo (no `claude-peers` peers visible via `list_peers`), the multi-session workflow does not apply — treat this section as informational only.
