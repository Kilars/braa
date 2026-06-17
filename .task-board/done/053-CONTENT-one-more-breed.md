# CONTENT: One More Breed + Signature Trick (TDD)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Low
**Labels**: content, core, tdd
**Estimated Effort**: Simple

## Context & Motivation

Add a 4th adoptable breed with its own signature trick to deepen the roster.

## Affected Components
- Modify: `src/core/breeds.ts` (add a breed to `BREED_CATALOG`, e.g. `puddel` ("Puddel" / Poodle) with `intrinsic`, `learnSpeed`, `distractibility`, `adoptCost`, `signatureTrickId: 'snurr'`) + test
- Modify: `src/core/tricks.ts` (add the signature trick `snurr` ("Snurr" / spin) to `SIGNATURE_TRICKS` with a difficulty profile; ensure `lookupTrick` finds it) + test
- Dependencies: `breeds.ts`, `tricks.ts` (045); Blocking: 026, 045

## Behaviors to test (each RED first)
- The new breed exists in `BREED_CATALOG` with a positive `adoptCost` + a `signatureTrickId` that resolves via `lookupTrick`.
- The signature trick `snurr` exists with a valid difficulty profile.
- `tricksForBreed(newBreed)` includes its signature trick; `adoptableBreeds`/`canAdopt` work for it unchanged.
- Catalog still internally consistent (intrinsics positive, costs positive).

## Visual Review
- Not required (content/logic). Confirm `bun run build` + `bun run e2e` still pass (the adopt panel lists `adoptableBreeds`).

## Progress Log
- 2026-06-14 — Task created (iteration 18)

## Resolution

**Puddel breed** (`src/core/breeds.ts`):
- `id: 'puddel'`, `name: 'Puddel'`
- `intrinsic: 1.4`, `learnSpeed: 1.3`, `distractibility: 0.7`
- `adoptCost: 225`
- `signatureTrickId: 'snurr'`
- Added as 5th entry in `BREED_CATALOG` (after Husky)

**Snurr trick** (`src/core/tricks.ts`):
- `id: 'snurr'`, `name: 'Snurr'`
- `learnMult: 0.75`, `windowMult: 0.8`, `distractorBonus: 0.2`
- Appended to `SIGNATURE_TRICKS`; `lookupTrick('snurr')` resolves correctly

**Tests added (TDD, red-green per cycle)**:
- `tricks.test.ts`: 4 tests for snurr (exists, valid profile, lookupTrick); 1 test for `tricksForBreed(puddel)` includes snurr — total +5
- `breeds.test.ts`: 5 tests for puddel (exists, name, adoptCost, intrinsic, signatureTrickId); 5 tests for adoptableBreeds/canAdopt behaviour — total +10

**Verification**:
- `bun run typecheck`: 0 errors
- `bun run test`: 433 passed (up from 418; +15 new tests), 0 failed
- `bun run build`: built in ~12s, dist generated
- `bun run e2e`: E2E SMOKE PASS

## Acceptance Criteria
- [x] 4th breed + its signature trick added (test-first), resolving via `lookupTrick`/`tricksForBreed`
- [x] Existing breed/adopt fns work for it unchanged (tested)
- [x] `bun run test` green; `bun run typecheck` 0; `bun run build` ok; `bun run e2e` PASS
