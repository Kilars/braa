# FEATURE: Dog scene — recognizable dog, idle, sit-to-apex (Babylon)

**Status**: Done
**Created**: 2026-06-27
**Priority**: High (Phase 1 — the thing you look at)
**Labels**: visual, rendering, babylon, phase-1
**Estimated Effort**: Complex

## Context & Motivation

Phase 1 needs a dog worth looking at, alive at rest, that plays a legible sit building
to a clear apex (spec P1-1, P1-2, P1-3). This introduces Babylon.js (tech-decisions §1)
onto the canvas seam the scaffold leaves in place, plus the cheap backdrop + blob shadow
approach (tech-decisions §2/§2b).

## Desired Outcome
- Bright, clean Pokémon-GO-style backdrop; one dog centered, anchored by a blob shadow.
- No bare-primitive flash, no T-pose, no off-center drift (P1-1, P1-2, P1-9): hold
  hidden/neutral until the model is ready, then fade in.
- Ambient idle loop; a distinct sit animation that builds to a readable apex, wired to
  the timing core (task 002) so the apex tell (P1-4) fires on the real scoring peak.

## Affected Components
### Files to Create
- `src/render/scene.ts` — Babylon engine/scene/camera/light + render loop
- `src/render/backdrop.ts` — cheap gradient sky/ground (tech-decisions §2b)
- `src/render/dog.ts` — dog model load + idle/sit animation states + blob shadow
- (asset) CC0 placeholder dog for dev; licensed Labrador is owner-gated (ADR-0002/0006)

## Technical Approach
- Import only the needed `@babylonjs/core` modules; set `build.chunkSizeWarningLimit`
  in `vite.config.ts` so `bun run build` stays warning-free.
- **Visual task**: run the `polish` skill + spawn phone-portrait (390×844) review
  agents against the running app; their findings are blocking (P1-10, X-6).
- Reduced-motion: dampen idle/apex/reaction, never remove the pose cue (P1-8, X-5).

## Risks & Considerations
- **Risk**: WebGL under headless Chrome in e2e. **Mitigation**: assert deterministic
  readiness flags / DOM, not pixels; keep the WebGL smoke check tolerant.
- **Risk**: licensed-asset gate. **Mitigation**: build to the CC0 placeholder; the
  licensed Labrador is a one-line swap (tech-decisions §3h), owner-injected in CI.

## Acceptance Criteria
- [x] Dog reads as a real dog, centered, shadow-anchored; no primitive/T-pose flash
- [x] Idle loop + distinct sit-to-apex animation, smooth (no slide/clip/snap)
- [x] Apex tell fires on the real scoring peak (wired to task 002)
- [x] Passes `polish` + independent phone-portrait Visual Review (P1-10)
- [x] Verify gate stays green (typecheck/test/build/e2e)

## Resolution (2026-06-27)

Done. Full gate green: `typecheck` 0 errors · `test` 28 passed · `build` no warnings ·
`e2e` 3 passed. Two independent phone-portrait reviewers PASS with no blockers (nits
only: faintly plump torso, far ear softly blending at the apex, tail occluded when
seated — all "within charming low-poly").

Key fixes this iteration (driven by the blocking Visual Review):

1. **Honest apex-tell capture (`scene.ts`).** `setPose`/`__braPose` used to freeze only
   the dog while the apex ring kept following the *live* clock, so every capture frame's
   ring was random vs. its pose (a build pose under a peak ring; the seated apex under a
   dark ring). Now it freezes the **shared clock** (`poseFreezeTime`, scrubbing cycle 0's
   BUILD), so pose and tell derive from one instant — the ring is dark through the build
   and peaks only at the seated apex, exactly as a player sees it. The capture spec lost
   its flaky live-wait + manual `--apex=1` poke; it now emits three honest frames
   (`01-stand`, `02-build`, `03-apex`). This is capture-only; play is unchanged.

2. **Dog face/model (`dog.ts`).** Reviewers blocked on the head at the apex up-tilt: a
   boxy snout read as a dark cavity, the head looked detached, eyes merged/one-eyed, ears
   were hard cubes. Fixed: rounded muzzle (no open box face), small reseated nose pad,
   added a **neck** bridging chest→head, eyes seated higher/wider, **soft drop ears**
   (flattened spheres, not boxes), rump blended into the torso, and — the root cause —
   the apex head pitch reduced (the shoulder lift already raises the gaze; the head now
   pitches *down* relative to it) so the face stays toward the camera: proud, not
   snout-to-the-sky. Re-review: 2/2 PASS.

Note: `e2e/_capture.spec.ts` remains a TEMPORARY non-gate harness for the review; the
licensed Labrador swap stays owner-gated (built to the composed CC0-style placeholder).
