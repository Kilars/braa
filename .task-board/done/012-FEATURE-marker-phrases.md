# FEATURE: Marker Phrases + Cooldown / Loadout (TDD)

**Status**: Backlog
**Created**: 2026-06-13
**Priority**: Medium
**Labels**: core, game-logic, tdd
**Estimated Effort**: Medium

## Context & Motivation

Spec "Marker Phrases": collectible marker words; base "bra" always available with
no cooldown; stronger phrases are more effective (wider window or bonus reward)
but carry a cooldown so they can't be spammed. Still one tap — a phrase is just
"loaded". Game starts with very few phrases. Pure logic — TDD.

## Current State

Only an implicit single "BRA" mark. No phrase data or cooldown logic.

## Desired Outcome

`src/core/phrases.ts` modelling phrases, the cooldown gate, and how a loaded
phrase modifies a mark (window bonus / reward bonus).

## Affected Components
- Create: `src/core/phrases.ts`, `src/core/phrases.test.ts`
- Dependencies: `mark.ts` (`Attempt`); Blocking: 002

## Interface (signatures only — bodies test-first)

```ts
export interface Phrase {
  id: string; word: string;       // 'bra', 'flink', ...
  windowBonusMs: number;          // widens the effective scoring window (0 for base)
  rewardBonus: number;            // extra learned-bar/coins factor (0 for base)
  cooldownMs: number;             // 0 for base 'bra'
}
export const BASE_PHRASE: Phrase;                       // 'bra', all bonuses 0, no cooldown
export function isReady(p: Phrase, now: number, lastUsedAt: number | null): boolean;
export function applyPhraseToAttempt(a: Attempt, p: Phrase): Attempt;   // widen window by windowBonusMs
```

## Behaviors to test (each RED first)
- `BASE_PHRASE` is always ready (cooldown 0), even right after use.
- A phrase with a cooldown is NOT ready within `cooldownMs` of `lastUsedAt`, and IS ready after.
- `isReady` with `lastUsedAt === null` is true (never used).
- `applyPhraseToAttempt` widens `[start,end]` by `windowBonusMs` (symmetric) and leaves base attempts unchanged for `BASE_PHRASE`.
- (Document) the loadout is just which Phrase is selected; still one tap.

## Risks
- Trade-off/balance model is an open design item (tech-decisions §6) — keep bonuses
  data-driven; don't hardcode a "best" phrase.

## Progress Log
- 2026-06-13 — Task created (iteration 4)

## Resolution

Implemented 2026-06-13 via 6 genuine RED→GREEN cycles:

1. **Cycle 1 — BASE_PHRASE always ready** RED: module not found. GREEN: created `phrases.ts` with `BASE_PHRASE` (cooldownMs=0) and `isReady` returning true when cooldownMs is 0.
2. **Cycle 2 — Cooldown blocks within cooldownMs** RED: stub returned true for all phrases. GREEN: added `now - lastUsedAt >= p.cooldownMs` branch.
3. **Cycle 3 — Boundary: ready exactly at cooldownMs** Wrote test; GREEN immediately — `>=` operator already handled boundary correctly.
4. **Cycle 4 — Ready when never used (null)** Wrote test; GREEN immediately — `null` guard was already added in Cycle 2.
5. **Cycle 5 — applyPhraseToAttempt widens window** RED: stub returned original attempt unchanged (start=100 expected 50). GREEN: spread with `start - windowBonusMs`, `end + windowBonusMs`.
6. **Cycle 6 — BASE_PHRASE leaves attempt unchanged (same reference)** Wrote test; GREEN immediately — `if (p.windowBonusMs === 0) return a` already returns the same object reference.

Final: 122 tests pass (115 pre-existing + 7 new), `bun run typecheck` clean.

## Acceptance Criteria
- [x] Written test-first (RED→GREEN) using the `tdd` skill
- [x] `BASE_PHRASE` always ready; no cooldown
- [x] Cooldown phrase blocked within `cooldownMs`, allowed after (boundary tested)
- [x] `isReady` true when never used
- [x] `applyPhraseToAttempt` widens the window by `windowBonusMs`; base phrase = no change
- [x] Pure module, no Babylon/DOM imports
- [x] `bun run test` green; `bun run typecheck` clean
