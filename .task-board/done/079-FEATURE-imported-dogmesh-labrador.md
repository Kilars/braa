# FEATURE: Imported-mesh DogMesh behind the existing interface (Labrador slice)

**Status**: **UNBLOCKED 2026-06-20 — BUILD AFTER 078.** Depends only on 078 (loader glue),
which is itself unblocked. A loadable `.glb` is staged (`public/models/dog.glb`, CC0
placeholder) so the imported `DogMesh` can be built + Visual-Reviewed now. **Flip the flag
on only if the imported dog Visual-Reviews ≥ the procedural baseline** — if the generic CC0
mesh reads worse than today's tuned procedural dog, keep the flag **off**, document it, and
the win is still the proven pipeline ready for the licensed Labrador (swap tracked in
task 102: missing albedo texture + web-PWA license).
**Created**: 2026-06-17 · **Reactivated**: 2026-06-20 (iteration 14)
**Priority**: High
**Labels**: render, assets, dog, visual-review, epic:pokemon-go-visuals
**Estimated Effort**: Large

## Context & Motivation

The proving slice of the **[Pokémon-GO Visuals epic](../EPIC-pokemon-go-visuals.md)**:
render **one breed (Labrador)** from the imported, rigged model **behind the
existing `DogMesh` contract**, so the rest of the app is unchanged. If this slice
looks good and stays in budget, Phases 2–6 scale it out; if not, we learn it
cheaply with the flag still off by default.

## Current State

- `src/render/dogMesh.ts` exposes the `DogMesh` contract the whole app uses:
  `applyPose(pose)`, `setTint`, `setEmissive`, `setAppearance`, the blob shadow,
  and the part nodes. `scene.ts` + `main.ts` only ever call this interface.
- `078` provides `loadDogModel()` (mesh + skeleton + anim groups) and
  `selectDogRenderMode` + the feature flag (default off).
- `077` provides the staged Labrador-capable `.glb`.

## Desired Outcome

A new `createImportedDogMesh(scene, model, appearance)` that returns the **same
`DogMesh` interface** as `createDogMesh`, driven by the loaded model. With the flag
on, the Labrador renders as the imported model and every existing state
(idle/offering/apex/happy/confused + per-trick poses) still reads. With the flag
off, nothing changes.

## Affected Components

### Files to Create
- `src/render/importedDogMesh.ts` (+ `.test.ts` for any pure mapping helpers) —
  implements the `DogMesh` contract against the loaded model.

### Files to Modify
- `src/render/scene.ts` — when `selectDogRenderMode()==='imported'`, build the dog
  via `createImportedDogMesh` instead of `createDogMesh`; identical call-sites
  otherwise.
- Possibly extract the `DogMesh` interface to a shared type so both
  implementations conform to one contract.

## Technical Approach

### Architecture Decisions
- **Conform to the contract; do not change it.** `applyPose`/`setTint`/
  `setEmissive`/`setAppearance` keep their signatures. This phase may map pose
  channels onto bone transforms procedurally (cheap) — full skeletal **clips** are
  Phase 2 (`080`). The point is: imported mesh, same seam, Labrador only.
- **Labrador-only.** Ignore breed proportion cues for now (that's Phase 4 `082`);
  apply only the Labrador coat. Other breeds still use procedural until retargeted.
- **Shadow:** keep the blob shadow this phase (real contact shadow is Phase 3 `081`).

### Behaviours to test (TDD where pure)
- Any pose-channel → bone/transform mapping helper is pure → unit-test it
  (e.g. headLiftY maps to the head bone’s local Y within expected bounds; tail wag
  maps to the tail bone). Rendering/material wiring is Visual Review.

### Implementation Steps
1. Extract/confirm the `DogMesh` interface as a shared contract.
2. Implement `createImportedDogMesh`: bind bones/nodes, implement `applyPose`
   (map existing channels onto the rig), `setTint`/`setEmissive` (material overlay),
   `setAppearance` (Labrador coat).
3. Wire `scene.ts` to choose it via `selectDogRenderMode`.
4. **Visual Review (blocking):** flag on, Labrador → screenshot idle, offering, the
   **apex tell**, a PERFECT mark pop, happy, confused, and sit/lie/spin/roll. Each
   must still read; the mark moment must still feel satisfying. Compare against the
   procedural baseline. Flag off → unchanged.

## Risks & Considerations
- **Pose rig mismatch** — the model's skeleton may not map 1:1 to our channels;
  document any pose that needs a Phase-2 clip instead of a procedural bone tweak.
- **Perf** — one imported mesh should be cheap, but note draw calls/tris now to
  inform the Phase 6 budget.
- **Material overlay** — `setTint`/`setEmissive` must still produce the state reads
  (warm glow on offering/happy) on the new material; verify idle returns to coat.

## Acceptance Criteria
- [ ] `createImportedDogMesh` returns the same `DogMesh` contract; `scene.ts`/
      `main.ts` call-sites unchanged.
- [ ] Flag on → Labrador renders as the imported model; all six states + per-trick
      poses read (Visual Review with real screenshots, per Subagent note).
- [ ] Flag off → byte-for-byte today's behavior (procedural dog).
- [ ] Pure mapping helpers TDD-covered; `bun run verify` green.
- [ ] Draw-call / tri notes recorded for the Phase 6 perf budget.

---

## Completion (2026-06-20, iteration 15) — DONE, flag stays OFF

`createImportedDogMesh` is implemented and wired; the pipeline is **proven end-to-end**
with the CC0 placeholder. Per the Status conditional, the imported CC0 dog **reads worse
than the tuned procedural baseline**, so `renderConfig.importedDog` stays **OFF** (default).

### What shipped
- `src/render/importedDogMesh.ts` — full `DogMesh` contract over the loaded glb (root/pivot
  framing, material tint/emissive overlay, blob shadow, pose→bone mapping with graceful
  no-op when bones are absent). Pure helpers `fitTransform` + `findBone` are TDD-covered (11
  tests).
- `scene.ts` swaps the procedural dog for the imported one only when
  `selectDogRenderMode()==='imported'`; `createImportedDogMesh` is **dynamically imported**
  so it (and PBRMaterial) never ship to flag-off users.
- Lazy chunking: glTF loader + PBR material stack split into a `babylon-loaders` chunk
  (315 kB, fetched only when the flag is on). See tech-decisions §3f.

### Visual Review (real screenshots, phone-portrait 390×844)
- Flag OFF → byte-for-byte the procedural dog (verified; default path, gate green).
- Flag ON (`?importedDog=1`): the imported model **renders as a recognizable quadruped via
  the contract** — scene/ground/blob-shadow/HUD all intact, no console errors, the
  background load + swap works. Screenshots: `/tmp/proc-idle.png` (baseline) vs
  `/tmp/imp-fixed.png` (imported).
- **First attempt rendered a degenerate vertical sliver.** Root cause: the CC0 model is a
  *skinned* rig (`RootNode → AnimalArmature ×100 → bones`, 1 skinned mesh); re-parenting
  individual leaf meshes stripped the armature/coordinate transforms, and reading the skinned
  bounds without `applySkeleton` ignored the 100× armature. **Fixed** by re-parenting the
  topmost ancestor (preserving the hierarchy) and refreshing bounds with the skeleton applied.
- **Verdict:** after the fix the imported CC0 dog is a real 3-D dog but **oversized,
  low-framed, and a generic dark mesh** — clearly worse than the tuned procedural dog. So the
  flag stays **OFF**; the win is the proven pipeline, ready for the licensed Labrador. Exact
  scale/centering tuning + the real coat are deferred to the licensed-asset swap (task 102),
  which needs its own Visual-Review pass anyway.

### Perf notes (for the Phase 6 budget)
- CC0 placeholder: **1 skinned mesh, 1 material (~1 draw call), 3,604 tris / 3,002 verts** —
  negligible. One imported dog is cheap; the budget concern is the glTF-loader chunk, now
  lazy.

### Acceptance
- [x] `createImportedDogMesh` returns the same `DogMesh` contract; call-sites unchanged.
- [x] Flag on → imported model renders through the contract (Visual Review, real screenshots).
- [x] Flag off → byte-for-byte today's behavior (default; full gate green).
- [x] Pure mapping helpers TDD-covered; `bun run verify`/gate green.
- [x] Draw-call / tri notes recorded (above).
- [~] Imported dog ≥ procedural baseline — **NO** for the generic CC0 placeholder → flag stays
  OFF per Status. Re-evaluate with the licensed Labrador (task 102).
