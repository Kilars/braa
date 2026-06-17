# FEATURE: Two-Tone Breed Coats (D2 polish — apply `coatBelly`)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: render, dog, breeds, visual-review, tdd
**Estimated Effort**: Simple

## Context & Motivation

Task 059 made breeds distinct by coat colour + proportions and **defined a
`coatBelly` field on `DogAppearance`** for two-tone coats — but left it
**unapplied** (the dog uses a single body material). Several real breeds are most
recognizable by their **two-tone markings** (Border Collie's white chest/blaze,
Husky's white underside/mask), so applying `coatBelly` is the cheapest remaining
boost to **D2 — breed reads clearly**.

## Current State

- `src/render/dogAppearance.ts` — `DogAppearance` has an optional `coatBelly`
  (defined, set for Border Collie / Husky), but `createDogMesh` ignores it; one
  shared body material in `dogMesh.ts`.
- 059's Resolution explicitly noted `coatBelly` is "defined … for future two-tone
  coat support … but not yet applied."

## Desired Outcome

Breeds with a `coatBelly` render a **visible second tone** on the underside /
chest (and optionally legs/snout) so Border Collie reads black-and-white and Husky
reads grey-with-white-underside at a glance. Breeds without `coatBelly` are
unchanged (single coat). Per-state tints (057/058) still work; idle returns to the
breed's two-tone look, not a flat colour.

## Affected Components

### Files to Modify
- `src/render/dogMesh.ts` — give the belly/chest (and optionally lower legs /
  snout underside) a **second material** driven by `appearance.coatBelly` when
  present; fall back to the main coat when absent. Ensure `setAppearance` updates
  both materials on dog-switch.
- `src/render/dogAppearance.ts` (+ test) — only if the belly assignment needs a
  tiny helper or an extra cue (e.g. which parts are belly-toned). Keep any logic
  added here **test-first**.

### Dependencies
- **External**: none.
- **Internal**: 059 (`dogAppearance`, `coatBelly`) — done.
- **Blocking**: none. Independent of 062/064.

## Technical Approach

### Architecture Decisions

- **Two materials, not a texture.** Cheapest path: a `coatMat` (existing) and a
  `bellyMat`; assign body underside parts (or a thin belly mesh, or the chest +
  lower legs) to `bellyMat` when `coatBelly` is set. No UV texturing needed for v1.
- **Belly tint must follow the breed**, and per-state tints should not flatten the
  two-tone (e.g. confused/distractor semantic hues may override both, but idle and
  happy keep the two-tone). Decide the simplest rule that still reads and keep idle
  two-tone.
- The only logic worth testing is in `dogAppearance` (which breeds have
  `coatBelly`, fallback when absent). Mesh assignment is Visual-Review-only.

### Behaviours to test (TDD, if any logic added to `dogAppearance`)

1. `breedAppearance('border-collie').coatBelly` and `breedAppearance('husky')
   .coatBelly` are defined and **differ from** their main coat.
2. A breed without two-tone (e.g. labrador) has `coatBelly` undefined → mesh uses
   the single coat (assert undefined; the mesh fallback is visual).

*(If no new logic is added — just consuming existing fields — this task is
pure-render and the acceptance criteria are Visual-Review only.)*

### Implementation Steps

1. **Add `bellyMat`** in `dogMesh.ts`; assign underside/chest parts to it when
   `appearance.coatBelly` is set, else to the main coat.
2. **Update `setAppearance`** to recolour both materials on switch.
3. **Verify idle** returns to the two-tone (not a flat colour); per-state tints
   still read.
4. **Visual Review** — screenshot Border Collie + Husky; confirm the two-tone
   reads and clearly separates them from single-coat breeds.

### Risks & Considerations

- **Risk: belly tone invisible from the trainer POV** (camera looks down/forward;
  underside may be hidden) — **Mitigation**: put the second tone on the **chest /
  front / lower legs / snout** (visible from POV), not just the literal belly.
- **Risk: per-state tint flattens the two-tone** — **Mitigation**: keep idle/happy
  two-tone; only the semantic-hue states (confused/distractor/misbehaving) may
  override.

## Before / After Examples

### Example 1: second material for the belly tone

**Before** (`src/render/dogMesh.ts`):
```ts
const mat = new StandardMaterial("dog-mat", scene);
mat.diffuseColor = appearance.coat.clone();
for (const part of [body, head, snout, ...legs, ...ears]) part.material = mat;
```

**After**:
```ts
const coatMat = new StandardMaterial("dog-coat", scene);
coatMat.diffuseColor = appearance.coat.clone();
const bellyMat = new StandardMaterial("dog-belly", scene);
bellyMat.diffuseColor = (appearance.coatBelly ?? appearance.coat).clone();
chest.material = bellyMat;            // chest + lower legs read from the POV
for (const part of [body, head, snout, ...ears]) part.material = coatMat;
```

## Code References

- `src/render/dogAppearance.ts` — `coatBelly` already set for border-collie/husky.
- `src/render/dogMesh.ts` — single-material assignment + `setAppearance` to extend.
- `.task-board/done/059-FEATURE-breed-distinct-dog-looks.md` — Resolution note on
  the deferred `coatBelly`.
- `.docs/specs.md` "The Dog" D2.

## Progress Log

- 2026-06-14 — Task created (scan round 3, focus: dog).
- 2026-06-14 — Implemented. Two-tone applied via `bellyMat` (second StandardMaterial);
  chest patch + front legs + snout/blaze use belly tone; `resetToBreedCoats()` restores
  two-tone on idle. Visual review passed. All 474 tests green, typecheck and build pass.

## Resolution

Implemented two-tone breed coats by:

1. **`src/render/dogMesh.ts`** — added `bellyMat` (second `StandardMaterial` initialised
   from `appearance.coatBelly ?? appearance.coat`). Three POV-visible body parts use it:
   - **Chest patch** — flattened ellipsoid on the front-lower torso (visible from 81° horizontal POV)
   - **Front legs** (indices 0 and 1) — cylinders already closest to trainer
   - **Snout** — already a separate box mesh, now uses `bellyMat`
   - **Face blaze** — new thin stripe sphere on forehead, facing trainer
   Back legs, body capsule, head, ears, and tail keep `mat` (main coat).

2. Added `breedBellyCoat` getter and `resetToBreedCoats()` method to `DogMesh` interface.
   `setTint()` now sets BOTH materials (correct for semantic states that should flatten
   the two-tone). `setEmissive()` also sets both.

3. **`src/render/scene.ts`** — replaced `tintFor()` + `setTint/setEmissive` with
   `applyVisualTint()` that calls `dog.resetToBreedCoats()` for idle and `dog.setTint()`
   for all semantic states (offering/happy/confused/distractor/misbehaving).

4. **No new logic in `dogAppearance.ts`** — `coatBelly` already existed; this task
   purely consumed existing fields (render-only, TDD not required for this part).

Visual result: Border Collie reads as clearly black-and-white (dark body, white chest/snout/legs).
Husky reads as grey-with-white. Labrador/Bulldog unchanged (single coat, chest sphere blends in).
Idle after mark correctly restores the two-tone; happy/confused/etc. collapse to semantic color.

## Acceptance Criteria

- [x] Breeds with `coatBelly` (Border Collie, Husky) render a **visible second
      tone** on POV-visible parts (chest/front/legs/snout); single-coat breeds
      unchanged.
- [x] `setAppearance` updates both coat and belly materials on dog-switch; idle
      returns to the two-tone look.
- [x] Any logic added to `dogAppearance` is covered **test-first**; existing
      `dogAppearance` tests stay green.
- [x] **Visual Review:** Border Collie reads black-and-white and Husky reads
      grey-with-white at a glance; clearly distinct from single-coat breeds.
- [x] `bun run test`, `bun run typecheck`, `bun run build` all pass.

---

**Next Steps**: Ready for implementation. Move to `.task-board/in-progress/` when starting work.
