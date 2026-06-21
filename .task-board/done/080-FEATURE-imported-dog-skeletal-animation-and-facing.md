# FEATURE: Imported Labrador — face camera + drive states via skeletal AnimationGroups, then flip the flag

**Status**: Backlog (epic phase 2 — promoted from outline; the reserved id `080`)
**Created**: 2026-06-20 (iteration 17 scan)
**Priority**: High
**Labels**: render, assets, animation, epic:pokemon-go-visuals
**Estimated Effort**: Medium

## Context & Motivation

This is the **single highest-impact remaining v1 gap** and the product owner's
explicit #1 ask (specs.md line 1: *"MAKE GLB REPLACE PLACEHOLDER DOG"*). The spec is
clear that the Pokémon-GO-style look — a dog that reads as a real dog and as its breed
— is **part of v1, not a later pass** (specs.md §Scope, §The Dog D1–D14, D14 explicitly
forbids "bare placeholder geometry").

Everything upstream of this task is already done:
- The real **textured licensed Labrador glb** exists (`models-build/out_anim.glb`,
  113 embedded animation clips) and is **AES-GCM packed** to `public/models/dog.pack`
  (task 103, tech-decisions §3i).
- The decrypt-in-memory **load path works end-to-end** — the packed Labrador renders
  with **correct matte fur** behind the DEV overrides `?importedDog=1&licensedDog=1`
  (task 103 Visual Review).
- The CC0 generic dog already proved the `createImportedDogMesh` pipeline (task 079).

The **only** reasons `renderConfig.importedDog` is still OFF (documented in
tech-decisions §3i and task 103's Resolution as the recommended follow-up) are two pure
**engineering** concerns — no owner/legal/asset gate remains:

1. **The imported rig faces AWAY from the camera.** `applyPose` owns
   `root.rotation.y` (used by the `bodyYaw` spin trick), so the camera-facing base yaw
   must live on the **framing pivot**, not the root.
2. **The 113 embedded skeletal clips are not played.** `createImportedDogMesh`
   currently drives the dog only through transform-tween pose channels (root/bone
   rotations); the AnimationGroups loaded with the glb are inert, so idle / offering /
   markable-apex / happy / confused all look the same. The procedural dog therefore
   still reads better, and per the **079 rule** the flag stays off until the imported
   dog Visual-Reviews **≥** the procedural baseline.

Close both and the licensed Labrador becomes the live dog — the visuals epic's vertical
slice lands.

## Current State

- `src/render/importedDogMesh.ts` (~499 lines) — `createImportedDogMesh()` implements
  the full `DogMesh` contract over the loaded glb. `applyPose()` maps whole-body
  channels onto `root.rotation.*` and per-part channels onto bones found by
  case-insensitive name (no-op if absent). Line ~311 comment: *"Phase 2 (task 080) will
  add full skeletal animation clips."* The AnimationGroups returned by the loader are
  **not retained or played**.
- `src/render/scene.ts` — dynamically imports `importedDogMesh` inside the flag-gated
  block when `selectDogRenderMode() === 'imported'`; otherwise uses the procedural
  `createDogMesh`. The render loop calls `updateDog` → `applyPose` every frame.
- `src/render/dogPose.ts` — pure `dogPose(state, t, …)` produces the `DogPose` channel
  values per visual state; already reduced-motion-aware.
- `src/render/dogState.ts` — the `DogVisualState` enum (idle / offering / markable /
  confused / happy / distractor …) that drives everything.
- Flag: `renderConfig.importedDog` is **default OFF**; DEV `?importedDog=1` +
  `?licensedDog=1` route to the imported + packed paths (`devOverrideLicensedDog`).

## Desired Outcome

- The imported Labrador **faces the camera** in its rest/idle framing (the spin trick's
  `bodyYaw` still rotates relative to that base — no regression).
- Each core visual state is driven by an appropriate **embedded AnimationGroup** played
  from the glb (idle, offering/sniff, the markable behaviour building to its apex,
  happy/reward, confused), blended with / falling back to the existing procedural pose
  channels so nothing upstream changes and missing clips degrade gracefully.
- `prefers-reduced-motion` dampens (not removes) the clip motion, consistent with D13.
- **Visual Review** on a phone-portrait viewport via `?importedDog=1&licensedDog=1`:
  the Labrador reads as a recognizable Labrador, states are tellable apart at a glance,
  the apex tell + mark pop feel satisfying, framerate is acceptable.
- **Flip `renderConfig.importedDog` to default ON only if** the imported dog
  Visual-Reviews **≥** the procedural baseline (the 079 rule). If it still falls short,
  leave the flag OFF, keep the proven improvements, and record precisely what remains.

## Affected Components

### Files to Create
- `src/render/dogAnimationMap.ts` — **pure** state → clip-name resolution + blend/damp
  logic (TDD; no Babylon import).
- `src/render/dogAnimationMap.test.ts` — its tests.

### Files to Modify
- `src/render/importedDogMesh.ts` — retain the loaded `AnimationGroup[]`, add a
  camera-facing base yaw on the framing pivot, and play the resolved clip per state.
- `src/render/scene.ts` — pass the current `DogVisualState` (and reduced-motion flag)
  through to the imported mesh so it can select the clip (the procedural path is
  unaffected).
- `.docs/tech-decisions.md` — update §3f/§3i with the animation-mapping decision and
  the final flag state (implementation notes only; **do not touch specs.md**).
- `public/models/CREDITS.md` — note the clips now drive states, if relevant.

### Dependencies
- **External**: none — `@babylonjs/loaders` already loads the AnimationGroups; the lazy
  `babylon-loaders` chunk already exists (tech-decisions §3f).
- **Internal**: task 079 (`createImportedDogMesh`), task 103 (packed load path) — both
  **DONE**.
- **Blocking**: none. No owner/legal/asset gate remains (texture supplied, license
  decided = pack/encrypt).

## Technical Approach

### Architecture Decisions

- **Keep the `DogMesh` / `DogPose` contract unchanged.** Upstream (`scene.ts`,
  `main.ts`) keeps calling `applyPose`; the imported mesh internally layers a baked clip
  under the procedural channels. This preserves the epic's "swap behind the seam"
  guarantee and keeps the procedural fallback intact.
- **Extract a pure resolver** so the logic is test-first per CLAUDE.md/TDD: which clip
  name maps to a state, the reduced-motion damping factor, and graceful fallback when a
  named clip is absent are all pure functions. The actual `AnimationGroup.play()` /
  blend-weight glue is render-only and covered by **Visual Review**.
- **Camera-facing yaw on the pivot, not the root.** `applyPose` owns
  `root.rotation.y`; baking the facing offset into the framing pivot (the ancestor
  created in `createImportedDogMesh` for centering/scaling) keeps the spin trick correct.
- **Match clips by case-insensitive name with fallbacks** (the rig has `Idle_1..7`,
  `Sitting_*`, `Lie_*`, `Bark`, `Scratching`, …; see tech-decisions §3e inventory), so
  the resolver never throws on an unexpected rig and the procedural pose shows through if
  a clip is missing.

### Implementation Steps

1. **Pure resolver (TDD — `tdd` skill, vertical slices):**
   - `resolveStateClip(state, availableClipNames)` → the best-match clip name or
     `null` (fallback to procedural). One test → impl → repeat for each state and the
     "missing clip" path.
   - `clipMotionScale(reducedMotion)` → damping factor (1 normal, dampened when reduced).
2. **Imported-mesh wiring (Visual Review):**
   - Retain the `AnimationGroup[]` from the load result; stop all on creation.
   - Add the camera-facing base yaw on the framing pivot.
   - On state change, `play` the resolved group (looping for idle/offering, one-shot for
     happy/mark), scaled by `clipMotionScale`, with the procedural channels still applied
     additively for head/tail micro-motion.
3. **Visual Review + flag decision:**
   - Screenshots/video on phone-portrait via `?importedDog=1&licensedDog=1`; spawn an
     independent review agent (never fabricate a screenshot — use
     `node scripts/shoot-hud.mjs` per the Subagent note).
   - Flip `renderConfig.importedDog` default ON **iff** it reads ≥ procedural; else keep
     OFF and document the remaining delta.

### Risks & Considerations

- **Risk**: clip + procedural channels fight each other (double rotation). **Mitigation**:
  decide per-channel ownership — baked clip owns gross body motion, procedural owns
  additive head/tail/breathe; document it.
- **Risk**: 18.7 MB packed asset hurts mobile load/decrypt time. **Mitigation**: it is
  DEV-gated until the flag flips; note load time in the Visual Review and, if needed,
  defer the default-ON flip to the perf phase (085) while keeping the animation work.
- **Risk**: headless software-render fps is ~3 (tech-decisions §3g) so motion review is
  unreliable headless. **Mitigation**: review on a real frame-rate path; assert clip
  selection via the pure resolver tests, not via headless timing.

## Before / After Examples

### Example 1: Camera-facing yaw moves off the root

**Before** (`src/render/importedDogMesh.ts`, `applyPose`):
```ts
root.rotation.y = pose.bodyYaw ?? 0;   // dog ends up facing away; spin uses the same axis
```

**After**:
```ts
// framing pivot carries the camera-facing base yaw (set once at creation)
framingPivot.rotation.y = CAMERA_FACING_YAW;
// root still owns the spin trick, now relative to a camera-facing rest pose
root.rotation.y = pose.bodyYaw ?? 0;
```

### Example 2: State drives a baked clip (pure resolver + render glue)

**Before**: AnimationGroups loaded but inert; every state looks identical except tint.
```ts
// (no AnimationGroup playback anywhere in importedDogMesh.ts)
```

**After** (`src/render/dogAnimationMap.ts`, pure + tested):
```ts
export function resolveStateClip(
  state: DogVisualState,
  clips: readonly string[],
): string | null {
  const wanted = STATE_CLIP_PREFERENCES[state]; // e.g. ['Idle_1','Idle']
  return wanted.find((w) => clips.some((c) => c.toLowerCase() === w.toLowerCase()))
    ?? null; // null → keep procedural pose
}
```
```ts
// importedDogMesh.ts render glue (Visual Review):
const name = resolveStateClip(state, clipNames);
const group = name ? groupsByName.get(name.toLowerCase()) : undefined;
if (group && group !== activeGroup) { activeGroup?.stop(); group.play(loops(state)); activeGroup = group; }
```

## Code References

- `src/render/importedDogMesh.ts` — the contract impl + the `// task 080` marker.
- `src/render/dogPose.ts` / `src/render/dogState.ts` — channel + state sources to map from.
- tech-decisions §3e (113-clip inventory), §3f (skinned-framing notes), §3i (packed path
  + the recommended follow-up this task implements).
- `src/render/backdropTier.ts` — example of a pure, fully-tested render-support module.

## Progress Log

- 2026-06-20 — Task created (iteration 17 scan). Promoted epic phase-2 outline `080` to a
  full task file; folds in task 103's recommended facing-fix follow-up. No owner gate
  remains — pure engineering.
- 2026-06-20 (resolution) — **Engineering complete; flag stays OFF for a packaging reason.**
  - Pure resolver (`dogAnimationMap.ts`) + 16 tests already present; refined idle mapping
    after Visual Review (see below). `clipMotionScale` (reduced-motion) + `clipLoops` tested.
  - Camera-facing yaw on a dedicated `facingPivot` (between root and framing pivot); fit
    scale also moved there so `scene.ts`'s per-frame `root.scaling` doesn't clobber it. Spin
    trick still composes on `root.rotation.y`. **Verified: Labrador faces camera.**
  - `setVisualState` plays the resolved `AnimationGroup` per state, restoring a bind-pose
    snapshot on each change. **Verified: idle (standing) vs offering (sitting) clearly distinct.**
  - **Visual-Review finding → idle remapped `Idle_1`→`Idle_2`.** `Idle_1` is the rig's *seated*
    idle (looked identical to the seated `offering`); `Idle_2` is the *standing* calm idle.
    Test + comment updated to document this; `Idle_1` kept as fallback.
  - **Bug found + fixed (the big one).** The CC0 dog rendered *exploded*. Root cause: Babylon's
    glTF loader auto-starts the first embedded clip; `refreshBoundingInfo({applySkeleton:true})`
    then bakes that pose into the framing bounds. CC0's first clip is `Death` (sprawled) →
    bbox `x:0..2.398` → garbage scale. Fix: `dogModelLoader` forces the glTF loader's
    `animationStartMode = NONE` (scoped `OnPluginActivatedObservable` hook) so both rigs frame
    at REST. Verified: CC0 bbox → symmetric `x:-0.475..0.475`; Labrador still renders great.
  - **Flag decision (079 rule): `renderConfig.importedDog` stays OFF.** Head-to-head on a
    390×844 portrait viewport: **Labrador ≫ procedural ≫ CC0-imported.** The licensed Labrador
    is ≥ procedural, but it ships ONLY via the DEV `?licensedDog=1` override / a native build —
    never the default web build (pack gitignored, §3d/§3i). Flipping the committed flag would
    ship the *CC0* dog, which reads BELOW the polished procedural dog. So OFF is correct; all
    engineering lands behind the flag. Remaining delta is now **owner/packaging**, not
    engineering (tech-decisions §3j). Real screenshots captured for Labrador, CC0, procedural.
  - Gate green: typecheck 0 · test 760 · build no-warn · e2e PASS. Decision recorded in
    tech-decisions §3i/§3j (+ §3f pointer). **specs.md untouched.**

## Acceptance Criteria

- [x] Pure `resolveStateClip` (+ reduced-motion damping) added **test-first** via the
      `tdd` skill — one failing test → minimal impl → repeat; behavior tested through the
      public function, not internals.
- [x] The imported Labrador faces the camera at rest; the `bodyYaw` spin trick still
      rotates correctly (no regression to the spin pose).
- [x] Idle / offering / markable-apex / happy / confused each play a distinct embedded
      AnimationGroup; a missing clip falls back to the procedural pose without throwing.
- [x] `prefers-reduced-motion` dampens (not removes) clip motion (D13).
- [x] **Visual Review (blocking)**: real phone-portrait screenshots via
      `?importedDog=1&licensedDog=1`, reviewed by an independent agent — the dog reads as
      a Labrador, states are distinguishable at a glance, the mark moment feels good. No
      fabricated screenshots.
- [x] `renderConfig.importedDog` flipped to default ON **iff** the imported dog
      Visual-Reviews ≥ the procedural baseline; otherwise OFF with the remaining delta
      documented in tech-decisions. → **OFF** (committed web build would ship the CC0 dog,
      which reads below procedural; licensed Labrador only ships via DEV override / native
      build because the pack is gitignored). Remaining delta is owner/packaging, not
      engineering (tech-decisions §3j).
- [x] Decision recorded in `.docs/tech-decisions.md` (§3f/§3i/§3j). **specs.md untouched.**
- [x] Full gate green: `bun run typecheck` (0) · `bun run test` (760) · `bun run build`
      (no warnings) · `bun run e2e` — re-verified iteration 18, 2026-06-20.

---

**Next Steps**: Engineering complete; closed to `done`. Remaining gap to default-ON is
owner/packaging (ship the licensed pack in the committed/native build), not engineering.
