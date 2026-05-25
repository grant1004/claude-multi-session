---
allowed-tools: Bash, Read, Glob, Grep, Edit, Write, AskUserQuestion, ToolSearch
description: Reviewer audit phase — survey a project and produce PROGRESS.md with milestone candidates + recommended worker count
---

## Context

- Project root: !`pwd`
- Working tree state: !`git status --short 2>/dev/null || echo "(not a git repository)"`
- Recent commits: !`git log --oneline -20 2>/dev/null || echo "(no commits yet — fresh repo)"`
- Existing `PROGRESS.md`: !`test -f PROGRESS.md && echo "yes (will refuse to overwrite without --force)" || echo "no"`
- Existing `CLAUDE.md`: !`test -f CLAUDE.md && head -5 CLAUDE.md || echo "(none)"`

## Your task

You are the **Reviewer** running the audit phase. Survey this project and produce a `PROGRESS.md` with milestone candidates + a recommended worker count. Do **not** write any production code; only the audit artifact.

### 0. Onboarding (mandatory, no skipping)

These steps are not optional — do them every time, even if you "think you remember". Audit quality collapses without role context.

1. **Sanity check scaffold**. If `.claude-multi-session/` doesn't exist, tell the user to run `/multi-session:init` first. Stop.
2. **Read the role file in full**: `Read .claude-multi-session/roles/reviewer.md`
3. **Read the workflow state machine**: `Read .claude-multi-session/workflow.md`
4. **Read the dispatch + review templates** (you'll need them later): `Read .claude-multi-session/messages/dispatch.md` and `Read .claude-multi-session/messages/review-pass.md`
5. **set_summary** to declare your role: `set_summary("Reviewer — auditing <project basename>")`

### 1. Pre-flight check

- If `PROGRESS.md` already exists and lacks an explicit "audit phase complete" marker in the `## 現在進度` line, **stop and ask the user** before overwriting. Show them the existing file.
- If working tree has uncommitted changes, mention this in your final report but proceed.

### 2. Grill — user intent discovery (mandatory, do NOT skip)

Before scanning any code, establish user intent. Use `AskUserQuestion` to ask these 5 questions in a single call. Each question allows the user to answer freely or skip with "N/A".

| # | Question | Purpose |
|---|----------|---------|
| 1 | 這次 session 要達成什麼？ | Scoping — goals drive milestone priorities |
| 2 | 哪些東西不要動？ | Exclusion zones — prevents wasted work |
| 3 | 有什麼已經卡住或壞掉的？ | Pain points — may become high-ROI milestones |
| 4 | 品質標準是什麼？ | Calibrates acceptance criteria depth |
| 5 | 有 deadline 或外部限制嗎？ | Effort/sequencing constraints |

**Dual-mode trigger logic based on answers:**

- **User has a clear goal** (Q1 answer is specific): Build milestones around that goal. Code scanning serves to find the right files and boundaries — not to generate ideas.
- **User is exploratory** (Q1 answer is vague or "not sure"): Scan code and propose directions, but **present them for user confirmation before producing final milestones**. Use a follow-up `AskUserQuestion` to confirm which direction(s) to pursue.

Record all answers — they feed into the PROGRESS.md "已知限制" section and milestone scoping.

> **Design note**: This grill section is intentionally self-contained so it can later be extracted into a standalone `/multi-session:grill` command without surgery.

### 3. Detect mode: catchup vs new project

Check `git log` output from the Context section above:

- **Catchup mode** (commits exist beyond initial scaffold): This is a continuing project. Execute these extra steps in §4.
- **New project mode** (no commits or only init commit): Skip catchup-specific steps in §4. Proceed with standard code survey.

### 4. Build a mental map

#### 4a. codebase-memory integration (three-tier)

1. **Try**: Use `ToolSearch` to load `mcp__codebase-memory-mcp__get_architecture`. If available, call `get_architecture` to get project structure. Also load and use `search_graph` / `search_code` for targeted lookups as needed.
2. **Ask**: If codebase-memory tools are unavailable (ToolSearch returns nothing or the call errors), inform the user: "codebase-memory MCP 不可用，建議安裝以獲得更準確的架構分析。要繼續嗎？" Use `AskUserQuestion`.
3. **Fallback**: If the user declines or tools remain unavailable, fall back to Glob + Grep + Read to manually survey the codebase.

#### 4b. Standard survey (always)

- Read project manifests: `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / `*.csproj` / etc — identify tech stack
- Read `README.md` for stated purpose and current state
- Read `CLAUDE.md` for project-specific rules (if present)
- Walk main source directories. Build a one-paragraph mental model of architecture (entry points, key modules, data flow).

#### 4c. Catchup-mode extras (skip for new projects)

- `git log --stat -30` — identify recently changed files and commit patterns
- Read existing docs: prior `PROGRESS.md` (if any), `docs/session-logs/`, `docs/pitfalls/`
- Identify **hotspots**: top 3-5 files/modules changed most frequently in last 30 commits
- Synthesize: what's done, what's half-done, what's broken

### 5. Produce 5-8 milestone candidates

**Important**: Milestone generation is driven by user intent from the Grill (§2):
- If the user stated a clear goal → milestones serve that goal
- If the user was exploratory and confirmed a direction → milestones follow the confirmed direction
- Never produce milestones purely from "code smells" without user buy-in. Interesting improvements the user didn't ask for go into "待用戶決定", not as milestones.

Each milestone must have all of:

- **ID**: `Mn.m` (n is theme cluster, m is sub-step). Cluster related milestones (M1.1, M1.2, M1.3 = same theme, can be sequenced or paralleled within theme).
- **Description**: 1-2 lines, action-oriented (start with verb: "Add", "Refactor", "Replace", "Test", "Document", "Remove").
- **Expected files**: explicit list of paths the worker is expected to touch. Tight is better than loose. Prefer 1-5 files; if a milestone touches >10 files, break it down further.
- **Acceptance criteria**: 2-3 concrete bullets. Each must be testable by a Reviewer reading `git diff` + running the build, without requiring the milestone author's verbal explanation. **Embed test specs directly in the criteria** — if a criterion can be verified by running a command or test, write the verification inline (e.g., "`npm test -- --grep 'auth'` passes", "`curl localhost:3000/health` returns 200"). Do not create a separate test section. Do not use `[diff]` / `[test]` / `[run]` markers.
- **Effort**: `S` (<1 hour), `M` (1-3 hours), or `L` (>3 hours). Prefer S/M; an `L` milestone should be broken down if possible.
- **ROI**: `high` / `medium` / `low` with a one-sentence justification (impact on users, devs, or future velocity).

Sweet spot: 5-8 milestones. Fewer = audit too shallow. More = audit lost focus.

### 6. Compute worker recommendation

Analyze file-region overlap between the milestones you proposed:

- Build a mental graph: milestone → set of expected files
- Count maximum independent set (milestones whose file sets don't overlap with each other)
- That's the upper bound on useful parallelism
- Recommend `min(max_independent_set, 3)` workers — beyond 3, Reviewer typically becomes the bottleneck

State this explicitly in the report, e.g.:

> **Recommended worker count: 3.** Out of 6 milestones, the maximum independent file-region set is 3 (M1.1, M2.1, M3.1 — touch entirely separate files). M1.2 / M1.3 depend on M1.1 and must be sequenced.

If max independent set is 1 (all milestones touch the same hot file), recommend single-worker execution and call this out as a workflow concern.

### 7. Write `PROGRESS.md`

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
- **Hotspots**: <top 3-5 files/modules changed most in last 30 commits — omit in new-project mode>
- **現狀**: <what's done, what's half-done, what's broken — omit in new-project mode>
- **已知限制**: <user-stated exclusion zones (from Grill Q2) + constraints observed in code>
- **Recommended worker count**: <N> (see analysis below)

## Milestones

### M1.1 — <description>
- **Expected files**: `<path1>`, `<path2>`
- **Acceptance**:
  - <criterion 1 — include test command inline if verifiable>
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

### 8. Report and stop

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
- **Milestones must reflect user intent** (from the Grill). Code-smell improvements without user buy-in go into "待用戶決定", not as milestones.
