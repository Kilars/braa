# FEATURE: Project Scaffolding (Vite + TS + Bun + Babylon + Vitest)

**Status**: Backlog
**Created**: 2026-06-13
**Priority**: High
**Labels**: infra, foundation
**Estimated Effort**: Simple

## Context & Motivation

Greenfield repo: only docs + skills exist, no code. Every other task depends on
a working TypeScript/Vite/Bun project with Babylon.js wired in and Vitest running
(TDD is mandatory for functional code, so the test runner must exist first).

## Current State

No `package.json`, no `src/`, no build/test tooling. Stack is decided in
`.claude/CLAUDE.md`: TypeScript + Vite + Bun, Babylon.js (WebGL), DOM UI overlay,
IndexedDB, Capacitor (later), Vitest for logic.

## Desired Outcome

`bun install` → `bun run dev` shows a placeholder Babylon scene on a portrait,
mobile-sized canvas; `bun run test` runs Vitest green; `bun run build` emits
`dist/`. Folder layout reflects the architecture layers.

## Affected Components

### Files to Create
- `package.json`, `tsconfig.json`, `vite.config.ts`
- `index.html` (portrait, mobile viewport)
- `src/main.ts` (entry; mounts UI + render)
- `src/render/scene.ts` (Babylon placeholder scene)
- `src/core/.gitkeep`, `src/state/.gitkeep`, `src/ui/.gitkeep`
- `src/core/example.test.ts` (smoke test proving Vitest works)
- `.gitignore` (`node_modules/`, `dist/`)

### Dependencies
- **External**: `@babylonjs/core`, `vite`, `typescript`, `vitest` (dev)
- **Internal**: none
- **Blocking**: none

## Technical Approach

### Architecture Decisions
- Folder = layer: `src/core` (pure game logic, TDD), `src/state` (IndexedDB
  save), `src/render` (Babylon), `src/ui` (DOM overlay). Keep `core` free of DOM
  and Babylon imports so it stays unit-testable.
- Vitest config lives inside `vite.config.ts` via the `test` field.

### Implementation Steps
1. `bun init`; add deps; author `package.json` scripts.
2. `tsconfig.json` with `strict: true`, `moduleResolution: bundler`.
3. `index.html` + `src/main.ts` mounting a Babylon scene from `src/render/scene.ts`.
4. Smoke test in `src/core/example.test.ts`.
5. Verify dev, build, test, typecheck.

### Risks & Considerations
- **Babylon bundle size** — only import from `@babylonjs/core` submodules used.
- **Bun + Vite interop** — use Vite as bundler, Bun as PM/runner.

## Before / After Examples

### Example 1: package scripts

**Before**: no `package.json`.

**After** (`package.json`):
```json
{
  "name": "bra",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "test": "vitest run",
    "typecheck": "tsc --noEmit"
  }
}
```

### Example 2: portrait viewport

**After** (`index.html`):
```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover, maximum-scale=1" />
<div id="app"><canvas id="scene"></canvas></div>
```

## Progress Log
- 2026-06-13 — Task created (iteration 1)

## Resolution

Implemented 2026-06-13. Greenfield scaffold created from scratch:

- `package.json` with dev/build/test/typecheck scripts; `bun install` resolved 77 packages in 15 s.
- `tsconfig.json`: `strict: true`, `moduleResolution: "bundler"`, `module: "ESNext"`, `target: "ESNext"`.
- `vite.config.ts` with `test` field (Vitest config inlined, node env, no jsdom needed for core tests).
- `index.html`: portrait/mobile viewport meta (`viewport-fit=cover, maximum-scale=1`), `<canvas id="scene">` inside `<div id="app">`.
- `src/render/scene.ts`: placeholder Babylon scene — sphere (warm tan, Labrador-ish) on a ground plane, `ArcRotateCamera`, `HemisphericLight`; imports from specific `@babylonjs/core` submodules only.
- `src/main.ts`: mounts the scene onto `#scene` canvas; no DOM/Babylon in core layer.
- `src/core/example.test.ts`: 3 pure-logic smoke tests (clamp, progress calc); zero Babylon/DOM imports.
- `.gitkeep` in `src/core`, `src/state`, `src/ui`; `src/render` has `scene.ts`.
- `.gitignore`: `node_modules/`, `dist/`.

Verified commands all pass:
- `bun install` — 77 packages, clean.
- `bun run typecheck` — 0 errors.
- `bun run test` — 3/3 tests passed.
- `bun run build` — `dist/` emitted (402 modules, 12.7 s). Chunk-size warning for Babylon main bundle is expected and non-blocking.

## Acceptance Criteria

- [x] `package.json` exists with `dev`, `build`, `test`, `typecheck` scripts; `bun install` succeeds
- [x] `tsconfig.json` with `strict: true`
- [x] `index.html` has mobile/portrait viewport meta and a `#scene` canvas
- [x] `bun run dev` renders a placeholder Babylon scene (e.g. a sphere) without console errors
- [x] `bun run test` runs Vitest and the smoke test passes
- [x] `bun run build` produces `dist/`
- [x] Folder structure: `src/core`, `src/state`, `src/render`, `src/ui`
- [x] `src/core` has no Babylon/DOM imports (stays unit-testable)
- [x] No git commands used

---
**Next Steps**: Ready for implementation.
