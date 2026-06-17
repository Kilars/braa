# FEATURE: Breed Signature Tricks (TDD + content)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: core, content, tdd, visual-review
**Estimated Effort**: Medium

## Context & Motivation

Spec "Breeds" calls for **deep breed kits** with signature tricks. Today every breed
shares the same trick list. Give each non-starter breed a signature trick so adopting
a breed unlocks something distinctive.

## Current State

`tricks.ts` has STARTER_TRICKS (Sitt/Ligg/Legg deg) + UNTRAIN_TRICKS (Ikke hopp).
`breeds.ts` has the catalog. `main.ts` `getTricks()` returns the same set regardless
of the active dog's breed.

## Affected Components
- Modify: `src/core/tricks.ts` (add signature tricks, e.g. Border Collie → "Rull" (roll over), Husky → "Ul" (howl), Bulldog → "Sov" (play dead); each with a difficulty profile) + test
- Modify: `src/core/breeds.ts` (each `Breed` references its `signatureTrickId(s)`) + test
- Modify: `src/main.ts` (`getTricks()` returns STARTER_TRICKS + the active breed's signature trick(s) (+ untraining); the select screen shows them)
- Dependencies: `breeds.ts`, `tricks.ts`, `roster.ts`; Blocking: 013, 021, 023, 026

## Behaviors to test (each RED first)
- Each non-starter breed in the catalog has a `signatureTrickId` that resolves to a real Trick via `lookupTrick`.
- A pure `tricksForBreed(breed)` returns STARTER_TRICKS + that breed's signature trick (Labrador = just starters, or a starter-friendly one).
- The signature tricks exist in the catalog with valid difficulty profiles (learn/window/distractor mults).
- `lookupTrick` finds the signature tricks.

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- Seed a save where a non-Labrador breed (e.g. Border Collie) is owned + active; screenshot the
  SELECT screen showing that breed's signature trick in the list. VIEW it; confirm it appears.
  (Or adopt one in-flow if coins allow.)

## Progress Log
- 2026-06-14 — Task created (iteration 15)

## Resolution

Implemented in 3 TDD cycles (all red-then-green):

**Signature tricks added to `tricks.ts`:**
- `rull` ("Rull" / roll over) — learnMult 0.65, windowMult 0.70, distractorBonus 0.25
- `ul` ("Ul" / howl) — learnMult 0.70, windowMult 0.75, distractorBonus 0.20
- `sov` ("Sov" / play dead) — learnMult 0.55, windowMult 0.65, distractorBonus 0.15

Exported as `SIGNATURE_TRICKS`. `lookupTrick` now searches all three arrays (starter + untrain + signature).

**`tricksForBreed(breed)` added to `tricks.ts`:** returns `[...STARTER_TRICKS]` for Labrador (no signatureTrickId), or `[...STARTER_TRICKS, sigTrick]` for breeds with a signatureTrickId.

**`Breed.signatureTrickId?: string` added to `breeds.ts`:**
- Border Collie → `rull`
- Husky → `ul`
- Bulldog → `sov`
- Labrador (STARTER_BREED) → none

**`main.ts` `getTricks()`** now calls `tricksForBreed(getActiveBreed())` instead of hard-coding `STARTER_TRICKS`, then appends `UNTRAIN_TRICKS` as before.

**Results:**
- `bun run typecheck` — 0 errors
- `bun run test` — 368 passed (was 355; +13 new tests across 5 new describe blocks)
- `bun run build` — succeeded (dist generated)
- `bun run e2e` — E2E SMOKE PASS

**Visual review:** Screenshot `/tmp/bra-signature.png` (real, not fabricated).
With Border Collie active, SELECT screen showed trick buttons: Sitt, Ligg, Legg deg, **Rull**, Ikke hopp.
Confirmed "Rull" present in both `querySelectorAll('button')` and DOM text walker output.

## Acceptance Criteria
- [x] Each non-starter breed has a signature trick (real Trick + difficulty profile), test-first
- [x] `tricksForBreed(breed)` returns starters + the breed's signature trick(s); Labrador = starters
- [x] `main.ts` shows the active dog's breed-appropriate trick list on select
- [x] Screenshot of a non-Labrador breed's signature trick reviewed (real) — /tmp/bra-signature.png shows "Rull" in Border Collie's list
- [x] Pure cores no DOM imports
- [x] `bun run test` green (368); `bun run typecheck` 0; `bun run build` succeeds; `bun run e2e` PASS
