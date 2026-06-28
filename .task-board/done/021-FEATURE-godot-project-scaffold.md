# FEATURE: Godot 4 project scaffold — boots headless with the dog loaded

**Status**: Done
**Created**: 2026-06-28
**Completed**: 2026-06-28
**Priority**: High (P0 — the mandated stack had no runnable project)
**Labels**: scaffolding, godot, infra
**Estimated Effort**: Medium

## Context & Motivation

The repo was in a **half-finished pivot**. The decision layer is unambiguous —
ADR-0001 (Accepted) mandates **Godot 4**, "supersedes the prior Babylon.js
direction"; ADR-0003 GDScript; ADR-0004 PWA web export; ADR-0005 the repo layout.
But the implementation layer was still 100% Babylon/bun: `package.json`, `src/*.ts`,
`vite`, and `deploy.yml` (bun→vite→Pages) untouched, and **no `project.godot`
existed at all**. PLANNING-BOARD and the mother-prompt gate were also stale (Babylon
/ bun). Per the mother-prompt conflict rule ("build to the spec as written"), the P0
is to scaffold the project in the mandated Godot stack.

Godot 4.6.3 was confirmed runnable here via `nix develop -c godot` (flake devshell).

## Desired Outcome

A minimal but real Godot project that **boots and loads the committed dog**, verified
headless — without touching the live bun→Pages deploy (kept green this iteration).

## Technical Approach (ADR-0005 layout, at repo root)

- `project.godot` — name "Bra!", `main_scene = res://scenes/main.tscn`,
  portrait 720×1280, `gl_compatibility` renderer (WebGL2, single-threaded — the
  Pages-compatible choice per ADR-0001/0005).
- `scenes/main.tscn` — `Node3D` root with `scripts/main.gd` attached (minimal scene;
  camera/light/env/dog built in code for headless robustness — no fragile uid refs).
- `scripts/main.gd` — typed GDScript (ADR-0003): bright environment, sun, framed
  camera, **loads `res://assets/models/dog.glb`** (the kept CC0 dog — no primitive
  placeholder, P1-1/ADR-0002), and a `window.__appReady` web hook via
  `JavaScriptBridge` (no-op off web; mirrors the old shell's readiness signal).
- `.gdignore` in the noisy gitignored dirs (`node_modules`, `dist`, `models-build`,
  `test-results`, `.screenshots`) so Godot's importer only sees the real asset tree —
  transitional, removed when the bun toolchain goes (task 023).
- `.gitignore` += `.godot/` (import cache).

### Deliberately deferred (outward-facing / destructive — not done unattended)
- **CI rewrite** deploy.yml → Godot Web/PWA export + `export_presets.cfg` → task 022.
- **bun toolchain removal** + verify-gate switch to Godot headless → task 023.
- **Phase 1 gameplay** (idle / sit+apex / BRA tap / score / payoff) → task 024.

These were left out because they change the **live** GitHub Pages deploy and rip out
a working toolchain; sequencing them after the scaffold keeps the live site green and
the change reviewable. (A scoping question to the owner was attempted and declined, so
the conservative additive path was taken.)

## Verification (real, not asserted)

- `nix develop -c godot --headless --import` → exit 0; **only `dog.glb` imported**
  (gdignore guards held), atlas + `.import` files generated.
- `nix develop -c godot --headless --quit-after 5` → exit 0, logs
  `[Bra!] dog loaded: res://assets/models/dog.glb` then `[Bra!] scaffold ready`,
  **no errors/warnings**.
- Existing bun gate (untouched, still ships the placeholder, still green):
  `typecheck` 0 errors · `test` 27 passed · `build` clean · `e2e` 1 passed.

## Progress Log

- 2026-06-28 — Diagnosed the half-finished pivot; confirmed Godot runs via nix.
- 2026-06-28 — Scaffolded the Godot project; verified headless boot + dog load;
  confirmed bun gate still green. Follow-ups (022–024) filed in backlog.
