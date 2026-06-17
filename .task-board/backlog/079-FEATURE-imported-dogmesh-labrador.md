# FEATURE: Imported-mesh DogMesh behind the existing interface (Labrador slice)

**Status**: Backlog — **blocked on 077 + 078**
**Created**: 2026-06-17
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

**Next Steps**: Unblocked after 077 (model) + 078 (loader). Largest slice in
Phase 1 — expect iteration in Visual Review.
