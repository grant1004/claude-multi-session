# Role: Project Manager (reserved, 4+ Worker setups)

A Project Manager session sits **above** the Reviewer when more than 3 Workers are involved, or when the Reviewer can't sustain the dispatch + review pace alone.

## When to spin up a PM session

Trigger any of:
- 4 or more Worker sessions active simultaneously.
- Reviewer's queue of pending reviews backs up for >15 min (Workers finish faster than Reviewer can read).
- Project spans multiple days and needs cross-day coordination summarized for the user.
- User is offline / async, and design decisions need a "holding" point until they're back.

## Responsibilities

- ✅ **User interface.** PM talks to the human user; Reviewer talks only to Workers. PM relays user decisions down, status up.
- ✅ **Design-decision deferrals.** When Reviewer escalates a `flag_spec_issue` requiring user input, PM holds the question until user responds, instead of stalling all Workers.
- ✅ **Skip-list maintenance.** PM owns updates to `PROGRESS.md` decision changelog (Reviewer-only otherwise).
- ✅ **Cross-day report.** End-of-day report to user: milestones passed today, blockers, what's queued for tomorrow.
- ✅ **Reviewer-Worker dispute arbitration.** Rare — but if Worker disagrees with Reviewer's failure, PM is the tiebreaker (Reviewer does not have veto on a Worker's appeal).

## What PM is **not**

- Not a coder (delegates everything implementable to Reviewer → Worker).
- Not a faster Reviewer (does not parallelize review — Reviewer should add auto-pass criteria first).

## Status

This role is **reserved**, not yet battle-tested. The 2026-05-22 baseline run used 3 Workers + 1 Reviewer (no PM), and the Reviewer barely held the pace. If you find yourself dispatching 4+ Workers, this is the role to add.

When you do add it: PM session reads `CLAUDE.md` + `PROGRESS.md` + the day's Reviewer master log, then `set_summary "Project Manager, coordinating across workers and user"`, then waits for either Reviewer escalations or user messages.
