# FEATURE: Wire the seeded glTF dog model into the scene (procedural fallback)

**Status**: Backlog
**Created**: 2026-06-27
**Priority**: High (Phase 1 debt — P1-1 is not actually met by the primitive dog)
**Labels**: visual, rendering, babylon, phase-1, assets
**Estimated Effort**: Complex

## Context & Motivation

P1-1 demands a realistic, breed-recognizable dog with **no bare primitive geometry** —
"hold hidden until the model is ready, then fade in". The live dog is a procedural
sphere/cylinder build (`src/render/dog.ts`); it was shipped as the *product* when it was
only ever meant to be the *fallback*. The real asset + loader pipeline now exists in-tree,
seeded from v1 (ADR-0007): `dogModelSource`, `dogModelLoader`, `assetCrypto`, `dogPackKey`,
and the CC0 `public/models/dog.glb`. This task makes the loaded model the primary dog.

## Desired Outcome
- The scene loads `public/models/dog.glb` via `loadDogModel` and renders it when the load
  reaches `ready`; on **any** non-ready state (loading/failed/timeout) it falls back to the
  procedural dog via `selectDogRenderMode` — the app is never broken.
- No primitive-geometry dog is shown once the imported path is `ready` (P1-1, P1-9).
- The imported dog drives the same pose contract the procedural dog exposes
  (`pose(buildAmount, now, reducedMotion, poseKind)`) so sit/ligg + idle + the apex tell and
  reaction all still work, wired to the timing core (tasks 002/005).

## Affected Components
- `src/render/scene.ts` — enter the imported path, manage `DogLoadState`, fall back.
- **New** `src/render/importedDog.ts` — re-fit of v1's `importedDogMesh` + `dogAnimationMap`
  to v2's rig. **Do NOT copy v1's versions** — they couple to v1's `dogState/dogPose/
  dogMesh/dogAppearance`. Map v2's `PoseKind` (sit/liedown) onto the model's clips/bones.
- `src/render/dog.ts` — stays as the guaranteed procedural fallback.

## Technical Approach
- The glTF loader is dynamic-imported (lazy chunk) — keep it that way; don't static-import
  `@babylonjs/loaders` into the entry.
- Licensed Labrador stays gated (ADR-0006/0007): the committed web build serves only the CC0
  `dog.glb`; the licensed path is the later `resolveDogModelDescriptor` → packed swap.

## Acceptance Criteria
- [ ] Imported CC0 model renders as the dog; procedural dog only on non-ready load
- [ ] **Source check**: when the imported path is active, the dog has no `MeshBuilder.Create*`
      primitive body (an independent grep/assert, not a self-review)
- [ ] sit/ligg, idle, apex tell, and mark reaction all work on the imported dog
- [ ] Independent phone-portrait Visual Review judged against the **literal** P1-1 clauses
      (loaded model, zero primitives), not "reads as a dog"
- [ ] Verify gate green (typecheck/test/build/e2e)

## Notes
Seeded by ADR-0007. This is the "make the dog real work" follow-up — it only became
buildable once the asset + loader were ported in; before that the loop had nothing to load.
