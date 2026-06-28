# FEATURE: CI — export the Godot Web/PWA build to GitHub Pages

**Status**: Done
**Created**: 2026-06-28
**Completed**: 2026-06-28
**Priority**: High (P0 after scaffold — the live deploy still ships the bun placeholder)
**Labels**: ci, godot, deploy, pwa
**Estimated Effort**: Medium

## Context & Motivation

Task 021 scaffolded the Godot project, but `deploy.yml` still does
`bun install → bun run build → upload dist/` — i.e. the **live** Pages site
(https://kilars.github.io/braa/) still serves the bun placeholder, not the Godot
build. ADR-0004/0005: ship the Godot **Web export with the PWA option** to Pages,
single-threaded (no COOP/COEP needed), base path `/braa/`. This is the outward-facing
half of the pivot, deliberately deferred from 021 so the live site wasn't risked
unattended.

## Desired Outcome

A push to `main` exports the Godot Web/PWA build and publishes it to Pages; the live
site shows the dog scaffold (then later Phase 1). Deploy is **gated on a successful
export** (no green-but-empty deploys).

## Technical Approach

- Add `export_presets.cfg` — a **Web** preset, PWA enabled, single-threaded
  (`variant/thread_support=false`), runnable, `export_path` under the publish dir.
  Author it via the editor or by hand, then verify the exported `index.html` actually
  loads (this is why it was NOT hand-authored blind in 021 — needs export templates).
- Rewrite `deploy.yml`: install Godot + the **Web export templates** in CI
  (nix `godot_4-export-templates-bin`, or download matching 4.6.3 templates), run
  `godot --headless --export-release "Web" <out>/index.html`, upload that dir to Pages.
- Confirm the base path works under `/braa/` (relative paths / Godot's web base).
- Keep the deploy job dependent on the export step succeeding.

### Risks
- Export-template version must match the engine (4.6.3). Mismatch → export fails.
- WASM payload size / Pages limits — fine for a single-dog game, but watch the budget.

## Definition of Done

- CI exports the Godot Web/PWA build and publishes it; live site loads the dog
  (father/PO reviews the LIVE site per process).
- Old bun build no longer the published artifact (its full removal is task 023).

## What was built

- **`export_presets.cfg`** — one `Web` preset, `runnable=true`,
  `variant/thread_support=false` (single-threaded → no COOP/COEP, Pages-safe),
  `progressive_web_app/enabled=true`. Fixed two int-enum options that are easy to
  get wrong (they are NOT strings): `progressive_web_app/display=1` (standalone) and
  `progressive_web_app/orientation=2` (portrait) — a first pass left them as strings
  and the manifest came out `fullscreen`/`landscape`. PWA bg `#87cfeb` matches the
  in-engine backdrop.
- **`.github/workflows/deploy.yml`** — rewritten from bun→vite→`dist/` to:
  `cachix/install-nix-action` → `nix build nixpkgs#godot_4-export-templates-bin` and
  symlink it into `~/.local/share/godot/export_templates/<ver>/` →
  `nix develop -c godot --headless --import` →
  `nix develop -c godot --headless --export-release "Web" build/web/index.html` →
  **gate** (`test -s` each of index.html/js/wasm/pck/manifest/service-worker, else
  `exit 1`) → upload `build/web`. Using nix for BOTH engine and templates pins them to
  the same 4.6.3 nixpkgs build, designing out the #1 risk (version mismatch).
- **`.gitignore`** += `build/` (export output, regenerable).

## Verification (real, not asserted)

Reproduced the exact CI commands locally with the matching nix templates installed:
- `godot --headless --import` → exit 0.
- `godot --headless --export-release "Web" build/web/index.html` → exit 0; produced a
  full bundle: `index.{html,js,wasm,pck}` (wasm 37.7 MB), PWA
  `index.manifest.json` + `index.service.worker.js` + `index.offline.html` + icons.
- Manifest correct: `name:"Bra!"`, `display:"standalone"`, `orientation:"portrait"`,
  `background_color:"#87cfeb"`, `start_url:"./index.html"`. HTML asset refs are all
  **relative** → works under the `/braa/` project sub-path with no base rewriting.
- **Real headless-Chromium boot** under a `/braa/`-mounted static server (no
  COOP/COEP headers, like Pages): waited for the scaffold's `window.__appReady` hook →
  `ready:true`, **zero** console/page/request errors, and the **dog renders centered**
  on the bright backdrop in portrait (screenshot `.screenshots/export-boot.png`). This
  proves the wasm actually boots and the scene/dog load — not just that export exit 0.
- Bun gate (still in place until 023) re-checked green: typecheck 0 errors · test 27
  passed · build clean · e2e 1 passed.

## Notes / follow-ups

- The exported `.pck` currently also bundles stray bun files (`package.json`,
  `tsconfig.json`) because `export_filter="all_resources"`. Harmless (pck is ~89 KB)
  and they disappear when **task 023** removes the bun toolchain — not worth a
  now-then-dead `exclude_filter`.
- CI re-downloads the ~1.2 GB templates closure from `cache.nixos.org` each push
  (slow is fine per process). Caching the nix store is a later optimisation.
- Final outward proof is the **father/PO live-site review** (the build can't be fully
  pixel-verified for the *deployed* URL from here — only the byte-identical local
  export was browser-booted).

## Progress Log

- 2026-06-28 — Confirmed nix `godot_4-export-templates-bin` is 4.6.3-stable (matches
  the 4.6.3 engine). Authored the Web/PWA preset; caught + fixed the display/orientation
  enum bug via the emitted manifest. Rewrote `deploy.yml` to a nix-based, export-gated
  Pages deploy. Verified end-to-end locally incl. a real-browser boot that renders the
  dog. Bun gate still green. Moved 022 → done.
