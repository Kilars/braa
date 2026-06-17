# FEATURE: Per-Trick Difficulty Profiles (TDD)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: High
**Labels**: core, game-logic, tdd
**Estimated Effort**: Medium

## Context & Motivation

Tricks (Sitt / Ligg / Legg deg) are currently just labels — they play identically.
Spec implies they differ: "lie down can take a very long time until it realizes."
Give each trick a difficulty profile so harder tricks learn slower / tighter
window / more distractors, and apply it to the round config.

## Current State

`tricks.ts` has `{ id, name }` only. The round config = `effectiveDifficulty(mode)`
(× breed via `composeDifficulty`, though main.ts uses mode only). Trick has no
gameplay effect.

## Affected Components
- Modify: `src/core/tricks.ts` (each `Trick` gains modifiers) + its test
- Create or extend: a pure `applyTrickProfile(effective, trick)` (in tricks.ts or difficulty.ts) + test
- Modify: `src/main.ts` (round config derives from mode AND the active trick's profile)
- Dependencies: `difficulty.ts` (`EffectiveDifficulty`), `tricks.ts`; Blocking: 008, 021

## Interface (signatures — bodies test-first)

```ts
export interface Trick {
  id: string; name: string;
  learnMult: number;       // 1 = baseline; <1 slower to learn (harder)
  windowMult: number;      // 1 = baseline; <1 tighter window (harder)
  distractorBonus: number; // added to distractorRate (harder)
}
// STARTER_TRICKS: Sitt baseline; Ligg medium; Legg deg hardest.
export function applyTrickProfile(eff: EffectiveDifficulty, trick: Trick): EffectiveDifficulty;
```

## Behaviors to test (each RED first)
- `STARTER_TRICKS` ordering: Sitt is the easiest profile; Legg deg the hardest
  (smaller learnMult/windowMult, larger distractorBonus) — assert monotonic.
- `applyTrickProfile` with a baseline trick (all mults 1, bonus 0) returns the input unchanged.
- A hard trick yields tighter window (smaller `scheduler.windowWidth`/`peakRadius`),
  higher `scheduler.distractorRate`, and slower learning than baseline.
- Existing `tricks.ts` tests still pass (the catalog grew fields — update intentionally).

## Risks
- Numbers are tuning — keep them as constants; note in tech-decisions §7.

## Progress Log
- 2026-06-14 — Task created (iteration 8)

## Resolution

### Red-Green Cycles

**Cycle 1 — Trick fields (tricks.test.ts → tricks.ts)**
- RED: added 7 tests asserting `learnMult`, `windowMult`, `distractorBonus` are present and monotonic across Sitt < Ligg < Legg deg
- GREEN: extended `Trick` interface with three fields; set `STARTER_TRICKS` values:

| Trick    | learnMult | windowMult | distractorBonus |
|----------|-----------|------------|-----------------|
| Sitt     | 1.0       | 1.0        | 0.0             |
| Ligg     | 0.75      | 0.8        | 0.1             |
| Legg deg | 0.5       | 0.6        | 0.2             |

**Cycles 2+3 — `applyTrickProfile` (difficulty.test.ts → difficulty.ts)**
- RED: added 8 tests: baseline trick = identity (scheduler, deltas, learnMult=1); hard trick = tighter window, more distractors, learnMult exposed; clamp at 1.0
- GREEN: added `learnMult: number` field to `EffectiveDifficulty`; implemented `applyTrickProfile(eff, trick)` — pure, immutable; scales `windowWidth` + `peakRadius` by `windowMult`; adds `distractorBonus` to `distractorRate` (clamped ≤ 1); scales positive deltas (PERFECT, OK) by `learnMult`; sets `result.learnMult = trick.learnMult`

**Wiring — main.ts (no new tests needed; pure-module change)**
- `roundDifficulty` variable added: derived from `applyTrickProfile(difficulty, activeTrick)`
- Rebuilt on `onSelectTrick` and `setMode`
- `applyMark` tap handler now passes `roundDifficulty.deltas` (so learnMult slows bar fill for harder tricks)
- `SCHEDULER_CFG` uses `roundDifficulty.scheduler` (tighter window/more distractors for Legg deg)
- `toViewModel` uses `roundDifficulty.tellIntensity` (consistent; was `difficulty.tellIntensity`)

### Verification
- `bun run test`: 224/224 (209 pre-existing + 15 new) ✓
- `bun run typecheck`: 0 errors ✓
- `bun run build`: dist/ produced ✓

## Acceptance Criteria
- [x] Written test-first (RED→GREEN) using the `tdd` skill
- [x] Each `Trick` has learn/window/distractor modifiers; Sitt easiest, Legg deg hardest (monotonic, tested)
- [x] `applyTrickProfile` baseline = identity; hard trick = tighter window + more distractors + slower learn
- [x] `main.ts` round config applies the active trick's profile (Legg deg visibly harder than Sitt in play)
- [x] Pure modules, no DOM imports
- [x] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
