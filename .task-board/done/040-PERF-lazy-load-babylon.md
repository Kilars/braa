# PERF: Lazy-load Babylon (select paints before the 3D engine)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: perf, refactor, visual-review
**Estimated Effort**: Medium

## Context & Motivation

Babylon is a separate 1.46 MB chunk (036) but `main.ts` still imports + creates the
scene at startup, so first paint waits on the 3D engine. The app starts in the
DOM-only **select** screen (3D is only needed for training). Dynamic-import the scene
so the select screen paints first and Babylon loads in the background / on first train.

## Current State

`main.ts` does a static `import { createScene } from './render/scene'` and calls
`createScene(canvas)` immediately at startup; `updateDog` is called every rAF frame.

## Approach (behavior-preserving)
- Change the scene import to a DYNAMIC import: `const sceneMod = await import('./render/scene')`.
- Create the scene either (a) right after the select screen has rendered (so it's ready
  before the first training), or (b) on the first `onSelectTrick` (entering training).
  Prefer (a) — kick off the import early but non-blocking, and guard `updateDog` calls
  until the scene exists (`if (sceneApi) sceneApi.updateDog(...)`).
- The dog/scene must be ready by the time training starts (it always passes through select
  first, so an early background import comfortably finishes). Handle the brief window where
  `sceneApi` is undefined gracefully (no error, just skip updateDog).
- Keep `vite-plugin-pwa` precache + manualChunks working.

## Verification (reuse the running dev server; do NOT pkill; never fake a screenshot)
- `bun run build` — confirm the babylon chunk is now an ASYNC chunk (dynamically imported), and the entry/app chunk no longer statically includes Babylon. No new warnings.
- App still works: screenshot the SELECT screen (loads fast) AND a TRAINING frame (click a trick → scene renders). VIEW both. The 3D dog must still appear in training.
- `bun run test` green; `bun run typecheck` 0.

## Risks
- The async gap: if a training frame runs before the scene loads, `updateDog` must no-op
  (guard it). Test by entering training quickly.

## Progress Log
- 2026-06-14 — Task created (iteration 14)

## Resolution

Changed `src/main.ts` only:

1. Replaced `import { createScene } from './render/scene'` with `import type { createScene } from './render/scene'` (type-only; zero runtime effect).
2. Removed the eager `const { updateDog } = createScene(canvas)` call.
3. Added `let sceneApi: ReturnType<typeof createScene> | null = null` after the canvas guard.
4. After `showSelect()`, kicked off `import('./render/scene').then(mod => { sceneApi = mod.createScene(canvas); }).catch(() => {})` — non-blocking background load.
5. Guarded the `updateDog` call in `tick()`: `if (sceneApi) sceneApi.updateDog(...)`.

**Build chunk evidence (Babylon now async):**
- Entry: `dist/assets/index-BIlaTrEF.js` — 28.98 kB (no Babylon code)
- Scene wrapper: `dist/assets/scene-DXvFmlvh.js` — 2.55 kB (bridge module)
- Babylon: `dist/assets/babylon-iDq-Og1e.js` — 1,459.89 kB (async chunk)
- Entry chunk contains `import("./scene-DXvFmlvh.js")` — confirmed dynamic import.
- Babylon is NOT present in the entry chunk; it loads only when the dynamic import resolves.

**E2E:** `E2E SMOKE PASS` (select→train→mark flow intact).

**Screenshots:**
- SELECT (`/tmp/bra-lazy-select.png`): trick-select grid visible, no 3D canvas loaded yet.
- TRAINING (`/tmp/bra-lazy-train.png`): "Teaching: Sitt" label visible; 3D dog sphere visible in "offering" (warm tan, slightly enlarged) state — Babylon loaded within ~1.8s of entering training.

**Typecheck:** 0 errors. **Tests:** 355/355 green. **Build:** no new warnings, PWA precache 13 entries intact.

## Acceptance Criteria
- [x] Scene is dynamic-imported; app/entry chunk no longer statically bundles Babylon (build-verified)
- [x] Select screen renders without waiting on Babylon; training still shows the 3D dog (both screenshot-verified, real)
- [x] `updateDog` guarded for the pre-load window (no error if scene not yet ready)
- [x] `bun run test` green; `bun run typecheck` 0; `bun run build` succeeds, no new warnings; PWA precache intact
