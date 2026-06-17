# CLEANUP: Consolidate screenshot scripts into one parametric helper

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Low
**Labels**: cleanup, tooling
**Estimated Effort**: Simple

## Context & Motivation

`scripts/` has accumulated ~11 one-off `shoot-*.mjs` screenshot scripts (shoot-hud,
shoot-tell, shoot-kennel, shoot-select-training, shoot-onboard, shoot-hard,
shoot-adopt-ish, shoot-combo, force-combo, shoot-layout, etc.). Replace them with
ONE parametric helper to cut clutter.

## Affected Components
- Create: `scripts/shoot.mjs` (parametric)
- Delete: the redundant `scripts/shoot-*.mjs` / `scripts/force-*.mjs` one-offs (keep only the consolidated one)
- Dependencies: `playwright-core` (already a devdep); Blocking: none

## Approach
`scripts/shoot.mjs` should support, via CLI flags or a small arg parser:
- `--url` (default http://localhost:5173), `--out <path>`, `--vp 390x844`
- `--click "<text>"` (click a button containing text, e.g. a trick name) — repeatable
- `--wait <ms>`
- `--force "<selector>{<css>}"` (inject an !important style to reveal a transient element)
- `--poll "<js-returning-bool>"` (waitForFunction before shooting)
- It MUST `delete process.env.LD_LIBRARY_PATH` (the Nix-glibc workaround) and use `executablePath: process.env.PW_CHROME`.
- Print any `--report "<selector>"` element's text/opacity for verification.

Then update any references (e.g. the loop docs mention `scripts/shoot-hud.mjs`) — keep
a `shoot-hud.mjs` shim OR update the RALPH-LOOP note to the new invocation. Verify the
consolidated script actually produces a PNG against the running dev server.

## Progress Log
- 2026-06-14 — Task created (iteration 11)

## Resolution
Implemented 2026-06-14.

### `scripts/shoot.mjs` flags supported
- `--url <u>` (default http://localhost:5173)
- `--out <path>` (default /tmp/bra-shot.png)
- `--vp <WxH>` (default 390x844)
- `--click "<text>"` — click first button containing text; repeatable; interleaved in order
- `--wait <ms>` — sleep; repeatable; interleaved in order
- `--force "<selector>{<cssDecls>}"` — inject !important style; repeatable; interleaved in order
- `--poll "<jsExpr>"` — waitForFunction before screenshot
- `--report "<selector>"` — logs textContent + computed opacity after screenshot; repeatable

### Scripts removed
force-combo.mjs, shoot-distractor.mjs, shoot-graduate.mjs, shoot-hard.mjs,
shoot-kennel.mjs, shoot-layout.mjs, shoot-onboard.mjs, shoot-select-training.mjs,
shoot-tell.mjs, shoot-untrain.mjs

`scripts/shoot-hud.mjs` kept as a thin backward-compatible shim (inline, same logic as before).

### Verification
- `node scripts/shoot.mjs --click Sitt --wait 400 --out /tmp/bra-consolidated-test.png --report "#hud-trick-label"`
  → PNG image data, 390 x 844, 8-bit/color RGB, non-interlaced ✓
  → report: `{"selector":"#hud-trick-label","found":true,"textContent":"Teaching: Sitt","opacity":"1"}` ✓
- `node scripts/shoot-hud.mjs` → /tmp/bra-initial.png + /tmp/bra-active.png both 390x844 PNG ✓
- `bun run test` → 298 passed (22 files) ✓
- `bun run build` → built in 13.44s ✓

## Acceptance Criteria
- [x] `scripts/shoot.mjs` exists, parametric (url/out/vp/click/wait/force/poll/report), clears LD_LIBRARY_PATH
- [x] The one-off `shoot-*.mjs` / `force-*.mjs` scripts are removed (or reduced to the single helper)
- [x] Verified: the consolidated script captures a real PNG of the training HUD against the running dev server
- [x] `bun run test` green; `bun run build` succeeds (app code untouched)
