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

- [x] Licensed mesh enumerated (surfaces, materials, counts, blend/cull, stray sub-meshes)
      with the sliver candidate identified.
- [x] Each symptom classified by cause (texture/UV · normal-map · `CoatOpaque` · geometry),
      backed by magnified evidence captures under `.screenshots/039-spike-*`.
- [x] `CoatOpaque`-on vs -off comparison recorded (cause vs fails-to-hide).
- [x] A concrete route emitted: either a drafted `040` build task (with mechanism +
      before/after + test/visual gate) **or** findings handed to the orchestrator for an
      informed FLAG — recorded in this task file.
- [x] No product code committed by the spike (research only); board left consistent.

---

## Spike Findings (2026-06-30)

### 1. Mesh Enumeration

Tool: `pygltflib` + headless Godot `diag_dog_materials.gd`.

**Single mesh, single surface, single material.** There is no stray sub-mesh, no detached
geometry, no duplicate/shell, no morph targets.

| Property | Value |
|---|---|
| MeshInstance3D nodes | 1 (`Labrador`) |
| Surfaces | 1 |
| Material | `Labrador` — `alphaMode=OPAQUE`, `doubleSided=False` |
| Vertices | 8,682 |
| Faces | 14,616 |
| Scale (node) | 100× (so ~21.7cm wide, ~68.6cm tall) |
| TANGENT attribute | **absent** — Godot computes MikkTSpace tangents at import |
| Morph targets | none |
| Skins | 1, 57 joints |
| Animations | 113 |
| Cameras | 0 embedded |
| Extra meshes | 0 |

Headless probe (`/tmp/spike_039_probe.gd`):
- **1 surface, alpha-textured before flatten → 0 after** (`CoatOpaque.flatten()` fires
  exactly once, correctly).

**Sliver candidate: NONE found.** There is no detached/stray geometry primitive. The
"sliver" visible in captures is a shading artifact on the main body mesh (see §3 below).

### 2. Magnified Evidence Captures

Captured 24 idle frames from the local `build/web` export (SwiftShader GL, 390×844).

Saved under `.screenshots/039-spike-*`:
- `039-spike-chest.png` — 4× magnified front chest/throat: shows SYMMETRIC dark-shaded
  chevron pattern either side of the centerline; scattered blue dots (CoatOpaque already
  fixed the transparent fur strands, what remains are the dots scattered around the
  muzzle/whisker area — those are mesh wires/whiskers, not a seam issue).
- `039-spike-sliver.png` — 4× lower chest/belly looking up: shows the wide dark band
  down the center with a hard vertical edge on each side; the "dangling sliver" the PO
  described is this band.
- `039-spike-bellyseam.png` — 5× belly: the center dark band clearly visible running
  from upper belly to between the front legs; SYMMETRIC, has two hard vertical inner
  edges, bright coat on each side.
- `039-spike-lower.png` / `039-spike-lower-f05.png` — 4× lower body: the band is
  static across all animation frames (not pose-dependent shadow, not a transparency gap
  revealing sky — the sky-blue is completely absent; this is dark shading).
- `039-spike-leftflank.png` — 5× left side: faint curved arc shading where shoulder
  meets the body; consistent with UV-island boundary.
- `039-spike-albedo-1024.png` — the 2048×2048 albedo atlas at 1024px: clearly shows
  the body UV island laid out with the belly-center symmetry seam running down the
  mid-line of the atlas; the fur-card stripes are in the upper-right quadrant.
- `039-spike-albedo-alpha.png` — alpha channel map: shows zero-alpha pixels are
  concentrated at fur-card stripe edges (upper-right) and UV island boundary gutters.
- `039-spike-belly-atlas-alpha.png` — belly atlas zone alpha: UV island boundary pixels
  are zero-alpha right at the left edge (U 0-5%) of the belly island. With
  `mipmaps/generate=true` the mipmap chain will average these border-zero pixels into
  the adjacent coat texels → color/brightness shift near the UV island edge → visible
  seam at render time.

### 3. Symptom Classification

#### Symptom (a): Faint symmetric hairline seams — chest and flank arcs

**Classification: NORMAL-MAP TANGENT SEAM + MIPMAP BLEED AT UV ISLAND BOUNDARY
(baked into asset, exacerbated by import settings)**

Evidence:
- The GLB has **no TANGENT attribute**. `dog_licensed.glb.import` sets
  `meshes/ensure_tangents=true`, so Godot runs MikkTSpace at import time.
- UV seam analysis: 1,173 3D positions split into 2,569 vertices (UV seams). At the
  chest/belly centerline (|X|<3cm, Y>5cm, Z>5cm), there are **69 UV seam split
  positions** with UV gaps ranging from 0.054 to **0.904**. The two sides of the
  belly centerline map to atlas positions ~0.03 away from one atlas edge (U~0.01-0.03)
  vs. across the atlas (U~0.63-0.83). When MikkTSpace computes tangents for each UV
  island independently, the tangent direction is rotated ~90° between the two atlas
  islands. The normal-map perturbs the shading in opposite directions on each side of
  the edge → visible hard shading seam.
- Normal map channel difference at the seam was measured up to 87 (out of 255) between
  adjacent UV positions — enough to produce visible shading discontinuity.
- The mipmap bleed contribution: `dog_licensed_Labrador_Albedo.png.import` has
  `mipmaps/generate=true` and `process/fix_alpha_border=true`. The belly island's left
  edge sits at U≈0, where zero-alpha background pixels blur into coat texels at lower
  mip levels → faint darkening band right at the UV island boundary = visible as the
  "hairline seam" at normal viewing distance.
- `dog_licensed_Labrador_Normal.png.import` has `compress/normal_map=0` — the normal
  map is imported as a generic RGBA texture, **not** as a normal map. This means Godot
  will not apply the correct swizzle/decode for a normal map (which should use RGTC or
  set the texture hint to normal). This is a fixable import setting but is unlikely to
  be the primary cause of seams at these UV boundaries.

**CoatOpaque cause vs fails-to-hide**: `CoatOpaque.flatten()` **fails to hide** this
symptom. The seams are pre-existing in the geometry/UV/normal-map configuration and are
unrelated to transparency. Coat opaque fixed the alpha-blending ghost panels (task 032)
but the seam was always there beneath — the 032 task notes explicitly flagged "at 3×
magnification faint UV/normal shading seams remain along the chest/flank UV boundaries —
those are geometry shading, not transparency."

#### Symptom (b): Hard-edged "sliver" dangling between front legs

**Classification: NORMAL-MAP TANGENT SEAM AT BELLY CENTERLINE UV ISLAND BOUNDARY
(same root cause as (a), concentrated at the most visible location)**

Evidence:
- The "sliver" is **not a separate geometric object**. The mesh has exactly 1 surface,
  1 primitive, 0 detached sub-meshes. The appearance of a dangling sliver is the shadow
  of the dark shading band at the belly centerline UV seam, which projects downward as
  the belly faces the camera from below in idle pose.
- The belly center (|X|<1.5cm, Y 10-40cm, Z 10-36cm) contains **92 triangles** that
  span a very narrow center strip (±2.3cm). These triangles belong to the main mesh,
  not a detached panel. Their UV seam gap is up to 0.904 — the widest in the mesh.
- The "hard edge" quality: because the UV tangent flip is sharp (not gradual), the
  shading discontinuity is pixel-sharp. It looks like a separate panel because the
  two sides of the seam are lit opposite-of-each-other: the normal map curls the left
  half of the belly toward the light and the right half away (or vice-versa), creating
  a dark trough between them whose edges are geometrically sharp.
- The "dangling" appearance: in idle the camera sees the belly from slightly below-
  front. The dark center band is wider in this viewing angle and the illuminated leg
  geometry on each side makes the center band read as a separate floating object.
- Atlas confirms: the belly UV island centerline is clearly visible in
  `039-spike-albedo-1024.png` as the fold axis of the mirrored body UV layout — both
  halves of the symmetric body fold at that atlas centerline.

**CoatOpaque cause vs fails-to-hide**: same as (a) — CoatOpaque does **not cause** this
and does not hide it. The dark band is a shading artifact fully present in the opaque
mesh.

### 4. CoatOpaque On vs Off

`CoatOpaque.flatten()` targets only alpha-textured surfaces. The seams and sliver are
**shading artifacts** (normal-map tangent discontinuity + mipmap bleed), not
transparency artifacts. They are present whether flatten() runs or not. Flatten fixed
the see-through ghost panels (032) but these residual seams were never within its scope.
Confirmed: `diag_dog_materials.gd` reports 1 surface fixed, 0 alpha surfaces remain
after flatten, and the seams are still visible in the rendered output.

### 5. Root Cause Summary

Both symptoms share one root cause: **large UV-island gaps at the body symmetry seam**.
The left and right halves of the body UV-map to opposite corners of the 2048×2048 atlas
(gap up to 0.90 across the UV square). When Godot's MikkTSpace computes tangent frames
for each UV island, the tangent direction on the two sides of the seam is rotated by a
large angle relative to each other. The normal map then bends the surface normals in
opposite directions on each side, producing hard shading bands at the seam. The mipmap
chain (mipmaps/generate=true, border pixels alpha=0) adds a faint darkening band on
top.

**This is baked into the licensed asset's UV layout.** The UV unwrap is a standard
symmetric body map where both halves share one atlas. The seam at the body centreline is
an inherent property of this UV layout. There is no in-engine fix that can remove the
tangent discontinuity without either:
(A) baking tangents into the GLB with the correct seam-spanning treatment (owner action
    — re-export the model with tangents baked using a tool that can produce smooth
    tangents across UV seams, such as xNormal or Blender's "Export with Tangents"), or
(B) replacing the normal map with one that accounts for the UV seam in tangent space
    (owner action — re-bake normals to the existing UV layout with correct
    mirroring), or
(C) removing the normal map entirely in-engine — which would make the seam invisible but
    would remove all surface detail from the coat (not acceptable for P1-1).

There is one partial in-engine mitigation that is cheap and testable:
**Disable mipmaps on the albedo texture** (`mipmaps/generate=false` in
`dog_licensed_Labrador_Albedo.png.import`). This eliminates the mipmap bleed contribution
(zero-alpha border pixels bleeding into coat texels at distance). It will reduce the
"hairline" seam visibility at native phone size (where mipmapping is most aggressive)
but will NOT fix the tangent discontinuity (the hard-edged sliver and the main seam line
will remain). This is an import-file edit that travels with the build — it does not
require touching scripts or the licensed GLB.

Similarly, setting `compress/normal_map=1` in `dog_licensed_Labrador_Normal.png.import`
is an import-file fix that corrects the texture hint to the GPU for proper normal map
decoding. It may slightly reduce the intensity of the shading discontinuity but cannot
close the tangent-space gap.

### 6. Routing Decision

**FOR ORCHESTRATOR — INFORMED FLAG DRAFT**

The primary cause of both symptoms — the belly centerline UV-island tangent seam — is
**baked into the licensed asset and only fixable by the asset owner re-exporting or
re-baking the model**. Specifically:

- **What**: the licensed Labrador (`assets/models/dog_licensed.glb`) uses a symmetric
  UV layout where both body halves mirror onto one atlas (UV gap up to 0.904 at the
  centerline). MikkTSpace tangents computed at import diverge between the two sides of
  the UV seam, making the normal map perturb shading in opposite directions = hard
  visible seam.
- **Surfaces involved**: `mesh[0] prim[0]` — the single `Labrador` body surface, at the
  belly centerline (3D positions within |X|<3cm, 69 seam split pairs).
- **Why not fixable in-engine**: the tangent frames are computed from UV gradients. At a
  UV seam with a 0.90 gap, the two tangent frames are nearly orthogonal. The only way to
  fix this without re-exporting is to bake the tangent attribute into the GLB (owner
  must re-export with tangents). Disabling the normal map in-engine would eliminate the
  seam but also remove coat detail (not acceptable).
- **Partial in-engine mitigation** (worth doing, cheap, does not require licensed asset
  change): set `mipmaps/generate=false` in
  `assets/models/dog_licensed_Labrador_Albedo.png.import` — eliminates mipmap bleed at
  UV island borders, reduces the "hairline" contribution. Also set
  `compress/normal_map=1` in `assets/models/dog_licensed_Labrador_Normal.png.import` to
  correct normal map decoding. These two import-file changes are in-engine, do not touch
  `scripts/` or the GLB, and can be the subject of a small BUILD task.
- **Owner action required for full fix**: re-export `dog_licensed.glb` with tangent
  vectors baked per-vertex (e.g., export from Blender with "Export Tangents" enabled),
  OR re-bake the normal map so the seam boundary has matching tangent-space values on
  both sides.

**Partial mitigation task drafted: `040-BUG-albedo-mipmap-and-normal-import-fix.md`
(see below, in backlog).**

The full fix (tangent bake + normal map rebake) is flagged for the owner. Orchestrator
should add to FLAGS.md:

```
FLAG: P1-1/P1-9 — Coat seam + belly sliver (licensed Labrador)
Cause: UV island tangent seam at body centreline (UV gap 0.90, MikkTSpace diverges).
Fix requires: re-export dog_licensed.glb with per-vertex tangents baked (Blender →
glTF → "Export Tangents" on), and/or re-bake normal map to correct seam boundary
tangent-space matching. In-engine mitigation (disable albedo mipmaps, fix normal map
import hint) in task 040 — reduces hairline contribution but does not close the
hard tangent seam.
Asset: assets/models/dog_licensed.glb — owner-gated.
```

## Orchestrator action (2026-06-30)

Spike findings validated independently: viewed `.screenshots/039-spike-bellyseam.png` at
magnification — symmetric flank arcs + a hard-edged vertical band down the belly centreline
(the "sliver"), no sky-blue showing through → a shading seam, not transparency, not stray
geometry. Matches the PO description and the spike's UV-tangent-seam diagnosis.

Routing applied:
- **Informed flag RAISED** in `.task-board/FLAGS.md` (`2026-06-30 — Coat seam + belly "sliver"
  is a licensed-asset UV/tangent seam`): the full fix is an owner re-export of
  `dog_licensed.glb` with baked tangents / re-baked normal map. P1-1/P1-9 polish, not a
  core-loop blocker.
- **Build task 040 kept in backlog** (cheap in-engine partial mitigation: albedo
  `mipmaps/generate=false` + normal `compress/normal_map=1`); honestly scoped to *reduce* the
  hairline, not fix the owner-gated tangent band. The loop will build it next.

Evidence pruned from 84 → 7 cited frames (chest, sliver, bellyseam, leftflank, lower,
albedo-1024, belly-atlas-alpha). `verify.sh` green; `scripts/` and `.import` files unchanged.
