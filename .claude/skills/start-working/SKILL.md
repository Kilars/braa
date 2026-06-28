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
- **ALWAYS include project context** (`specs2.md` + the `adr/` ADRs) in subagent prompts

### 4. TASKS ARE DONE IN ORDER
Tasks are numbered for dependency reasons. Execute them **sequentially, in order**:
- Pick task 001 -> Complete -> Pick task 002 -> Complete -> Pick task 003...
- **NEVER skip ahead** unless user explicitly requests it
- **NEVER run tasks in parallel**

### 5. VERIFY BEFORE MARKING COMPLETE
Every task MUST be verified before marking complete via the **Godot gate**:
`nix develop -c bash verify.sh` (import → boot `main.tscn` → headless GDScript
tests → Web/PWA export, fail-closed). The spec is `specs2.md`; technical
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
All **functional / game-logic** code MUST be written test-first using the
**`tdd`** skill (red-green-refactor, vertical slices). See
[`.claude/skills/tdd/SKILL.md`](../tdd/SKILL.md).
- One failing test -> minimal code to pass -> repeat. **No horizontal slicing.**
- Pure rendering / 3D / asset glue is exempt (covered by Visual Review).
- A functional task that ships without tests is **INCOMPLETE**.

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

**If PLANNING-BOARD is empty**: Ask if the user wants to populate it from the backlog.

### Step 2: Select Top Priority

Pick the **first numbered item** from the planning board (unless blocked).

**Decision criteria**:
- Is it blocked by dependencies?
- Are all prerequisites met? (check task file's Dependencies section)
- Is the scope clear and actionable?

### Step 3: Move to In-Progress

Move the task file from `.task-board/backlog/` to `.task-board/in-progress/`.

**Important**: Limit in-progress to **1 task**. If in-progress already has tasks, ask the user.

### Step 4: Read the Task File

Understand the full task:
- Context & Motivation
- Acceptance Criteria (checkboxes to complete) — **MUST be at the bottom of the task file**
- Technical Approach with **before and after code examples** for every code change
- Dependencies and risks

### Step 5: Clarify Uncertainties

**STOP and ask the user if**:
- The task is ambiguous
- Multiple approaches are possible
- Dependencies are unclear
- Scope seems too large

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
  prompt: <see Test-Writer Prompt Template below>
```
Wait for completion. Confirm tests exist and fail before proceeding.

**Step 7b — Implementation (Haiku or Sonnet)**
```
Agent tool:
  subagent_type: "general-purpose"
  model: "haiku" (default) or "sonnet" (complex logic)
  description: "Implement <task> to pass tests"
  prompt: <see Implementation Prompt Template below>
```

For **rendering / 3D / asset tasks** (TDD-exempt): skip Step 7a, run only Step 7b.

### Step 8: Verify Completion

After subagents return, verify:
1. All acceptance criteria checked off in the task file
2. Project builds successfully
3. Tests pass — and functional code was written test-first (TDD), not after
4. Code follows project conventions (see `specs2.md` + the `adr/` ADRs)

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

## Test-Writer Prompt Template

```
You are the TEST-WRITER for the task:
.task-board/in-progress/{TASK-FILE}.md

Read the task file FIRST. Your ONLY job is to write failing tests — no implementation.

PROJECT CONTEXT:
- Read specs2.md for the full specification (phased user stories)
- Read the adr/ ADRs for technical conventions (engine, stack, asset pipeline)
- Read .claude/skills/tdd/SKILL.md for TDD rules

CRITICAL RESTRICTIONS:
1. NEVER use git commands
2. Use Read tool (NOT cat/head/tail)
3. Use Write tool (NOT echo/cat heredoc)
4. Use Edit tool (NOT sed/awk)
5. Use Glob tool (NOT find/ls for search)
6. Use Grep tool (NOT grep/rg bash commands)
7. DO NOT write any implementation code — tests only
8. Tests must be RED (failing) when you finish

YOUR TASK:
- Read the task's acceptance criteria and Technical Approach
- Write one test file (or extend the relevant test file) with failing tests
  covering all the behaviors listed in the task
- Follow vertical-slice order: first behavior first, last behavior last
- Test through public interfaces only — no testing internals
- Run the Godot gate (`nix develop -c bash verify.sh`) to confirm the new tests
  exist and FAIL (red) — the test leg runs the headless GDScript runner

Provide a summary of:
- Test file created/modified
- Number of failing tests written and what each covers
- The test-runner output showing red failures (short excerpt only)
```

---

## Implementation Prompt Template

```
You are the IMPLEMENTATION agent for the task:
.task-board/in-progress/{TASK-FILE}.md

Failing tests are already written. Your job is to make them pass with minimal code.

PROJECT CONTEXT:
- Read specs2.md for the full specification (phased user stories)
- Read the adr/ ADRs for technical conventions (engine, stack, asset pipeline)

CRITICAL RESTRICTIONS:
1. NEVER use git commands
2. Use Read tool (NOT cat/head/tail)
3. Use Write tool (NOT echo/cat heredoc)
4. Use Edit tool (NOT sed/awk)
5. Use Glob tool (NOT find/ls for search)
6. Use Grep tool (NOT grep/rg bash commands)
7. CHECK OFF acceptance criteria as you complete them (change [ ] to [x])
8. Write ONLY enough code to pass the current failing tests — no speculation

YOUR TASK:
- Read the task file and existing test file
- Make each failing test pass, one at a time (vertical slices)
- After all tests pass, look for refactor opportunities (but keep tests green)

VERIFY: run the Godot gate `nix develop -c bash verify.sh` (import → boot →
GDScript tests → Web/PWA export, fail-closed). DO NOT paste full logs — report
the final `verify gate green` line (and the failing leg's detail if any).

Provide a summary of:
- Files created/modified
- All acceptance criteria status (checked off in task file)
- The verify gate result (`verify gate green`, or which leg failed)
- Any issues encountered
```

---

## Model Selection

| Role | Model | Examples |
|------|-------|---------|
| **Test-writer** | `haiku` | Always — writing failing tests is a focused, well-scoped task |
| **Implementation (standard)** | `haiku` | Simple classes, interfaces, basic implementations, file operations |
| **Implementation (complex)** | `sonnet` | Complex business logic, multi-file architectural decisions, intricate parsing |

---

## Handling Edge Cases

### If PLANNING-BOARD is Empty
Ask the user to populate it or offer to add top backlog items.

### If Top Priority is Blocked
Identify the blocker, check if the blocker task exists, and ask the user.

### If Task is Too Large
Break into sub-tasks (e.g., 003a, 003b), create new files, update PLANNING-BOARD.md.

### If the Verify Gate Fails After Implementation
Fix the issues before marking complete. Re-run `nix develop -c bash verify.sh`.

### Verification command
Use the Godot gate: `nix develop -c bash verify.sh` — four fail-closed legs in
order (import resources → boot `main.tscn` headless → headless GDScript test
runner → Web/PWA export + bundle-exists). Success ends with `verify gate green`;
any failing leg aborts (`set -e`) and prints that leg's output. Report only the
final line plus any failing-leg detail — don't paste full logs.

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
- [`specs2.md`](../../../specs2.md) — Full project specification (phased user stories)
- [`adr/`](../../../adr/) — Technical decisions (engine, stack, asset pipeline)
- [`.claude/skills/task-board/skill.md`](../task-board/skill.md) — Planning skill
- [`.claude/skills/scan-project/SKILL.md`](../scan-project/SKILL.md) — Project scanning skill