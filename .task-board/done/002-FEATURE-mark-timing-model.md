# FEATURE: Mark Timing & Classification Model (TDD)

**Status**: Backlog
**Created**: 2026-06-13
**Priority**: High
**Labels**: core, game-logic, tdd
**Estimated Effort**: Simple

## Context & Motivation

The heart of the game is timing a tap against the dog's behavior window. This is
pure, deterministic logic — perfect for TDD and the cheapest way to prove the
"feel math" before any 3D. Per spec: PERFECT / OK / MISS / FALSE_MARK and a
learned-bar delta.

## Current State

Nothing exists. Depends on 001 (Vitest must run).

## Desired Outcome

A pure module `src/core/mark.ts` exporting `classifyMark(...)` and a data-driven
delta lookup, fully covered by behavior tests. No Babylon/DOM.

## Affected Components

### Files to Create
- `src/core/mark.ts`
- `src/core/mark.test.ts`

### Dependencies
- **External**: none
- **Internal**: none
- **Blocking**: 001 (scaffolding/Vitest)

## Technical Approach

### Architecture Decisions
- Model the **active correct attempt** as the public input. If the dog is idle or
  only a distractor is showing, the active attempt is `null` → a tap is a
  FALSE_MARK. If an attempt is active, timing decides PERFECT/OK/MISS. This
  cleanly expresses the spec's Miss (mistimed during a real attempt) vs.
  false-mark (tapped with nothing to mark) split.
- Deltas live in a config object (data-driven per tech-decisions §5), default =
  Normal values from the spec.

### Implementation Steps (TDD — use the `tdd` skill, vertical slices)
1. RED: test "no active attempt → FALSE_MARK". GREEN: minimal impl.
2. RED: "tap within peak band → PERFECT". GREEN.
3. RED: "tap inside window, off-peak → OK". GREEN.
4. RED: "tap inside attempt but outside window → MISS". GREEN.
5. RED: delta lookup maps each result to the Normal-mode value. GREEN.
6. Refactor once green.

### Risks & Considerations
- **Boundary semantics** — decide inclusive/exclusive edges in tests first.

## Before / After Examples

### Example 1: public interface

**Before**: none.

**After** (`src/core/mark.ts`):
```ts
export type MarkResult = 'PERFECT' | 'OK' | 'MISS' | 'FALSE_MARK';

export interface Attempt {
  start: number;       // ms, scoring window opens
  end: number;         // ms, scoring window closes
  peak: number;        // ms, ideal instant
  peakRadius: number;  // ms, half-width of the PERFECT band
}

export function classifyMark(tapTime: number, attempt: Attempt | null): MarkResult {
  if (!attempt) return 'FALSE_MARK';
  if (tapTime < attempt.start || tapTime > attempt.end) return 'MISS';
  if (Math.abs(tapTime - attempt.peak) <= attempt.peakRadius) return 'PERFECT';
  return 'OK';
}

export const NORMAL_DELTAS: Record<MarkResult, number> = {
  PERFECT: 8, OK: 3, MISS: 0, FALSE_MARK: -4,
};
```

### Example 2: a behavior test

**After** (`src/core/mark.test.ts`):
```ts
import { describe, it, expect } from 'vitest';
import { classifyMark } from './mark';

describe('classifyMark', () => {
  const attempt = { start: 100, end: 200, peak: 150, peakRadius: 15 };
  it('is a false mark when nothing is being attempted', () => {
    expect(classifyMark(150, null)).toBe('FALSE_MARK');
  });
  it('is perfect on the apex', () => {
    expect(classifyMark(150, attempt)).toBe('PERFECT');
  });
});
```

## Code References
- Spec: "Core Gameplay Loop" tap-quality tiers; "Mistakes" for the Miss vs.
  false-mark split.

## Progress Log
- 2026-06-13 — Task created (iteration 1)

## Resolution

Implemented in 5 RED→GREEN cycles:

1. **Cycle 1** — `attempt === null` → `FALSE_MARK`. Minimal impl: return `FALSE_MARK` unconditionally.
2. **Cycle 2** — tap exactly at `peak` → `PERFECT`. Added peak-distance check with `Math.abs`.
3. **Cycle 3** — tap inside window but outside peak band → `OK`. Added `start`/`end` window bounds check (MISS for out-of-window) + `OK` as the default in-window result. Boundary semantics confirmed: `start` and `end` are **inclusive** edges.
4. **Cycle 4** — confirmed boundary semantics explicitly (tap at `start` → OK, tap at `start-1` → MISS; same for `end`). Logic already correct from cycle 3; tests green immediately.
5. **Cycle 5** — `NORMAL_DELTAS` lookup exports `{ PERFECT: 8, OK: 3, MISS: 0, FALSE_MARK: -4 }` per spec. Added export and four delta tests.

Post-cycles: verified `mark.ts` has zero import statements (no Babylon/DOM). `bun run test` — 12/12 green. `bun run typecheck` — 0 errors.

## Acceptance Criteria

- [x] Written test-first (RED→GREEN per behavior, vertical slices) using the `tdd` skill
- [x] `classifyMark` returns FALSE_MARK when `attempt` is null
- [x] Returns PERFECT within `peakRadius` of `peak`
- [x] Returns OK inside the window but outside the peak band
- [x] Returns MISS inside the attempt span but outside `[start, end]`
- [x] Delta lookup maps each `MarkResult` to its Normal-mode value
- [x] `src/core/mark.ts` imports nothing from Babylon/DOM
- [x] `bun run test` green; tests describe behavior via the public interface only

---
**Next Steps**: Ready for implementation.
