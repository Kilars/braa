# Planning Board — Bra! v2

Source of truth: [`specs2.md`](../specs2.md) (phased user stories) and the ADRs in
[`adr/`](../adr/).

> **Phasing rule (from the spec):** Phase 1 is the whole bet. Nothing past Phase 1
> starts until Phase 1 passes its Visual Review and is bug-free.

## Status — Phase 1 begun: the scoring math, test-first (2026-06-28)

Task **024** (Phase 1 — the perfect single mark) is a large epic; per the spec it's
built **per story, not as a monolith**, so it was decomposed into slices **024a–024g**
(idle, sit+apex, tell, BRA+scoring, payoff, readout) and moved to **in-progress**.

The first slice, **024a**, is **done**: the apex-band / scoring-window math — the pure
heart of "mark the moment" — built test-first. `scripts/sit_window.gd` (`class_name
SitWindow`): a sit is markable over its clip span; a tap is scored by closeness to the
apex → **PERFECT / OK / MISS**, or **DEAD** (no sit active → no penalty, P1-5). 12 new
unit tests cover the bands, inclusivity (with a float-noise epsilon), active bounds,
asymmetric apex, and the `is_successful` audio gate (P1-6). The visual slices
(024b–024g) wire onto this proven core. **Gate-integrity fix** bundled in: the test
runner silently passed test files that failed to *parse* — added a `can_instantiate()`
guard so a broken test now fails the gate (no more hollow green). Verify gate green
end-to-end (import · boot · test → 15 tests · export).

## Status — bun toolchain removed, Godot verify gate live (2026-06-28)

Task **023** ripped out the dead Babylon/TS/Vite/Bun stack (`package.json`, `bun.lock`,
`tsconfig.json`, `vite.config.ts`, `playwright.config.ts`, `src/`, `e2e/`, `index.html`,
`public/`, `node_modules/`, `dist/`) — the repo is now a clean Godot project. The verify
gate moved off the bun four onto **Godot headless** (`nix develop -c bash verify.sh`):
**import → boot `main.tscn` → GDScript unit tests (`tests/test_runner.gd`) → Web/PWA
export + bundle-exists gate**, fail-closed. A self-contained test runner (no addon /
network) is in `tests/` so Phase 1 logic (task 024) can TDD. Verified green end-to-end;
the export `.pck` no longer carries the stray bun config files (the old leak is gone).
Process docs (`mother_prompt`, `father_prompt`, `process/README`, `loop.sh`'s
`app_runnable`) now reference only the Godot gate / deployed-site review. The licensing
decision is **not** lost: ADR-0006 (encrypted PCK, native to Godot's export) supersedes
the deleted client-side TS crypto — see task 023's notes.

## Status — Godot Web/PWA export now deploys (2026-06-28)

Task **022** rewrote `deploy.yml`: a push to `main` now exports the Godot Web/PWA build
(nix-pinned engine **and** templates, 4.6.3 — version match designed out) and publishes
`build/web/` to Pages, **gated on a real export** (fails closed if the bundle is
missing). Verified locally by reproducing the CI commands and **booting the export in a
headless browser under a `/braa/` mount** — `window.__appReady` fires, zero errors, the
dog renders centered on the bright backdrop, PWA manifest is standalone/portrait. The
live site should now serve the Godot scaffold instead of the bun placeholder (father/PO
confirms on the live URL). `export_presets.cfg` added at repo root.

The bun toolchain is **still on disk** (and its gate still green) — its removal is the
next card (023), deliberately ordered AFTER the Godot deploy proved out.

## Status — Godot pivot, scaffold landed (2026-06-28)

The stack is **Godot 4 + GDScript + PWA** (ADR-0001/0003/0004/0005). Babylon/bun was
the wrong path. The pivot was **half-finished** as of "initial commit v2": the docs
(ADRs, README, flake.nix) declared Godot, but the code, CI, and verify-gate were still
Babylon/bun and **no `project.godot` existed**.

**This iteration (task 021) scaffolded the Godot project** — verified by booting it
headless (`nix develop -c godot --headless`): the dog loads from
`res://assets/models/dog.glb`, the readiness hook fires, exit 0. Layout (ADR-0005, at
repo root): `project.godot`, `scenes/main.tscn`, `scripts/main.gd` (typed), the kept CC0
`assets/models/dog.glb`. `.gdignore` markers keep Godot's importer out of the
transitional bun dirs.

**Was transitional, now resolved:** the bun toolchain and the bun→vite→Pages `deploy.yml`
were left in place through 021/022 so the live site never went dark mid-pivot, then
removed in **023** once the Godot export was deploying. The pre-pivot state is recoverable
on branch **`backup/pre-rip-out-2026-06-28`**; old cards under [`archive/`](./archive/).

## Current phase

**Phase 1 — the perfect single mark** (specs2.md §Phase 1). Build it in Godot on top of
the scaffold; the loaded dog drives the pose system — the committed glb is the dog, no
bare primitive geometry as the shipped product. See task 024.

## In progress

- **024** — Phase 1 epic (idle → sit+apex → BRA → payoff). Decomposed into 024a–024g;
  build one slice per iteration. Stays open until the **P1-10 done-gate** passes.

## Backlog (Phase 1 slices, in build order)

- **024b** — a legible sit with a clear apex (P1-3) [visual]
- **024c** — alive at rest: ambient idle loop (P1-2) [visual]
- **024d** — the apex tell (P1-4) [visual] — fires on the *same* apex 024a/024b use
- **024e** — BRA button + wire scoring to taps (P1-5) [interaction; uses 024a's `SitWindow`]
- **024f** — the mark feels good: voice + SFX + dog reaction (P1-6) [audio/visual]
- **024g** — honest timing readout + reduced motion (P1-7, P1-8) [visual]

## Done (recent)

- **024a** — apex-band / scoring-window math (`SitWindow`), test-first (12 tests);
  plus a test-runner hardening so un-parseable test files fail the gate.
- **023** — Removed the bun/Babylon toolchain; verify gate switched to Godot headless
  (`verify.sh`: import · boot · test · export). Self-contained GDScript test runner added;
  process docs de-bunned; export `.pck` no longer leaks bun config files.
- **022** — CI exports the Godot Web/PWA build to Pages (export-gated, nix-pinned);
  verified by a real-browser boot of the export that renders the dog.
- **021** — Godot 4 project scaffold; boots headless with the dog loaded.
