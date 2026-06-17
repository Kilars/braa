# FEATURE: Round Controller — headless playable round (TDD)

**Status**: Backlog
**Created**: 2026-06-13
**Priority**: High
**Labels**: core, game-logic, tdd
**Estimated Effort**: Medium

## Context & Motivation

Bind the pieces into a playable round: scheduler (004) supplies the active
attempt, `classifyMark` (002) judges a tap, `session` (003) accumulates the
learned bar to mastery. After this the game is fully playable in tests — the
cheapest possible proof of the core loop, before any UI.

## Current State

Have `mark.ts`, `session.ts`, and (after 004) `scheduler.ts`. No orchestrator.

## Desired Outcome

`src/core/round.ts` exposing a pure round state + `markAt(state, now)` that runs
the full pipeline and returns the new state plus the last result.

## Affected Components
- Create: `src/core/round.ts`, `src/core/round.test.ts`
- Dependencies: internal `mark.ts`, `session.ts`, `scheduler.ts`; Blocking: 002, 003, 004

## Technical Approach

### Architecture Decisions
- Pure reducer, time injected. `createRound(timeline)` → `{ session, lastResult,
  timeline }`. `markAt(state, now)` = `classifyMark(now, attemptAt(timeline, now))`
  → `applyMark(session, result, now)`; returns `{ ...state, session, lastResult }`.
- `isMastered(state)` derives from `session.mastered`.
- No real clock; `now` is always a parameter.

### Implementation Steps (TDD — `tdd` skill)
1. RED: a fresh round is not mastered, learned 0. GREEN.
2. RED: marking on the peak of an active attempt advances the bar (PERFECT). GREEN.
3. RED: marking with no active attempt records FALSE_MARK and starts confuse. GREEN.
4. RED: enough PERFECT marks across attempts reach mastery. GREEN.
5. RED: `lastResult` reflects the most recent mark. GREEN.
6. Refactor.

## Before / After

**After** (`src/core/round.ts`, shape):
```ts
import { MarkResult, classifyMark } from './mark';
import { SessionState, newSession, applyMark } from './session';
import { TimelineEvent, attemptAt } from './scheduler';

export interface RoundState {
  timeline: TimelineEvent[];
  session: SessionState;
  lastResult: MarkResult | null;
}

export const createRound = (timeline: TimelineEvent[]): RoundState => ({
  timeline, session: newSession(), lastResult: null,
});

export function markAt(state: RoundState, now: number): RoundState {
  const result = classifyMark(now, attemptAt(state.timeline, now));
  return { ...state, session: applyMark(state.session, result, now), lastResult: result };
}

export const isMastered = (s: RoundState) => s.session.mastered;
```

## Progress Log
- 2026-06-13 — Task created (iteration 2)

## Resolution

Implemented 2026-06-13 via strict RED→GREEN TDD (5 cycles):

**Cycle 1** — RED (module not found) → GREEN: `createRound(timeline)` returns state with `learned=0`, `mastered=false`, `lastResult=null`.

**Cycle 2** — GREEN immediately (implementation correct): PERFECT mark on peak of active attempt sets `learned=8` and `lastResult='PERFECT'`.

**Cycle 3** — GREEN immediately (implementation correct): Tap in idle gap returns `FALSE_MARK` and sets `confusedUntil = now + 3000`.

**Cycle 4** — GREEN immediately (implementation correct): 13 consecutive PERFECT marks accumulate `learned=100` and `isMastered()` returns `true`.

**Cycle 5** — GREEN immediately (implementation correct): `lastResult` progresses `null → 'PERFECT' → 'FALSE_MARK'` across successive taps; `'MISS'` recorded when tapping in active span but outside scoring window.

All 48 tests pass (`42 pre-existing + 6 new`). `bun run typecheck` → 0 errors.

Files: `src/core/round.ts`, `src/core/round.test.ts`.

## Acceptance Criteria
- [x] Written test-first (RED→GREEN per behavior) using the `tdd` skill
- [x] Fresh round: learned 0, not mastered
- [x] PERFECT mark on an active attempt advances the bar
- [x] Mark with no active attempt → FALSE_MARK + confuse started
- [x] Repeated good marks reach mastery
- [x] `lastResult` reflects the latest mark
- [x] `now` injected everywhere (no internal clock)
- [x] No Babylon/DOM imports
- [x] `bun run test` green; `bun run typecheck` clean
