# FEATURE: glTF load path + procedural fallback (keep the app shippable)

**Status**: Backlog — **blocked on 077** (needs a concrete `.glb`)
**Created**: 2026-06-17
**Priority**: High
**Labels**: render, assets, loading, tdd, epic:pokemon-go-visuals
**Estimated Effort**: Medium

## Context & Motivation

Phase 1 of the **[Pokémon-GO Visuals epic](../EPIC-pokemon-go-visuals.md)**. Before
we render an imported dog we need a robust way to **load it asynchronously** and to
**degrade gracefully** to today's procedural mesh if the model fails or is slow —
so the app is never broken while the pipeline matures. This task adds the load path
and the fallback decision; `079` plugs the loaded model in behind the `DogMesh`
interface.

## Current State

- `src/render/scene.ts` builds the procedural dog synchronously via
  `createDogMesh()`; there is no async asset load anywhere.
- `#hud-loading` spinner already exists for the lazy-Babylon window (task 043) —
  reuse it for the model-load window.
- Zero `.glb`/glTF assets and zero loader code today.

## Desired Outcome

An async `loadDogModel()` path that imports the `.glb` (Babylon glTF loader),
exposes loading/ready/failed states, and a **pure fallback decision** that the
scene uses to pick imported-vs-procedural — defaulting to procedural until the
imported path is proven and flag-enabled.

## Affected Components

### Files to Create
- `src/render/dogModelLoader.ts` + `.test.ts` — async load wrapper **and** a pure
  `selectDogRenderMode(...)` (the testable part: given `{ flagEnabled, loadState }`
  → `'imported' | 'procedural'`).
- Assets convention from `077` (e.g. `public/models/dog.glb`).

### Files to Modify
- `src/render/scene.ts` — await the loader, show/hide `#hud-loading`, pick render
  mode via `selectDogRenderMode`, fall back to `createDogMesh()` on failure.
- A feature flag (e.g. `VITE_IMPORTED_DOG` env or a `renderConfig` const) —
  default **off** this phase.

## Technical Approach

### Architecture Decisions
- **Pure decision, impure load.** Keep `selectDogRenderMode` a pure function (TDD);
  the actual `ImportMeshAsync`/`SceneLoader` call is render glue covered by Visual
  Review. This mirrors the existing core-vs-render split.
- **Fallback is mandatory, not optional.** A load failure or timeout must leave a
  fully playable procedural dog — never a blank scene.
- **Lazy + code-split** the glTF loader so the entry bundle stays small (consistent
  with tasks 036/040).

### Behaviours to test (TDD)
1. `flagEnabled=false` → always `'procedural'` regardless of load state.
2. `flagEnabled=true, loadState='ready'` → `'imported'`.
3. `flagEnabled=true, loadState='failed'|'loading'|'timeout'` → `'procedural'`.
4. (If a timeout is modeled) elapsed > budget with state `'loading'` → `'procedural'`.

### Implementation Steps
1. TDD `selectDogRenderMode` through behaviours 1–4.
2. Implement `loadDogModel()` (lazy glTF loader, returns mesh + skeleton +
   animation groups, or throws → caught as `failed`).
3. Wire `scene.ts`: spinner during load, `selectDogRenderMode` to choose, fall back
   to procedural on anything but a clean `imported` ready.
4. **Visual Review:** with flag on, model loads and the dog appears; with flag off
   or model removed, procedural dog still renders. No blank frames.

## Risks & Considerations
- **Bundle bloat** — glТF loader must be lazy/split; check the build chunk table.
- **Async race on dog-switch/adopt** — ensure a switch mid-load resolves to the
  right dog; guard with the existing switch path.

## Acceptance Criteria
- [ ] `selectDogRenderMode` is pure + TDD-covered (flag off, ready, failed, loading).
- [ ] `loadDogModel()` lazily loads the `.glb`; failure is caught, not thrown to UI.
- [ ] Flag **off** by default → identical to today (procedural dog, all states work).
- [ ] Flag **on** + valid model → model loads with the `#hud-loading` spinner; load
      failure cleanly falls back to procedural (Visual Review confirms both paths).
- [ ] Entry bundle unaffected (loader is split); `bun run verify` green.

---

**Next Steps**: Unblocked once `077` stages a `.glb`. Move to `in-progress` then.
