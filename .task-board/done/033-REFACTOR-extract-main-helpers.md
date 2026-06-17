# REFACTOR: Extract testable helpers out of main.ts (TDD-protected)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: refactor, quality, tdd
**Estimated Effort**: Medium

## Context & Motivation

`main.ts` has grown large — it holds the select/training state machine plus all the
wiring AND several pure-ish helpers (scheduler-config building, distractor-rate
gating, mastered-count, boosted-combo deltas, save-snapshot construction). Extract
the PURE logic into tested modules so main.ts shrinks and the logic gets coverage.
Behavior must stay IDENTICAL (readability-first per CLAUDE.md).

## Current State

`main.ts` contains helpers like `buildSchedulerCfg`, `effectiveDistractorRate`,
`totalMasteredCount`, combo `boostedDeltas`, and inline `GameSave` snapshot
construction — none unit-tested.

## Approach (surgical, low-risk — extract pure functions, add tests, keep behavior)
1. Identify the PURE helpers currently inline in main.ts (no DOM/Babylon, deterministic).
2. Move each into an appropriate module (existing or a new `src/app/` pure module) and
   import it back into main.ts. Examples:
   - scheduler-config builder + distractor-rate gating → a pure fn taking (mode, breed, trick, revealed) → SchedulerConfig
   - total-mastered-count over roster → a pure fn
   - combo-boosted deltas → a pure fn
   - the `GameSave` snapshot builder (profile, roster, ids, etc. → GameSave) → a pure fn (very valuable to test — persistence correctness)
3. Add unit tests for each extracted fn (TDD where practical: write the test against the
   intended behavior, then move/adjust the impl until green).
4. main.ts just calls them. DO NOT change observable behavior.

## Verification (critical — main.ts isn't unit-tested)
- Full `bun run test` stays green (existing + new extraction tests).
- A smoke screenshot of BOTH the select screen and a training frame (reuse the running
  dev server; do NOT pkill; never fake) to confirm no regression — coins/level, selector,
  trick label, BRA, combo, shops still render and the app still starts in select.

## Progress Log
- 2026-06-14 — Task created (iteration 11)

## Resolution

Extracted 5 pure helpers from main.ts into `/home/larsski/Code/bra/src/app/gameHelpers.ts`:

| Helper | Description |
|---|---|
| `totalMasteredCount(roster)` | Sums masteredTrickIds across all dogs |
| `effectiveDistractorRate(masteredCount, roundDifficulty)` | Gates distractorRate to 0 until onboarding reveal |
| `buildSchedulerCfg(masteredCount, roundDifficulty)` | Assembles full SchedulerConfig with gated distractorRate |
| `boostedDeltas(deltas, comboMult)` | Applies combo multiplier to PERFECT/OK deltas, rounds to int |
| `buildGameSave(params)` | Pure GameSave snapshot builder (persistence shape) |

Tests: 36 new unit tests in `/home/larsski/Code/bra/src/app/gameHelpers.test.ts`.

main.ts line count: 454 → 426 (−28 lines). All `buildSchedulerCfg()` call sites updated to pass `(totalMasteredCount(roster), roundDifficulty)`; `persist()` now calls `buildGameSave(...)`; inline `boostedDeltas` block replaced with imported function.

Smoke screenshots: select screen renders (3D scene + dog selector visible), training screen confirms `#hud-trick-label` = "Teaching: Sitt" with opacity 1 after clicking Sitt.

`bun run test`: 334/334 (298 existing + 36 new). `bun run typecheck`: 0 errors. `bun run build`: success.

## Acceptance Criteria
- [x] ≥3 pure helpers extracted from main.ts into tested module(s); each has unit tests
- [x] The GameSave-snapshot builder is extracted and unit-tested (persistence correctness)
- [x] main.ts is smaller and just orchestrates; NO observable behavior change
- [x] Full `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
- [x] Smoke screenshots (select + training) reviewed — no regression
