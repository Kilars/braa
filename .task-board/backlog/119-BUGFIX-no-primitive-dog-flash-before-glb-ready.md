# BUGFIX: Never flash the primitive placeholder dog before the GLB is ready

**Status**: Backlog
**Created**: 2026-06-21 (iteration 25 scan)
**Priority**: High
**Labels**: bugfix, visual, loading-state, dog, po-review, D1, D14
**Estimated Effort**: Small-Medium

## Context & Motivation

PO Review — 2026-06-21, **Bugfix #1**: on a cold start, entering a round shows the
old **capsule-body / sphere-head / cylinder-leg primitive** dog for ~0.3–1 s before
the real Labrador GLB swaps in (a shot at +300 ms vs +1000 ms after picking Sitt
differs). The spec is explicit (D1, D14): bare capsule/sphere/cylinder geometry does
**not** satisfy "reads as a dog" — *not even as a placeholder*. So the flash is a
spec violation at the most-seen moment (every cold round entry).

Root cause: `scene.ts` builds the procedural primitive dog **synchronously and
visibly** (to "guarantee no blank frame"), then swaps it for the imported GLB once
the async load settles. During the load window the primitive is on screen.

## Current State

- `src/render/scene.ts:138-146` — `let dog = createDogMesh(scene, ...)` built and
  shown immediately.
- `src/render/scene.ts:164-257` — when `renderConfig.importedDog || _devForceImported`,
  the GLB loads in the background; on `ready`+`imported` the procedural dog is
  **disposed** (`:238-239`) and `dog` is reassigned (`:243`). On failure/timeout it
  silently keeps the procedural dog (`:247-253`, the documented fallback). The
  `#hud-loading` spinner already shows during the window (`:167-168`, hidden in
  `.finally` `:254-256`).
- So today the primitive renders for the whole load window. There is **no helper**
  deciding the procedural dog's *visibility* during load.

## Desired Outcome

When the imported path is active, the procedural primitive dog is **hidden during the
load window** (so the blob never shows); the spinner covers the wait. On settle:
- **ready + imported** → reveal the imported GLB (fade in), procedural already disposed;
- **failure / timeout / procedural mode** → reveal the procedural dog as the
  documented graceful fallback (a primitive dog is still better than no dog when the
  GLB genuinely can't load — and the public CC0 path only hits this on a real failure).

When the imported block is skipped entirely (flag fully off) behavior is unchanged —
the procedural dog shows immediately as before.

## Affected Components

### Files to Create / Modify
- `src/render/dogModelLoader.ts` (+ `dogModelLoader.test.ts`) — new pure helper
  `proceduralDogVisible({ flagActive, loadState, mode })` returning whether the
  procedural mesh should be enabled. TDD.
- `src/render/scene.ts` — at load kick-off set `dog.root.setEnabled(false)` when the
  imported block runs; in `.then`/`.catch` reveal per the helper (fade the imported
  root in on success). Skip-block path untouched.
- `.docs/tech-decisions.md` — note the "hold-then-reveal" loading policy (no primitive
  blob during load).

### Dependencies
- **Internal**: `selectDogRenderMode`, `resolveLoadState`, `DogLoadState` (already in
  `dogModelLoader.ts`). None blocking.
- **External**: none. Babylon `AbstractMesh.setEnabled` already used (`palm.setEnabled`,
  `scene.ts:344/364`).

## Technical Approach

### Implementation Steps
1. **TDD (pure helper, red→green)** — `proceduralDogVisible({ flagActive, loadState, mode })`:
   - `flagActive: false` → `true` (flag off: primitive is the intended dog, show it).
   - `flagActive: true, loadState: 'loading'` → `false` (hide during the load window).
   - `flagActive: true, mode: 'imported'` (ready) → `false` (GLB replaces it).
   - `flagActive: true, loadState: 'failed'|'timeout'`, `mode: 'procedural'` → `true`
     (graceful fallback — a primitive dog beats no dog).
2. **Glue (scene.ts, Visual Review-covered)**:
   - In the `if (renderConfig.importedDog || _devForceImported)` block, immediately
     after building `dog`, call `dog.root.setEnabled(false)` (hidden while loading).
   - In `.then`: on `imported`, after building `importedDog`, set its root visible and
     fade in (e.g. ramp `visibility` 0→1 over ~200 ms via a short scene observer, or
     reuse an existing fade if present); on non-imported, `dog.root.setEnabled(true)`.
   - In `.catch`: `dog.root.setEnabled(true)` (reveal fallback).
3. **Visual Review**: cold-load the round with the imported path on; capture +300 ms
   and +1000 ms — confirm **no primitive blob** at +300 ms (spinner/empty stage only),
   real Labrador faded in by +1000 ms. Then confirm the failure path (block the asset)
   still shows the procedural dog.

### Before / After

**Before** (`src/render/scene.ts`, primitive visible during load):
```ts
let dog = createDogMesh(scene, initialAppearance);
dog.root.position.y = BASE_Y;
if (renderConfig.importedDog || _devForceImported) {
  const spinner = document.getElementById('hud-loading');
  if (spinner) spinner.style.display = '';
  // ... load GLB; primitive keeps rendering until swap/failure ...
}
```

**After**:
```ts
let dog = createDogMesh(scene, initialAppearance);
dog.root.position.y = BASE_Y;
const _flagActive = renderConfig.importedDog || _devForceImported;
if (_flagActive) {
  // Hold the primitive hidden — the spec forbids the blob even as a placeholder
  // (D1/D14, PO Review 2026-06-21 #1). The spinner covers the wait.
  dog.root.setEnabled(false);
  const spinner = document.getElementById('hud-loading');
  if (spinner) spinner.style.display = '';
  loadModel.then(/* on imported: reveal+fade importedDog; else dog.root.setEnabled(
    proceduralDogVisible({ flagActive: true, loadState, mode })) */)
           .catch(/* dog.root.setEnabled(true) — graceful primitive fallback */);
}
```

### Risks & Considerations
- **Risk**: hiding the procedural dog leaves a permanently empty stage if the GLB
  never settles. **Mitigation**: the `MODEL_BUDGET_MS` timeout (`scene.ts:163`) forces
  a terminal `timeout` state → `proceduralDogVisible` returns `true` → fallback shows.
  The `.catch` also reveals on any throw. There is always a terminal reveal.
- **Risk**: a one-frame blank instead of the blob. **Mitigation**: acceptable and
  spec-preferred — a neutral loading state (spinner) beats a non-dog blob (PO "hold
  the dog hidden … then fade it in").
- **Risk**: fade-in adds motion under `prefers-reduced-motion`. **Mitigation**: a
  simple opacity fade is fine (no jitter/bounce); if desired, snap to visible under
  reduced motion. Keep it minimal.

## Acceptance Criteria

- [ ] `proceduralDogVisible` added to `dogModelLoader.ts` **test-first** via `tdd`
      with the four cases above (flag off → visible; loading → hidden; imported →
      hidden; failed/timeout procedural → visible).
- [ ] `scene.ts` hides the procedural dog at load kick-off (imported path only) and
      reveals the correct dog on every terminal outcome via the helper; flag-off path
      byte-for-byte unchanged.
- [ ] **Visual Review (blocking)**: cold-start +300 ms shows **no** primitive
      capsule/sphere/cylinder dog (spinner/empty stage), +1000 ms shows the Labrador;
      the GLB-failure path still shows the procedural dog. Screenshots attached.
- [ ] Decision noted in `.docs/tech-decisions.md`. **specs.md untouched.**
- [ ] Full gate green: `bun run typecheck` (0) · `bun run test` · `bun run build`
      (no warnings) · `bun run e2e`.

---

**Technical approach hint**: the decision is a tiny pure helper (TDD); the rest is
`setEnabled`/fade glue verified by Visual Review. The invariant to protect: there is
**always** a terminal reveal (success, failure, or timeout) so the stage is never
permanently empty — and the blob is **never** shown while a GLB load is in flight.
