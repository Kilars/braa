# FEATURE: 024c — Alive at rest: ambient idle loop (P1-2)

**Status**: DONE (2026-06-28 19:48) — idle is LIVE + real and **centred on BOTH dogs**: the framing regression on the licensed Labrador is **FIXED and pixel-verified** (`.screenshots/024c-licensed-framing-fixed.png`). See "Framing regression — FIXED" below. (Was: reopened 2026-06-28 because the licensed dog was badly mis-framed; original idle/centring work for CC0 was already done.)
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

## Framing regression — licensed Labrador (found 2026-06-28 17:36, building 024g)

A live phone-portrait web screenshot of the **current local export** —
`.screenshots/024g-readout-idle.png` — shows the **licensed Labrador badly mis-framed**:
the head and upper body are cut off above the top of the frame; only the lower torso,
legs, and paws are visible. The dog reads as far too high and too zoomed-in. This fails
P1-1/P1-2 "centered, recognizable dog."

**Why this slipped through 024c's "model-agnostic, Labrador too" claim:** the screenshot
024c verified (`024c-idle-framing.png`, 15:33) was taken **before** the licensed-dog
wiring landed (025-wire, commit 64536a9 ~17:19). At 15:33 `main._dog_path()` could only
return the CC0 dog, so 024c only ever framed CC0 — which it does correctly. The licensed
Labrador's live framing had **never been seen** (025-wire verified it only via boot logs:
"dog can Sitt — apex at 1.250s"). Now that the licensed glb is present locally, the export
loads it and the bug is visible. (Confirmed: real boot logs `dog loaded:
res://assets/models/dog_licensed.glb` + `can Sitt`.)

**Likely cause (to investigate, not yet fixed):** `main._dog_bounds()` / `DogFraming`
mis-measure the licensed dog's bounds. The licensed rig differs from CC0 (113 anims,
different skeleton); a skinned mesh's `get_aabb()` at the bind/rest pose may not reflect
the posed dog (cf. the "skinned AABB ~origin until frame 1" gotcha already noted for
global_transform). The per-VisualInstance AABB accumulation that frames CC0 correctly is
evidently wrong for this mesh — needs a real diagnose pass (measure the licensed dog's
actual AABB headlessly, compare to CC0, fix the bounds calc model-agnostically).

**Scope:** NOT caused by 024g (readout/reduced-motion only — that node is correctly
invisible at rest in the same screenshot). This is 024c/framing's to fix. Until fixed,
the licensed dog cannot pass P1-1/P1-2 visual review, which also blocks the P1-10 done-gate
and the eventual 025 live-Sitt review. The public deploy is unaffected for now (it ships
CC0, which frames fine).

## Framing regression — FIXED (2026-06-28 19:48)

**Root cause (diagnosed headless, not guessed).** A temp probe measured both dogs'
bounds two ways. The skinned mesh's `MeshInstance3D.get_aabb()` is the raw mesh in the
mesh's OWN authoring frame, which need not line up with the skeleton:

| dog       | mesh AABB (old `_dog_bounds`)             | rest-pose BONE span (new)            |
|-----------|-------------------------------------------|--------------------------------------|
| CC0       | y:[-0.021, 1.877], centre 0.928           | y:[0, 1.840], centre 0.920           |
| Labrador  | **y:[-0.638, 0.499], centre -0.069**      | **y:[0, 0.673], centre 0.336**       |

The CC0 mesh box happens to match its bones, so framing off it read fine. The licensed
mesh box is centred **~0.07 below the floor** (extends to y=-0.638), so the camera aimed
*under* the dog and the dog rendered too high → head cut off above the frame. The bug was
purely **measurement**; `DogFraming` math was correct given a correct box.

**Fix (model-agnostic, no per-model tuning — TDD).** New pure `scripts/dog_bounds.gd`
(`DogBounds.measure(dog)`): prefer the skeleton **rest-pose bone span** (the honest
standing extent — feet on the floor for both rigs) over the skinned mesh AABB, falling
back to the mesh-AABB merge only when there's no skeleton. `main._dog_bounds()` now just
delegates to it. 2 new synthetic-rig tests (`tests/test_dog_bounds.gd`) pin the regression
without needing the gitignored glb (a skinned dog whose mesh box is sunk below the floor
must still measure feet-on-floor from its bones); the CC0 scene guard's expected centre
moved 0.928→0.920·z 0.279→0.037 (the bone-span centre). **90 tests green** (was 88).

**Verified in pixels (not fabricated).** Full verify gate green; the licensed dog now
loads in the local web export (boot log `dog loaded: …/dog_licensed.glb` + `can Sitt`).
Real phone-portrait (720×1280, COOP/COEP server + headless Chrome) screenshot
`.screenshots/024c-licensed-framing-fixed.png`: the **whole Labrador — head, face, body,
paws — is centred and fully in frame** on the bright backdrop, paws at the BRA band. The
"head cut off above the frame" symptom (`024g-readout-idle.png`) is gone. P1-1/P1-2
"centred, recognizable dog" now holds for the licensed Labrador too.
