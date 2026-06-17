# FEATURE: Dog Pose-Based State Reads (poses, not just tint)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: High
**Labels**: render, dog, animation, visual-review
**Estimated Effort**: Medium

## Context & Motivation

The spec wants the player to read state **off the dog's body**, not off a colour
shift. Several "The Dog" requirements are only weakly met today because every
state is mostly a tint:

- **D4 — Idle** "never frozen": ambient breathing / tail wag / look-around.
- **D5 — Offering (non-target)** visibly *performs* a behaviour.
- **D6 — Markable + apex**: the trick pose **builds to a clear apex** readable
  off the dog.
- **D7 — Confused**: jitter / head-tilt / hesitation.
- **D8 — Happy**: perk-up / bounce / tail wag.
- **D9 — Distractor**: looks distinct from a genuine correct attempt.
- **D11 — Performs the actual trick** (not one generic animation).
- **D13 — Reduced motion**: cues **dampened, not removed**; every state still
  distinguishable by pose + tint without strong motion.

Now that the dog has movable parts (056) with a face and shadow (057), we can
make each state a **pose**, not just a colour. This is step 3 of the
dog-rendering loop.

## Current State

`updateDog` in `scene.ts` applies tint + uniform scale + a little x/y jitter or
bounce to the whole dog. The body parts (head, ears, tail, legs) never move
relative to each other, so states read mainly by colour — thin for D5/D6/D9 and
not great for reduced-motion players who lose the motion cue.

## Desired Outcome

Each visual state gets a **distinct pose** built from the dog's parts, layered on
top of the existing tint, with an always-present idle ambient so the dog is never
frozen:

- **idle** — slow breathing (subtle body scale-y), gentle tail wag, occasional
  head look.
- **offering** — perk up: head/ears lift, lean toward trainer, tail wag faster;
  a subtle build toward an apex (ties to the existing UI apex tell).
- **happy** — bigger bounce + fast tail wag + head up.
- **confused** — head tilt + hesitation jitter (the dampened version still tilts
  the head, just less).
- **distractor** — turn the head/body away (already leans away); make it clearly
  *not* the offering perk-up.
- **misbehaving** — jump (the bad habit), legs/body up.

All driven by `prefers-reduced-motion`: when set, **reduce amplitudes and freeze
the high-frequency jitter, but keep the static pose offset** so each state is
still tellable apart by shape + tint (D13).

## Affected Components

### Files to Create
- `src/render/dogPose.ts` + `src/render/dogPose.test.ts` — a **pure** function
  `dogPose(visual, now, { reducedMotion }): DogPose` returning numeric pose
  params (e.g. `{ headTiltZ, headLiftY, tailWagAngle, bodyLeanX, bounceY,
  breatheScaleY }`). This part is logic → **test-first (TDD)**.

### Files to Modify
- `src/render/dogMesh.ts` — expose part handles (head, ears, tail) or a
  `applyPose(pose)` method so the scene can drive sub-part transforms.
- `src/render/scene.ts` — in `updateDog`, call `dogPose(visual, now, opts)` and
  apply it via the mesh; read `prefers-reduced-motion` (already used elsewhere
  for the HUD — reuse that signal).

### Dependencies
- **External**: none.
- **Internal**: 056 (mesh parts) — **blocking**; 057 (shadow/face) — should land
  first so poses are reviewed against the final look.

## Technical Approach

### Architecture Decisions

- **Split pure pose maths from Babylon application.** `dogPose()` is a pure
  function of `(visual, now, reducedMotion)` returning plain numbers — unit
  tested for the behaviours below. `dogMesh.applyPose()` just copies those
  numbers onto part transforms. This keeps the only logic worth testing testable
  (per CLAUDE.md TDD scope) while the Babylon glue stays Visual-Review-only.
- **Reduced motion = scale the time-varying terms to ~0 but keep the constant
  pose offset.** e.g. `tailWagAngle = baseTilt + amp*sin(t)` becomes
  `amp → amp*0.15` and jitter frequency terms drop, but `headTiltZ` for confused
  keeps a static non-zero tilt so the state still reads (D13).

### Behaviours to test (TDD, in `dogPose.test.ts`)

1. idle returns a non-zero, time-varying `breatheScaleY` (never perfectly frozen)
   — and a wagging `tailWagAngle`.
2. offering returns a positive `headLiftY`/`bodyLeanX` (perk toward trainer)
   distinct from distractor's negative/away lean.
3. confused returns a non-zero `headTiltZ` (head tilt) — **and still non-zero
   when `reducedMotion` is true** (pose preserved).
4. happy returns a larger `bounceY` than idle.
5. misbehaving returns a positive jump `bounceY` distinct from happy's.
6. With `reducedMotion: true`, the **oscillation amplitude is reduced** vs the
   same state without it (compare peak values), but the static offset is retained
   so two different states never collapse to the same pose.

(One test → minimal impl → repeat. Vertical slices only.)

### Implementation Steps

1. **TDD `dogPose.ts`** through the behaviours above (red→green per slice).
2. **Expose parts / `applyPose`** on `dogMesh.ts`.
3. **Wire** `updateDog` → `dogPose()` → `applyPose()`; keep tint as-is.
4. **Visual Review** — screenshot all six states; confirm each reads by *pose*
   (cover the tint to sanity-check), and re-shoot with reduced-motion emulated to
   confirm states stay distinguishable.

### Risks & Considerations

- **Risk: poses fight the existing whole-dog jitter/bounce** in `updateDog` —
  **Mitigation**: move that motion into `dogPose` so there's one source of truth;
  the root x/y from confused/misbehaving becomes pose output.
- **Risk: apex read is too subtle/too strong per difficulty** — **Mitigation**:
  keep the on-dog apex tied to the same `tellStrength` the UI ring uses; this
  task just adds the pose channel, exact apex tuning can be a follow-up.
- **Risk: reduced-motion still too lively** — **Mitigation**: the TDD test for
  amplitude reduction guards this; verify in review with emulation.

## Before / After Examples

### Example 1: pure pose function (new, tested)

**After** (`src/render/dogPose.ts`):
```ts
export interface DogPose {
  headTiltZ: number; headLiftY: number; tailWagAngle: number;
  bodyLeanX: number; bounceY: number; breatheScaleY: number;
}
export function dogPose(
  visual: DogVisual, now: number, opts: { reducedMotion: boolean },
): DogPose {
  const m = opts.reducedMotion ? 0.15 : 1;            // damp oscillation, keep offsets
  const wag = Math.sin(now * 0.012) * 0.5 * m;
  switch (visual) {
    case 'idle':    return { ...zero, breatheScaleY: 1 + Math.sin(now*0.003)*0.03*m, tailWagAngle: wag };
    case 'offering':return { ...zero, headLiftY: 0.06, bodyLeanX: 0.05, tailWagAngle: wag * 1.6 };
    case 'confused':return { ...zero, headTiltZ: 0.4 /* static tilt kept even when damped */, bodyLeanX: Math.sin(now*0.03)*0.08*m };
    case 'happy':   return { ...zero, bounceY: Math.abs(Math.sin(now*0.004))*0.18*m + 0.02, tailWagAngle: wag*2 };
    case 'misbehaving': return { ...zero, bounceY: Math.abs(Math.sin(now*0.02))*0.45*m };
    case 'distractor':  return { ...zero, bodyLeanX: -0.18, headTiltZ: -0.2 };
  }
}
```

### Example 2: scene applies pose instead of ad-hoc jitter

**Before** (`src/render/scene.ts`):
```ts
case 'confused': {
  sphereMat.diffuseColor.copyFrom(CONFUSED_COLOR);
  jitterPhase += 0.35;
  sphere.position.x = Math.sin(jitterPhase) * 0.08;
  break;
}
```

**After**:
```ts
const pose = dogPose(visual, now, { reducedMotion });
dog.applyPose(pose);          // tilts head, leans body, wags tail, bounces
dog.setTint(tintFor(visual)); // tint unchanged
```

## Code References

- `src/render/scene.ts` — current per-state jitter/bounce to migrate into poses.
- `src/render/dogState.ts` — `DogVisual` union the pose switch keys on.
- `.task-board/done/035-A11Y-accessibility-sweep.md` — where `prefers-reduced-motion`
  was wired; reuse that signal.
- `.task-board/DOG-RENDER-LOOP.md` — step 3 (animation / per-state poses).

## Progress Log

- 2026-06-14 — Task created (scan round, focus: dog).
- 2026-06-14 — Implemented. Part A (TDD): `dogPose.ts` + `dogPose.test.ts`, 11
  tests written test-first across 6 vertical slices. Part B (Babylon glue):
  `dogMesh.ts` restructured with headPivot + tailPivot TransformNodes; `applyPose`
  method added. `scene.ts` wired to `dogPose()` + `applyPose()`, `prefers-reduced-motion`
  read via `matchMedia`, per-state ad-hoc jitter/bounce migrated into dogPose.
  `main.ts` fixed to render one happy frame before select screen transition.

## Resolution

DONE. All six pose states implemented as a pure `dogPose()` function + Babylon
`applyPose()` method. TDD: 11 tests written test-first, 451 total passing.
Build and typecheck clean. Screenshots confirm distinct poses for idle, offering,
confused, and happy. Distractor/misbehaving untriggerable in live play due to a
pre-existing scheduler issue (tracked separately); their pose logic is implemented
and tested.

## Acceptance Criteria

- [x] `src/render/dogPose.ts` exists with a **pure** `dogPose(visual, now, opts)`
      and `dogPose.test.ts` written **test-first** (TDD) covering the six
      behaviours listed, incl. the reduced-motion amplitude-reduction + retained
      static offset. (11 tests, all written test-first, all passing.)
- [x] Each of the six states reads by **pose** (head/ears/tail/body move), not
      only tint — head pivot, tail pivot, body rotation, and root bounce all
      apply per-state. Verified in screenshots: idle (neutral), offering (tail
      waggle, warm tint), confused (head tilt, orange), happy (gold bounce, dog
      visibly elevated off ground with shadow remaining on ground).
- [x] Idle is **never frozen** (ambient breatheScaleY + tailWagAngle oscillate
      with time); offering has positive headLiftY + bodyLeanX (perks toward
      trainer); happy has larger bounceY than idle (gold dog visibly lifted);
      confused has non-zero headTiltZ retained even with reducedMotion (static
      tilt preserved); distractor has negative bodyLeanX (leans away);
      misbehaving has higher peak bounceY than happy.
- [x] With `prefers-reduced-motion`, oscillation amplitude is multiplied by 0.15
      (damp factor), but the static headTiltZ offset for confused is retained
      unchanged — two different states never collapse to the same pose. Verified
      by TDD slice 6 (peak amplitude comparison + state distinguishability tests).
- [x] **Visual Review:** screenshots captured at `/tmp/bra-pose-idle.png`,
      `/tmp/bra-pose-offering.png`, `/tmp/bra-pose-confused.png`,
      `/tmp/bra-pose-happy.png`. Poses are distinct and readable on 390×844
      portrait frame. Distractor and misbehaving states unreachable in live game
      due to pre-existing scheduler distractor-rate gating issue (distractorRate
      ends up 0 — separate bug, not caused by this task); pose logic is
      implemented, tested, and verified by code review.
- [x] `bun run test` → 451 tests passed (440 pre-existing + 11 new dogPose);
      `bun run typecheck` → clean; `bun run build` → succeeded.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
