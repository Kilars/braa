# FEATURE: Per-Trick Dog Poses (D11 — the dog performs the actual trick)

**Status**: Done
**Created**: 2026-06-14
**Priority**: High
**Labels**: render, dog, animation, tricks, visual-review, tdd
**Estimated Effort**: Medium

## Context & Motivation

Spec **D11 — Performs the actual trick**:

> Trick poses must be legible as the specific trick (sit, lie down, roll over,
> spin, paw) — **not one generic animation reused for every command**. Reading the
> behavior is part of the skill.

Today the dog shows **one generic "offering" perk-pose for every trick**. The
active trick is known in `main.ts` (`activeTrick`) but only `{ untrain }` is
passed to the renderer — the **trick id never reaches `dogPose`**. So Sitt, Ligg,
Legg deg, Rull, Snurr, Sov, Ul all look identical when offered. Since "reading the
behavior is part of the skill," this undercuts the core game.

## Current State

- `src/main.ts` — `activeTrick: Trick` is known; `updateDog(state, now, opts)` is
  called with `opts = { untrain: true } | undefined`. Trick id not threaded.
- `src/render/dogState.ts` — `DogVisualOpts = { untrain?: boolean }`.
- `src/render/dogPose.ts` — `dogPose(visual, now, opts)` switches only on the
  6 visual states; the `offering` case is identical regardless of trick.
- 8 tricks (`src/core/tricks.ts`): `sitt`, `ligg`, `legg-deg`, `no-jump`
  (untrain), `rull`, `ul`, `sov`, `snurr`.

## Desired Outcome

When the correct behavior surfaces (the `offering` state), the dog adopts a pose
**legible as that specific trick**, building to the apex (the 060 apex channel
still rides on top):

| Trick | Read | Pose cue (primitive-level) |
|-------|------|----------------------------|
| sitt | sit | haunches/back lowered, front legs straight, head up |
| ligg | lie down | whole body lowered toward the ground, head forward |
| legg-deg | settle | body low + relaxed, head down/resting |
| rull | roll over | body roll (rotate around forward axis) |
| snurr | spin | body yaw rotation (turn in place) |
| sov | sleep | curl/lower, head tucked |
| ul | howl | head/snout raised up |
| no-jump (untrain) | calm = markable | calm settled pose (the *absence* of the jump) |

The apex (060) still crests at the markable instant within each trick's pose.
Reduced motion keeps the **static distinguishing pose** (D13) — a sit still reads
as a sit without the motion.

## Affected Components

### Files to Modify
- `src/render/dogState.ts` — extend `DogVisualOpts` with `trickId?: string`.
- `src/render/dogPose.ts` + `dogPose.test.ts` — `dogPose` takes `trickId` (via
  opts) and the `offering` case returns a **trick-specific** pose. Add pose
  channels as needed (e.g. `crouchY`, `bodyRollZ`, `bodyYaw`, `headPitch`).
  **Test-first** (pure pose selection/maths).
- `src/render/dogMesh.ts` — `applyPose` applies any new channels (body roll/yaw,
  crouch) to the root/body.
- `src/render/scene.ts` — pass `opts.trickId` into `dogPose`.
- `src/main.ts` — include `trickId: activeTrick.id` in the opts passed to
  `updateDog` (both call sites — the untrain one and the normal one).

### Dependencies
- **External**: none.
- **Internal**: 058 (`dogPose`), 060 (apex channel) — done.
- **Blocking**: none.

## Technical Approach

### Architecture Decisions

- **Trick → pose is a pure mapping**, keyed by trick id, with a sensible default
  (unknown/未mapped trick → the current generic perk so nothing breaks). This is
  the TDD-able part. Keep it in `dogPose.ts` (or a small `trickPose` helper it
  calls) — no Babylon.
- **Layer, don't replace.** The trick pose sets base offsets (crouch/roll/yaw);
  the 060 apex channel and tail wag still add on top so the markable instant still
  crests.
- **Reduced motion** keeps the static pose offset (a sit is still a sit), only the
  oscillation/transition is damped (D13).

### Behaviours to test (TDD, `dogPose.test.ts` additions)

1. offering with `trickId: 'sitt'` returns a pose distinct from `trickId: 'ligg'`
   (e.g. different `crouchY`/`headPitch`) — two tricks ≠ same pose.
2. `trickId: 'snurr'` returns a non-zero `bodyYaw`; `trickId: 'rull'` returns a
   non-zero `bodyRollZ`; sit/lie do not.
3. `trickId: 'ul'` raises the head (headPitch/headLift up) vs sov which lowers it.
4. An unknown/undefined trickId falls back to the existing generic offering pose
   (no throw, existing behavior preserved).
5. With `reducedMotion`, the trick's **static** distinguishing offset is retained
   (e.g. sit's crouchY non-zero) while oscillation is damped.
6. trickId only affects the `offering` (and untrain-calm) state — idle/confused/
   etc. unchanged by it.

### Implementation Steps

1. **TDD** the trick→pose mapping + new channels in `dogPose` (slices per
   behavior, red→green).
2. **Thread `trickId`** through opts: main.ts → scene.ts → dogState opts → dogPose.
3. **Apply** new channels in `dogMesh.applyPose` (body roll/yaw/crouch).
4. **Visual Review** — screenshot each trick's offering pose; confirm sit ≠ lie ≠
   spin ≠ roll ≠ howl ≠ sleep at a glance, and the apex still crests.

### Risks & Considerations

- **Risk: poses overlap the apex/tail channels** — **Mitigation**: trick pose =
  base offsets; apex + wag are additive; verify they compose, not fight.
- **Risk: roll/spin look broken with the blob shadow / face** — **Mitigation**:
  keep rotations modest (a lean/partial roll reads as "roll over" without a full
  flip that hides the face); review and tune.
- **Risk: too many channels bloat `DogPose`** — **Mitigation**: add only what's
  needed (crouchY, bodyRollZ, bodyYaw, headPitch); reuse existing headLift/bounce
  where possible.

## Before / After Examples

### Example 1: trick-aware offering pose (tested)

**Before** (`src/render/dogPose.ts`):
```ts
case "offering": {
  // identical for every trick
  const apex = smoothApex(prox) * strength;
  return { ...zero, headLiftY: 0.06 + apex*0.10, bodyLeanX: 0.05, tailWagAngle: wag*1.6, apexPop: apex };
}
```

**After**:
```ts
case "offering": {
  const apex = smoothApex(prox) * strength;
  const base = trickPose(opts.trickId);   // pure: sit→crouch, ligg→low, snurr→yaw, rull→roll, ul→head up...
  return {
    ...zero, ...base,
    headLiftY: base.headLiftY + apex*0.10*apexMotionScale,
    tailWagAngle: wag*1.6,
    apexPop: apex,
  };
}
```

### Example 2: trick id threaded through

**Before** (`src/main.ts`):
```ts
if (sceneApi) sceneApi.updateDog(state, now, activeTrick.untrain ? { untrain: true } : undefined);
```

**After**:
```ts
if (sceneApi) sceneApi.updateDog(state, now, { trickId: activeTrick.id, untrain: activeTrick.untrain });
```

## Code References

- `src/core/tricks.ts` — the 8 trick ids to map.
- `src/render/dogPose.ts` — pose maths (058) + apex (060) to extend.
- `src/render/dogMesh.ts` — `applyPose`, head/tail pivots, root for body roll/yaw.
- `src/main.ts` — `activeTrick`, the two `updateDog` call sites.
- `.docs/specs.md` "The Dog" D11/D6/D13, "Tricks".

## Progress Log

- 2026-06-14 — Task created (scan round 3, focus: dog).
- 2026-06-14 — Implemented fully (Part A TDD + Part B wiring + Visual Review).
  - Part A: 8 new tests written test-first (red→green per slice) in dogPose.test.ts.
    New channels: crouchY, bodyRollZ, bodyYaw, headPitch added to DogPose interface.
    trickPose() pure helper maps all 8 trick ids to bold, legible base offsets.
  - Part B: DogVisualOpts.trickId added; threaded main.ts (both call sites) →
    scene.ts → dogPose opts. dogMesh.applyPose applies crouchY to root.position.y
    (via scene.ts composition: BASE_Y + bounceY + crouchY), bodyRollZ/bodyYaw to
    root.rotation.z/y, headPitch to headPivot.rotation.x.
  - Also added __setTrick dev hook (harmless, no-op in prod) alongside __setBreed.
  - Visual Review: all 8 tricks captured at offering moment — poses clearly distinct
    at a glance (sitt=crouch, ligg=flat, legg-deg=flatter+head-down, rull=dramatic
    sideways tilt, snurr=dog faces camera, sov=low+head-tucked, ul=head-raised,
    no-jump=calm standing). Apex (BRA glow) composes on top of each trick pose.
  - 474 tests pass (466 pre-existing + 8 new). typecheck clean. build clean.

## Resolution

All acceptance criteria met. The dog now performs the specific trick visually during
the offering state (D11). trickId flows from activeTrick in main.ts through
DogVisualOpts → scene.ts → dogPose → DogPose channels → applyPose on the mesh.
The 060 apex channel composes additively on top of the trick base pose so the
markable instant still crests. Reduced motion retains the static trick offsets
(crouchY/bodyYaw/etc are not scaled by the reducedMotion multiplier).

## Acceptance Criteria

- [x] `DogVisualOpts` carries `trickId`; it's threaded main.ts → scene.ts → dogPose.
- [x] `dogPose` offering pose is **trick-specific**; new tests written **test-first**
      prove: sit ≠ lie pose, snurr yaw / rull roll non-zero, ul head-up vs sov
      head-down, unknown-trick fallback, reduced-motion retains the static pose,
      trickId only affects offering.
- [x] The 060 apex still crests within each trick's pose (composes, doesn't fight).
- [x] **Visual Review:** screenshots of each trick's offering show a distinct,
      legible pose at a glance (satisfies **D11**); reduced-motion still
      distinguishable.
- [x] `bun run test`, `bun run typecheck`, `bun run build` all pass; existing tests green.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
