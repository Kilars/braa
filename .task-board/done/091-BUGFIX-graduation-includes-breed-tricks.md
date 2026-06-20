# BUGFIX: Graduation eligibility must include the breed's signature trick

**Status**: ✅ Done (2026-06-17)
**Created**: 2026-06-17

> **Outcome:** Added pure `graduationTrickIds(breed)` to `core/tricks.ts`
> (starter set + breed signature trick, single-sourced off `tricksForBreed`),
> TDD red→green with 5 new tests in `tricks.test.ts`. Both `main.ts` graduation
> call-sites (`canGraduateActiveDog`/`onGraduate`) now pass
> `graduationTrickIds(getActiveBreed())` instead of `STARTER_TRICKS.map(...)`.
> A Collie/Husky/Bulldog/Puddel no longer "graduates" until its signature trick
> is mastered. Labrador (no signature) unchanged. Typecheck clean; full gate green.

**Priority**: High (v1 progression correctness)
**Labels**: bugfix, progression, prestige, tdd
**Estimated Effort**: Small

## Context & Motivation

Graduation (task 030 / `core/prestige.ts`) is the v1 "fully-trained dog →
permanent prestige multiplier" reward. The eligibility check in `main.ts` is:

```ts
canGraduate(dog, STARTER_TRICKS.map(t => t.id))   // main.ts:517 and :522
```

But the trick-select screen shows each dog **its breed's full set** via
`tricksForBreed(breed)`, which is `[...STARTER_TRICKS, signatureTrick]` for any
breed with a `signatureTrickId` (Border Collie → Rull, Husky → Ul, Bulldog →
Sov, Puddel → Snurr). So a Border Collie that has mastered only Sitt / Ligg /
Legg deg — but **not** its signature Rull — is reported as graduation-ready and
"fully trained", even though the UI still lists an unmastered trick for it.

This is a genuine correctness gap: "graduate = mastered everything this dog can
learn" is violated for every breed that has a signature trick. The starter
Labrador (no signature trick) is unaffected, which is why it slipped through.

Untrain tricks are out of scope for v1 (task 075 gates them out, and
`tricksForBreed` never includes them), so the correct v1 graduation set is
exactly `tricksForBreed(breed)`.

## Desired Outcome

A dog graduates only once it has mastered **every trick its breed offers**
(starter set + the breed's signature trick). The pure check stays pure and
test-first; the two `main.ts` call-sites consult the breed's full trick set.

## Affected Components

### Files to Create / Modify
- `src/core/tricks.ts` (+ `tricks.test.ts`) — add a pure
  `graduationTrickIds(breed)` helper returning the ids required to graduate.
- `src/main.ts` — both `canGraduateActiveDog()` and `onGraduate()` use
  `graduationTrickIds(getActiveBreed())` instead of `STARTER_TRICKS.map(t => t.id)`.

`canGraduate` / `graduate` in `core/prestige.ts` are already correctly
parameterised by `allTrickIds` and need **no change** — the bug is the wrong
list passed in.

## Technical Approach

This is functional/game-logic → **test-first (TDD)**, per
[`.claude/skills/tdd`](../../.claude/skills/tdd/SKILL.md). Vertical slices:
one failing test → minimal impl → repeat.

### Behaviours to test (TDD)
1. `graduationTrickIds(breed)` for a breed **with** a `signatureTrickId` returns
   the three starter ids **plus** the signature id.
2. `graduationTrickIds(breed)` for a breed **without** a signature trick returns
   exactly the three starter ids.
3. Composition: a dog that has mastered only the starter ids is **not**
   `canGraduate(dog, graduationTrickIds(collieBreed))`; after also mastering the
   signature id it **is**.

### Before
```ts
// src/main.ts
canGraduateActiveDog() {
  const dog = roster.find(d => d.id === activeDogId);
  if (!dog) return false;
  return canGraduate(dog, STARTER_TRICKS.map(t => t.id));
},
onGraduate() {
  const dog = roster.find(d => d.id === activeDogId);
  if (!dog) return;
  if (!canGraduate(dog, STARTER_TRICKS.map(t => t.id))) return;
  ...
}
```

### After
```ts
// src/core/tricks.ts
/** Trick ids a dog of this breed must master to graduate (starter set + breed signature). */
export function graduationTrickIds(breed: { signatureTrickId?: string }): string[] {
  return tricksForBreed(breed).map(t => t.id);
}

// src/main.ts
canGraduateActiveDog() {
  const dog = roster.find(d => d.id === activeDogId);
  if (!dog) return false;
  return canGraduate(dog, graduationTrickIds(getActiveBreed()));
},
onGraduate() {
  const dog = roster.find(d => d.id === activeDogId);
  if (!dog) return;
  if (!canGraduate(dog, graduationTrickIds(getActiveBreed()))) return;
  ...
}
```

## Risks & Considerations
- **Behaviour change is intended**: dogs with a signature trick that were
  previously "graduation-ready" at 3 tricks now need 4. This is the fix, not a
  regression. No save-format change (graduation reads live roster state).
- Keep `graduationTrickIds` a thin pure wrapper over `tricksForBreed` so there is
  a single source of truth for "this breed's trick set".

## Acceptance Criteria
- [x] Failing test written first for `graduationTrickIds` (signature + non-signature) and the `canGraduate` composition (TDD red → green).
- [x] `graduationTrickIds(breed)` returns starter+signature ids for a signature breed, starter-only otherwise.
- [x] Both `main.ts` graduation call-sites use `graduationTrickIds(getActiveBreed())`; no remaining `STARTER_TRICKS.map(t => t.id)` in the graduation path.
- [x] A breed with a signature trick is not graduation-ready until that trick is mastered (covered by test).
- [x] `bun run verify` green (typecheck + tests + build); `bun run e2e` green (full gate at iteration end).
