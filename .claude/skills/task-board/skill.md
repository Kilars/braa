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

1. **Listen carefully**: Read the user's request completely
2. **Ask clarifying questions** to understand scope:
   - What problem are you trying to solve?
   - What does success look like?
   - Are there any constraints or preferences?
   - What's the priority level?
3. **Identify plan type**: Feature, refactor, exploration, or epic
4. **Assess complexity**: Simple (1-2 days), Medium (3-5 days), or Complex (1+ weeks)

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
   - Read `.docs/specs.md` for the project specification
   - Read `.claude/CLAUDE.md` for project conventions
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

2. **Break down into phases**:
   - Phase 1: Core functionality
   - Phase 2: Testing
   - Phase 3: Polish and edge cases

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
- [ ] User's request is fully understood
- [ ] All clarifying questions answered
- [ ] Technical approach is clear and feasible
- [ ] Specific file locations and paths included
- [ ] Dependencies and risks identified
- [ ] Priority and effort estimate set
- [ ] Plan file created in `backlog/` folder
- [ ] User informed that plan is ready for implementation

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
**Estimated Effort**: [Simple/Medium/Complex]

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

1. **[Phase 1: Core Implementation]**
   - Files to create: [specific paths]
   - Files to modify: [specific paths]
   - Key changes: [what needs to be done]

2. **[Phase 2: Testing & Verification]**
   - How to verify the implementation works

3. **[Phase 3: Polish]**
   - Edge cases, error handling

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

After creating a plan file, inform the user:

```
Plan documented: .task-board/backlog/[PLAN-NAME].md

Next steps:
1. Review the plan to ensure accuracy and completeness
2. Add to PLANNING-BOARD.md if this is a top priority (max 3-5 items)
3. When ready to implement, move file to .task-board/in-progress/
4. Implement the feature following the plan
5. Move to .task-board/done/ when complete
```

## Integration with Workflow

This skill creates plans in `backlog/` folder. The implementation workflow then:
1. Adds plan to PLANNING-BOARD.md if it's a priority (max 3-5 items)
2. Moves file to `in-progress/` when starting work
3. Adds detailed implementation breakdown
4. Updates progress log during work
5. Moves to `done/` when complete
6. Updates PLANNING-BOARD.md to remove completed item

## See Also

- [`.task-board/PLANNING-BOARD.md`](../../../.task-board/PLANNING-BOARD.md) — Current priorities
- [`.docs/specs.md`](../../../.docs/specs.md) — Full project specification
- [`.claude/CLAUDE.md`](../../CLAUDE.md) — Project-wide instructions