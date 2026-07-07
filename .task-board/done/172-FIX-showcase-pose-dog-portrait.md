# 172 — FIX: breed showcase poses the hero dog as a composed portrait (pause the wander)

**Source:** PO father-pass-37 (2026-07-08, `.docs/specs/po-review.md`) — ONE buildable **X-4** directive.
HEAD `d959615` (171 ghost-pill-chrome). Board was empty → this is the replenish.

## The problem the PO saw

The breed showcase (completion-menu «Vis frem hundene») spotlights the **LIVE training rig with the
idle-wander still running**, so the "hero" dog roams out of frame, faces away, or is clipped at the
edge — the opposite of the kennel's composed, centered portraits. Over ~6 s of capture only ~1 of 5
sampled moments actually "shows off" the dog; the rest catch it mid-stride, off-center, or half out
of frame.

Root cause: `main.gd:_on_showcase_requested` only brightens the stage + re-tints the live rig — it
**never pauses the wander or poses the dog**, so `_wander_active` stays true and the hero keeps
roaming its patch (`_drive_wander`, line 611, runs every `_process` even while the menu/showcase is
open). This also breaks cohesion with the kennel, which renders each dog as a clean centered front-¾
portrait via its live SubViewport (116/155).

## What "good" looks like (per the directive)

While the breed showcase is open: quiet the wander and gently pose the spotlit dog as a **portrait** —
centered, camera-facing, whole body in frame — so it holds still and reads as "shown off", matching
the kennel modal. The dog keeps its idle breath/blink; it just must not walk off-frame or turn its
back. Keep the spotlight brightening + live preview re-tint (087/163) and the control-bar chrome (171)
exactly as they are.

## Plan

- `_on_showcase_requested`: `_pause_wander()`, recenter the roam to patch centre (new pure
  `WanderField.recenter()` → snap `_pos`/`_target` to ZERO, phase PAUSING), and engage a
  face-the-camera turn (new `_engage_face_for_showcase()`, mirroring `_engage_face_for_sit` but
  without the `_window`-coupled apex timing — a plain FaceTurn to `_camera_facing_heading()`).
- `_close_showcase` (shared by commit + dismiss): `_release_face()` + `_resume_wander()`, so the dog
  eases back to roaming behind the menu / resumes training exactly as the sit-end path does.

## Tests (TDD, written first)

- `test_wander_field.gd`: `recenter()` returns `position()`/`target()` to ZERO and leaves it paused.
- new `tests/test_breed_showcase_pose.gd` (CC0 dog — walk, no sit, wander runs continuously):
  opening the showcase sets `_wander_active == false` and `_facing == true`; after a few frames the
  dog holds at patch centre and its yaw converges to `_camera_facing_heading()`; both close paths
  (`_on_showcase_dismissed`, `_on_showcase_commit`) restore `_wander_active == true`.

## Done when

Tests green, full verify gate green, in-pixel re-verify (the spotlit dog stays centered + camera-facing
across several seconds). No regression to 090 chrome-hide wiring or 171 chrome.
