# FEATURE: Graduation / Prestige (TDD + UI)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: core, ui, economy, tdd, visual-review
**Estimated Effort**: Medium

## Context & Motivation

Spec scaling branch: "Graduation / prestige — a fully-trained dog graduates / gets
adopted → ascension reset for a permanent bonus." When a dog has mastered all its
tricks, let it graduate for permanent prestige that boosts all future payouts.

## Current State

Dogs accumulate `masteredTrickIds` but there's no end-state. No prestige.

## Affected Components
- Create: `src/core/prestige.ts` + test
- Modify: `src/state/save.ts` (`GameSave` gains `prestigePoints: number`, default 0; backward-compat), `src/core/game.ts` (payout includes `prestigeMultiplier`), `src/main.ts` (offer/handle graduation; persist), `src/ui/hud.ts`/`hud.css` (a "Graduate" affordance on the select screen when a dog is fully trained + a prestige display)
- Dependencies: `roster.ts`, `tricks.ts`, `economy.ts`, `save.ts`, `game.ts`; Blocking: 021, 026

## Interface (signatures — bodies test-first)

```ts
export function canGraduate(dog: Dog, allTrickIds: string[]): boolean;   // every trick mastered
export function graduate(dog: Dog): Dog;                                  // clears masteredTrickIds (re-trainable)
export const PRESTIGE_PER_GRADUATION: number;
export function prestigeMultiplier(prestigePoints: number): number;      // 1 at 0; grows per point
```

## Behaviors to test (each RED first)
- `canGraduate` false until ALL trick ids are in the dog's repertoire; true when complete.
- `graduate` returns a dog with cleared `masteredTrickIds` (immutably); other fields intact.
- `prestigeMultiplier(0)` = 1; rises per point.
- Payout via `completeMastery`/award includes prestige (extend the multiplier chain: difficulty × kennel × prestige).

## Wiring
- main.ts: when `canGraduate(activeDog, STARTER_TRICKS ids)`, show a Graduate button on
  select; graduating adds `PRESTIGE_PER_GRADUATION` to `prestigePoints`, resets the dog,
  persists. Payout everywhere includes `prestigeMultiplier(prestigePoints)`.
- HUD: small prestige indicator + the Graduate affordance.

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- Seed a fully-trained dog; screenshot the select screen showing the Graduate affordance +
  prestige display. VIEW it; confirm it reads clearly, no overlap.

## Progress Log
- 2026-06-14 — Task created (iteration 10)

## Resolution
_(added when complete)_

## Acceptance Criteria
- [ ] `prestige.ts` written test-first; `canGraduate`/`graduate`/`prestigeMultiplier` correct
- [ ] `GameSave` gains `prestigePoints` (backward-compat default 0); persists
- [ ] Payout includes prestige multiplier (difficulty × kennel × prestige)
- [ ] Graduate affordance appears only for fully-trained dogs; graduating resets the dog + adds prestige
- [ ] Screenshot reviewed (real)
- [ ] Pure `prestige.ts` no DOM imports
- [ ] `bun run test` green; `bun run typecheck` clean; `bun run build` succeeds
