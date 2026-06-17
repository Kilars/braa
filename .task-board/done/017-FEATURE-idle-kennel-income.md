# FEATURE: Idle Income + Kennel Multiplier (TDD)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: High
**Labels**: core, game-logic, economy, tdd
**Estimated Effort**: Medium

## Context & Motivation

Spec "Kennel (Idle / Upgrade Layer)": a capped passive **coin** trickle while away
(collected on return) and kennel upgrades that boost active payouts. We have the
idle timestamp in GameSave but never grant idle income, and payout never includes
a kennel multiplier. Build the pure logic + wire idle-on-load and kennel-mult into
payout. (The buy-upgrades UI is a later task; this lays the foundation.)

## Current State

`GameSave { profile, masteredTrickIds, idleTimestamp }`. `completeMastery` does
`award(p, base, difficulty.rewardMultiplier)` — no kennel factor. Idle never paid.

## Desired Outcome

`src/core/kennel.ts` with: a small kennel-upgrade catalog, `kennelMultiplier(ownedIds)`,
and `idleIncome(idleTimestamp, now)` (capped, coins-only). On load the app grants
idle income and resets the timestamp; mastery payout becomes base × difficulty ×
kennel.

## Affected Components
- Create: `src/core/kennel.ts` + test
- Modify: `src/state/save.ts` (`GameSave` gains `kennelUpgradeIds: string[]`; keep deserialize backward-compatible — default `[]` if absent), `src/core/game.ts` (`completeMastery` takes/uses kennel multiplier), `src/main.ts` (grant idle on load; pass kennel mult to payout; persist new field)
- Dependencies: `economy.ts`, `difficulty.ts`, `save.ts`; Blocking: 009, 010, 011

## Interface (signatures — bodies test-first)

```ts
export interface KennelUpgrade { id: string; name: string; cost: number; payoutMultiplier: number; }
export const KENNEL_UPGRADES: KennelUpgrade[];           // small starter catalog
export function kennelMultiplier(ownedIds: string[]): number;   // 1 for none; grows with owned
export const IDLE_RATE_PER_MS: number;                   // coins per ms
export const IDLE_CAP_COINS: number;                     // max collectible per return
export function idleIncome(idleTimestamp: number, now: number): number; // 0 if now<=ts; capped
```

## Behaviors to test (each RED first)
- `kennelMultiplier([])` === 1; with one upgrade > 1; with two, more than one (monotonic).
- `idleIncome(t, t)` === 0; grows with elapsed time; never exceeds `IDLE_CAP_COINS`.
- Negative/zero elapsed → 0 (no negative income).
- `completeMastery(p, mode, kennelMult)` awards base × difficultyReward × kennelMult (test NORMAL×1 vs NORMAL×kennel>1).
- `deserialize` of an old save WITHOUT `kennelUpgradeIds` defaults it to `[]` (backward-compat).

## Risks
- IDLE_RATE/CAP are tuning values — keep them constants, note in tech-decisions §7.

## Progress Log
- 2026-06-14 — Task created (iteration 6)

## Resolution

Implemented 2026-06-14. 9 red-green cycles.

**Cycles:**
1. `kennelMultiplier([])===1` — RED (module didn't exist), wrote `kennel.ts` skeleton → GREEN
2. `kennelMultiplier` with one upgrade > 1 — GREEN immediately (multiplicative reduce already correct)
3. `kennelMultiplier` monotonic with two upgrades — GREEN immediately
4. `idleIncome(t,t)===0` — GREEN immediately (elapsed≤0 guard)
5. `idleIncome` grows with time + exact value — GREEN immediately
6. `idleIncome` capped at `IDLE_CAP_COINS` — GREEN immediately
7. Negative elapsed → 0 — GREEN immediately
8. `completeMastery(p, mode, kennelMult)` — RED (old 2-arg signature didn't multiply kennel), updated `game.ts` → GREEN
9. `deserialize` backward-compat for old saves — updated `save.ts` with `??[]` default + test → GREEN

**Signature changes:**
- `completeMastery(p, mode, kennelMult = 1)` — added optional third arg with default 1; all existing call sites pass 2 args and still work
- `GameSave.kennelUpgradeIds: string[]` — new required field; `deserialize` defaults absent field to `[]` for old saves
- `deserialize` — now does defensive defaulting instead of blind cast

**Files changed:**
- `src/core/kennel.ts` — new (pure, no DOM)
- `src/core/kennel.test.ts` — new (10 tests)
- `src/core/game.ts` — added optional `kennelMult` param
- `src/core/game.test.ts` — 2 new tests for kennel multiplier path
- `src/state/save.ts` — added `kennelUpgradeIds` field + backward-compat deserialize
- `src/state/save.test.ts` — updated round-trip + new backward-compat test
- `src/state/storage.test.ts` — added `kennelUpgradeIds` to all `GameSave` literals (typecheck fix)
- `src/main.ts` — wired idle income on load, kennel mult in mastery payout, kennelUpgradeIds in save

**Results:** 169 tests (156 pre-existing + 13 new), 0 typecheck errors, build succeeds.

## Acceptance Criteria
- [x] Written test-first (RED→GREEN) using the `tdd` skill
- [x] `kennelMultiplier` 1 for none, monotonic with owned upgrades
- [x] `idleIncome` 0 at no-elapsed, grows, capped, never negative
- [x] `completeMastery` includes the kennel multiplier (base × difficulty × kennel)
- [x] `GameSave` gains `kennelUpgradeIds`; old saves deserialize with `[]` default
- [x] App grants idle income on load and persists the reset timestamp
- [x] Pure core (kennel.ts) has no DOM imports
- [x] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
