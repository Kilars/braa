# FEATURE: 025 — Ship the licensed Labrador as an encrypted .pck (ADR-0006)

**Status**: Backlog — **local wire DONE** (2026-06-28): `main.gd` loads the licensed
Labrador when it's present (`assets/models/dog_licensed.glb`, gitignored), the dog
**sits in dev** (boot logs `dog can Sitt — apex at 1.250s`), and the verify gate is
green at 74 tests. `DogClips` fixed to match Godot's renamed hold loop (`Sitting_1`,
not `Sitting_loop_1`). **REMAINING (this card's real scope) = the encrypted CI deploy**
so the live site shows the sit without leaking the license — still **owner-gated** (needs
the CI secret/key). Until then the deployed dog is still CC0 (idle only).
**Priority**: High — **unblocks the visible Sitt (024b/P1-3) and all of Phase 1's
real gameplay on the live deploy.** Without it the deployed dog (CC0 placeholder)
has no Sitt clip and the live site the father reviews cannot perform the core verb.
**Labels**: pipeline, godot, ci, licensing, blocker
**Estimated Effort**: Large
**Owner gate**: yes — touches a secret-injected licensed asset + CI; confirm the
approach (and that the licensed glb may be injected via CI secret) with the owner.

## Why (discovered building 024b, 2026-06-28)

- The real `Sitting_start / loop / end` (and `Idle_1..7`, `Lie_*`, etc.) clips live
  ONLY in the licensed Labrador `models-build/out_anim.glb` (19 MB, 100+ clips).
- That file is `.gitignore`'d **and** `.gdignore`'d — it must NEVER enter the public
  repo or the public `.pck` (ADR-0002 + ADR-0006). The CC0 `assets/models/dog.glb`
  is a **dev-only fallback with no Sitt** — it is what ships today, so the deployed
  dog can only idle.
- ADR-0006 decision: ship the licensed model as an **encrypted Godot `.pck`/binary,
  built in CI from a secret-injected glb**. That pipeline is **not built yet**.

## Outcome (acceptance)

- CI (deploy.yml) injects the licensed Labrador from a **secret** (not the repo),
  imports it, and builds the Web/PWA export with **encryption enabled** (Godot
  script/pck encryption key from a CI secret) so the raw model is not trivially
  extractable from the published `.pck` (deterrence per ADR-0006, not DRM).
- The export still boots clean (the existing export/boot gates stay green) and the
  app loads the **licensed** dog, whose `AnimationPlayer` exposes the real
  `Sitting_*` clips → `DogDirector.has_sit()` is true → the live deploy shows a real
  Sitt with a clear apex (closes 024b/P1-3).
- The **local verify gate keeps using the CC0 dog** (no secret locally); the
  director already degrades gracefully, so local stays green without the licensed
  asset.

## Approach / notes

- Godot supports PCK/script encryption via an export build with `script_encryption_key`
  (or `--encryption-key`); the engine/templates must match. The flake already pins
  Godot + export templates (4.6.3) — verify the templates support the encryption key.
- The director/clip layer is already dog-agnostic (`dog_clips.gd`, `dog_director.gd`,
  apex via `SitWindow.from_sit_clips`), so no gameplay code should need changes —
  this is purely the **asset + CI + encryption** plumbing.
- Keep the licensed glb out of the repo: inject at CI time only; never commit; never
  land it in a tracked path.

## Depends on / blocks

- Unblocks **024b** (visible Sitt on deploy) and, by extension, the visible parts of
  024c–024g and the **P1-10 done-gate** (father visual review of the live Sitt).
