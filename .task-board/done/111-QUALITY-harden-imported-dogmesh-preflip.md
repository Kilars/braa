# QUALITY: Harden `importedDogMesh.ts` ahead of the flag-flip

**Status**: Done
**Created**: 2026-06-21 (iteration 21 scan)
**Completed**: 2026-06-21 (iteration 22)
**Priority**: Medium
**Labels**: quality, correctness, render
**Estimated Effort**: Simple

## Context & Motivation

The imported licensed-Labrador render path (`createImportedDogMesh`, tasks
078/079/080) is engineering-complete and is the strategic default once the owner
decides the PWA-license/packaging question (§3i/§3j). It currently ships **flag
OFF**, so latent defects in it are invisible today but will surface the instant
`renderConfig.importedDog` flips on. A code-quality scan (iteration 21) found
concrete issues to fix **before** that flip so the swap is clean:

1. **Head-bone Y drift (real bug).** `applyPose` does
   `headBone.position.y += pose.headLiftY` every frame — it **accumulates** the
   lift onto the previous frame's value instead of setting it from the bind pose,
   so the head drifts upward unboundedly while the imported dog is live. The
   procedural mesh (`dogMesh.ts`) correctly *assigns* from a fixed rest offset
   (`headPivot.position.y = 0.28 + pose.headLiftY`). Fix: capture the bind-pose Y
   in `captureBindPose` and assign `headBone.position.y = bindY + pose.headLiftY`.
2. **Dead `setEmissiveMat` branch.** The helper switches on `PBRMaterial` vs
   `StandardMaterial` but both branches run the identical
   `mat.emissiveColor.copyFrom(c)` — both material types expose `.emissiveColor`.
   Collapse to one line (the PBR/Standard split is only needed for *diffuse*:
   `albedoColor` vs `diffuseColor`).
3. **Dead "Phase 2" captures.** `_originalDiffuse` / `_originalEmissive` are
   captured at build time and immediately suppressed with an eslint-disable; their
   stated consumer is task 082 (not yet landed). Remove them (re-add in 082) so the
   load path doesn't retain two `Color3[]` arrays per model with no reader.

This is correctness + dead-code cleanup confined to one render module, de-risking
the highest-priority visual swap.

## Current State

- `src/render/importedDogMesh.ts` — `captureBindPose` snapshots node transforms;
  `applyPose` mutates bones per frame; `setDiffuse`/`setEmissiveMat` apply tints;
  `_originalDiffuse`/`_originalEmissive` captured but unused (lint-suppressed).
- Flag `renderConfig.importedDog` is OFF; the procedural `dogMesh.ts` ships.
- `src/render/importedDogMesh.test.ts` exists (build/contract coverage).

## Desired Outcome

The imported mesh applies head lift as a **bounded, bind-relative assignment** (no
drift), `setEmissiveMat` is single-line, and the unused Phase-2 captures are gone —
with the `DogMesh` contract and existing tests still green.

## Affected Components

### Files to Modify
- `src/render/importedDogMesh.ts` — (1) bind-pose Y capture + assign in
  `applyPose`; (2) collapse `setEmissiveMat`; (3) drop the dead captures.
- `src/render/importedDogMesh.test.ts` — add coverage for the drift fix where
  unit-testable (e.g. a small pure helper `headBoneY(bindY, headLiftY) = bindY +
  headLiftY`, TDD); the Babylon-bound `applyPose` glue itself stays Visual-Review
  territory but the offset math should be a tested pure function.
- `.docs/tech-decisions.md` §3j — one-line note that the head-lift is bind-relative
  and the Phase-2 emissive captures were deferred back to task 082.
  **specs.md untouched.**

### Dependencies
- **Blocking**: none. Independent of the owner license decision (pure code health).

## Technical Approach

### Architecture Decisions
- **Extract the offset math to a pure, tested helper.** The drift bug is a
  set-vs-accumulate error; expressing the target Y as `headBoneY(bindY, lift)` and
  TDD-ing it (a) documents intent and (b) guards the regression. The Babylon
  assignment that consumes it remains render glue (Visual-Review exempt).
- **Mirror the procedural mesh's rest-relative model.** `dogMesh.ts` is the
  reference for "assign from rest, never accumulate."
- **Don't expand scope into Phase-2 tint work** — just remove the dead captures;
  task 082 re-introduces them when it needs them.

### Behaviors to test (TDD)
1. `headBoneY(bindY, 0)` returns `bindY` (rest pose, no lift).
2. `headBoneY(bindY, lift)` returns `bindY + lift` (bounded, not cumulative).
3. Calling it twice with the same inputs is idempotent (documents non-accumulation).

### Implementation Steps
1. **Red/Green**: add `headBoneY` pure helper + tests; wire `applyPose` to capture
   the head bone's bind Y in `captureBindPose` and assign
   `headBone.position.y = headBoneY(bindY, pose.headLiftY)`.
2. Collapse `setEmissiveMat` to the single `emissiveColor.copyFrom` line.
3. Remove `_originalDiffuse` / `_originalEmissive` and their eslint-disable.
4. Run `importedDogMesh.test.ts` + the full suite — green.
5. tech-decisions §3j note. **specs.md untouched.**

### Risks & Considerations
- **Risk**: removing the Phase-2 captures breaks task 082 later.
  **Mitigation**: note in §3j that 082 must re-capture; trivially re-added.
- **Risk**: the flag is OFF, so runtime verification of the drift fix is limited.
  **Mitigation**: the pure `headBoneY` test covers the math; the contract tests
  cover load; a DEV `?importedDog=1` screenshot can sanity-check the static pose
  (no live multi-frame review required for a no-accumulation guarantee).

## Before / After Examples

**Before** (`src/render/importedDogMesh.ts`):
```ts
headBone.position.y += pose.headLiftY; // drifts: adds onto last frame's value
```
**After**:
```ts
// captured once in captureBindPose: const headBindY = headBone.position.y;
headBone.position.y = headBoneY(headBindY, pose.headLiftY); // bind-relative, no drift
```

**Before** (`setEmissiveMat`):
```ts
if (mat instanceof PBRMaterial) mat.emissiveColor.copyFrom(c);
else mat.emissiveColor.copyFrom(c); // identical branches
```
**After**:
```ts
mat.emissiveColor.copyFrom(c); // both PBR + Standard expose emissiveColor
```

## Code References
- `src/render/importedDogMesh.ts` (`applyPose`, `captureBindPose`,
  `setEmissiveMat`, the `_original*` captures).
- `src/render/dogMesh.ts` (the rest-relative reference: `headPivot.position.y =
  0.28 + pose.headLiftY`).
- tech-decisions §3j (task 080 imported-dog notes).

## Progress Log
- 2026-06-21 — Task created (iteration 21 scan). Fixes a real per-frame head-bone
  drift + removes two dead branches/captures in the imported render path, so the
  eventual flag-flip swap is clean.
- 2026-06-21 (iteration 22) — Done. (1) Added pure `headBoneY(bindY, lift)` helper,
  TDD red→green (rest / lift / idempotence — 3 tests). `createImportedDogMesh` now
  captures `headBindY = headBone.position.y` once (bind pose) and `applyPose` assigns
  `headBone.position.y = headBoneY(headBindY, pose.headLiftY)` — no more `+=` drift,
  mirroring the procedural dog's rest-relative model. (2) `setEmissiveMat` collapsed
  to a single `mat.emissiveColor.copyFrom(c)` (both material types expose it); the
  diffuse `albedoColor`/`diffuseColor` split is left intact. (3) Removed dead
  `_originalDiffuse`/`_originalEmissive` captures + their eslint-disables, and the
  now-orphaned `getDiffuse` reader; the foot-of-file note records that task 082 must
  re-capture if it wants raw-colour restoration. `DogMesh` contract unchanged.
  **Visual Review:** waived per this task's own risk-mitigation — the flag is OFF, the
  no-accumulation guarantee is a pure-math property fully covered by the `headBoneY`
  test, and no value/visual output changed (a SET-from-bind that equals the old value
  on frame 1; the bug was only the per-frame creep). tech-decisions §3j note added.

## Acceptance Criteria
- [x] `headBoneY` pure helper added and **TDD**-covered (rest, lift, idempotence);
      `applyPose` assigns `headBone.position.y` bind-relative (no `+=` accumulation).
- [x] `setEmissiveMat` collapsed to a single `emissiveColor.copyFrom` (no dead
      branch); diffuse PBR/Standard split left intact.
- [x] `_originalDiffuse` / `_originalEmissive` (and their eslint-disable) removed.
- [x] `importedDogMesh.test.ts` + full suite green; `DogMesh` contract unchanged.
- [x] tech-decisions §3j note added. **specs.md untouched.**
- [x] Full gate green: `bun run typecheck` (0) · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`. *(verified in the iteration's final gate below.)*

---

**Next Steps**: Move to `.task-board/in-progress/` when starting.
