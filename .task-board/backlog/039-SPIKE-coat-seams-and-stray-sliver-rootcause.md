# SPIKE: 039 — Root-cause the coat seams + stray sliver on the licensed Labrador (P1-1/P1-9)

**Status**: Backlog
**Created**: 2026-06-30
**Type**: SPIKE (timeboxed research — findings + routing only; **no product code, no TDD**)
**Priority**: High — open **PO directive** (Improvements) on the Phase-1 Visual-Review
sign-off path (P1-10). Routed as a spike (not a build task) because the **cause is unknown**:
the fix differs entirely depending on whether the seams/sliver are a texture-UV artifact, a
normal-map seam, a material/blend side effect of `CoatOpaque.flatten`, or actual stray/
mirrored geometry baked into the licensed glb. Per `process/mother_prompt.md`, a
research-class unknown is spiked before it is built or flagged.
**Labels**: research, visual, phase-1, po-directive, p1-1, p1-9
**Estimated Effort**: Small (one research subagent pass)

## What it addresses (PO directive, `.docs/specs/po-review.md` → Improvements)

> **Residual coat seams + a stray geometry sliver (P1-1 / P1-9).** Magnified, the
> now-opaque coat still shows faint symmetric hairline seams down the chest and curved arcs
> across both flanks, plus a small hard-edged sliver dangling between the front legs
> (clearest in idle). Subtle at native phone size, but they break the clean real-dog
> silhouette up close. *Good looks like:* smooth opaque coat with no hard-edged seams or
> stray dangling geometry at any pose, confirmed by a magnified capture.

Two distinct symptoms with likely-different causes — that is exactly why this is a spike:

- **Symmetric hairline seams (chest) + curved arcs (both flanks).** Symmetry strongly
  suggests a **UV-island / mirror-modeling seam** in the licensed albedo/normal textures
  (filtering or mipmap bleed at island edges), **or** a normal-map discontinuity. Could
  also be a side effect of `CoatOpaque.flatten` (`scripts/coat_opaque.gd`) changing
  transparency/cull/blend in a way that reveals edges.
- **Hard-edged sliver between the front legs (clearest in idle).** "Hard-edged" + "dangling"
  reads as **actual stray geometry** in `dog_licensed.glb` (a detached face/edge, an
  inner-mouth/tongue/collar sub-mesh, or a stray element), not a texture artifact.

Both are on the **licensed Labrador** (`res://assets/models/dog_licensed.glb`), which loads
locally (the raw 19 MB glb is present; encryption is deploy-only), so this is fully
investigable here — no owner gate to *diagnose* (a fix baked into the asset itself could be).

## Spike goal (research only)

Find the **root cause** of each symptom and produce a concrete routing decision. Deliverable
is **findings + a route**, not a fix. No shippable product code, no TDD.

### Investigation checklist (research subagent, model `sonnet`)

1. **Enumerate the licensed mesh.** Load `dog_licensed.glb` (Godot headless or a glb
   inspector via `nix shell nixpkgs#<pkg>` — e.g. `gltf-transform`/`assimp`): list every
   `MeshInstance3D`/surface, its material, vertex/face count, blend/cull/transparency mode,
   and any tiny/detached sub-mesh that could be the sliver. Note any duplicated/mirrored
   surface that could z-fight along the symmetry plane.
2. **Capture the magnified evidence.** Use the local licensed web export + a capture seam to
   shoot magnified idle frames of (a) the chest seam, (b) a flank arc, (c) the sliver
   between the front legs. Save under `.screenshots/039-spike-*`.
3. **Test the texture hypothesis.** Inspect `dog_licensed_Labrador_Albedo.png` /
   `_Normal.png` import settings (filter, mipmaps, repeat). Determine whether the seams sit
   on UV-island boundaries (texture artifact) or on geometry edges (mesh artifact).
4. **Test the `CoatOpaque` hypothesis.** Check whether the seams/sliver are present with
   `CoatOpaque.flatten` disabled vs enabled — i.e. does flatten *cause* or merely *fail to
   hide* them. (`scripts/coat_opaque.gd`, called at `main.gd:395`.)
5. **Classify each symptom** as one of: texture/UV artifact (fixable via import/material) ·
   normal-map seam · `CoatOpaque` side effect · stray/mirrored geometry baked into the glb.

## Routing (the spike's actual output)

- **If fixable in-engine** (import setting, material flag, a `CoatOpaque`/load-time mesh
  pass that strips a stray sub-mesh or fixes the seam) → write the findings into a
  **follow-up build task** (`040-BUG-…`) with the exact mechanism + before/after, TDD where
  there's a logic seam (e.g. "flatten also removes the stray sub-mesh", asserted on a
  synthetic mesh like 032 did), Visual Review with a magnified proof capture as the gate.
- **If baked into the licensed asset and only fixable by re-exporting the model** (owner
  action) → hand the precise findings to the orchestrator to raise an **informed flag** in
  `.task-board/FLAGS.md` (which surface/UV/sub-mesh, why it can't be fixed in-engine).
  Subagents never write FLAGS.md — only the orchestrator does.

## Acceptance Criteria

- [ ] Licensed mesh enumerated (surfaces, materials, counts, blend/cull, stray sub-meshes)
      with the sliver candidate identified.
- [ ] Each symptom classified by cause (texture/UV · normal-map · `CoatOpaque` · geometry),
      backed by magnified evidence captures under `.screenshots/039-spike-*`.
- [ ] `CoatOpaque`-on vs -off comparison recorded (cause vs fails-to-hide).
- [ ] A concrete route emitted: either a drafted `040` build task (with mechanism +
      before/after + test/visual gate) **or** findings handed to the orchestrator for an
      informed FLAG — recorded in this task file.
- [ ] No product code committed by the spike (research only); board left consistent.
