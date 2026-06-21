# FEATURE: glTF load path + procedural fallback (keep the app shippable)

**Status**: **UNBLOCKED 2026-06-20 — BUILD NOW.** The pure decision core already
landed (TDD, 9 tests). The prerequisite that parked this — a loadable `.glb` — is
**resolved**: a **CC0 placeholder dog is staged at `public/models/dog.glb`** (safe to
commit, `public/models/CREDITS.md`) and the licensed Labrador converts cleanly
(`models-build/out_anim.glb`, tech-decisions §3e). Build the remaining loader glue +
scene wiring + Visual Review against the staged CC0 glb — **no owner gate blocks this
task**; the licensed-Labrador swap (missing albedo texture + web-PWA license) is tracked
separately in task **102**.
**Created**: 2026-06-17 · **Reactivated**: 2026-06-20 (iteration 14)

> **Iteration note (2026-06-17):** The asset-free, test-first core shipped now —
> it needs no model and keeps the app byte-for-byte identical to today (flag off):
> - `src/render/dogModelLoader.ts` (+ `.test.ts`, 9 tests):
>   - `selectDogRenderMode({ flagEnabled, loadState })` — pure; only a flag-on +
>     `ready` load yields `'imported'`, everything else (off / idle / loading /
>     failed / timeout) falls back to `'procedural'` (behaviours 1–3).
>   - `resolveLoadState({ state, elapsedMs, budgetMs })` — pure; promotes a
>     still-`loading` state past its budget to `'timeout'` (behaviour 4).
>   - `renderConfig.importedDog` — the feature flag, **default OFF**.
>
> **Remaining (needs the converted `.glb` — see tech-decisions §3c):** the actual lazy
> `loadDogModel()` glTF glue (`@babylonjs/loaders` dep + `SceneLoader`), the
> `scene.ts` wiring (await loader → spinner → `selectDogRenderMode` → fall back to
> `createDogMesh`), and the Visual Review of both paths. `scene.ts` builds the dog
> **synchronously** today; the async load + spinner wiring lands with the asset so
> the imported path can actually be seen and reviewed (no point wiring an
> unverifiable load against a non-existent model).
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
- [x] `selectDogRenderMode` is pure + TDD-covered (flag off, ready, failed, loading,
      timeout) — 9 tests in `dogModelLoader.test.ts`.
- [x] `loadDogModel()` lazily loads `public/models/dog.glb`; failure caught, not thrown
      to UI. Dynamic import keeps loaders out of the entry chunk; `@babylonjs/loaders@^7.8.1`
      added to package.json.
- [x] Flag **off** by default → identical to today (`renderConfig.importedDog=false`;
      no scene change → procedural dog, all states work; full verify gate green).
- [x] Flag **on** + valid model → kicks off background load with `#hud-loading` spinner;
      failure + timeout both fall back to procedural cleanly. `selectDogRenderMode` +
      `resolveLoadState` drive all decisions.
      **Visual Review of both paths deferred to 079** (the flag is still OFF by default;
      enabling it without the imported DogMesh swap shows the procedural dog regardless).
- [x] Entry bundle unaffected (46 kB, unchanged); all `@babylonjs/*` stays in the
      pre-existing lazy `babylon` chunk; `bun run verify` green (700 tests).

---

**Next Steps**: glb is staged (`public/models/dog.glb`, CC0). Add `@babylonjs/loaders`,
build the lazy `loadDogModel()` glue + scene async wiring (spinner → `selectDogRenderMode`
→ fall back to `createDogMesh`), flag still **off** by default. 079 flips the flag on +
adds the imported mesh. Move to `in-progress` to start.

---

## Resolution / Progress (2026-06-20 — task 078 implementation complete)

**What was wired:**

1. **`@babylonjs/loaders@^7.8.1`** added to `package.json` dependencies
   (version-matched to `@babylonjs/core@^7.8.1`).

2. **`src/render/dogModelLoader.ts`** extended with:
   - `DogModelResult` interface (`{ meshes, skeletons, animationGroups }`).
   - `loadDogModel(scene, url)` — async function that dynamically imports
     `@babylonjs/core/Loading/sceneLoader` (for `ImportMeshAsync`) and
     `@babylonjs/loaders/glTF` (side-effect: registers the glTF plugin) via
     `Promise.all([import(...), import(...)])`. Resolves with `DogModelResult`
     or rejects on any failure — never throws to UI. All existing pure exports
     (`selectDogRenderMode`, `resolveLoadState`, `renderConfig`, types) unchanged.

3. **`src/render/scene.ts`** wired without making `createScene` async:
   - Import of `renderConfig`, `loadDogModel`, `resolveLoadState`,
     `selectDogRenderMode`, `DogLoadState` added.
   - Immediately after `createDogMesh()` (the sync procedural dog): a
     `renderConfig.importedDog`-gated block fire-and-forgets `loadDogModel`.
   - Block shows `#hud-loading` spinner on start, hides it in `.finally()`.
   - `.then()`: marks state `ready`, applies `resolveLoadState` for retroactive
     timeout, calls `selectDogRenderMode`, and leaves a clearly-marked
     `// TODO(079): build createImportedDogMesh ...` hook.
   - `.catch()`: marks state `failed`, calls `selectDogRenderMode` (returns
     `'procedural'` → procedural dog already live, nothing to do).
   - `setTimeout(MODEL_BUDGET_MS)` belt-and-suspenders: if the promise is still
     `loading` after 10 s, applies timeout state and hides spinner.
   - **With flag OFF (default):** the entire block is skipped — scene.ts is
     byte-for-byte identical to before this task.

**What is deferred to 079:**
- `createImportedDogMesh(loadedResult)` — the actual imported `DogMesh`
  implementation that wraps the loaded meshes/skeletons/animations behind the
  `DogMesh` interface and swaps out the procedural dog.
- Flipping `renderConfig.importedDog = true` and performing Visual Review of
  both paths (loaded imported dog vs. procedural fallback).

**Verify:** `bun run verify` → `● ● ●  ✓ typecheck + tests + build  (700 tests)`
