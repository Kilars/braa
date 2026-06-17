# FEATURE: On-Dog Apex Build (D6 — the markable instant reads off the dog)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: High
**Labels**: render, dog, animation, timing, visual-review, tdd
**Estimated Effort**: Medium

## Context & Motivation

Spec **D6 — Markable behavior + apex**:

> When the *correct* behavior surfaces, the dog performs that trick's pose and its
> animation **builds to a clear apex** — the markable instant — readable off the
> dog itself, reinforcing the UI apex tell. Per difficulty the on-dog apex gets
> **fainter/faster**.

Right now the `offering` pose (from 058) is a **steady perk-up** — head lifts and
the dog leans in, but it does **not build to a peak and release**. The player
reads the markable instant only from the UI gold ring (the `tellStrength` apex
cue), not from the dog. D6 wants the dog's body to *also* crest at the peak, and
to get **fainter/faster on harder difficulty** (the existing `tellStrength`
already encodes this for the UI ring — reuse it).

## Current State

- `src/render/dogPose.ts` — `dogPose(visual, now, { reducedMotion })` returns a
  static-ish offering pose (constant `headLiftY`/`bodyLeanX`, time-based tail wag).
  It has **no notion of how close "now" is to the attempt's peak**.
- The apex timing already exists: the scheduler attempt has an active window with a
  peak; the UI apex ring is driven by a `tellStrength`/peak-proximity value
  (introduced in 014-FEATURE-apex-tell-cue). The dog pose just doesn't consume it.

## Desired Outcome

During an offering/markable attempt, the dog's pose **builds toward the peak and
crests at the apex** (e.g. a gather/crouch that pops up, or a rising
head/anticipation that peaks exactly at the markable instant), then settles —
readable off the dog. The apex strength scales with the same difficulty signal as
the UI ring, so harder modes make the on-dog apex **fainter and faster** (D6).
Reduced motion keeps a (dampened) but still-present apex cue (D13).

## Affected Components

### Files to Modify
- `src/render/dogPose.ts` + `src/render/dogPose.test.ts` — add a **peak-proximity**
  input (e.g. `apexProgress: number` 0..1, or `peakProximity` 0..1 where 1 = at
  apex) and an optional `tellStrength` (0..1) so offering returns an apex-peaked
  pose channel (e.g. `apexPop` / a boosted `headLiftY` that maxes at the peak).
  **Test-first** (this is pure maths).
- `src/render/scene.ts` — compute peak proximity for the current attempt (reuse
  whatever the UI apex ring uses) and pass it + `tellStrength` into `dogPose`.

### Dependencies
- **External**: none.
- **Internal**: 058 (`dogPose`), 014 (apex tell / `tellStrength`) — done.
- **Blocking**: none. Independent of 059; can land in either order.

## Technical Approach

### Architecture Decisions

- **Reuse the existing peak-proximity signal** that drives the UI gold ring rather
  than inventing a second timing source — one source of truth keeps the on-dog
  apex and the UI ring in sync (they must agree on the markable instant). Find it
  in `scene.ts`/the apex-tell code (014) and thread it into `dogPose`.
- **Apex shape = a smooth 0→1→0 around the peak.** A function of `peakProximity`
  (e.g. `apex = smooth(peakProximity)`) scaled by `tellStrength`. The pose adds
  this to the offering perk so the body visibly crests at the markable instant.
- **Difficulty = scale by `tellStrength`** (already fainter/faster per difficulty
  from 014). Reduced motion multiplies the *motion* down but keeps a small static
  apex offset so the cue still exists.

### Behaviours to test (TDD, `dogPose.test.ts` additions)

1. offering at `peakProximity = 1` (at apex) returns a **larger** apex/headLift
   value than at `peakProximity = 0` (windows edge) — the pose peaks at the apex.
2. The apex magnitude **scales with `tellStrength`**: lower tellStrength → smaller
   apex pop (fainter on harder difficulty).
3. Non-offering states ignore `peakProximity` (idle/happy/etc. unchanged by it).
4. With `reducedMotion`, the apex pop amplitude is reduced but **non-zero** at the
   peak (cue retained, D13).

### Implementation Steps

1. **TDD** the apex channel in `dogPose` (behaviours 1–4, red→green per slice).
2. **Thread peak-proximity + tellStrength** from `scene.ts` into `dogPose` each
   frame (reuse the UI apex source).
3. **Apply** the apex pop in `dogMesh.applyPose` (it's just another pose number).
4. **Visual Review** — screenshot/observe an attempt: confirm the dog visibly
   crests at the markable instant and the UI ring agrees; check a harder mode shows
   a fainter on-dog apex; check reduced-motion still shows a (smaller) crest.

### Risks & Considerations

- **Risk: on-dog apex and UI ring disagree** on the peak instant (confusing) —
  **Mitigation**: derive both from the same peak-proximity value; do not
  re-derive timing in `dogPose`.
- **Risk: too subtle to read** at faint/Expert tellStrength — **Mitigation**:
  that's intended (fainter per difficulty), but verify the Normal-mode apex is
  clearly readable in review.
- **Risk: fighting the tail-wag/perk terms** — **Mitigation**: keep apex as its
  own additive channel layered on the offering pose.

## Before / After Examples

### Example 1: apex-aware pose maths (tested)

**Before** (`src/render/dogPose.ts`):
```ts
export function dogPose(visual, now, opts: { reducedMotion: boolean }): DogPose {
  // offering: constant perk — no peak awareness
  case 'offering': return { ...zero, headLiftY: 0.06, bodyLeanX: 0.05, tailWagAngle: wag*1.6 };
```

**After**:
```ts
export function dogPose(
  visual, now,
  opts: { reducedMotion: boolean; peakProximity?: number; tellStrength?: number },
): DogPose {
  const m = opts.reducedMotion ? 0.15 : 1;
  case 'offering': {
    const prox = opts.peakProximity ?? 0;             // 0..1, 1 = at apex
    const apex = smooth01(prox) * (opts.tellStrength ?? 1); // fainter on harder difficulty
    return { ...zero, headLiftY: 0.06 + apex * 0.10 * (0.3 + 0.7*m), bodyLeanX: 0.05, tailWagAngle: wag*1.6, apexPop: apex * m };
  }
```

### Example 2: scene feeds the same peak signal as the UI ring

**After** (`src/render/scene.ts`):
```ts
// peakProximity / tellStrength already computed for the UI apex ring (014)
const pose = dogPose(visual, now, { reducedMotion, peakProximity, tellStrength });
dog.applyPose(pose);
```

## Code References

- `src/render/dogPose.ts` — pose maths from 058 (extend here).
- `.task-board/done/014-FEATURE-apex-tell-cue.md` — where `tellStrength`/the apex
  ring came from; the signal to reuse.
- `src/render/scene.ts` — where the UI apex cue is computed (the integration point).
- `.docs/specs.md` "The Dog" D6, "Difficulty Levers".

## Progress Log

- 2026-06-14 — Task created (scan round 2, focus: dog).
- 2026-06-14 — Implemented. Part A (TDD): 4 new tests written test-first in
  `dogPose.test.ts` covering apex peak, tellStrength scaling, non-offering
  isolation, and reducedMotion floor. Part B (wiring): `peakProximity` added to
  `HudViewModel`/`toViewModel`, threaded via `DogVisualOpts` into `scene.ts` →
  `dogPose`. Same `vm.peakProximity` and `vm.tellStrength` values used for both
  the UI ring and the dog pose — one source of truth. Visual review: screenshots
  confirmed clear head lift and body lean crest at ring opacity ~0.94. All 466
  tests pass, typecheck clean, build passes.

## Resolution

Implemented in four files:
- `src/render/dogPose.ts` — added `smoothApex()`, extended `offering` case with
  `peakProximity`/`tellStrength`/`reducedMotion`-aware apex channel (headLiftY
  +0.10, bodyLeanX +0.04 at full apex; reducedMotion floor = 30%).
- `src/render/dogPose.test.ts` — 4 new TDD tests under "apex-pop (offering)".
- `src/ui/viewModel.ts` — added `peakProximity` field to `HudViewModel`;
  refactored `toViewModel` to derive `peakProximity` first, then
  `tellStrength = peakProximity * tellIntensity` (same geometry, no second source).
- `src/render/dogState.ts` — added `peakProximity` and `tellStrength` to
  `DogVisualOpts`.
- `src/render/scene.ts` — threads `opts.peakProximity` and `opts.tellStrength`
  into `dogPose` each frame.
- `src/main.ts` — passes `vm.peakProximity` and `vm.tellStrength` to `updateDog`
  on every tick.

## Acceptance Criteria

- [x] `dogPose` takes a peak-proximity (and `tellStrength`) input; new tests
      written **test-first** prove: offering pose peaks at the apex, apex scales
      with `tellStrength`, non-offering states ignore it, reduced-motion apex is
      reduced-but-non-zero.
- [x] The on-dog apex is driven by the **same** peak signal as the UI apex ring
      (no second timing source); they crest together.
- [x] **Visual Review:** during a Normal-mode attempt the dog visibly builds to and
      crests at the markable instant; a harder mode shows a fainter/faster on-dog
      apex; reduced-motion still shows a (smaller) crest (D6/D13).
- [x] `bun run test`, `bun run typecheck`, `bun run build` all pass.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
