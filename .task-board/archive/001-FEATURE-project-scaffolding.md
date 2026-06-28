# FEATURE: Project scaffolding — runnable bun skeleton with the verify gate

**Status**: Done
**Created**: 2026-06-27
**Completed**: 2026-06-27
**Priority**: High (P0 — overrides all other findings until the app runs)
**Labels**: scaffolding, infra, build
**Estimated Effort**: Medium

## Context & Motivation

There is no runnable app yet (no `package.json`). Per `scan-project` and the mother
prompt, the P0 until the app runs is **project scaffolding**: a runnable bun skeleton
that makes the four verify-gate commands exist and pass green, so every later
iteration can build, gate, and (eventually) be play-tested by the father/PO pass.

## Current State

Docs-and-tooling only: `specs2.md` (→ `.docs/specs.md`), `tech-decisions.md`, `adr/`,
`.task-board/`, `.claude/skills/`, `process/` loop. No source tree, no package manifest.

## Desired Outcome

`bun install` works, a dev server runs, and the verify gate is green:

- `bun run typecheck` → 0 errors
- `bun run test` → passes
- `bun run build` → succeeds, no warnings
- `bun run e2e` → passes
- `bun run dev` → serves the app (unblocks the deferred father/PO play-test pass)

## Technical Approach (per ADR / tech-decisions §1 — the v2 stack)

Stack = **TypeScript + Vite + Bun**, DOM/CSS UI overlay over a `<canvas>`, client-only.
(Babylon.js 3D rendering is deferred to the dog-scene task to keep this scaffold lean
and the build warning-free; the canvas + render-loop seam is in place for it.)

### Files to Create
- `package.json` — scripts: `dev`, `build`, `typecheck`, `test`, `e2e`, `preview`
- `tsconfig.json` — strict, DOM libs, bundler resolution
- `vite.config.ts` — vite + vitest config (base `./`)
- `playwright.config.ts` — chromium via system Chrome channel, 390×844 portrait
- `index.html` — portrait phone shell, mounts `#app`
- `src/main.ts` — entry: mounts shell + canvas, starts a (stub) render loop
- `src/app/shell.ts` — DOM overlay: title + BRA button (pure, testable structure)
- `src/core/math.ts` — `clamp01` (a real helper the timing core will use)
- `src/core/math.test.ts` — vitest unit test (proves the test harness)
- `e2e/smoke.spec.ts` — boots the page, asserts the BRA button + canvas render

### Risks & Considerations
- **Risk**: `bun run build` emitting a chunk-size warning fails the "no warnings" gate.
  **Mitigation**: keep the scaffold dependency-light (no Babylon yet); set a generous
  `chunkSizeWarningLimit` when Babylon lands.
- **Risk**: Playwright browser-version mismatch with the cached browsers.
  **Mitigation**: use `channel: 'chrome'` → system `google-chrome-stable`, no download.

## Progress Log

- 2026-06-27 — Task created and taken in-progress this iteration (scaffolding is the P0).
- 2026-06-27 — Built the bun/Vite/TS skeleton; full verify gate green (see Resolution).

## Resolution

Scaffolded the v2 bun skeleton (stack per tech-decisions §1: TypeScript + Vite + Bun,
DOM/CSS overlay over a `<canvas>`). Files created:

- `package.json` (scripts: dev/build/typecheck/test/test:watch/e2e/preview),
  `tsconfig.json` (strict), `vite.config.ts` (vite + vitest, base `./`),
  `playwright.config.ts` (390×844 portrait, system Chrome channel).
- `index.html`, `src/main.ts` (mounts shell + canvas, stub render loop, sets
  `window.__appReady`), `src/app/shell.ts` (title + BRA button + canvas seam),
  `src/style.css` (portrait, bright sky, thumb-friendly BRA), `src/core/math.ts`
  + `src/core/math.test.ts` (4 passing unit tests), `e2e/smoke.spec.ts`.

**Verify gate (all green):** `typecheck` 0 errors · `test` 4 passed · `build`
succeeded, no warnings · `e2e` 1 passed · `dev` serves the shell.

**One real blocker hit and solved (not blocked):** the sandbox's
`LD_LIBRARY_PATH` points at a nix `alsa-lib` that drags in a mismatched nix glibc,
so Chrome failed to launch (`GLIBC_ABI_DT_X86_64_PLT not found`). Fix: `playwright.config.ts`
hands the browser a copy of the env with `LD_LIBRARY_PATH` stripped (node/vite keep
theirs). This makes `bun run e2e` durable for every future iteration in this env.

**Deferred deliberately:** Babylon.js 3D is left to task 003 (dog scene) to keep the
scaffold build warning-free and lean; the canvas + render-loop seam is in place.

## Acceptance Criteria

- [x] `bun install` succeeds
- [x] `bun run typecheck` → 0 errors
- [x] `bun run test` → green (4 passed)
- [x] `bun run build` → succeeds with no warnings
- [x] `bun run e2e` → green (1 passed)
- [x] `bun run dev` serves the app (the BRA shell renders in portrait)
