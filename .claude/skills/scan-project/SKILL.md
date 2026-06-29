---
name: scan-project
description: Scans the project to find gaps between specs and implementation, identifies bottlenecks, reviews code quality and readability, checks best practices, and generates 3 prioritized tasks per round via the task-board skill.
---

# Scan Project

Autonomous project scanner that analyzes your codebase from multiple angles and generates actionable tasks.

**PLANNING ONLY — NO IMPLEMENTATION**
This skill creates task files via the `task-board` skill. It does NOT write code.

## What This Skill Does

1. **Spec vs Implementation gap analysis** — compares the spec in `.docs/specs/` against actual code to find missing or incomplete features
2. **Code quality & readability review** — finds bottlenecks, code smells, and readability issues
3. **Best practices audit** — checks for consistent patterns, naming, error handling, test quality
4. **Task generation** — produces 3 prioritized, actionable tasks per scan round

## When to Use This Skill

**Use this skill when**:
- Starting a new development phase
- Backlog is stale or empty
- Want to discover gaps between spec and implementation
- Need to find bottlenecks or performance issues
- Want a code quality and readability audit
- Looking for changes that could improve readability or maintainability
- Need a best practices review
- Running `/scan-project` slash command

**DO NOT use this skill for**:
- Creating a single specific task -> use `task-board` skill directly
- Implementing tasks -> this skill only discovers and plans
- Quick bug fixes -> just fix them directly

## Scan Workflow

### Phase 1: Load Context

Before any analysis, load ALL context:

1. **Read specification**: the spec in `.docs/specs/` — `index.md` (the shared frame:
   North Star, Cross-cutting, Non-Goals + a phase index), the relevant `phaseN.md`, and
   `po-review.md` (the PO's buildable directives)
2. **Read technical conventions**: the ADRs in `adr/`
3. **Scan completed tasks**: `.task-board/done/` (learn what's already done)
4. **Scan existing backlog**: `.task-board/backlog/` + `.task-board/in-progress/` + `.task-board/on-hold/`
5. **Note available skills**: Check `.claude/skills/` for delegation
6. **Determine the current phase**: the **current phase** is the lowest-numbered `phaseN.md` whose stories are not yet fully implemented. Extract its stories plus `## North Star`, `## Cross-cutting` (applies to every phase), and `## Non-Goals` (all in `index.md`); keep them in context for Phase 4 eligibility filtering. Per the spec's phasing rule, **nothing past the current phase starts until the current phase is complete** — later `phaseN.md` files and `beyond.md` are out of scope this round.
7. **Compute domain saturation**: Count the last 15 done tasks by domain (visual/rendering, economy, audio, UI, logic, content, etc.). Note any domain with 3+ tasks — it is **saturated** and must be deprioritised in Phase 4 unless it is the only remaining gap in the current phase.

### Phase 2: Spec vs Implementation Gap Analysis

**Goal**: Produce a comprehensive gap report by comparing the spec in `.docs/specs/` against the actual codebase.

Use a **subagent** (Agent tool, model: `sonnet`) to perform this analysis. The subagent should:

0. **Scaffolding / core-loop check** — Before the full matrix, answer ONE question:
   - **If there is no runnable app yet** (no `project.godot`, or `verify.sh`'s gate doesn't pass: import → boot `main.tscn` → headless GDScript tests → Web/PWA export): the **P0 is project scaffolding** — a bootable Godot project plus the headless verify gate, so later iterations can build, gate, and (eventually) be play-tested. This overrides all other findings.
   - **If the app runs**: answer "Can a player experience the **current phase's** core loop end-to-end in the running app (for Phase 1: offer → apex tell → tap BRA → score/learn → payout)?" If NO, identify the specific broken step and flag it as **P0** — it overrides all other findings in Phase 4.

1. **Read the spec** end-to-end — the current phase's `.docs/specs/phaseN.md`, plus `.docs/specs/index.md` (cross-cutting + Non-Goals) and `.docs/specs/po-review.md` (PO directives) — and extract every specified feature, interface, model, behavior, and non-functional requirement into a checklist.

2. **Scan all source code** — list every source file, read key files, and map what exists:
   - Classes, modules, components, functions
   - Key interfaces and their implementations
   - Test files and what they cover
   - TODOs, FIXMEs, HACK comments

3. **Build a Spec Coverage Matrix** — for each item from the spec, mark its status:

   | Spec Item | Status | Evidence |
   |-----------|--------|----------|
   | Feature X | Implemented / Partial / Missing / N/A | File path or note |

   Categories to cover:
   - Core features listed in the spec
   - Architecture layers and components
   - Interfaces and contracts specified
   - Test coverage specified
   - Non-functional requirements (readability, conventions, etc.)

4. **Return the matrix** and a summary of the top gaps, ordered by impact.

### Phase 3: Code Quality, Readability & Best Practices Review

**Goal**: Evaluate the GDScript for quality and readability. Find opportunities to make
the code better — tuned to this project, not a generic web-app checklist.

**GDScript readability & style**:
- Descriptive names, consistent casing; small single-purpose functions
- Self-documenting code — comments only for "why", not "what"
- Magic numbers homed in named constants, not scattered literals (cf. task 029)

**Structure (the project's pattern)**:
- Pure logic lives in its own class and is unit-testable; `main.gd` stays thin scene/node
  glue. Flag fat logic baked into `main.gd` that should be extracted to a pure class.
- **Dog logic is dog-agnostic & clip-name-driven** — never hardcode a fake sit or a clip
  index. Flag any sit/anim logic that assumes a specific model instead of resolving by
  clip name (cf. `DogClips.resolve`, ADR-0006 / CC0-vs-licensed split).
- No duplicated logic (cf. task 028's shared test-mount + finder consolidation).

**Test honesty (this harness has bitten before)**:
- The headless runner hides runtime `SCRIPT ERROR`s as hollow green — a `test_*` that ends
  with **zero assertions** must fail (cf. task 026). Flag hollow/assertion-free tests.
- `.play()` and `_init` `add_child` don't work headless — guard `.play()` on
  `is_inside_tree()`, attach lazily.
- Tests assert observable behavior through public interfaces, not internals.

**Asset integrity** (cf. CLAUDE.md "Don't fake assets"):
- No bare primitive geometry standing in for the dog — not even for one frame. Flag any
  placeholder/faked artifact or self-certified "fix" left as a stub.

**Code smells**: god functions, deep nesting, long parameter lists, swallowed errors
(silent `pass` on failure), dead seams with no caller.

### Phase 4: Task Generation (3 tasks per round)

From the gaps and quality issues found, select the **3 most impactful tasks**.

**Pre-selection filters (apply BEFORE ranking)**:

- **Phase scope gate**: Stories from any phase **later** than the current phase (and the parked `## Beyond the phases` section) are **ineligible** until every story in the current phase is implemented and passes its acceptance criteria. The spec is explicit: "Phase 1 is the whole bet … Nothing past Phase 1 starts until Phase 1 passes its Visual Review and is bug-free." Placeholder art is acceptable in early phases — nail the feel first; visual refinements beyond basic readability wait for later phases.
- **Domain saturation filter**: If a domain was marked saturated in Phase 1 (3+ of the last 15 done tasks), do NOT select another task from it unless it is the only remaining gap in the current phase. Log the reason if overriding.
- **Anti-polish heuristic**: Pure visual refinements (flourishes, idle animations, coat variations, look-around behaviors) are ineligible when any v1 core gameplay feature or user-facing flow is incomplete.

**Selection criteria** (prioritize in order, after filters):
1. **P0 scaffolding / core-loop break**: If Phase 2 flagged missing scaffolding or a broken end-to-end flow, fix that first — no other tasks.
2. **Blocking dependencies**: Infrastructure/foundation that other features need
3. **Current-phase spec gaps over quality**: Missing current-phase features before polish
4. **High impact, right size**: Not epic-sized, not trivial
5. **Progressive**: Build on what exists, don't leap ahead

**Quality bar** (ALL must be met):
- Clear value: Obvious benefit or v1 spec alignment
- Well-scoped: Completable in one focused session
- Actionable: Can implement without major unknowns
- Non-redundant: Not covered by existing task

**For each of the 3 tasks**:
1. Invoke `task-board` skill with full context
2. Include: what it addresses (spec gap, quality issue, bottleneck), why it's prioritized now, technical approach hints
3. Assign sequential number (scan ALL `.task-board/**/*.md` for highest existing number)

**Task file format requirements**:
- Acceptance criteria MUST appear at the bottom of the task file as checkboxes (`- [ ]`)
- All code changes MUST be represented with **before and after examples** in the Technical Approach section
- **Functional / game-logic tasks MUST be test-first (TDD):** the Technical
  Approach names the behaviors to test, and the acceptance criteria include the
  failing-test-first steps. Reference the `tdd` skill
  (`.claude/skills/tdd/SKILL.md`). Pure rendering/3D/asset tasks are exempt (they
  get a Visual Review acceptance criterion instead).

### Phase 5: Update Planning Board

After creating tasks, update `.task-board/PLANNING-BOARD.md` with:
- Current top 3 priorities (the tasks just created)
- Any recently completed work from `done/`
- Current focus area

## Numbering Protocol

**CRITICAL**: Never reuse numbers.

```
1. Glob: .task-board/**/*.md
2. Scan ALL folders: backlog/ + in-progress/ + done/ + on-hold/
3. Find highest number
4. Next task = highest + 1
```

File format: `NNN-TYPE-description.md`
- `001-FEATURE-project-scaffolding.md`
- `002-REFACTOR-naming-consistency.md`
- `003-QUALITY-test-coverage.md`

## Output

Summary report with:
- Spec coverage overview (X of Y spec items implemented)
- Top code quality and readability findings
- Bottlenecks or best practice violations found
- 3 tasks created (number, type, title, priority)
- Recommended implementation order
- What to focus on in the next scan round

## Delegates To

- `task-board` skill — for creating detailed plan files
