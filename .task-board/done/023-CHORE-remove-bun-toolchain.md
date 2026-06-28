# CHORE: Remove the bun/Babylon toolchain and switch the verify gate to Godot

**Status**: Done (2026-06-28)
**Created**: 2026-06-28
**Priority**: Medium (do AFTER 022 ships the Godot export — not before)
**Labels**: cleanup, godot, gate, infra
**Estimated Effort**: Medium

## Context & Motivation

ADR-0005 wants a clean Godot tree with **no dead Babylon/TS/Vite/Bun files**. Tasks
021/022 leave the bun toolchain in place transitionally so the live deploy never goes
dark during the pivot. Once 022 publishes the Godot export, the bun stack is dead
weight and the **verify gate must move to Godot** (the mother-prompt's `bun run …`
gate is stale).

**Ordering guard:** do NOT start this until 022's Godot deploy is live and green —
removing bun first would break the live site.

## Desired Outcome

- Remove: `package.json`, `bun.lock`, `tsconfig.json`, `vite.config.ts`,
  `playwright.config.ts`, `src/`, `e2e/`, `index.html`, `public/`, `node_modules/`
  (and the now-needless `.gdignore` markers in `node_modules`/`dist`).
- New verify gate (replaces the bun four; update `process/mother_prompt.md`):
  - `godot --headless --import` → exit 0, no import errors
  - `godot --headless --check` (or a `--quit-after` boot of `main.tscn`) → 0 script/scene errors
  - `godot --headless --export-release "Web" <out>` → exit 0 (the build gate)
  - a headless gdUnit/GUT test run (set up the test runner) → green
- Update `process/father_prompt.md` + `PLANNING-BOARD.md` to drop bun references.

## Notes

- The 3D loader logic in `src/render/*.ts` (assetCrypto/dogPackKey/dogModelLoader)
  encodes the **ADR-0006 encrypted-licensed-asset** strategy. Before deleting, confirm
  the equivalent is handled by the Godot export path (encrypted `.pck`) so the
  licensing decision isn't lost — port the intent, not the TS.
- Full pre-pivot state remains recoverable on `backup/pre-rip-out-2026-06-28` and in git.

## Definition of Done

Repo is a clean Godot project; the Godot verify gate is green; no bun/Babylon files
remain; process docs reference only the Godot gate.

## Resolution (2026-06-28) — DONE

**Removed** (from disk; git left for the owner to commit): `package.json`, `bun.lock`,
`tsconfig.json`, `vite.config.ts`, `playwright.config.ts`, `index.html`, `src/`, `e2e/`,
`public/` (empty), plus the gitignored `node_modules/`, `dist/`, `test-results/`. The
`.gdignore` markers under those dirs went with them; `.gitignore` was trimmed to drop the
bun/vite lines (`node_modules/`, `dist/`, `*.local`, `public/models/*`) while **keeping**
the ADR-0006 licensed-asset ignores (`models-build/`, `*.fbx`). `models-build/` (local
licensed Labrador staging) and the tracked CC0 `assets/models/dog.glb` were left intact.

**New verify gate** — `verify.sh` (run `nix develop -c bash verify.sh`), replacing the
bun four. Four fail-closed legs: `--import` → boot `main.tscn` headless (gated on no
script/scene/load error + the readiness print) → `tests/test_runner.gd` (exit 1 on any
failed assertion) → `--export-release "Web"` + bundle-exists gate (mirrors deploy.yml).
**Verified green end-to-end** (exit 0); the export `.pck` no longer carries the stray bun
config files (grepped clean — resolves the obs-2176 leak).

**Test runner** — self-contained, no GUT/gdUnit addon (the nix CI sandbox can't fetch
one): `tests/test_runner.gd` (a `SceneTree` script that discovers `tests/test_*.gd`, runs
each `test_*` on a fresh instance, exits 1 on failure), `tests/test_case.gd` (assert
helpers that collect failures), `tests/test_smoke.gd` (3 real tests: dog glb imports to a
PackedScene, main scene loads, framework self-check). Phase-1 scoring/apex math (task 024)
TDDs on top of this.

**Docs de-bunned:** `process/mother_prompt.md` (gate → Godot), `process/father_prompt.md`
(review the deployed Web/PWA build in a headless browser, not `bun run dev`),
`process/README.md`, and `loop.sh`'s `app_runnable()` (now `[[ -f project.godot ]]` so the
PO review isn't permanently deferred). ADR Babylon mentions are historical pivot records —
left as-is.

**ADR-0006 licensing intent preserved (the task's key NOTE):** the deleted
`src/render/*.ts` (assetCrypto / dogPackKey / dogModelLoader / dogModelSource) was the
**Babylon-era client-side scheme** — AES-GCM a separate `.pack`, decrypt in Web Crypto,
hand to Babylon. **ADR-0006 supersedes it**: encrypt the Godot **PCK** natively (custom
export templates + `SCRIPT_AES256_ENCRYPTION_KEY`, decrypted in-engine), licensed `.glb`
gitignored + injected from a CI secret. So there is **nothing to port to GDScript** — the
mechanism is native Godot export config (`export_presets.cfg` already carries
`encrypt_pck` / `encryption_*_filters`, currently off for the CC0 default profile) and the
decision lives in ADR-0006. The follow-up (stand up the two build profiles in CI) remains
open and is unaffected by this cleanup.
