---
name: task-board
description: Planning specialist that creates structured implementation plans. Use this skill to transform user requests into comprehensive, well-researched plan files stored in .task-board/backlog/. This skill plans without implementing.
---

# Task-Board Planning Skill

This skill provides specialized workflows for creating and managing implementation plans. It transforms user requests into comprehensive, well-researched plan files that guide future implementation.

**CRITICAL CONSTRAINT**: This skill is for planning and documentation ONLY. Never implement fixes, write code changes, or modify the codebase. The sole responsibility is creating thorough plan documentation in `.task-board/backlog/`.

## When to Use This Skill

**Use this skill for**:
- Feature planning requiring technical design
- Refactoring plans needing impact assessment
- Exploration and research documentation
- Breaking down epics into implementation phases
- User requests that need structured planning

**DO NOT use this skill for**:
- Quick bug fixes (just implement directly)
- Simple changes with obvious implementation
- Active code implementation (skill is planning-only)
- Trivial updates that don't need planning
- AI scaffolding (CLAUDE.md, rules, skills) - update directly, no task

## Core Planning Principles

- **Research before planning**: Thoroughly explore the codebase before creating plan files
- **Ask clarifying questions**: Never assume — gather complete information from users
- **Break down complexity**: Decompose large features into manageable phases
- **Identify dependencies**: Map out external packages, internal dependencies, and blocking work
- **Document technical approach**: Include architecture decisions, file paths, and code references
- **Assess risks**: Identify what could go wrong and mitigation strategies
- **Plan-only**: Focus solely on designing the approach, not implementing

## Planning Workflow

### Phase 1: Initial Understanding (Gather Context)

1. **Read the request completely** (the user's, or — when invoked by `scan-project`
   in the autonomous loop — the gap/PO directive driving the task).
2. **Resolve scope**: problem being solved, what success looks like, constraints,
   priority. **Interactive:** ask the user. **Autonomous (no user):** do NOT block on
   questions — make the best-supported assumption and record it in the task file's
   Context section so the implementer can see it.
3. **Identify plan type**: Feature, bug, refactor, quality, exploration, or epic
4. **Assess size**: one focused session is the target (cf. `scan-project`'s "well-scoped"
   bar). Bigger than that → split into `NNNa`/`NNNb` sub-tasks.

### Phase 2: Codebase Research (Deep Exploration)

**CRITICAL**: Conduct thorough research before creating the plan file.

1. **Search for relevant code**:
   - Use search tools to find related features, components, or patterns
   - Look for similar implementations in the codebase
   - Check for existing utilities or shared components to reuse

2. **Read relevant files**:
   - Examine the feature area
   - Review related interfaces and implementations
   - Check for existing patterns and conventions

3. **Understand architecture**:
   - Read the spec in `.docs/specs/` for the project specification (phased user stories)
   - Read the `adr/` ADRs for technical conventions (engine, stack, asset pipeline)
   - Map the relevant layers and components

4. **Map dependencies**:
   - What external packages might be needed?
   - What internal features does this depend on?
   - Are there any blocking tasks?

5. **Identify risks**:
   - What could go wrong?
   - Are there performance concerns?
   - Security considerations?

### Phase 3: Approach Design (Technical Solution)

1. **Define architecture decisions**:
   - Where should code live?
   - What patterns to follow? (existing patterns in the codebase)
   - Interface design and dependency approach

2. **Order the work** (functional tasks are test-first per `tdd` — vertical slices,
   not a "write tests / then code / then polish" split).

3. **Plan implementation steps**:
   - List specific files to create or modify
   - Describe key changes needed in each file
   - Identify test scenarios

### Phase 4: Documentation (Create Plan File)

Create a comprehensive plan file in `.task-board/backlog/` with:

1. **Descriptive filename** following conventions (see File Naming Convention below)
2. **Complete template** with all sections filled (see template below)
3. **Specific technical details**: File paths, code snippets, architecture context

### Phase 5: Validation (Confirm Completeness)

Before finishing, verify:
- [ ] Scope is understood (or, headless, assumptions recorded in the task file)
- [ ] Technical approach is clear and feasible
- [ ] Specific file locations and paths included
- [ ] Before/After examples for every code change
- [ ] Acceptance criteria are concrete checkboxes at the **bottom** of the file
- [ ] Functional tasks are test-first (reference `tdd`); pure render/asset tasks
      get a Visual Review criterion instead
- [ ] Dependencies and risks identified
- [ ] Plan file created in `backlog/` with a non-reused `NNN`

## File Naming Convention

Use numbered, descriptive, kebab-case names with type prefix:

**Format**: `[NNN]-[TYPE]-[short-description].md`

### Task Numbering - CRITICAL

**ALWAYS scan ALL folders to find the next task number:**

```
1. Glob pattern: .task-board/**/*.md
2. Scan: backlog/, in-progress/, done/, AND on-hold/
3. Extract numbers from filenames (e.g., 003-FEATURE-xxx.md -> 003)
4. Find highest number across ALL folders
5. Next task = highest + 1
```

**Why include `done/`**: Completed tasks retain their numbers. Reusing numbers breaks history tracking.

### Type Prefixes

- `FEATURE-` — New functionality
- `BUG-` — Bug fixes
- `REFACTOR-` — Code improvements
- `TEST-` — Testing additions
- `SECURITY-` — Security work
- `PERF-` — Performance improvements
- `DESIGN-` — Design/styling work
- `DOCS-` — Documentation
- `EPIC-` — Major multi-phase features
- `EXPLORE-` — Research/investigation
- `CLEANUP-` — Code cleanup
- `A11Y-` — Accessibility improvements
- `QUALITY-` — Code quality improvements

## Enhanced Plan Template

Use this comprehensive template for all plan files. Fill in ALL sections based on research:

```markdown
# [Type]: [Short Description]

**Status**: Backlog
**Created**: [YYYY-MM-DD]
**Priority**: [High/Medium/Low]
**Labels**: [relevant labels]
**Size**: [one focused session — if bigger, split into NNNa/NNNb]

## Context & Motivation

[Why this work is needed — business value, user need, or technical debt]

## Current State

[What exists today — relevant background, current implementation]

## Desired Outcome

[What we want to achieve after this is complete — specific goals]

## Affected Components

### Files to Create
- [Specific file paths]

### Files to Modify
- [Specific file paths]

### Dependencies
- **External**: [packages needed]
- **Internal**: [other features/components this depends on]
- **Blocking**: [tasks that must be completed first]

## Technical Approach

### Architecture Decisions

[Key architectural choices and rationale]

### Implementation Steps

Vertical slices, in order (functional tasks test-first per the `tdd` skill; pure
render/asset tasks verify by Visual Review instead):

1. [First slice — the behavior to test/build, files touched, key change]
2. [Next slice]
3. [Verify: `nix develop -c bash verify.sh` green; edge cases / error paths]

### Risks & Considerations

- **Risk 1**: [What could go wrong] — **Mitigation**: [How to address]

## Before / After Examples

Show concrete code comparisons to clarify the intended changes.

### Example 1: [Brief description]

**Before** (`path/to/file`):
[current code]

**After**:
[how it should look after implementation]

## Code References

### Relevant Existing Code

[Point to existing code that follows similar patterns]

## Progress Log

- [YYYY-MM-DD] — Task created

## Resolution

[This section added when complete — summary of implementation]

## Acceptance Criteria

- [ ] [Specific, measurable criterion 1]
- [ ] [Specific, measurable criterion 2]
- [ ] [Specific, measurable criterion 3]

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
```

## Handoff to Implementation

This skill only writes the plan into `backlog/`. The implementation side
(`start-working`, or the autonomous loop) then:

1. Adds it to `PLANNING-BOARD.md` if it's a priority (max 3–5 items)
2. Moves the file `backlog/ → in-progress/` when work starts
3. Builds it per the plan (functional = test-first), updating the Progress Log
4. Moves it to `done/` and removes it from `PLANNING-BOARD.md` when complete

When invoked interactively, tell the user the plan path and that it's ready. In the
autonomous loop there's no user to notify — just leave the file consistent on disk.

## See Also

- [`.task-board/PLANNING-BOARD.md`](../../../.task-board/PLANNING-BOARD.md) — Current priorities
- [`.docs/specs/`](../../../.docs/specs/) — Full project specification (phased user stories)
- [`adr/`](../../../adr/) — Technical decisions (engine, stack, asset pipeline)