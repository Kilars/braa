# FEATURE: Distinct lie-down pose/clip for the down-family tricks (Ligg, Legg deg)

**Status**: Backlog
**Created**: 2026-06-21 (iteration 25 scan)
**Priority**: High
**Labels**: feature, dog, state-legibility, imported-dog, po-review, D6, D11
**Estimated Effort**: Small-Medium

## Context & Motivation

PO Review — 2026-06-21, **Improvement #1**: on the imported Labrador, **Sitt, Ligg,
and Legg deg all render the same upright sit** at the markable moment — three
different commands look identical on the dog. (Rull shows a clearly distinct rolling
pose, so the rig *can* carry distinct clips.) This breaks "reading the behavior is
part of the skill": the apex must read as the *specific* trick, not one generic pose
(D6, D11).

Root cause: the imported dog's clip selection is **trick-blind**. `dogVisualState`
collapses every offered/markable behavior to the single `DogVisual` value `offering`,
and `resolveStateClip(state, clips)` maps `offering → ['Sitting_loop_1','Sitting']`
for *all* tricks. `trickId` already flows to the **procedural** pose (`dogPose.ts`
gives `ligg`/`legg-deg` deeper crouches) but is **not threaded into the imported
clip resolution**, so the GLB always plays the sitting clip.

## Current State

- `src/render/dogAnimationMap.ts:66-87` — `STATE_CLIP_PREFERENCES.offering =
  ['Sitting_loop_1','Sitting']`; no trick dimension. (A `Lie`/`Lying` family is
  already referenced for the `flop` beat, `:85`, so down clips exist on the rig.)
- `src/render/dogAnimationMap.ts:26-39` — `resolveStateClip(state, clips)` takes only
  the state.
- `src/render/scene.ts:483` — `dog.setVisualState?.(visual, { reducedMotion })` is
  called **without** `trickId`, though `opts.trickId` is in scope (`:493`).
- `src/render/dogPose.ts:44-47` — procedural already distinguishes `ligg` (crouchY
  -0.42) and `legg-deg` (-0.46) from `sitt` (-0.28); the procedural dog is fine. The
  gap is the **imported** path only.

## Desired Outcome

For the **down-family tricks** (`ligg`, `legg-deg`, and the play-dead `sov`), the
imported dog plays a **Lie/Lying** clip (or, if absent, the procedural deep-crouch
already drives the bones) at the offering/markable moment — so the apex reads
unmistakably *down* and different from Sitt's upright sit. Sitt and all non-down
tricks are unchanged (still the sitting clip). The procedural dog is already correct;
this only makes the imported dog match.

## Affected Components

### Files to Create / Modify
- `src/render/dogAnimationMap.ts` (+ `dogAnimationMap.test.ts`) — thread an optional
  `trickId` into `resolveStateClip`; for `offering` with a down-family trick prefer
  the `Lie`/`Lying` family before `Sitting`. TDD.
- `src/render/dogState.ts` — small shared `isDownFamilyTrick(trickId)` predicate (or
  a `DOWN_FAMILY_TRICKS` set) so the rule has one tested home.
- `src/render/scene.ts:483` — pass `opts?.trickId` through to `setVisualState`.
- `src/render/importedDogMesh.ts` — `setVisualState(visual, { reducedMotion, trickId })`
  forwards `trickId` to `resolveStateClip`.
- `.docs/tech-decisions.md` — note that imported clip selection is trick-aware for the
  down family.

### Dependencies
- **Internal**: `resolveStateClip` (pure, tested), `DogVisualOpts.trickId` (already
  plumbed to scene). None blocking.
- **External**: relies on a `Lie`/`Lying` family clip existing on the rig — already
  assumed by the `flop` beat (`dogAnimationMap.ts:85`). If absent at runtime,
  `resolveStateClip` returns null and the procedural deep-crouch pose drives the bones
  (still visibly down) — so the fix degrades gracefully.

## Technical Approach

### Implementation Steps (TDD — `tdd` skill, vertical slices)
1. **RED**: `isDownFamilyTrick('ligg') === true`, `'legg-deg' === true`, `'sov' === true`,
   `'sitt' === false`, `'rull' === false`. **GREEN**: a small set/predicate.
2. **RED**: `resolveStateClip('offering', clips, { trickId: 'ligg' })` returns a
   `Lie`/`Lying` clip when present (e.g. `['Lying_loop','Sitting_loop_1']` → the lying
   one). **GREEN**: when `state === 'offering'` and `isDownFamilyTrick(trickId)`, try a
   `['Lie','Lying']` preference list first, then fall back to the existing `offering`
   prefs.
3. **RED (regression)**: `resolveStateClip('offering', clips, { trickId: 'sitt' })` and
   with no `trickId` still return the `Sitting` clip (down-family rule is opt-in).
4. **RED**: down-family + only sitting clips present → returns the sitting clip (no
   crash; procedural crouch carries the "down" read). Confirms graceful degrade.
5. **Glue**: forward `trickId` scene → importedDogMesh → `resolveStateClip`.
6. **Visual Review (blocking)**: imported dog, capture the markable apex for Sitt vs
   Ligg vs Legg deg — Sitt upright, Ligg/Legg deg clearly *down* and distinct.

### Before / After

**Before** (`src/render/dogAnimationMap.ts`, trick-blind):
```ts
export function resolveStateClip(state: DogVisual, clips: readonly string[]): string | null {
  const prefs = STATE_CLIP_PREFERENCES[state] ?? [];
  // ... match prefs ...
}
const STATE_CLIP_PREFERENCES = { offering: ['Sitting_loop_1', 'Sitting'], /* ... */ };
```
```ts
// scene.ts
dog.setVisualState?.(visual, { reducedMotion });
```

**After**:
```ts
export function resolveStateClip(
  state: DogVisual, clips: readonly string[], opts?: { trickId?: string },
): string | null {
  // Down-family tricks must read as *down*, not the generic sit (D6/D11,
  // PO Review 2026-06-21 Improvement #1). Prefer a lie/lying clip for them.
  const prefs = state === 'offering' && isDownFamilyTrick(opts?.trickId)
    ? ['Lie', 'Lying', ...STATE_CLIP_PREFERENCES.offering]
    : STATE_CLIP_PREFERENCES[state] ?? [];
  // ... existing exact/family match loop, unchanged ...
}
```
```ts
// scene.ts
dog.setVisualState?.(visual, { reducedMotion, trickId: opts?.trickId });
```

### Risks & Considerations
- **Risk**: the rig has no usable lie clip → no behavior change. **Mitigation**: the
  fallback chain returns the sitting clip, but the procedural deep-crouch (already
  -0.42/-0.46) still tilts the imported root down via `applyPose`, so the apex reads
  down regardless. Note this outcome in Visual Review.
- **Risk**: `legg-deg`/`sov` over-mapped. **Mitigation**: the down-family set is
  explicit and unit-tested; non-down tricks are proven unchanged by the regression test.
- **Note**: `resolveStateClip` is pure and tested — this is **test-first**. Keep the
  matching loop intact; only the preference *selection* becomes trick-aware.

## Acceptance Criteria

- [ ] `isDownFamilyTrick` (or equivalent set) added **test-first** via `tdd`
      (`ligg`/`legg-deg`/`sov` true; `sitt`/`rull` false).
- [ ] `resolveStateClip` accepts an optional `trickId`; down-family + `offering`
      prefers `Lie`/`Lying`; **regression tests** prove Sitt / no-trickId / down-with-
      only-sitting-clips all still resolve as before.
- [ ] `trickId` forwarded scene → `setVisualState` → `resolveStateClip`.
- [ ] **Visual Review (blocking)**: imported dog's markable apex is visibly **down**
      for Ligg and Legg deg and distinct from Sitt's upright sit. Screenshots attached.
- [ ] Decision noted in `.docs/tech-decisions.md`. **specs.md untouched.**
- [ ] Full gate green: `bun run typecheck` (0) · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`.

---

**Technical approach hint**: the plumbing (`trickId`) already reaches the scene — the
real fix is making the *imported* clip selection trick-aware for the down family and
forwarding the id the last two hops. Pure-logic core is TDD; the on-dog read is
closed by Visual Review.
