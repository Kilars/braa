# FEATURE: Adopt More Dogs (breed catalog + roster expansion)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: High
**Labels**: core, ui, economy, tdd, visual-review
**Estimated Effort**: Medium

## Context & Motivation

Spec "Breeds" + "Dogs & Roster": collect dogs; each breed has its own intrinsic
difficulty/personality; switch dogs anytime. Today only Rex (Labrador) exists.
Add a breed catalog + an adopt flow (spend coins) so the roster grows, and make
the active dog's breed affect difficulty via `composeDifficulty`.

## Current State

`breeds.ts` has only `STARTER_BREED`. `composeDifficulty(mode, breed)` exists but
main.ts uses mode only. Select screen shows one dog. GameSave persists `roster`.

## Affected Components
- Modify: `src/core/breeds.ts` (add a `BREED_CATALOG` — e.g. Border Collie [fast/distractible], Bulldog [slow/steady], Husky [high-energy/jittery] — each with `intrinsic` + an `adoptCost`) + test
- Create/extend: pure adopt helpers — `adoptableBreeds(roster)`, `canAdopt(breed, coins, roster)` (TDD)
- Modify: `src/main.ts` (active dog state; round config = `applyTrickProfile(composeDifficulty(mode, activeBreed), trick)`; adopt = spend coins → `addDog(roster, …)` → persist), `src/ui/hud.ts`/`hud.css` (select screen: a roster row to pick the active dog + an "Adopt" affordance/panel listing adoptable breeds with cost)
- Dependencies: `breeds.ts`, `roster.ts`, `difficulty.ts`, `economy.ts`, `tricks.ts`, `save.ts`; Blocking: 013, 021, 023

## Behaviors to test (each RED first)
- `BREED_CATALOG` includes the starter + ≥2 more, each with a positive `adoptCost`; intrinsics vary.
- `canAdopt` false if already in roster, false if unaffordable, true otherwise.
- `composeDifficulty(mode, harderBreed)` is strictly harder than with the starter breed (already partly covered — extend for new breeds).
- Adopting adds the dog to roster (immutably) and is reflected in `adoptableBreeds`.

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- Screenshot the select screen with the roster row + Adopt panel open. VIEW it; confirm
  multiple dogs / adopt costs render and you can pick the active dog. Note findings.

## Progress Log
- 2026-06-14 — Task created (iteration 9)

## Resolution

### Wiring (main.ts)
- Added `getActiveBreed()` helper (function declaration, hoisted) that looks up the active dog's breed from `BREED_CATALOG`.
- Replaced all `effectiveDifficulty(MODE)` calls with `composeDifficulty(MODE, getActiveBreed())` so the active dog's breed intrinsic multiplier scales the scheduler params.
- Made `activeDogId` mutable (`let`).
- Added `onSelectDog(dogId)` callback: updates `activeDogId`, rebuilds `difficulty` via `composeDifficulty` with the new dog's breed, reapplies trick profile, and calls `showSelect()`.
- Added `getRoster()` callback: returns `{ dog, isActive }[]` from the live roster.
- Added `getAdoptableBreeds()` callback: delegates to `adoptableBreeds(roster)` + affordability check.
- Added `onAdoptBreed(breedId)` callback: `canAdopt` guard → `spend` → `addDog` → `persist`.
- Imports: added `BREED_CATALOG`, `adoptableBreeds`, `canAdopt`, `composeDifficulty`, `Breed` from `breeds.ts` and `addDog` from `roster.ts`.

### UI (hud.ts / hud.css)
- `HudCallbacks` extended with `getRoster`, `onSelectDog`, `getAdoptableBreeds`, `onAdoptBreed`.
- **Roster row** (`#hud-roster-row`): rendered in `showSelect()` above the trick list; each dog gets a `.hud-roster-btn` pill, active dog styled `.active` (green highlight, no click handler).
- **Adopt button** (`#hud-adopt-btn`): amber-styled button below the trick list; opens the adopt panel.
- **Adopt panel** (`#adopt-panel`): modal matching kennel panel style — header with "Adopt a Dog" + ✕ close, list of `adoptableBreeds` with breed name, cost, and Adopt button (disabled if unaffordable; on success calls `onAdoptBreed` + `refreshAdoptPanel` + `showSelect`).
- CSS added: `#hud-roster-row`, `.hud-roster-btn`, `.hud-roster-btn.active`, `#hud-adopt-btn`, `#adopt-panel`, `.adopt-breed-row`, `.adopt-buy-btn`, `.adopt-empty`.

### Screenshot result (real)
- **Select screen** (`/tmp/bra-select-screen.png`): dark background; "Rex" title; green "Rex" roster pill (active, highlighted); three trick buttons (Sitt, Ligg, Legg deg); amber "+ Adopt Dog" button.
- **Adopt panel** (`/tmp/bra-adopt.png`): full-screen modal overlay; "Adopt a Dog" header + ✕; three breed rows — Border Collie 🪙 200, Bulldog 🪙 150, Husky 🪙 300 — all with active golden ADOPT buttons (seeded 501 coins ≥ all costs); select screen ghosting through at 3% opacity behind.

## Acceptance Criteria
- [x] `BREED_CATALOG` (starter + ≥2) with adopt costs + varied intrinsics, written test-first
- [x] `canAdopt`/`adoptableBreeds` TDD'd (owned/affordability rules)
- [x] Active dog selectable; training uses that dog's breed via `composeDifficulty` (harder breeds visibly harder)
- [x] Adopting spends coins, adds the dog to the persisted roster
- [x] Select screen shows the roster + an adopt affordance; screenshot reviewed (real)
- [x] Pure cores no DOM imports
- [x] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
