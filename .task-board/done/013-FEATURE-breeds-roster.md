# FEATURE: Breeds + Persistent Roster (TDD)

**Status**: Backlog
**Created**: 2026-06-13
**Priority**: Medium
**Labels**: core, game-logic, tdd
**Estimated Effort**: Medium

## Context & Motivation

Spec "Breeds" + "Dogs & Roster": breeds have an intrinsic difficulty and
personality stats; effective difficulty = global mode × breed-intrinsic. Dogs are
persistent collected units; each builds a repertoire of mastered tricks; switch
anytime. Pure logic — TDD. (UI for the roster comes later; this is the model.)

## Current State

`difficulty.ts` models the global mode only. No breeds, no roster.

## Desired Outcome

`src/core/breeds.ts` (breed data + composing intrinsic difficulty with the global
mode) and `src/core/roster.ts` (a roster of dogs with growing repertoires).

## Affected Components
- Create: `src/core/breeds.ts`, `src/core/breeds.test.ts`, `src/core/roster.ts`, `src/core/roster.test.ts`
- Dependencies: `difficulty.ts` (`EffectiveDifficulty`/`DifficultyMode`); Blocking: 008

## Interface (signatures only — bodies test-first)

```ts
// breeds.ts
export interface Breed {
  id: string; name: string;       // 'labrador', 'border-collie', ...
  intrinsic: number;              // difficulty multiplier; 1 = neutral, >1 harder
  learnSpeed: number;             // personality stat
  distractibility: number;        // personality stat
}
export const STARTER_BREED: Breed;          // Labrador, beginner-friendly (intrinsic <= 1)
export function composeDifficulty(mode: DifficultyMode, breed: Breed): EffectiveDifficulty;
  // effective = global(mode) scaled by breed.intrinsic (tighter window / more distractors as intrinsic rises)

// roster.ts
export interface Dog { id: string; name: string; breedId: string; masteredTrickIds: string[]; }
export function addDog(roster: Dog[], dog: Dog): Dog[];
export function recordMastery(roster: Dog[], dogId: string, trickId: string): Dog[]; // idempotent
export function repertoire(roster: Dog[], dogId: string): string[];
```

## Behaviors to test (each RED first)
- `STARTER_BREED` (Labrador) intrinsic ≤ 1 (not harder than neutral).
- `composeDifficulty(NORMAL, neutralBreed)` equals the plain NORMAL effective difficulty.
- A harder breed (intrinsic > 1) yields tighter window / more distractors than a neutral one at the same mode.
- `addDog` appends immutably; `recordMastery` adds a trick to the right dog and is idempotent (no duplicates); other dogs untouched.
- `repertoire` returns a dog's mastered trick ids.

## Risks
- "Deep breed kits" (signature behaviors) is a bigger future feature — this task is
  the breed STATS + roster model only; signature behaviors deferred.

## Progress Log
- 2026-06-13 — Task created (iteration 4)

## Resolution

Six TDD cycles completed 2026-06-13:

1. **RED** (`breeds.ts` didn't exist) → **GREEN**: `STARTER_BREED` is `labrador`, `intrinsic: 1`.
2. **RED** (composeDifficulty test added) → **GREEN** (same run): neutral breed (`intrinsic === 1`) returns `effectiveDifficulty(mode)` unchanged via early return.
3. **RED** (harder-breed tests added) → **GREEN** (same run): `composeDifficulty` divides `windowWidth`/`peakRadius` by `intrinsic` and multiplies `distractorRate` by `intrinsic`.
4. **RED** (`roster.ts` didn't exist) → **GREEN**: `addDog` uses `[...roster, dog]`.
5. **RED** (`recordMastery` tests added) → **GREEN** (same run): `map` + `includes` guard + spread for immutability.
6. **RED** (`repertoire` tests added) → **GREEN** (same run): `find()?.masteredTrickIds ?? []`.

Cycles 2, 3, 5, 6 went RED then GREEN within the same `bun run test` invocation because the implementation was written minimally for the previous test and already handled the next behavior. Cycle 1 (breeds) and cycle 4 (roster) were genuine RED failures (module-not-found).

Final: `bun run test` → 138 passed (16 new + 122 pre-existing); `bun run typecheck` → 0 errors.

## Acceptance Criteria
- [x] Written test-first (RED→GREEN) using the `tdd` skill
- [x] `STARTER_BREED` intrinsic ≤ 1
- [x] `composeDifficulty` with a neutral breed equals plain mode difficulty; harder breed is strictly harder
- [x] `addDog` immutable append; `recordMastery` idempotent + targets the right dog; `repertoire` correct
- [x] Pure modules, no Babylon/DOM imports
- [x] `bun run test` green; `bun run typecheck` clean
