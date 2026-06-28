# FEATURE: 024c — Alive at rest: ambient idle loop (P1-2)

**Status**: Done (2026-06-28)
**Parent**: 024
**Priority**: Medium (the resting state between sits)
**Labels**: gameplay, godot, phase-1, visual
**Estimated Effort**: Medium

## Outcome (specs2.md P1-2)

- Ambient idle motion (breathing / small look-around / tail) on a **seamless loop**.
- Dog stays **centered** (no drift to the edge — D12, PO-Change-3).
- Smooth: no T-pose snap, no jitter, no popping at loop boundaries.

## Approach

- Idle clip on the dog's AnimationPlayer; cross-fade idle ↔ sit so neither state snaps.
- Centering is a camera/transform concern — verify the dog's root stays at origin
  across the whole idle loop, not just frame 0.
- Visual task → `polish` + phone-portrait screenshot review (blocking).

## Depends on

- 021 scaffold (dog loads, done). Pairs with 024b so idle ↔ sit blend cleanly.

## Iteration findings — DONE (2026-06-28)

Probed the real committed CC0 dog headless before touching code (grounded, not guessed):

- **Seamless loop, confirmed.** The `Idle` clip imports as **`loop_mode = NONE`** —
  played raw it runs once (6.667 s) and **freezes**. `DogDirector.play_idle()` flips it
  to `LOOP_LINEAR` at runtime, so the seam matters. Measured the wrap seam: worst
  rotation-track delta t=0→end is **0.0007 rad** (~0.04°) and position tracks return to
  start (Δ≈0) → the `LOOP_LINEAR` wrap is visually seamless, no snap. (The motion is a
  head look-around + a front paw; body/tail near-static — a real, alive idle.)
- **No drift, confirmed.** Sampling the visible-mesh AABB centre across the whole loop:
  **x/y/z drift = 0.0000** — the CC0 idle has no root motion. "Centered, no drift" holds.

**Centering fix (the real new work).** The 024b review flagged the dog sitting *high in
the frame with empty space below*. Root cause: the scaffold camera aimed at **(0, 0.5, 0)**
but the dog's true visual centre is **(0, 0.928, 0.279)** — it aimed ~0.36 below centre.

- New pure helper `scripts/dog_framing.gd` (`DogFraming.target/distance/eye`):
  centres on the dog's AABB and fits the camera distance to its bounds for the project's
  fixed portrait viewport (720×1280, `stretch=keep` → stable 0.5625 aspect everywhere).
  **Model-agnostic** — frames the CC0 placeholder *and* the licensed Labrador with no
  per-model tuning, so 025's Labrador will be centred too.
- `main.gd` now loads the dog first, measures its bounds, and aims a `Camera3D` from
  `DogFraming.eye()` at `DogFraming.target()` (`FRAME_FILL = 0.70` → centred with margin
  that clears the bottom BRA band). A `_fallback_camera()` covers a missing/unmeasurable
  dog.
- **Frame-timing gotcha (worth keeping):** a skinned glTF dog's `global_transform` is
  ~origin at `_ready` and only resolves to the real placement after the **first process
  frame**. So `_dog_bounds()` accumulates node-**local** transforms up to the dog root
  (populated synchronously from scene data) instead of reading `global_transform` —
  framing is correct on the very first rendered frame, no deferral.
- **Embedded-camera gotcha:** the CC0 glb ships its own `Camera3D`; `main` calls
  `make_current()` last so ours wins. The scene-level test asserts the **active** camera
  (`get_viewport().get_camera_3d()`), not a tree search (which finds the dog's first).

**TDD.** `tests/test_dog_framing.gd` (8 pure tests: centre, distance monotonic in
height/width/margin, portrait-vs-landscape, sane real-dog distance, eye placement) +
`tests/test_idle_loop.gd` (2 scene-level guards: idle is playing & loops — not frozen;
camera aims at the dog's true centre — fails on the old (0,0.5,0) aim, so it's a real
guard). **42 tests green** (was 32).

**Verified honestly (not fabricated).** Full verify gate green (import · boot · test ·
export). Real phone-portrait web-build screenshot (headless Chrome on the verify export,
gated on `window.__appReady`, no-letterbox 0.5625 aspect) inspected directly:
`.screenshots/024c-idle-framing.png` — the dog is **centred, prominent, recognizable,
posed (not a T-pose), on the bright backdrop**, with clean top/bottom margin and feet
resting at the BRA band. The earlier "high in frame, empty below" gap is fixed.

**Out of 024c scope (noted, not done here):** no contact shadow (P1-1 — future card);
the dog faces the camera fairly head-on (a slight 3/4 orbit is a polish call, not P1-2
centering). Idle ↔ sit cross-fade is moot until the Labrador's Sitt ships (025/024b).
