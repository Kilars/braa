# FEATURE: Dog Grounded Contact Shadow + Softer Material + Face

**Status**: Done
**Created**: 2026-06-14
**Priority**: High
**Labels**: render, dog, visual-review
**Estimated Effort**: Medium

## Context & Motivation

Two spec requirements are currently unmet on the dog:

- **D12 — Grounded & framed.** "The dog rests on the ground (**anchored by a
  contact shadow, not floating**)…" — today the dog has **no shadow** and reads
  as hovering above the grass.
- The "Visual Presentation" art direction calls for **Pokémon-GO-style
  stylized-realism, bright soft lighting**. The current material is flat plastic
  with a harsh specular hotspot (baseline review in `DOG-RENDER-LOOP.md`:
  "flat plastic shading + harsh specular").

A face (eyes + nose) also sharply increases the "reads as a dog" signal and the
emotional read of the happy/confused states (D8/D7). This is step 2 of the
dog-rendering loop and depends on the mesh from 056.

## Current State

After 056, the dog is a primitive silhouette using one `StandardMaterial` with
default specular, on a green ground, lit by a single `HemisphericLight`. No
shadow-casting light, no `ShadowGenerator`, no eyes/nose. The dog appears to
float.

## Desired Outcome

- A **soft contact shadow** beneath the dog so it reads as resting on the ground
  (D12). Either a real `ShadowGenerator` (add a `DirectionalLight` as caster) or
  a cheap **blob-shadow** (a soft dark disc/decal under the dog that tracks the
  root's x). Either is acceptable; pick the one that looks good and stays cheap
  on mobile.
- A **softer, fur-ish material**: kill the plastic specular hotspot (low/no
  `specularColor`), keep the warm tan diffuse, so it reads stylized-realistic
  rather than shiny plastic.
- **Eyes + nose** on the head so the dog has a face and the happy/confused reads
  land.

## Affected Components

### Files to Modify
- `src/render/dogMesh.ts` — add eyes + nose meshes; tune the material
  (`specularColor`/`specularPower`); if using a blob shadow, add the disc here
  parented near the feet (kept un-tinted by `setTint`).
- `src/render/scene.ts` — if using a real shadow: add a `DirectionalLight` +
  `ShadowGenerator`, register the dog meshes as casters and the ground as a
  receiver; soften the existing lighting if needed. Keep the blob-shadow option
  fully inside `dogMesh.ts`.

### Dependencies
- **External**: none beyond Babylon (`DirectionalLight`,
  `@babylonjs/core/Lights/Shadows/shadowGenerator` if using real shadows).
- **Internal**: 056 (dog mesh) — **blocking**.
- **Blocking**: this should land before 058 so poses are reviewed with the final
  material/shadow, but 058 does not hard-depend on it.

## Technical Approach

### Architecture Decisions

- **Prefer a blob shadow for mobile cheapness** unless a real shadow clearly
  looks better: a flattened, soft-edged dark disc at `y≈0.01` under the dog,
  slightly transparent, that follows `dog.root.position.x`. No shadow map cost.
  Document the choice in `tech-decisions.md` (rendering section) per the autonomy
  rule.
- **`setTint` must not recolour the shadow, eyes, or nose** — give those their
  own materials so the per-state body tint leaves them alone (black nose stays
  black, shadow stays dark).
- Keep eyes/nose small and high-contrast for legibility at phone size.

### Implementation Steps

1. **Material softening** — set `specularColor` low (e.g. `new Color3(0.05,
   0.05,0.05)`) / raise `specularPower`, kill the hotspot; re-check the six tint
   states still read.
2. **Face** — two small dark spheres (eyes) on the head front, one small dark
   sphere/box (nose) on the snout tip; own materials.
3. **Shadow** — add a soft blob disc under the dog (or a `ShadowGenerator` with a
   `DirectionalLight`); make it track the root x so it stays under the dog during
   jitter/lean.
4. **Visual Review** — screenshot; confirm the dog is grounded (shadow visible),
   no plastic hotspot, face reads.

### Risks & Considerations

- **Risk: shadow doesn't track lateral motion** (confused jitter / distractor
  lean shift the dog off its shadow) — **Mitigation**: update the blob's x from
  `dog.root.position.x` each frame, or parent it under root with a fixed local y.
- **Risk: real shadows tank mobile FPS** — **Mitigation**: default to the blob
  shadow; only use a shadow map at low resolution if it clearly wins.
- **Risk: tint bleeds onto eyes/nose/shadow** — **Mitigation**: separate
  materials; `setTint` touches only body/head/legs/snout.

## Before / After Examples

### Example 1: Kill the plastic specular

**Before** (`src/render/scene.ts`, sphere material):
```ts
const sphereMat = new StandardMaterial("dog-mat", scene);
sphereMat.diffuseColor = BASE_COLOR.clone();
// default specular → harsh white hotspot
```

**After** (`src/render/dogMesh.ts`):
```ts
const mat = new StandardMaterial("dog-mat", scene);
mat.diffuseColor = new Color3(0.76, 0.6, 0.42);
mat.specularColor = new Color3(0.05, 0.05, 0.05); // soft, fur-ish — no plastic glare
mat.specularPower = 64;
```

### Example 2: Grounded blob shadow

**After** (`src/render/dogMesh.ts`):
```ts
const shadow = MeshBuilder.CreateDisc("dog-shadow", { radius: 0.55 }, scene);
shadow.rotation.x = Math.PI / 2;          // flat on the ground
shadow.position.y = 0.01;                 // just above the grass to avoid z-fight
const shadowMat = new StandardMaterial("dog-shadow-mat", scene);
shadowMat.diffuseColor = new Color3(0, 0, 0);
shadowMat.alpha = 0.28;                    // soft, semi-transparent
shadow.material = shadowMat;               // NOT affected by setTint
// each frame: shadow.position.x = dog.root.position.x;
```

### Example 3: A face

**After** (`src/render/dogMesh.ts`):
```ts
const eyeMat = new StandardMaterial("dog-eye", scene);
eyeMat.diffuseColor = new Color3(0.05, 0.05, 0.05);
const leftEye = MeshBuilder.CreateSphere("eye-l", { diameter: 0.08 }, scene);
leftEye.position.set(0.74, 0.36, 0.12); leftEye.material = eyeMat; leftEye.parent = root;
// rightEye mirrored; nose a small dark sphere at the snout tip
```

## Code References

- `src/render/scene.ts` — lighting setup (`HemisphericLight`, intensity 1.2) and
  the material to soften.
- `src/render/dogMesh.ts` — created in 056; extended here.
- `.docs/specs.md` "The Dog" D12, "Visual Presentation" art direction.
- `.task-board/DOG-RENDER-LOOP.md` — step 2 (material + shadow + lighting).

## Progress Log

- 2026-06-14 — Task created (scan round, focus: dog).
- 2026-06-14 — Implemented: blob shadow, softer material, eyes + nose. All criteria met.

## Resolution

**Completed 2026-06-14.**

Three changes to `src/render/dogMesh.ts`:

1. **Softer material** — `specularColor = Color3(0.05, 0.05, 0.05)` + `specularPower = 64` on the body `StandardMaterial`. Kills the harsh plastic hotspot; all six tint states still read clearly.

2. **Face** — two dark eye spheres (diameter 0.07) at `(0.76, 0.34, ±0.11)` and a dark nose sphere at `(0.94, 0.18, 0)`, each with their own `StandardMaterial` (near-black). `setTint` touches only the body mat — eyes, nose untouched.

3. **Blob contact shadow** — a `MeshBuilder.CreateDisc` (radius 0.52, 24 sides) at world `y=0.01` with `alpha=0.28`, `disableLighting=true`. NOT parented to root so it stays on the ground even during happy bounce / misbehaving jumps. `DogMesh` interface gained `updateShadowX(x)` which `scene.ts` calls each render frame to track lateral motion.

Shadow approach (blob) documented in `tech-decisions.md` §2.

`bun run typecheck` ✓ · `bun run build` ✓ · 440 tests ✓ · screenshots captured at `/tmp/bra-initial.png` + `/tmp/bra-active.png`.

## Acceptance Criteria

- [x] The dog casts/has a **soft contact shadow** that reads as grounding it on
      the grass (satisfies **D12**); the shadow tracks the dog's lateral motion.
- [x] The dog material has **no harsh plastic specular hotspot** — soft, fur-ish
      stylized look; the six tint states still read.
- [x] The dog has **eyes and a nose**; `setTint` does **not** recolour the
      eyes/nose/shadow (they keep their own materials).
- [x] **Visual Review:** portrait screenshot shows a grounded, faced dog with
      soft lighting — no float, no plastic glare.
- [x] Chosen shadow approach (blob vs shadow map) noted in `tech-decisions.md`.
- [x] `bun run typecheck` + `bun run build` pass; tests stay green; no mobile FPS
      regression from the shadow choice.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
