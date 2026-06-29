# CLAUDE.md

**Bra!** — a mobile-only (phone-portrait) dog-training timing game. Watch the dog,
tap **BRA** the instant it sits, get a payoff that lands on the beat. This is the
**v2** build tree; the spec is the source of truth, code is built up from it.

- **Spec:** [specs2.md](specs2.md) — user stories, phased. **Phase 1 is the whole bet**:
  one good-looking dog, one Sitt, one perfect mark. Nothing past Phase 1 starts
  until Phase 1 passes visual review and is bug-free.
- **Decisions:** [adr/](adr/) (0001–0006) — ADRs are the source of truth for tech
  choices. There is no `tech-decisions.md`.

## Stack

Godot 4 (4.6.x) + GDScript + Web/PWA export. GL Compatibility renderer (WebGL2,
no COOP/COEP). Toolchain comes from the Nix flake — **always run godot through the
devshell:**

```sh
nix develop -c godot          # editor
nix develop -c bash verify.sh # the verify gate (run before declaring work done)
```

## Verify gate (`verify.sh`)

Four fail-closed legs, in order: **import → boot → test → export**. Green output
ends with `✓ verify gate green`. Treat a failing leg as a hard stop.

- Tests live in `tests/test_*.gd`, discovered by `tests/test_runner.gd`.
- New code is TDD: write the failing test first, then make it pass.

## Layout

- `scripts/` — gameplay logic (`main.gd`, `sit_*`, `dog_*`, `apex_tell*`, `*payoff*`, …).
- `scenes/main.tscn` — the one scene. `assets/`, `models-build/` — dog model pipeline.
- `.task-board/` — work tracking: `backlog/ → in-progress/ → done/` (+ `archive/`).
  The autonomous loop reads the board, does one task, moves it, commits, pushes.
- `process/` — mother/father prompts + runner for the autonomous build loop.

## Gotchas (these have bitten before)

- **Headless test harness hides runtime `SCRIPT ERROR`s as hollow green.** Don't
  trust a green test count alone — `verify.sh` greps the boot log for red; do the
  same when in doubt. In that harness `_init` `add_child` and audio/anim `.play()`
  don't work — attach lazily, guard `.play()` on `is_inside_tree()`.
- **Don't fake assets.** No bare primitive geometry (capsule/sphere/cylinder) for
  the dog, *not even for one frame on load*. Hold hidden until the model is ready,
  then fade in. The loop has dodged un-generatable assets before; build real or
  surface that you can't.
- **Dog scripts are dog-agnostic and clip-name-driven.** The deployed CC0 dog only
  idles (no Sitt clip); the real Sitt lives in the licensed Labrador, gated behind
  ADR-0006 encryption. Drive sit logic off clip names — never hardcode a fake sit.
- **Local Chromium** (export boot check / e2e) needs `env -u LD_LIBRARY_PATH` or it
  dies with a glibc error. CI is unaffected.
- Skinned-dog `global_transform`/AABB is ~origin until frame 1 — accumulate
  node-local transforms instead. The CC0 glb ships its own `Camera3D`.

## Deploy

Constant push → CI exports Godot Web/PWA → GitHub Pages → reviewed on the live
site. `deploy.yml` ships the CC0 build (deploy gated on a successful export).
`deploy-licensed.yml` is the owner-gated encrypted-licensed-dog pipeline (ADR-0006).
