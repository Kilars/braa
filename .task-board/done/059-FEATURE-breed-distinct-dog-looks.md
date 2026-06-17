# FEATURE: Breed-Distinct Dog Looks (D2 — tell breeds apart at a glance)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: High
**Labels**: render, dog, breeds, visual-review, tdd
**Estimated Effort**: Medium

## Context & Motivation

Now that the dog reads as a dog (056) with shadow/face (057) and poses (058),
the next "The Dog" gap is **D2 — Breed reads clearly**:

> Each breed must be recognizable as its real breed … silhouette, proportions,
> coat, and coloring differ enough to tell a Labrador from a Border Collie from a
> Husky **at a glance**.

Today **every breed renders the identical tan dog** — `src/render/` has **zero**
breed references; `createDogMesh(scene)` takes no appearance input. The game ships
5 breeds (Labrador, Border Collie, Bulldog, Husky, Puddel) that are
mechanically distinct (difficulty/personality) but **visually identical**. That
breaks the core "breeds are a collection axis, not skins" promise and D2.

## Current State

- `src/core/breeds.ts` — `Breed` has `id/name/intrinsic/learnSpeed/distractibility/
  adoptCost/signatureTrickId`. **No appearance fields.**
- `src/render/dogMesh.ts` — `createDogMesh(scene)` builds one tan dog, one shared
  body material. No parameters.
- `src/main.ts` — knows the active breed (`getActiveBreed()`), but only feeds it to
  `composeDifficulty`; never to the renderer.

## Desired Outcome

Each breed renders with a **distinct, recognizable appearance** — at minimum
**coat colour** + **proportion/shape cues** (e.g. Bulldog stocky & low, Husky
upright pricked ears, Border Collie black-and-white, Puddel curly/rounded,
Labrador the warm tan baseline) — tellable apart at a glance in portrait. A given
roster dog keeps its look across rounds/sessions (D3 — appearance is derived from
the persistent breed id, so this is automatic).

## Affected Components

### Files to Create
- `src/render/dogAppearance.ts` + `src/render/dogAppearance.test.ts` — a **pure**
  `breedAppearance(breedId: string): DogAppearance` mapping (colours + a few
  numeric proportion cues). This is data/logic → **test-first (TDD)**.

### Files to Modify
- `src/render/dogMesh.ts` — `createDogMesh(scene, appearance?)`: apply coat
  colour(s) and proportion cues (body scale, leg length, ear shape/size) from the
  appearance; default to the Labrador baseline when omitted.
- `src/render/scene.ts` — accept an appearance (or breedId) and pass it through;
  expose a way to rebuild/recolour the dog when the active dog changes.
- `src/main.ts` — pass `getActiveBreed().id` → appearance into the scene on load,
  on dog-switch, and on adopt.

### Dependencies
- **External**: none.
- **Internal**: 056/057/058 (dog mesh + parts) — done. `breeds.ts` (breed ids).
- **Blocking**: none.

## Technical Approach

### Architecture Decisions

- **Keep appearance OUT of the gameplay `Breed` type.** Rendering data lives in
  the render layer (`dogAppearance.ts`), keyed by breed id — mirrors the existing
  separation (core logic vs render). Avoids polluting `breeds.ts`/save logic with
  colours.
- **`breedAppearance` is a pure lookup** with a Labrador fallback for unknown ids
  (so a new breed never crashes the renderer — it just looks like the baseline
  until given an entry). This is the testable part.
- **Proportion cues stay cheap**: a handful of multipliers the mesh applies to
  existing parts (bodyLength, bodyGirth, legLength, earStyle: 'floppy'|'pricked',
  curliness/roundness) — no new meshes required for v1, just parameterise 056's
  parts. Document any breed-look choices in `tech-decisions.md`.

### Behaviours to test (TDD, `dogAppearance.test.ts`)

1. `breedAppearance('labrador')` returns the warm-tan baseline coat.
2. Each catalog breed id returns a **distinct** primary coat colour (no two
   breeds share the same coat) — e.g. assert collie ≠ labrador ≠ husky.
3. An unknown id falls back to the Labrador baseline (no throw).
4. Proportion cues differ where the breed implies it (e.g. bulldog bodyGirth >
   labrador; husky earStyle === 'pricked').

### Implementation Steps

1. **TDD `dogAppearance.ts`** through behaviours 1–4 (red→green per slice).
2. **Parameterise `createDogMesh`** to consume `DogAppearance` (coat → materials;
   cues → part scales/ear style). Keep `setTint`/`setEmissive` working as a
   per-state overlay on top of the breed coat (state tints multiply/replace
   coat; ensure idle returns to the breed coat, not a hardcoded tan).
3. **Wire the active breed** through scene → mesh in `main.ts` (load, switch,
   adopt).
4. **Visual Review** — screenshot all 5 breeds; confirm each is tellable at a
   glance.

### Risks & Considerations

- **Risk: per-state tints (057) overwrite the breed coat** so all breeds look the
  same again in offering/happy — **Mitigation**: derive state tints relative to
  the breed base (idle = breed coat; offering/happy = brighten the breed coat;
  confused/distractor/misbehaving keep their semantic hue but the implementer
  decides whether to blend with the coat). Make idle return to the **breed** coat.
- **Risk: switching dogs needs a mesh rebuild** — **Mitigation**: either rebuild
  the dog mesh on switch, or expose a `setAppearance(appearance)` that recolours
  + rescales the existing parts (cheaper). Either is fine.

## Before / After Examples

### Example 1: pure appearance lookup (new, tested)

**After** (`src/render/dogAppearance.ts`):
```ts
export interface DogAppearance {
  coat: Color3; coatBelly?: Color3;
  bodyGirth: number; legLength: number;      // proportion multipliers (1 = baseline)
  earStyle: 'floppy' | 'pricked';
}
const LAB: DogAppearance = { coat: rgb(0.76,0.6,0.42), bodyGirth: 1, legLength: 1, earStyle: 'floppy' };
const APPEARANCE: Record<string, DogAppearance> = {
  labrador: LAB,
  'border-collie': { coat: rgb(0.1,0.1,0.1), coatBelly: rgb(0.95,0.95,0.95), bodyGirth: 0.95, legLength: 1.05, earStyle: 'pricked' },
  bulldog: { coat: rgb(0.82,0.74,0.6), bodyGirth: 1.35, legLength: 0.7, earStyle: 'floppy' },
  husky: { coat: rgb(0.55,0.58,0.62), coatBelly: rgb(0.95,0.95,0.95), bodyGirth: 1.0, legLength: 1.1, earStyle: 'pricked' },
  puddel: { coat: rgb(0.2,0.2,0.22), bodyGirth: 1.05, legLength: 1.0, earStyle: 'floppy' },
};
export function breedAppearance(breedId: string): DogAppearance {
  return APPEARANCE[breedId] ?? LAB;   // unknown → baseline, never throws
}
```

### Example 2: mesh consumes appearance

**Before** (`src/render/dogMesh.ts`):
```ts
export function createDogMesh(scene: Scene): DogMesh {
  const mat = new StandardMaterial("dog-mat", scene);
  mat.diffuseColor = new Color3(0.76, 0.6, 0.42);  // always tan
```

**After**:
```ts
export function createDogMesh(scene: Scene, appearance = breedAppearance('labrador')): DogMesh {
  const mat = new StandardMaterial("dog-mat", scene);
  mat.diffuseColor = appearance.coat.clone();      // breed coat
  // body.scaling from appearance.bodyGirth/legLength; ears from earStyle
```

## Code References

- `src/core/breeds.ts` — `BREED_CATALOG` ids: labrador, border-collie, bulldog,
  husky, puddel (the keys to map).
- `src/render/dogMesh.ts` / `src/render/scene.ts` — mesh + scene built in 056/057.
- `src/main.ts` `getActiveBreed()` — the active breed source to wire through.
- `.docs/specs.md` "The Dog" D2/D3, "Breeds".

## Progress Log

- 2026-06-14 — Task created (scan round 2, focus: dog).
- 2026-06-14 — Implemented. TDD Part A (11 tests, 4 slices red-green). Part B: dogMesh.ts
  parameterised with DogAppearance (coat/bodyGirth/legLength/earStyle); setAppearance() for
  live recolouring on dog-switch; scene.ts wired with initialAppearance + setBreed(); main.ts
  passes active breed on load, onSelectDog, onAdoptBreed. Idle tint now reads dog.breedCoat
  instead of hardcoded BASE_COLOR. After visual review, Bulldog changed to orange-brindle and
  Puddel changed to off-white/cream for better separation. 462 tests pass, typecheck clean,
  build passes.

## Resolution

Implemented breed-distinct dog looks (D2). Created `src/render/dogAppearance.ts` with pure
`breedAppearance()` lookup for all 5 catalog breeds (Labrador warm-tan, Border Collie near-
black, Bulldog orange-brindle, Husky blue-grey, Puddel off-white). 11 new tests written
test-first. `createDogMesh` now accepts `DogAppearance` and applies coat colour, body girth
scaling, leg length scaling, and ear rotation style (floppy vs pricked). `setAppearance()`
method allows live recolouring without mesh rebuild. Idle tint now returns `dog.breedCoat`
not a hardcoded tan. All 5 breeds are visually distinct at a glance in portrait training view.
A `window.__setBreed` dev hook was added for screenshot automation.

## Acceptance Criteria

- [x] `src/render/dogAppearance.ts` exists with a **pure** `breedAppearance(id)` and
      `dogAppearance.test.ts` written **test-first** covering: labrador baseline,
      distinct coats per breed, unknown-id fallback, differing proportion cues.
- [x] `createDogMesh` consumes a `DogAppearance` (coat + proportions + ear style);
      the active breed is wired through `scene.ts`/`main.ts` on load, switch, and adopt.
- [x] Idle returns to the **breed** coat (not a hardcoded tan); per-state tints
      still read on top of the breed coat.
- [x] **Visual Review:** screenshots of all 5 breeds show each is recognizably
      different at a glance (satisfies **D2**); a switched/adopted dog shows its
      breed look.
- [x] `bun run test`, `bun run typecheck`, `bun run build` all pass; existing
      tests stay green.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
