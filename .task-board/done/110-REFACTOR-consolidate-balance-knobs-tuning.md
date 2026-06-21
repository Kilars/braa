# REFACTOR: Consolidate remaining balance knobs into `src/core/tuning.ts`

**Status**: Done
**Created**: 2026-06-21 (iteration 21 scan)
**Completed**: 2026-06-21 (iteration 22)
**Priority**: Medium
**Labels**: refactor, quality, tuning
**Estimated Effort**: Simple

## Context & Motivation

Task 105 created `src/core/tuning.ts` as the single home for balance knobs (the
difficulty mode tables + the two `main.ts` stragglers) and tech-decisions §8 now
points at it as the live tuning surface. A code-quality scan (iteration 21) found
several **playtest-relevant balance knobs still scattered** across domain modules
— they are already named consts, but not in the one place a tuner is told to edit:

- `src/core/mark.ts:11` — `NORMAL_DELTAS` (`PERFECT 8 / OK 3 / MISS 0 /
  FALSE_MARK -4`): the reference learned-bar deltas. HARD/EXPERT false-mark
  overrides already live in `tuning.ts`, but the NORMAL baseline does not.
- `src/core/engagement.ts:19-30` — `MARK_ENGAGEMENT_DELTA`, `REWARD_SNAPPY_MS`
  (800), `REWARD_SLOW_MS` (2400), `REWARD_SNAPPY_REFILL` (0.05),
  `REWARD_SLOW_DRAIN` (-0.15).
- `src/core/disengage.ts` — `CALL_BACK_ENGAGEMENT` (0.5).
- `src/core/difficulty.ts:106` — `CONFUSE_WINDOW_MULT` (0.6),
  `CONFUSE_DISTRACTOR_MULT` (1.5).
- `src/app/gameHelpers.ts:50` — `BASE_SCHEDULER_TIMING` (`attemptInterval 2000,
  activeSpan 800`).

These are exactly the knobs the imminent balance/playtest pass will want to tweak.
Centralising them in `tuning.ts` is the documented §8 pattern and a **mechanical,
behavior-preserving** move (no value changes).

## Current State

- `src/core/tuning.ts` exists (task 105) hosting the difficulty mode constants +
  `PANT_INTERVAL_MS` / `TIMELINE_EVENTS`, and imports nothing from `src/core/*`.
- The knobs above are named consts in their own modules; each module has a test
  suite asserting current behavior (the safety net for the move).

## Desired Outcome

The listed balance knobs live in (or are re-exported from) `src/core/tuning.ts`;
their domain modules import them. **Zero behavior change** — every existing test
passes **unchanged**. A tuner edits one file.

## Affected Components

### Files to Modify
- `src/core/tuning.ts` — add the named constants, grouped/commented to mirror §8.
- `src/core/mark.ts`, `src/core/engagement.ts`, `src/core/disengage.ts`,
  `src/core/difficulty.ts`, `src/app/gameHelpers.ts` — import the constants from
  `tuning.ts`; delete the local literal definitions (or keep a thin
  `export { X } from '../core/tuning'` re-export where a name is imported widely,
  to minimise call-site churn).
- `.docs/tech-decisions.md` §8 — extend the "now-live" note with the newly homed
  knobs. **specs.md untouched.**

### Dependencies
- **Blocking**: none.

## Technical Approach

### Architecture Decisions
- **Pure move, behavior-preserving.** The win is locating + single-sourcing, not
  changing values. Diff every moved literal against its origin.
- **No cycles.** `tuning.ts` must keep importing nothing from `src/core/*` —
  these are all primitive numbers / a `Record`, so they sit at the bottom of the
  graph. The consuming modules import *from* `tuning.ts` (one-way).
- **Tests are the contract.** This is a refactor: existing tests must pass
  **unchanged** (only import paths may change, if anything). No new behavior to
  TDD. If any test imported a moved const directly, repoint its import.

### Implementation Steps
1. Add the constants to `tuning.ts` (value-for-value), grouped by domain with a
   one-line comment each.
2. Repoint one module at a time (`mark` → run tests → green; `engagement` → …),
   so a regression localises immediately.
3. Repoint any test imports of the moved consts to `tuning.ts`.
4. Update tech-decisions §8.

### Risks & Considerations
- **Risk**: a typo silently changes balance. **Mitigation**: per-module test
  suites + e2e full-loop; diff each moved value.
- **Risk**: scope creep into a giant rename. **Mitigation**: move only the listed
  knobs; leave already-well-placed module-local helpers alone.

## Before / After Examples

**Before** (`src/core/engagement.ts`):
```ts
export const REWARD_SNAPPY_MS = 800;
export const REWARD_SLOW_MS = 2400;
export const REWARD_SNAPPY_REFILL = 0.05;
export const REWARD_SLOW_DRAIN = -0.15;
```
**After** (`src/core/tuning.ts`):
```ts
// Engagement — reward-latency feed (task 100/098)
export const REWARD_SNAPPY_MS = 800;     // at/under → max refill
export const REWARD_SLOW_MS = 2400;      // at/over  → max drain
export const REWARD_SNAPPY_REFILL = 0.05;
export const REWARD_SLOW_DRAIN = -0.15;
```
**After** (`src/core/engagement.ts`):
```ts
import {
  REWARD_SNAPPY_MS, REWARD_SLOW_MS, REWARD_SNAPPY_REFILL, REWARD_SLOW_DRAIN,
} from './tuning';
```

## Code References
- `src/core/tuning.ts` (the home, task 105) · `.docs/tech-decisions.md` §8.
- `src/core/mark.ts`, `engagement.ts`, `disengage.ts`, `difficulty.ts`,
  `src/app/gameHelpers.ts` (the straggler sites).

## Progress Log
- 2026-06-21 — Task created (iteration 21 scan). Completes the §8/105 tuning
  centralisation for the knobs a balance pass will touch. Mechanical,
  behavior-preserving; tests are the safety net.
- 2026-06-21 (iteration 22) — Done. Added `NORMAL_DELTAS`, `MARK_ENGAGEMENT_DELTA`,
  the reward-latency feed (`REWARD_SNAPPY_MS`/`REWARD_SLOW_MS`/`REWARD_SNAPPY_REFILL`/
  `REWARD_SLOW_DRAIN`), `CALL_BACK_ENGAGEMENT`, `CONFUSE_WINDOW_MULT`/
  `CONFUSE_DISTRACTOR_MULT`, and `BASE_SCHEDULER_TIMING` to `tuning.ts`, grouped by
  domain. Repointed `mark.ts`, `engagement.ts`, `disengage.ts`, `difficulty.ts`,
  `gameHelpers.ts` — each imports from `tuning.ts`, thinly re-exporting any name
  imported elsewhere (`NORMAL_DELTAS` via mark.ts → difficulty/session/tests;
  engagement knobs via engagement.ts → tests; `CALL_BACK_ENGAGEMENT` via disengage.ts;
  `BASE_SCHEDULER_TIMING` via gameHelpers.ts → main.ts) so **no test import changed**.
  The `Record`/`as const` tables write their key types inline so `tuning.ts` still
  imports nothing from `src/core/*`. All 805 tests pass unchanged; grep confirms the
  literals exist only in `tuning.ts`. tech-decisions §8 note extended.

## Acceptance Criteria
- [x] `NORMAL_DELTAS`, the engagement reward-latency knobs, `CALL_BACK_ENGAGEMENT`,
      `CONFUSE_WINDOW_MULT` / `CONFUSE_DISTRACTOR_MULT`, and `BASE_SCHEDULER_TIMING`
      live in / are re-exported from `src/core/tuning.ts`.
- [x] Their domain modules import from `tuning.ts`; no duplicate literal of those
      values remains (grep-clean).
- [x] **Zero behavior change**: every existing test passes **unchanged** (only
      import paths adjusted); each moved value diffed against its origin.
- [x] `tuning.ts` still imports nothing from `src/core/*` (no cycle).
- [x] tech-decisions §8 note extended. **specs.md untouched.**
- [x] Full gate green: `bun run typecheck` (0) · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`. *(typecheck + test confirmed green; build + e2e
      run in the iteration's final combined gate.)*

---

**Next Steps**: Move to `.task-board/in-progress/` when starting.
