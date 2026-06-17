# FEATURE: Dog Mesh Silhouette (sphere → recognizable dog)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: High
**Labels**: render, dog, visual-review, blocking
**Estimated Effort**: Medium

## Context & Motivation

The dog is the game's **primary state-communication channel** (specs "The Dog",
D1–D14) and the visual focus of every screen. It is currently a single
`MeshBuilder.CreateSphere` with per-state colour/scale/jitter. Spec **D1** is
explicit and non-waivable at any fidelity:

> **D1 — Reads as a dog.** … A featureless shape (a bare sphere/blob/capsule)
> does **not** satisfy this — not even as a placeholder.

So the current scene *fails the spec by construction*. This is the single
highest-impact gap in the whole project and the foundation the rest of the
dog-rendering loop (material/shadow, poses, breed looks) builds on. Per
`DOG-RENDER-LOOP.md` step 1, this task is "build a dog silhouette".

## Current State

`src/render/scene.ts` builds one tan sphere (`dog-placeholder`, diameter 1.2)
at `y=0.6` on a green ground, and `updateDog()` switches its `diffuseColor` /
`emissiveColor` / `scaling` / `position` across six visual states
(`idle | offering | confused | happy | distractor | misbehaving`) returned by
the pure mapper `dogVisualState()` in `src/render/dogState.ts`.

There are **no external 3D model files** (confirmed) — the scene is built from
Babylon primitives in code, which is the right approach to keep going.

## Desired Outcome

A **primitive-composed dog** — body, head, two ears, snout, four legs, a tail —
assembled from Babylon primitives, parented under a single root
`TransformNode` so the existing per-state transforms (scale, x/y offset, jitter,
bounce) apply to the **whole dog** unchanged. From the trainer POV at phone
size it reads immediately as a dog (clear canine silhouette: head, ears, snout,
body, four legs, tail), satisfying **D1**. Fidelity may stay placeholder-grade
(simple geometry, flat-ish material) — legibility is what matters here.

The six visual states must keep working: tint + scale + the confused/misbehaving
jitter should now move the **assembled dog**, not a sphere.

## Affected Components

### Files to Create
- `src/render/dogMesh.ts` — `createDogMesh(scene): { root: TransformNode; setTint(c): void; setEmissive(c): void }`
  builds the parented primitive dog and exposes hooks the scene needs.

### Files to Modify
- `src/render/scene.ts` — replace the sphere with `createDogMesh(scene)`; point
  `updateDog`'s transforms/tints at the returned `root` + tint hooks.

### Dependencies
- **External**: none (Babylon `MeshBuilder`, `TransformNode`, `StandardMaterial`
  already in use; import `TransformNode` from `@babylonjs/core/Meshes/transformNode`).
- **Internal**: `dogState.ts` (unchanged — the mapper already returns the 6 states).
- **Blocking**: none. **Blocks**: 057 (material/shadow), 058 (poses).

## Technical Approach

### Architecture Decisions

- **Extract the dog into its own module** (`dogMesh.ts`) so `scene.ts` stays
  about camera/lights/ground/loop and the dog's geometry lives in one place —
  this is also where breed variation (a later task) will hook in.
- **Single root `TransformNode`.** All body parts are children with local
  offsets. `updateDog` keeps operating on one node (now `root` instead of
  `sphere`), so the diff in `scene.ts` is minimal and the per-state behaviour is
  preserved. Tint is applied via a shared material (one `setTint`/`setEmissive`
  that updates the body/head/leg materials together) so the existing colour
  states keep working.
- **Proportions for silhouette legibility:** body a horizontal capsule/box,
  head a smaller sphere forward+up, snout a small box off the head, two cone/box
  ears on top, four short cylinder legs at the corners, a tail cylinder angled
  up at the back. Keep the overall bounding height ≈ the old sphere so camera
  framing (`target y=0.6`, radius 4.5) still centres the dog; adjust the root
  `y` once if needed and note it.

### Implementation Steps

1. **Core: build the mesh.** Create `dogMesh.ts` with `createDogMesh(scene)`.
   Assemble parts under a root `TransformNode`; give body/head/legs a shared
   `StandardMaterial` (tan base) and return `{ root, setTint, setEmissive }`.
2. **Wire into scene.** In `scene.ts`, replace sphere creation with
   `const dog = createDogMesh(scene)`; in `updateDog`, replace
   `sphere.scaling/position` with `dog.root.scaling/position` and
   `sphereMat.diffuseColor/emissiveColor` with `dog.setTint(...)/dog.setEmissive(...)`.
3. **Verify framing & states (Visual Review).** Run the app, screenshot each of
   the six states (force them as prior dog tasks did), confirm it reads as a dog
   and each state is still distinguishable.

### Risks & Considerations

- **Risk: framing breaks** (dog too big/small/off-centre after the swap) —
  **Mitigation**: keep total height ≈ 1.2; tweak only the root `y` and re-shoot;
  camera target/radius are already tuned.
- **Risk: tint no longer reads** now that the dog is multi-part —
  **Mitigation**: apply tint to all major body materials via `setTint`, and keep
  the existing emissive glow for offering/happy.
- **Risk: per-frame cost** from many meshes — negligible at this part count;
  merging can be a later optimisation if needed.

## Before / After Examples

### Example 1: The dog is no longer a sphere

**Before** (`src/render/scene.ts`):
```ts
const sphere = MeshBuilder.CreateSphere(
  "dog-placeholder", { diameter: 1.2, segments: 16 }, scene,
);
sphere.position.y = BASE_Y;
const sphereMat = new StandardMaterial("dog-mat", scene);
sphereMat.diffuseColor = BASE_COLOR.clone();
sphere.material = sphereMat;
```

**After** (`src/render/scene.ts`):
```ts
import { createDogMesh } from './dogMesh';
// ...
const dog = createDogMesh(scene);   // parented primitive dog: body/head/ears/snout/legs/tail
dog.root.position.y = BASE_Y;
```

### Example 2: `updateDog` drives the assembled dog (idle case)

**Before**:
```ts
case 'idle': {
  sphereMat.diffuseColor.copyFrom(BASE_COLOR);
  sphereMat.emissiveColor.copyFrom(BASE_EMISSIVE);
  sphere.scaling.setAll(BASE_SCALE);
  sphere.position.x = 0;
  sphere.position.y = BASE_Y;
  break;
}
```

**After**:
```ts
case 'idle': {
  dog.setTint(BASE_COLOR);
  dog.setEmissive(BASE_EMISSIVE);
  dog.root.scaling.setAll(BASE_SCALE);
  dog.root.position.x = 0;
  dog.root.position.y = BASE_Y;
  break;
}
```

### Example 3: new module shape (`src/render/dogMesh.ts`)

**After**:
```ts
export interface DogMesh {
  root: TransformNode;
  setTint: (c: Color3) => void;
  setEmissive: (c: Color3) => void;
}

export function createDogMesh(scene: Scene): DogMesh {
  const root = new TransformNode("dog", scene);
  const mat = new StandardMaterial("dog-mat", scene);
  mat.diffuseColor = new Color3(0.76, 0.6, 0.42);

  const body = MeshBuilder.CreateCapsule("dog-body", { radius: 0.34, height: 1.1 }, scene);
  body.rotation.z = Math.PI / 2;              // lie the capsule horizontal
  const head = MeshBuilder.CreateSphere("dog-head", { diameter: 0.5 }, scene);
  head.position.set(0.62, 0.28, 0);
  // ... snout (box), 2 ears (cones), 4 legs (cylinders), tail (cylinder) ...
  for (const part of [body, head, /* ... */]) { part.material = mat; part.parent = root; }

  return {
    root,
    setTint: (c) => mat.diffuseColor.copyFrom(c),
    setEmissive: (c) => mat.emissiveColor.copyFrom(c),
  };
}
```
*(Exact primitive choices/offsets are the implementer's call — the contract is
"reads as a dog, one root, tint hooks".)*

## Code References

- `src/render/scene.ts` — current sphere + `updateDog` six-state switch (the
  integration point).
- `src/render/dogState.ts` — pure `dogVisualState()` mapper (unchanged).
- `.task-board/DOG-RENDER-LOOP.md` — the 5-step dog-rendering plan; this is step 1.
- `.task-board/done/015-FEATURE-dog-visual-states.md` — how the six states were
  introduced (pattern to preserve).

## Progress Log

- 2026-06-14 — Task created (scan round, focus: dog).
- 2026-06-14 — Implemented: created `src/render/dogMesh.ts` with primitive-composed dog
  (body capsule, head sphere, snout box, 2 ear cylinders, 4 leg cylinders, tail cylinder)
  under a single root `TransformNode`. Updated `src/render/scene.ts` to remove sphere
  and wire all six visual states through `dog.root`/`dog.setTint()`/`dog.setEmissive()`.
  All checks pass; visual review confirmed dog silhouette reads clearly at phone size.

## Resolution

Completed 2026-06-14. The placeholder sphere (`dog-placeholder`) is replaced by a
primitive-composed dog built entirely from Babylon shapes in `src/render/dogMesh.ts`.
The dog has a horizontal capsule body, spherical head, box snout, two tapered-cylinder
ears, four cylinder legs, and an angled cylinder tail, all parented under one root
`TransformNode`. The `DogMesh` interface (`{ root, setTint, setEmissive }`) keeps the
six visual states fully working — idle (tan), offering (warm bright + 1.1× scale),
confused (orange + X-jitter), happy (gold + bounce), distractor (grey + 0.9× scale),
misbehaving (red + fast jump) — now applied to the whole assembled dog.

Screenshots confirm clear canine silhouette at 390×844 (iPhone SE portrait size),
satisfying spec D1. `bun run typecheck`, `bun run build`, and all 440 tests pass.

## Acceptance Criteria

- [x] `src/render/dogMesh.ts` exists and exports `createDogMesh(scene)` returning
      a single root `TransformNode` with body, head, two ears, snout, four legs,
      and a tail parented under it.
- [x] `scene.ts` uses the new dog mesh; the sphere `dog-placeholder` is gone.
- [x] All six visual states still drive the dog (tint + scale + jitter/bounce act
      on the assembled dog, not a sphere) and remain distinguishable.
- [x] **Visual Review:** app runs; a portrait screenshot at phone size reads
      immediately as a dog (head, ears, snout, body, four legs, tail visible) —
      satisfies **D1**. Dog stays centred and fully in frame.
- [x] `bun run typecheck` and `bun run build` pass; existing tests stay green.
- [x] `prefers-reduced-motion` unaffected (no new always-on motion introduced here).

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
