# 061 — FEATURE: Face me for the trick (P2-11) — turn to face the camera on a real trick

**Type:** FEATURE (new story P2-11, owner directive 2026-07-01 `larssski`, added to `phase2.md`
in commit `f9a7a6f`; that commit was **spec-only** — no facing code shipped, so this is genuine
unbuilt current-phase work).
**Phase:** 2 (current). **Non-owner-gated** — buildable now on the existing Sitt (the owner note
says "Buildable now (Sitt only); build + Visual-Review it"). Preempts any work-ahead.

## What P2-11 asks (phase2.md:113)

> As a player, I want the dog to turn and face me (the camera POV) whenever it performs a trick,
> so that I read the trick head-on and the payoff feels aimed at me — never in profile or behind.

Acceptance:
- A **real (non-feint) trick** begins → the dog **turns to face the camera POV**, apex reads head-on.
- The turn is **smooth + in-character** — rotates on its gait, **no snap, no foot-slide**, and
  **completes before the apex**.
- A **feint** commits to no trick → it does **NOT** force a face turn; keeps its wander heading.
- Reduced motion: the facing still **resolves** (a dampened/near-instant turn is fine). (X-5, D13)

## The gap today

`main._drive_wander` drives the dog root yaw every frame from `_wander_base()`, which yaws
`_dog_rest.basis` by `_wander.heading()` (the travel heading). `_begin_sit` calls `_pause_wander()`
so the roam **freezes at whatever heading the dog was ambling** — which can be side-on or rear-on.
The seated apex then reads at that arbitrary angle. Nothing turns the dog to the camera.

## Technical approach (pure core + thin glue, mirrors the WanderField pattern)

**1. `scripts/face_turn.gd` — pure `FaceTurn` (TDD, no Node).** A bounded-angular-speed,
shortest-path turner: eases a heading toward a target at `speed` rad/s, taking the short way
around ±π. Retargetable (so the same turner eases *in* to the camera during the sit and *back out*
to the roam heading after). `is_facing()` reports arrival. Reduced motion → main hands it a very
high speed so it resolves near-instantly (facing still resolves — spec). Deterministic, so the
math is unit-tested headless; the node-driving glue is Visual-Review-gated (same split as 050).

**2. Camera-facing heading (model-agnostic).** Reuse the wander's exact convention: the dog at
yaw `H` faces `(sin H, cos H)` in XZ, so `heading = atan2(dir.x, dir.z)` faces `dir` — Visual
Review already proved this faces the travel direction (050). So the camera-facing target is
`atan2((cam - dog).x, (cam - dog).z)` — no hardcoded angle, no per-model tuning, correct whatever
the rig's rest orientation. Store the `Camera3D` in `_frame_camera`/`_fallback_camera`.

**3. Wiring in `main.gd`.**
- `_begin_sit` → `_engage_face_for_sit()`: cache the camera-facing target, build `_face` from the
  dog's current yaw, and pick a `speed` that **completes the turn within `apex * 0.6`** (floored),
  so it always finishes before the seated apex regardless of turn size; reduced motion → near-instant.
- `_end_sit` → begin the **eased release**: `_facing = false`, reset `_face` to the natural roam
  speed; `_drive_wander` then eases `_face` back to `_wander.heading()` and, once aligned, drops
  `_face` (yaw handed back to the instant wander — steady-roam feel unchanged).
- `_begin_feint` / `_end_feint`: **untouched** — never engage `_face`, so the dog keeps its wander
  heading through a feint (spec: a feint keeps its wander heading). Feints never open `_session`, so
  driving facing off `_begin_sit` (not any tap) is inherently feint-safe.
- `_dog_yaw()` returns `_face.heading()` when `_face != null`, else `_wander.heading()`;
  `_wander_base()` yaws by `_dog_yaw()`. The confused beat (045) already composes off `_wander_base`,
  so it layers on the faced heading for free.

**Why root-yaw during the sit is safe:** the AnimationPlayer animates the skeleton, not this root
node (same basis the confused beat + wander already rotate the root while a clip plays), so the turn
never fights the sit clip. The turn is a pivot-in-place (the honest best with the available clips —
there is no authored stepping-turn); it completes before the apex and the dog is small in frame, so
it reads as the dog turning to face you as it settles. Visual Review confirms no perceptible slide.

## Acceptance criteria

- [x] Failing test first (RED confirmed: `FaceTurn` not declared; then wiring RED on the new main
      members). GREEN after implementation.
- [x] `tests/test_face_turn.gd` (pure, 6 tests): shortest-path (turns the short way across ±π);
      bounded speed (no overshoot per step); reaches + holds the target (`is_facing`); **completes
      within a deadline** when speed = turn/deadline; a very high speed resolves in ~one frame
      (reduced-motion path); retarget redirects the turn (the release reuse).
- [x] `tests/test_face_wiring.gd` (scene glue, CC0, 5 tests): a walk-capable dog gets a `_face`+
      `_camera`; `_camera_facing_heading()` = atan2 of the dog→camera XZ vector and points **toward**
      the camera (dot ~+1); `_engage_face_for_sit()` then N frames → the dog root is yawed to the
      camera-facing heading (`is_facing`); releasing eases the yaw back to the wander heading and
      drops `_face`; a **feint** leaves `_face` null (keeps its wander heading).
- [x] `FaceTurn` (`scripts/face_turn.gd`) + main wiring implemented; **232 tests, 0 failures**.
- [x] Verify gate green (import · boot · test · export) — `✓ verify gate green`.
- [x] Visual Review (local licensed web capture, 390×844 — the bundle prefers the sit-capable
      licensed Labrador). Free-run + dense bursts:
      - `.screenshots/061-face-08` and `061-dense-22..25` / `061-dense-31`: on a real sit the dog is
        **seated facing the camera dead head-on** — apex reads head-on, across two separate sits.
      - `061-dense-26..30`: after the sit the dog **stands up (059) and turns away**, easing back into
        the roam — **no snap, no visible foot-slide**; `061-face-40` catches a mid-build-in already
        oriented to the camera (turn completes before the seated apex).
      - `061-face-17` / `061-face-25` (no trainer ring): while **roaming/feinting** the dog stays in
        **profile / its wander heading** — facing is sit-specific, never globally forced.
      - `061-reduced-20` (`prefers-reduced-motion: reduce`): the facing **still resolves** — the dog
        reads head-on at the apex (near-instant turn). (X-5, D13)
- [x] Placeholder check clean on the diff (scripts/ + assets/).
