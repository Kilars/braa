# FEATURE: Learned-Bar / Training-Session Model (TDD)

**Status**: Backlog
**Created**: 2026-06-13
**Priority**: High
**Labels**: core, game-logic, tdd
**Estimated Effort**: Medium

## Context & Motivation

A round = one dog + one trick; well-timed marks fill a learned bar to 100% =
mastery. The bar only ever stalls (no fail), false marks set it back and trigger
a brief confuse debuff. This is the session state machine that turns individual
marks (002) into progress — pure logic, TDD.

## Current State

Depends on 002 (`MarkResult` + deltas). Nothing exists yet.

## Desired Outcome

`src/core/session.ts` exporting a `TrainingSession` (or pure reducer) covering:
apply a mark → bar delta (clamped 0–100, never below 0), mastery at ≥100, and a
confuse debuff window started by a false mark.

## Affected Components

### Files to Create
- `src/core/session.ts`
- `src/core/session.test.ts`

### Dependencies
- **External**: none
- **Internal**: `src/core/mark.ts` (002)
- **Blocking**: 002

## Technical Approach

### Architecture Decisions
- Prefer a **pure reducer**: `applyMark(state, result, now) → newState`. Keeps it
  trivially testable and replay-safe (no hidden clocks; time passed in).
- State: `{ learned: number; confusedUntil: number | null; mastered: boolean }`.
- Confuse: a false mark sets `confusedUntil = now + CONFUSE_MS`; repeated false
  marks **refresh** (max), not stack. `isConfused(state, now)` derives from it.
- No-fail: `learned` clamps to `[0, 100]`; never below 0.

### Implementation Steps (TDD — `tdd` skill, vertical slices)
1. RED: fresh session has `learned 0`, not mastered. GREEN.
2. RED: PERFECT adds its delta. GREEN.
3. RED: bar clamps at 100 and sets `mastered`. GREEN.
4. RED: false mark subtracts, clamps at 0 (never negative). GREEN.
5. RED: false mark sets `confusedUntil`; `isConfused` true before, false after. GREEN.
6. RED: a second false mark refreshes (does not stack beyond one window). GREEN.
7. Refactor.

### Risks & Considerations
- **Time injection** — never read a real clock inside the reducer; pass `now`.

## Before / After Examples

### Example 1: pure reducer

**After** (`src/core/session.ts`):
```ts
import { MarkResult, NORMAL_DELTAS } from './mark';

export const CONFUSE_MS = 3000;

export interface SessionState {
  learned: number;
  confusedUntil: number | null;
  mastered: boolean;
}

export const newSession = (): SessionState => ({
  learned: 0, confusedUntil: null, mastered: false,
});

export function applyMark(state: SessionState, result: MarkResult, now: number): SessionState {
  const learned = Math.max(0, Math.min(100, state.learned + NORMAL_DELTAS[result]));
  const confusedUntil =
    result === 'FALSE_MARK' ? now + CONFUSE_MS : state.confusedUntil;
  return { learned, confusedUntil, mastered: learned >= 100 };
}

export const isConfused = (s: SessionState, now: number) =>
  s.confusedUntil !== null && now < s.confusedUntil;
```

## Code References
- Spec: "Training Sessions & Mastery" (no-fail, learned bar), "Mistakes"
  (confuse debuff, refresh-not-stack).

## Progress Log
- 2026-06-13 — Task created (iteration 1)

## Resolution
Implemented `src/core/session.ts` (pure reducer) and `src/core/session.test.ts` using 6 TDD cycles:

1. RED→GREEN: `newSession()` returns `{learned:0, mastered:false, confusedUntil:null}`
2. RED→GREEN: PERFECT/OK/MISS apply their NORMAL_DELTAS
3. RED→GREEN: bar clamps at 100 and sets `mastered:true`
4. RED→GREEN: FALSE_MARK subtracts and clamps at 0 (no fail)
5. RED→GREEN: FALSE_MARK sets `confusedUntil = now + CONFUSE_MS`; `isConfused` true before expiry, false at/after
6. RED→GREEN: repeated false marks refresh the window (replace, not stack)

Refactor: simplified `confusedUntil` assignment to `now + CONFUSE_MS` (plain replace is sufficient for refresh semantics). All 24 tests green, 0 typecheck errors.

## Acceptance Criteria

- [x] Written test-first (RED→GREEN per behavior) using the `tdd` skill
- [x] New session starts `learned: 0`, `mastered: false`
- [x] PERFECT/OK marks add their deltas
- [x] Bar clamps at 100 and sets `mastered: true`
- [x] False mark subtracts and clamps at 0 — never negative (no fail)
- [x] False mark sets a confuse window; `isConfused` is true before it and false after
- [x] Repeated false marks refresh (do not infinitely stack) the confuse window
- [x] Reducer takes `now` as a parameter (no internal clock)
- [x] `bun run test` green

---
**Next Steps**: Ready for implementation.
