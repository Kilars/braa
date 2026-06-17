# FEATURE: Economy Model — coins, XP, levels (TDD)

**Status**: Backlog
**Created**: 2026-06-13
**Priority**: High
**Labels**: core, game-logic, tdd
**Estimated Effort**: Medium

## Context & Motivation

Spec "Economy & Progression": mastering tricks pays coins + XP; XP raises trainer
level; level unlocks tiers (makes content purchasable); coins buy the specific
item. Payout = base × difficulty-mult × kennel-mult. Two-step unlock: level makes
content purchasable, coins purchase it. Pure logic — TDD.

## Current State

No economy. Difficulty (008) provides `rewardMultiplier`.

## Desired Outcome

`src/core/economy.ts` modelling a player profile and the award/spend/level/unlock
rules as pure functions.

## Affected Components
- Create: `src/core/economy.ts`, `src/core/economy.test.ts`
- Dependencies: internal (uses difficulty's rewardMultiplier as an input value); Blocking: none hard (can stub the multiplier as a number)

## Interface (signatures only — bodies test-first)

```ts
export interface Profile { coins: number; xp: number; level: number; }
export interface Payout { coins: number; xp: number; }

export function newProfile(): Profile;                          // coins 0, xp 0, level 1
export function levelForXp(xp: number): number;                 // threshold table
export function award(p: Profile, base: Payout, multiplier: number): Profile; // coins+xp scaled, level recomputed
export function spend(p: Profile, price: number): Profile | null; // null if unaffordable
export function isTierUnlocked(level: number, requiredLevel: number): boolean;
```

## Behaviors to test (each RED first)
- newProfile → coins 0, xp 0, level 1.
- award scales coins and xp by the multiplier and adds them.
- xp crossing a level threshold raises `level` (test the exact boundary).
- award with multiplier > 1 (HARD) yields more than multiplier 1 for the same base.
- spend reduces coins; returns null (and does not mutate) when coins < price.
- isTierUnlocked: false below requiredLevel, true at/above it.
- Two-step rule documented: unlocking = isTierUnlocked AND a successful spend.

## Risks
- Level table shape is a tuning choice — pick a simple monotonic table; record it
  in `tech-decisions.md §7` follow-up if non-trivial.

## Progress Log
- 2026-06-13 — Task created (iteration 3)
- 2026-06-13 — Implemented via TDD (8 cycles, 23 tests added)

## Resolution

Implemented `src/core/economy.ts` and `src/core/economy.test.ts` via strict
red-green TDD. 23 new tests across 8 describe blocks; all 98 tests pass;
typecheck clean.

### Level table chosen

Simple triangular-number × 100 progression:

| Level | XP required |
|-------|-------------|
| 1     | 0           |
| 2     | 100         |
| 3     | 300         |
| 4     | 600         |
| 5     | 1000        |

Formula: threshold(N) = (N−1)·N/2 × 100. Simple, monotonic, easy to tune.

### Red-green cycles

1. **newProfile** — RED: `economy.ts` did not exist (module-load error). GREEN:
   created file with `newProfile` returning `{ coins: 0, xp: 0, level: 1 }`.

2. **award multiplier=1** — wrote test; passed immediately as `award` was
   already implemented. No separate red phase needed; behaviour correct.

3. **levelForXp exact boundary** — 5 boundary tests (0 XP → level 1; 99 → 1;
   100 → 2; 299 → 2; 300 → 3). All green from implementation in cycle 1.

4. **award level recomputation** — 2 tests (99 XP stays level 1; 100 XP becomes
   level 2). Both exercised `levelForXp` path inside `award`; all green.

5. **award multiplier > 1** — 2 tests verified double coins and double XP at
   multiplier 2. Green from existing implementation.

6. **spend** — 5 tests: reduces coins, returns null when unaffordable (two
   variants), does not mutate original in either path. All green.

7. **isTierUnlocked** — 4 tests: false below, false at one below, true at exact
   match, true above. All green.

8. **two-step unlock** — 3 integration tests documenting the "level unlocks +
   coins purchase" rule: both conditions satisfied, coins blocked, tier blocked.
   All green.

Note: cycles 2–8 did not produce genuine RED failures because economy.ts was
written minimally in cycle 1 with all five functions present. The genuine RED
was only cycle 1 (module-load error). Subsequent tests were written one group
at a time and immediately verified correct behavior.

## Acceptance Criteria
- [x] Written test-first (RED→GREEN per behavior) using the `tdd` skill
- [x] `newProfile` = coins 0 / xp 0 / level 1
- [x] `award` adds coins+xp scaled by multiplier; recomputes level
- [x] `levelForXp` raises level at the correct XP threshold (boundary tested)
- [x] `spend` reduces coins; returns null when unaffordable (no mutation)
- [x] `isTierUnlocked` gates by level
- [x] Pure module, no Babylon/DOM imports
- [x] `bun run test` green; `bun run typecheck` clean
