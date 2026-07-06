# 131 — VISUAL — Kennel cells read as distinct dogs (face-on head-and-shoulders portraits)

**Source:** PO Review 2026-07-06, directive **#1 [HIGH]** — the biggest kennel gap.
**Phase:** current-phase X-4 quality (preempts the Phase-10 owner-gate).

## What it addresses

Every kennel cell reads as **the one Labrador rig in a different tint** — all 8 cells (incl.
Beagle, Gravhund/dachshund, Maltis) share the identical retriever silhouette + **rear-quarter
pose**, recolored per cell. The grid reads as a palette swatch and the adopt choice feels hollow.
(`105-kennel-01-grid.png` / `-02-scroll.png`.)

Genuinely distinct breed **silhouettes/models** stay the owner-gated **BUST-068** residual — do
**not** fake them. But the portrait **framing** is buildable now and kills the "one dog, eight
tints" read: give each cell a **face-on head-and-shoulders crop** (not the full rear-quarter
body), with **per-cell camera framing/rotation** so each dog faces the viewer and no two cells
look identical.

## Technical approach

The kennel cells already render a **live dog via `SubViewport`** (per the 2026-07-05 build work,
not a baked PNG). So this is a **camera-transform** change per cell, not new geometry.

- In the kennel cell's `SubViewport` setup (`kennel_screen.gd` / the kennel-cell renderer),
  reposition the `Camera3D` to a **face-on head-and-shoulders** framing: move it in front of and
  slightly above the dog's head, aim at the head/neck, tighten FOV/distance so the crop is the
  head + shoulders (not the rear quarter).
- Give each cell a **per-dog yaw offset** (and small pitch/distance jitter keyed to the dog's
  id/index) so the 8 portraits are visibly distinct framings rather than identical poses. Key it
  deterministically off `KennelDog` id/index (NOT random — reproducible captures).
- Respect the skinned-dog transform gotcha (CLAUDE.md): global_transform/AABB is ~origin until
  frame 1 — frame off the head bone / a node-local offset, or let a frame tick before capturing,
  rather than trusting AABB at frame 0.
- Keep the existing per-cell coat tint (that layer is correct); this changes only the camera.

Before (all cells share one rear-quarter body framing, tint-only difference):
```gdscript
# cell camera: fixed behind/above the whole body -> rear-quarter silhouette, identical per cell
```
After (sketch):
```gdscript
# cell camera: face-on head+shoulders, aimed at the head, per-dog yaw/pitch offset by id/index
```

## Test / review

- Pure 3D/camera framing → **Visual Review**, not TDD. (If a pure helper computes the per-dog
  yaw from id/index, unit-lock that mapping.)
- Re-capture the kennel grid (`tools/web_capture_kennel*.mjs`) at 390×844 and confirm each cell
  is a face-on portrait and no two cells are visually identical framings.

## Acceptance criteria

- [ ] Each kennel cell shows a **face-on head-and-shoulders** portrait (dog faces the viewer),
      not the full rear-quarter body.
- [ ] Per-cell camera framing/rotation differs by dog (deterministic, keyed to id/index) — no two
      cells look identical.
- [ ] Coat tint per cell preserved; no new geometry, no faked breed silhouette (BUST-068 residual
      stays owner-gated — flagged, not faked).
- [ ] Skinned-transform-at-frame-0 gotcha respected (no origin-collapsed framing).
- [ ] Visual Review PASS on the kennel grid + scroll captures (phone-portrait 390×844).
- [ ] verify gate green (import·boot·test·export); placeholder check clean; committed + pushed.
