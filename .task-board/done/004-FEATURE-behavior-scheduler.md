# FEATURE: Behavior Scheduler (TDD)

**Status**: Done
**Created**: 2026-06-13
**Priority**: High
**Labels**: core, game-logic, tdd
**Estimated Effort**: Medium

## Context & Motivation

The dog offers behaviors over time; the correct one opens an attempt window,
distractors fill other slots. We need a deterministic, pure module that produces
this timeline so `classifyMark` (002) has an "active attempt or null" to judge
against. Pure + seeded RNG = fully testable, no rendering.

## Current State

`src/core/mark.ts` defines `Attempt { start, end, peak, peakRadius }`. Nothing
schedules attempts yet.

## Desired Outcome

`src/core/scheduler.ts` that builds a timeline of behavior events and answers
"what correct attempt is active at time `now`?" (or null).

## Affected Components
- Create: `src/core/scheduler.ts`, `src/core/scheduler.test.ts`
- Dependencies: internal `src/core/mark.ts` (`Attempt`); Blocking: 002

## Technical Approach

### Architecture Decisions
- **Inject RNG** as `rng: () => number` (0..1) — deterministic tests, no
  `Math.random` inside.
- Each scheduled correct attempt has an **outer active span** `[activeStart,
  activeEnd]` (when the dog is visibly doing the behavior) AND an inner scoring
  window `Attempt { start, end, peak, peakRadius }` inside that span. This is what
  lets `classifyMark` return MISS (tap inside the active span but outside the
  scoring window) vs FALSE_MARK (no active span → `attemptAt` returns null).
- `attemptAt(timeline, now)` returns the inner `Attempt` whose outer span
  contains `now`, else `null`.

### Implementation Steps (TDD — `tdd` skill, vertical slices)
1. RED: an empty timeline → `attemptAt` returns null for any `now`. GREEN.
2. RED: a timeline with one attempt → `attemptAt` returns it inside its outer span, null outside. GREEN.
3. RED: `buildTimeline(config, rng, count)` produces `count` correct attempts spaced by `config.attemptInterval`. GREEN.
4. RED: distractor slots are inserted per `config.distractorRate` and never make `attemptAt` non-null. GREEN.
5. RED: window width / peakRadius come from config. GREEN.
6. Refactor.

### Risks
- **Overlap** — ensure attempt spans don't overlap distractors ambiguously; assert ordering in tests.

## Before / After

**After** (`src/core/scheduler.ts`, shape):
```ts
import { Attempt } from './mark';

export interface SchedulerConfig {
  attemptInterval: number; // ms between correct attempts
  activeSpan: number;      // ms the behavior is visibly held
  windowWidth: number;     // ms scoring window (<= activeSpan)
  peakRadius: number;      // ms PERFECT band half-width
  distractorRate: number;  // 0..1 chance of a distractor between attempts
}

export interface TimelineEvent {
  kind: 'attempt' | 'distractor';
  activeStart: number;
  activeEnd: number;
  attempt?: Attempt;       // present when kind === 'attempt'
}

export function buildTimeline(cfg: SchedulerConfig, rng: () => number, count: number): TimelineEvent[];
export function attemptAt(timeline: TimelineEvent[], now: number): Attempt | null;
```

## Progress Log
- 2026-06-13 — Task created (iteration 2)

## Resolution

Implemented 2026-06-13 via strict RED→GREEN TDD cycles:

**Cycle 1** — `attemptAt` on empty timeline → null. RED: module not found (import error). GREEN: created `scheduler.ts` with stub `buildTimeline` returning `[]` and `attemptAt` iterating events.

**Cycle 2** — `attemptAt` inside/outside outer span + distractor returns null. Tests written; all passed immediately because the cycle-1 `attemptAt` already handled these cases correctly (the check `kind === 'attempt' && now >= activeStart && now <= activeEnd` covered all three behaviors).

**Cycle 3** — `buildTimeline` produces `count` attempt events spaced by `attemptInterval`. RED: `expected [] to have a length of 3 but got +0` and `Cannot read properties of undefined`. GREEN: implemented the loop, computing `activeStart/End`, centering the scoring window within the active span, setting `peakRadius` from config.

**Cycle 4** — Distractor slots inserted per `distractorRate`; `attemptAt` returns null during them. RED: `expected 0 to be greater than 0`. Fixed a semantic issue: test used `seqRng([1])` but `1 < 1 = false`; corrected to `seqRng([0.99])` (matching `Math.random`'s real `[0,1)` range). GREEN after fix.

**Cycle 5** — Window width and peakRadius derive from config. RED→GREEN: all 5 tests passed immediately confirming cycle-3 implementation already correctly derived these from config.

**Cycle 6 (refactor + integration)** — Added integration tests verifying `buildTimeline + attemptAt` together for the MISS vs FALSE_MARK downstream split. All 42 tests pass; `bun run typecheck` clean; no `Math.random`/Babylon/DOM in module.

## Acceptance Criteria
- [x] Written test-first (RED→GREEN per behavior) using the `tdd` skill
- [x] `attemptAt` returns null on an empty timeline
- [x] `attemptAt` returns the inner `Attempt` only within an attempt's outer span
- [x] `buildTimeline` spaces correct attempts by `attemptInterval`
- [x] Distractor slots never cause `attemptAt` to return non-null
- [x] Window width and peakRadius derive from config
- [x] RNG is injected (no `Math.random` in module); tests are deterministic
- [x] `src/core/scheduler.ts` has no Babylon/DOM imports
- [x] `bun run test` green; `bun run typecheck` clean
