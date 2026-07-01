# CLAUDE.md

**Bra!** — a mobile-only (phone-portrait) dog-training timing game. Watch the dog,
tap **BRA** the instant it sits, get a payoff that lands on the beat. This is the
**v2** build tree; the spec is the source of truth, code is built up from it.

- **Spec:** [.docs/specs/](.docs/specs/) — user stories, phased. One file per phase
  (`phase1.md` … `phase7.md`), `index.md` for the shared frame (North Star, Cross-cutting,
  Non-Goals + a phase index), and `po-review.md` for the PO play-test log. **Phase 1 is
  the whole bet**: one good-looking dog, one Sitt, one perfect mark. A phase is *declared
  done* only on the PO's visual-review sign-off — but when a phase is **exhausted and blocked
  purely on the owner/human** (built + green + all flags busted-or-owner-gated), the loop may
  build the next phase's stories **provisionally** (dormant, never counts as sign-off,
  preempted by any current-phase work) rather than idle-spin. See the "Work-ahead exception"
  in `.docs/specs/index.md` and the flag-bust / work-ahead rules in `process/mother_prompt.md`.
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
- **Don't fake deliverables — attempt the real thing, or flag it.** General, not just
  the dog: a placeholder is never "done" — a sine beep is not the "Bra!" voice, a
  flat-tan fill is not the coat, no bare primitive geometry (capsule/sphere/cylinder)
  stands in for the dog *even for one frame* (hold hidden until the model loads, then
  fade in). **Genuinely attempt** the real asset/capability first — offline tools are a
  `nix shell nixpkgs#<pkg>` away (that's how the espeak "Bra!" got made). If it's truly
  **owner-gated** (a specific human voice, a license), ship the best honest stand-in
  **and raise a flag** in `.task-board/FLAGS.md` — never silently self-certify a stub.
  (Deferring *later-phase* visual polish is fine and phase-gated; stubbing a feature the
  *current* phase requires is not.) When the real thing needs research first
  (feasibility / how is unknown), **spike it** — a timeboxed `SPIKE-` task — before you
  flag (see `process/mother_prompt.md`).
- **Placeholder check at "done" (the canonical list).** Before any task is done, grep its
  diff (added lines in `scripts/` + `assets/`) for
  `placeholder|stub|dummy|fake|mock|TODO|FIXME|temporary|stand-in|hack|XXX|for now|… later`.
  A hit means **not done** unless allowlisted: test doubles in `tests/`, docs/specs/board
  meta-text, or a stand-in an **open flag/task names** (e.g. `bra_tts_placeholder.wav` ←
  the human-voice flag). Soft orchestrator judgement, **not** a `verify.sh` leg.
- **Dog scripts are dog-agnostic and clip-name-driven.** The deployed CC0 dog only
  idles (no Sitt clip); the real Sitt lives in the licensed Labrador, gated behind
  ADR-0006 encryption. Drive sit logic off clip names — never hardcode a fake sit.
- **The licensed glb has 113 clips — the app *wires* only Sitt.** `DogClips.resolve()` only
  resolves idle/sit/reaction names, so the running game shows one trick — but the asset already
  holds **Ligg** (`Lie_*`), **Legg deg** (`Lie_belly_*`), dig, crouch, jumps, bark, swim, … The
  committed inventory is [`assets/models/dog_licensed.clips.txt`](assets/models/dog_licensed.clips.txt).
  **Never infer the asset's contents from the running game (behavior ≠ inventory)** — grep the
  manifest. "Owner-gated on assets" is a hypothesis to **flag-bust against that manifest**, never a
  verdict from the running build (this is what wrongly skipped the Phase-2 trick roster P2-1/2/3).
- **Local Chromium** (export boot check / e2e) needs `env -u LD_LIBRARY_PATH` or it
  dies with a glibc error. CI is unaffected.
- Skinned-dog `global_transform`/AABB is ~origin until frame 1 — accumulate
  node-local transforms instead. The CC0 glb ships its own `Camera3D`.

## Deploy

Constant push → CI exports Godot Web/PWA → GitHub Pages → reviewed on the live
site. `deploy-licensed.yml` is the **only** deploy now: every push to `main` builds
the **encrypted licensed Labrador** (ADR-0006), proves it decrypts + boots + can Sitt
in a real browser, then publishes to Pages — all gates fail-closed (a failed gate
leaves the live site stale, never broken). Needs the `GODOT_SCRIPT_ENCRYPTION_KEY`
secret + the committed `assets/models/dog_licensed.glb.enc`; without them the job
no-ops and Pages is left unchanged. The old CC0 `deploy.yml` was removed (it republished
on every push and would clobber the licensed site). The CC0 dog asset + the "Web" preset
stay — the local `verify.sh` gate and the editor still use them, since the licensed dog
needs the encryption key/from-source template that only CI has.
