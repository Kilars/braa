# BALANCE: Apply the §7 tuning fixes (TDD)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: High
**Labels**: balance, core, tdd
**Estimated Effort**: Simple

## Context & Motivation

The iteration-11 audit (tech-decisions §7) flagged 5 concrete imbalances with
recommended numbers. Apply them and update the affected tests. These are constant
changes only — keep all logic the same.

## Changes to apply (from §7 recommendations)
1. **EXPERT FALSE_MARK** penalty −14 → **−10** (`difficulty.ts`)
2. **EXPERT distractorRate** 0.7 → **0.55** (`difficulty.ts`)
3. **HARD rewardMultiplier** 1.5 → **1.3** (`difficulty.ts`) — so HARD no longer strictly dominates NORMAL
4. **IDLE_CAP_COINS** 200 → **110** (`kennel.ts`) — idle stays a nudge, not a replacement
5. **prestigeMultiplier** — add a CAP at **2.5×** (`prestige.ts`) — currently unbounded `1 + 0.1*points`
6. **SUPER phrase unlockCost** 150 → **275** (`phrases.ts`) — so the coin cost isn't cleared before the level-3 gate

## Affected Components
- Modify: `src/core/difficulty.ts`, `src/core/kennel.ts`, `src/core/prestige.ts`, `src/core/phrases.ts`
- Update tests: `difficulty.test.ts`, `kennel.test.ts`, `prestige.test.ts`, `phrases.test.ts` — adjust the asserted values to the new numbers (and add a test for the prestige CAP)
- Update doc: `.docs/tech-decisions.md` §7 — mark these as APPLIED with the new values
- Dependencies: none; Blocking: 031

## Approach (TDD — update the test to the new expected value first, watch it fail against the old constant, then change the constant)
- For each change: update the test assertion to the new number (RED against old constant), then change the constant (GREEN). For the prestige cap: add a test that `prestigeMultiplier(50)` is clamped to 2.5, then implement `Math.min(2.5, 1 + 0.1*points)`.
- Re-check the monotonicity tests still hold (HARD still harder than NORMAL on the difficulty axes even with reward 1.3; EXPERT still hardest).

## Progress Log
- 2026-06-14 — Task created (iteration 12)

## Resolution

Applied 2026-06-14. All 6 constant changes implemented TDD-style (test RED → constant change → GREEN).

### Applied changes (old → new)

1. `src/core/difficulty.ts` — EXPERT `FALSE_MARK` delta: −14 → **−10**
2. `src/core/difficulty.ts` — EXPERT `distractorRate`: 0.7 → **0.55**
3. `src/core/difficulty.ts` — HARD `rewardMultiplier`: 1.5 → **1.3**
4. `src/core/kennel.ts` — `IDLE_CAP_COINS`: 200 → **110**
5. `src/core/prestige.ts` — `prestigeMultiplier`: `1 + 0.1*points` → `Math.min(2.5, 1 + 0.1*points)`
6. `src/core/phrases.ts` — SUPER phrase `unlockCost`: 150 → **275**

### Tests changed

- `src/core/difficulty.test.ts` — added "specific tuned constant values" describe block (3 new tests: EXPERT FALSE_MARK −10, EXPERT distractorRate 0.55, HARD rewardMultiplier 1.3)
- `src/core/kennel.test.ts` — added "IDLE_CAP_COINS specific tuned value" describe block (1 new test: IDLE_CAP_COINS is 110)
- `src/core/prestige.test.ts` — added "cap at 2.5×" describe block (3 new tests: clamp at 50 points, clamp at 100 points, low values unchanged)
- `src/core/phrases.test.ts` — added "PHRASE_CATALOG unlock costs" describe block (1 new test: SUPER unlockCost is 275)

### Monotonicity

All difficulty monotonicity tests continue to pass: HARD window (280) < NORMAL (400); HARD distractorRate (0.45) < EXPERT (0.55); EXPERT rewardMultiplier (2.5) > HARD (1.3) > NORMAL (1.0). No monotonicity test broke.

### Verification

- `bun run test`: 342 passed (334 original + 8 new) — all green
- `bun run typecheck`: 0 errors
- `bun run build`: dist produced successfully

## Acceptance Criteria
- [x] All 6 constant changes applied; tests updated to the new values (TDD)
- [x] `prestigeMultiplier` is capped at 2.5× with a test proving the clamp
- [x] Difficulty monotonicity tests still pass (HARD > NORMAL, EXPERT > HARD on the difficulty axes)
- [x] tech-decisions §7 marked APPLIED with the new numbers
- [x] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
