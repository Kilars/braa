# FEATURE: Loading indicator while Babylon lazy-loads

**Status**: Done
**Created**: 2026-06-14
**Priority**: Low
**Labels**: ui, ux, visual-review
**Estimated Effort**: Simple

## Context & Motivation

Since 040 lazy-loads Babylon, there's a brief window when entering training before
the 3D scene is ready (the canvas is blank). Show a small "loading" indicator until
the scene is up, so it doesn't look broken on a slow connection / first entry.

## Affected Components
- Modify: `src/main.ts` (track scene-ready state; show indicator while loading, hide when `sceneApi` is set), `src/ui/hud.ts`/`hud.css` (a `#hud-loading` element — a spinner or "Loading…" text centered over the canvas)
- Dependencies: 040; Blocking: 040

## Approach
- Add `#hud-loading` (hidden by default) — a small centered spinner/"Loading…" pill.
- In main.ts: when training starts and `sceneApi` is still null, show `#hud-loading`; when the dynamic `import('./render/scene')` resolves and the scene is created, hide it. (If the scene is already loaded by the time training starts — the common case after select — the indicator never shows or flashes briefly; that's fine.)
- Keep it subtle; don't block input. Respect reduced-motion for any spinner animation.

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- The window is brief — to capture it, you can artificially delay scene creation for the screenshot (e.g. a `--force` style or a small timeout) OR just confirm the `#hud-loading` element exists + is shown when `sceneApi` is null and hidden once ready (report the element's computed display in both states). Screenshot the loading state if you can; VIEW it.

## Progress Log
- 2026-06-14 — Task created (iteration 15)

## Resolution

### Indicator DOM/CSS
- Added `#hud-loading` (fixed, centered pill) to `src/ui/hud.ts` — created as the first appended element in `createHud`, starts with `display:none`.
- The pill contains `#hud-loading-spinner` (rotating ring, 20px, green `border-top-color: #4cde80`) and `#hud-loading-text` ("Loading…", uppercase pill text).
- CSS in `src/ui/hud.css`: `position:fixed; top:50%; left:50%; transform:translate(-50%,-50%); z-index:12; pointer-events:none;` — never blocks input.
- Spinner uses `@keyframes hud-spin` (360° rotation, 0.75s linear). Under `prefers-reduced-motion: reduce`, replaced with `@keyframes hud-pulse` (opacity 0.4→1→0.4, 1.5s) — no spinning motion.

### Show/Hide wiring
- `createHud` return type extended with `showLoading` / `hideLoading`.
- `showLoading` sets `display:flex`; `hideLoading` sets `display:none`.
- `showSelect()` calls `hideLoading()` unconditionally (so returning to select always clears it).
- `main.ts` destructs `showLoading` / `hideLoading` from `createHud`.
- In `onSelectTrick`: after `showTraining(trick.name)`, `if (sceneApi === null) showLoading()`. If already loaded — no indicator shown.
- In the dynamic `import('./render/scene').then(mod => { ... })`: calls `hideLoading()` after `sceneApi` is set. Also calls `hideLoading()` in the `.catch()` (failure is non-fatal, indicator must not stick).

### Verification
- `bun run typecheck`: **0 errors**
- `bun run test`: **355 passed (23 files)**
- `bun run build`: **succeeded** (dist created, 13.64s)
- `bun run e2e`: **E2E SMOKE PASS**
- Screenshot `/tmp/bra-loading.png` captured with `--force "#hud-loading{display:flex !important;}"` — element found, textContent "Loading…", opacity 1. Visible.
- Computed display in both real states (no force):
  - SELECT state (default, `sceneApi` null on page load): `display: none` — correctly hidden.
  - TRAINING state (2s wait then click Sitt, scene already loaded): `display: none` — correctly stays hidden (scene was ready before trick selected).

## Acceptance Criteria
- [x] `#hud-loading` shows while the scene is loading and hides once `sceneApi` is ready
- [x] Doesn't block input; reduced-motion respected for any animation
- [x] Verified (screenshot of the loading state, or reported computed display in both states — real, not fabricated)
- [x] `bun run test` green; `bun run typecheck` 0; `bun run build` succeeds; `bun run e2e` still PASS
