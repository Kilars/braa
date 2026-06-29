---
name: start-working
description: Autonomously execute ALL tasks from the backlog until complete. Runs in a continuous loop — picks task, implements via subagent, moves to done, commits (caveman message) and pushes, repeats. No user prompts between tasks. Follows task-board workflow (backlog -> in-progress -> done).
---

# Start Working Skill

This skill **autonomously executes ALL tasks** from the task board until the backlog is empty. It runs in a continuous loop without stopping between tasks.

**Task Board Flow**: `.task-board/backlog/` -> `.task-board/in-progress/` -> `.task-board/done/`

---

## CRITICAL RULES

### 1. USE THE TASK BOARD SYSTEM
**ALL work flows through `.task-board/`** — non-negotiable.
- Tasks live in: `backlog/` -> `in-progress/` -> `done/`
- `PLANNING-BOARD.md` is the source of truth for priorities
- **NEVER work on something not tracked in the task board**
- Update task files with progress as you work

### 2. GIT: ONE CAVEMAN COMMIT + PUSH PER TASK (MAIN AGENT ONLY)
The **main agent commits exactly once per completed task and then pushes** — after
the task is verified and moved to `done/` (see Step 9b). Nothing else touches git.
- **Subagents NEVER use git** — no `git` of any kind in subagent prompts.
- Main agent uses **only** `git add` + `git commit` + `git push`. **No**
  `git checkout`, `git branch`, `git reset`, `git rebase`, or force-anything.
- One commit = one task: stage the task's code changes **and** the moved task
  file + board update together, commit, push, then start the next task.
- **Commit message is caveman language** — see [Caveman Commit Format](#caveman-commit-format).
- Only commit and push a **verified, complete** task (Step 8 passed). Push the
  current branch to its tracked upstream (`git push`) — never force-push.

### 3. USE SUBAGENTS FOR EACH TASK
Each task MUST be executed using the **Agent tool** with a subagent:
- **Default model: `haiku`** — fast and efficient for most tasks
- **Use `sonnet` only for**: Complex business logic, architectural decisions, intricate logic
- **ALWAYS include project context** (the spec in `.docs/specs/` + the `adr/` ADRs) in subagent prompts

### 4. TASKS ARE DONE IN ORDER
Tasks are numbered for dependency reasons. Execute them **sequentially, in order**:
- Pick task 001 -> Complete -> Pick task 002 -> Complete -> Pick task 003...
- **NEVER skip ahead** unless user explicitly requests it
- **NEVER run tasks in parallel**

### 5. VERIFY BEFORE MARKING COMPLETE
Every task MUST be verified before marking complete via the **Godot gate**:
`nix develop -c bash verify.sh` (import → boot `main.tscn` → headless GDScript
tests → Web/PWA export, fail-closed). The spec lives in `.docs/specs/`; technical
conventions (engine, stack, asset pipeline) live in the ADRs under `adr/`.

**Tasks where the verify gate is not green are INCOMPLETE.**

### 6. ALWAYS PREFER TOOLS OVER BASH
Subagents MUST use built-in tools instead of bash equivalents.

| NEVER USE | ALWAYS USE |
|-----------|------------|
| `cat`, `head`, `tail` | **Read** tool |
| `echo >`, `cat <<EOF` | **Write** tool |
| `sed`, `awk` | **Edit** tool |
| `find`, `ls` (for search) | **Glob** tool |
| `grep`, `rg` | **Grep** tool |

### 7. FUNCTIONAL CODE IS TEST-FIRST (TDD)
All **functional / game-logic** code MUST be written test-first per the **`tdd`** skill
([`.claude/skills/tdd/SKILL.md`](../tdd/SKILL.md)) — that skill is the **single source of
truth** for the red-green-refactor mechanics; don't re-derive them here.
- Pure rendering / 3D / asset glue is exempt (covered by Visual Review).
- A functional task that ships without tests is **INCOMPLETE**.

### 8. INTERACTIVE VS AUTONOMOUS — FLAG, DON'T BLOCK
This skill runs two ways: **interactively** (a user invoked it) and **autonomously** (the
headless build loop drives it, no user present). Several Workflow steps below say "ask the
user" — that means:
- **Interactive:** ask the user directly and wait.
- **Autonomous:** **NEVER stop to wait.** Make the best-supported assumption, record it in
  the task file's Context/Progress, and keep going. If the open question is genuinely
  **user-only** — a product / scope / legal / asset / owner decision, or an ambiguity whose
  answers lead to materially different outcomes (not a technical fork you can reason out) —
  AND you (the orchestrator) judge it material, **raise a flag** in `.task-board/FLAGS.md`
  per its protocol, then continue. Flags are **async and non-blocking** — they never halt
  the loop. (The flag file rides the per-task `git add -A` commit, so the user sees it.)

---

## When to Use This Skill

Use when the user says:
- "Start working" / "Start implementing"
- "Continue work" / "Keep going"
- "Pick up the next task"
- "Work on the planning board items"

## The Workflow

### Step 1: Check Current Priorities

Read `.task-board/PLANNING-BOARD.md` to see what's next.

**If PLANNING-BOARD is empty**: interactive → ask if the user wants to populate it from the
backlog; autonomous → populate it from the backlog (top priorities) and continue (Rule 8).

### Step 2: Select Top Priority

Pick the **first numbered item** from the planning board (unless blocked).

**Decision criteria**:
- Is it blocked by dependencies?
- Are all prerequisites met? (check task file's Dependencies section)
- Is the scope clear and actionable?

### Step 3: Move to In-Progress

Move the task file from `.task-board/backlog/` to `.task-board/in-progress/`.

**Important**: Limit in-progress to **1 task**. If in-progress already has tasks: interactive
→ ask the user; autonomous → finish and move that stray task first, or flag it per Rule 8 if
it looks abandoned, then proceed.

### Step 4: Read the Task File

Understand the full task:
- Context & Motivation
- Acceptance Criteria (checkboxes to complete) — **MUST be at the bottom of the task file**
- Technical Approach with **before and after code examples** for every code change
- Dependencies and risks

### Step 5: Clarify Uncertainties

If the task is ambiguous, has multiple viable approaches, unclear dependencies, or seems too
large:
- **Interactive:** STOP and ask the user.
- **Autonomous:** do not stop — proceed on the best-supported assumption (recorded in the
  task file), and if it's a genuinely user-only decision you judge material, raise a flag in
  `.task-board/FLAGS.md` (Rule 8). Then continue.

### Step 6: Assess Complexity

**If task is too complex**: Break it into sub-tasks, create new files in `backlog/`, update PLANNING-BOARD.md.

### Step 7: Spawn Subagents (TDD: test-first, then impl)

For **functional / game-logic tasks**, run two subagents in sequence:

**Step 7a — Test-writer (Haiku)**
```
Agent tool:
  subagent_type: "general-purpose"
  model: "haiku"
  description: "Write failing tests for <task>"
  prompt: <shared preamble + Test-Writer block — see Subagent Prompt Templates below>
```
Wait for completion. Confirm tests exist and fail before proceeding.

**Step 7b — Implementation (Haiku or Sonnet)**
```
Agent tool:
  subagent_type: "general-purpose"
  model: "haiku" (default) or "sonnet" (complex logic)
  description: "Implement <task> to pass tests"
  prompt: <shared preamble + Implementation block — see Subagent Prompt Templates below>
```

For **rendering / 3D / asset tasks** (TDD-exempt): skip Step 7a, run only Step 7b.

For **`SPIKE-` tasks** (research, TDD-exempt): skip Step 7a. Run a **single timeboxed
research subagent (one pass)** that investigates feasibility / approach and writes
**findings + a recommendation** into the task file. A spike ships **no product code** — its
outcome is either a new **build task** in `backlog/` or an **informed flag** in
`.task-board/FLAGS.md` (with the findings attached). Record the findings + routing, then move
the spike to `done/`. (Spikes are the first handling of a research-class unknown — they come
*before* a "can't do it" flag; see `process/mother_prompt.md`.)

### Step 8: Verify Completion

After subagents return, verify:
1. All acceptance criteria checked off in the task file
2. Project builds successfully
3. Tests pass — and functional code was written test-first (TDD), not after
4. Code follows project conventions (see `.docs/specs/` + the `adr/` ADRs)
5. **Placeholder check** — grep the task's diff for the placeholder/stub list (CLAUDE.md
   "Placeholder check at done"); an un-allowlisted hit means the task is **not done** (fix
   it, or — if owner-gated — it should have gone spike → flag, not shipped as a stub)

### Step 9: Complete and Move to Done

1. **Update Resolution section** in the task file with implementation summary
2. **Move file** from `.task-board/in-progress/` to `.task-board/done/`
3. **Update PLANNING-BOARD.md**: remove completed item, add to "Recently Completed"

### Step 9b: Commit and Push the Task (caveman, main agent only)

Only after Step 8 passed (verified, complete), the **main agent** makes exactly
**one commit** capturing this task end-to-end, then pushes it:

1. `git add -A` — stage code changes, tests, the moved task file, and the board update
2. `git commit` with a **caveman-language** message — see
   [Caveman Commit Format](#caveman-commit-format)
3. `git push` — push the current branch to its tracked upstream (never force-push)
4. **Confirm it landed**: `git push` exits 0 **and** `git status --porcelain` is
   empty. If either fails, the task is NOT done — fix and re-push before moving on.
   Leaving committed-but-unpushed or uncommitted work is a loop failure: the
   review model is *push → CI exports → father reviews the live site*, so an
   unpushed task is invisible and effectively undone.

One task = one commit + one push. Subagents never touch git. Then
**IMMEDIATELY start next task** — no waiting for user confirmation.

### Step 10: Loop

Continue to the next task. **DO NOT STOP between tasks.** Continue until:
- All tasks in PLANNING-BOARD are complete, OR
- A critical blocker prevents progress, OR
- User explicitly interrupts

---

## Caveman Commit Format

Commit messages use **caveman language** (the global `caveman` skill style):
terse, lowercase, present tense, no articles, no filler, no ceremony. Say what
changed, that it works, and which task — nothing else.

**Subject shape**: `<task-id>: <what changed>. <verify state>.`

**Examples**:
- `075: add confuse debuff to train loop. tests green.`
- `082: gate breed adopt by level. verify pass.`
- `090: fix bra ring no pulse on untrain. test added. verify pass.`

Rules:
- Subject line only for small tasks; for multi-part work add caveman body lines
  (one change per line), still terse.
- No `feat:`/`fix:` prefixes, no fluff (`this commit`, `we now`, `update`), no emoji.
- Always state the verify result (`tests green` / `verify pass`) so history proves it built.
- End the message with the trailer: `Co-Authored-By: Claude <noreply@anthropic.com>`

---

## Subagent Prompt Templates

Both subagents get the **shared preamble** first, then their role block. Paste the
preamble verbatim at the top of the prompt, then append the matching role block.

### Shared preamble (paste into both)

```
PROJECT CONTEXT:
- Read the spec in .docs/specs/ for the full specification (phased user stories)
- Read the adr/ ADRs for technical conventions (engine, stack, asset pipeline)

CRITICAL RESTRICTIONS:
1. NEVER use git commands.
2. Use built-in tools, never bash for file ops: Read (not cat/head/tail), Write
   (not echo/heredoc), Edit (not sed/awk), Glob (not find/ls), Grep (not grep/rg).
```

### Test-Writer block (Haiku) — append to the preamble

```
You are the TEST-WRITER for: .task-board/in-progress/{TASK-FILE}.md
Read the task file FIRST, plus .claude/skills/tdd/SKILL.md for TDD rules.
Your ONLY job is to write failing tests — no implementation code; they must be
RED (failing) when you finish.

YOUR TASK:
- Read the task's acceptance criteria and Technical Approach
- Write/extend ONE test file with failing tests covering every behavior listed
- Vertical-slice order (first behavior first); test public interfaces only
- Run the gate (`nix develop -c bash verify.sh`) to confirm the new tests FAIL (red)

Summarize: test file touched · number of failing tests + what each covers ·
the red test-runner excerpt (short).
```

### Implementation block (Haiku/Sonnet) — append to the preamble

```
You are the IMPLEMENTATION agent for: .task-board/in-progress/{TASK-FILE}.md
Failing tests already exist. Make them pass with minimal code.
- CHECK OFF acceptance criteria as you go (change [ ] to [x])
- Write ONLY enough code to pass the current failing tests — no speculation

YOUR TASK:
- Make each failing test pass, one at a time (vertical slices)
- After green, look for refactor opportunities (keep tests green)
- VERIFY with the gate `nix develop -c bash verify.sh` (import → boot → tests →
  Web/PWA export, fail-closed); report the final `verify gate green` line only.

Summarize: files touched · acceptance-criteria status · gate result
(`verify gate green` or failing leg) · issues hit.
```

---

## Handling Edge Cases

### If PLANNING-BOARD is Empty
Interactive: ask the user to populate it / offer to add top backlog items. Autonomous:
populate it from the backlog and continue — no prompt (Rule 8).

### If Top Priority is Blocked
Identify the blocker and check whether a blocker task exists. Interactive: ask the user.
Autonomous: park the blocked task in `.task-board/on-hold/`, keep every other task moving,
and — if clearing the block needs a user / owner decision — raise a flag in
`.task-board/FLAGS.md` (Rule 8). Never let one blocked task stall the loop.

### If Task is Too Large
Break into sub-tasks (e.g., 003a, 003b), create new files, update PLANNING-BOARD.md.

### If the Verify Gate Fails After Implementation
Fix the issues before marking complete. Re-run `nix develop -c bash verify.sh`.

---

## Success Criteria

### Per Task:
- [ ] Task comes from `.task-board/`
- [ ] Subagents used NO git commands
- [ ] Executed via subagent (Agent tool)
- [ ] Built-in tools used (no bash for file ops)
- [ ] All acceptance criteria checked off in task file
- [ ] Project builds successfully
- [ ] Functional code written test-first (TDD); tests pass
- [ ] Task file updated with Progress Log and Resolution
- [ ] Task moved to `.task-board/done/`
- [ ] One caveman commit by main agent (code + tests + task move), then pushed

### Per Session:
- [ ] All work tracked in `.task-board/`
- [ ] Git touched only by main-agent commits — one commit + push per task
- [ ] ALL tasks processed automatically (no stopping between tasks)
- [ ] Tasks processed IN ORDER from PLANNING-BOARD.md
- [ ] PLANNING-BOARD.md updated after each completion

## See Also

- [`.task-board/PLANNING-BOARD.md`](../../../.task-board/PLANNING-BOARD.md) — Current priorities
- [`.docs/specs/`](../../../.docs/specs/) — Full project specification (phased user stories)
- [`adr/`](../../../adr/) — Technical decisions (engine, stack, asset pipeline)
- [`.claude/skills/task-board/SKILL.md`](../task-board/SKILL.md) — Planning skill
- [`.claude/skills/scan-project/SKILL.md`](../scan-project/SKILL.md) — Project scanning skill