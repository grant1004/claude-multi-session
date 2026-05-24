---
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
description: Reviewer audit phase — survey a project and produce PROGRESS.md with milestone candidates + recommended worker count
---

## Context

- Project root: !`pwd`
- Working tree state: !`git status --short`
- Recent commits: !`git log --oneline -20`
- Existing `PROGRESS.md`: !`test -f PROGRESS.md && echo "yes (will refuse to overwrite without --force)" || echo "no"`
- Existing `CLAUDE.md`: !`test -f CLAUDE.md && head -5 CLAUDE.md || echo "(none)"`

## Your task

You are the **Reviewer** running the audit phase. Survey this project and produce a `PROGRESS.md` with milestone candidates + a recommended worker count. Do **not** write any production code; only the audit artifact.

### 0. Onboarding pre-check

- If you haven't already in this session, run `/multi-session:bootstrap` first (or do its core steps manually): read `.claude-multi-session/roles/reviewer.md`, `.claude-multi-session/workflow.md`, and `set_summary` to declare your Reviewer role. The audit produced without role context tends to drift.
- If `.claude-multi-session/` doesn't exist, the project hasn't been scaffolded — tell the user to run `/multi-session:init` first. Stop.

### 1. Pre-flight check

- If `PROGRESS.md` already exists and lacks an explicit "audit phase complete" marker in the `## 現在進度` line, **stop and ask the user** before overwriting. Show them the existing file.
- If working tree has uncommitted changes, mention this in your final report but proceed.

### 2. Build a mental map

- Read project manifests: `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / `*.csproj` / etc — identify tech stack
- Read `README.md` for stated purpose and current state
- Read `CLAUDE.md` for project-specific rules (if present)
- Use Glob / Grep to walk the main source directories. Build a one-paragraph mental model of architecture (entry points, key modules, data flow).

### 3. Produce 5-8 milestone candidates

Each milestone must have all of:

- **ID**: `Mn.m` (n is theme cluster, m is sub-step). Cluster related milestones (M1.1, M1.2, M1.3 = same theme, can be sequenced or paralleled within theme).
- **Description**: 1-2 lines, action-oriented (start with verb: "Add", "Refactor", "Replace", "Test", "Document", "Remove").
- **Expected files**: explicit list of paths the worker is expected to touch. Tight is better than loose. Prefer 1-5 files; if a milestone touches >10 files, break it down further.
- **Acceptance criteria**: 2-3 concrete bullets. Each must be testable by a Reviewer reading `git diff` + running the build, without requiring the milestone author's verbal explanation.
- **Effort**: `S` (<1 hour), `M` (1-3 hours), or `L` (>3 hours). Prefer S/M; an `L` milestone should be broken down if possible.
- **ROI**: `high` / `medium` / `low` with a one-sentence justification (impact on users, devs, or future velocity).

Sweet spot: 5-8 milestones. Fewer = audit too shallow. More = audit lost focus.

### 4. Compute worker recommendation

Analyze file-region overlap between the milestones you proposed:

- Build a mental graph: milestone → set of expected files
- Count maximum independent set (milestones whose file sets don't overlap with each other)
- That's the upper bound on useful parallelism
- Recommend `min(max_independent_set, 3)` workers — beyond 3, Reviewer typically becomes the bottleneck

State this explicitly in the report, e.g.:

> **Recommended worker count: 3.** Out of 6 milestones, the maximum independent file-region set is 3 (M1.1, M2.1, M3.1 — touch entirely separate files). M1.2 / M1.3 depend on M1.1 and must be sequenced.

If max independent set is 1 (all milestones touch the same hot file), recommend single-worker execution and call this out as a workflow concern.

### 5. Write `PROGRESS.md`

Format (frontmatter is the machine-readable skip-list per the workflow spec):

```markdown
---
skipped: []
in_progress: []
completed: []
---

# PROGRESS

## 現在進度

audit phase complete — awaiting user to select milestones for dispatch.

## Audit summary

- **Project**: <name + one-line purpose>
- **Tech stack**: <list>
- **Architecture quick-take**: <one paragraph>
- **Recommended worker count**: <N> (see analysis below)

## Milestones

### M1.1 — <description>
- **Expected files**: `<path1>`, `<path2>`
- **Acceptance**:
  - <criterion 1>
  - <criterion 2>
- **Effort**: <S/M/L>
- **ROI**: <high/medium/low> — <one-sentence justification>

### M1.2 — ...
(repeat for each milestone)

## Parallelism analysis

- Max independent file-region set: <N> milestones
- Sequencing constraints:
  - M1.2 depends on M1.1 (both touch `<file>`; M1.2 builds on M1.1's API change)
  - M3.1 should be sequenced after M2.1 if both touch <shared resource>
- **Recommendation**: spin up <N> workers (`claude-peers -id sessionA / sessionB / ...`)

## 待用戶決定 / Pending user decision

- <design question 1>
- <design question 2>

(Leave this empty if no judgment calls; don't pad.)

## 設計決策變更紀錄 / Decision changelog

(Empty at audit time; Reviewer appends as decisions are made during dispatch.)
```

### 6. Report and stop

Print a summary to the user:
- Path to the produced `PROGRESS.md`
- Milestone count + recommended worker count
- Top 1-2 "待用戶決定" items (if any)
- Suggested next action (e.g. "Open N more terminals, run `claude-peers -id sessionA` etc., then come back and tell me which milestones to dispatch.")

**Do not** dispatch work yourself. **Do not** call `send_message` to peers (there are none yet, this is solo audit). **Do not** start writing code for any milestone.

## Behavior rules

- Stay strictly in audit mode. Resist suggesting "while I'm here, let me fix this typo" — that's scope creep that defeats the audit.
- If you find a critical bug during audit (e.g. security hole, broken build), surface it in the report but still don't fix it inline; it becomes its own M-numbered milestone.
- If the project is so small there are <5 reasonable milestones, say so — don't pad with low-value busywork.
- If the project state is "completely done, no obvious next step", report this and ask the user what direction they want (refactor / new feature / hardening / docs).
