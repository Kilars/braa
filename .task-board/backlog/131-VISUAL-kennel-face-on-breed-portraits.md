# 131 — VISUAL — Kennel cells read as distinct dogs (face-on head-and-shoulders portraits)

**Source:** PO Review 2026-07-06, directive **#1 [HIGH]** — the biggest kennel gap.
**Phase:** current-phase X-4 quality (preempts the Phase-10 owner-gate).

## ⚠️ 2026-07-06 — first attempt REVERTED (web CPU-readback pitfall); re-filed with the fix

An attempt this round rendered 8 per-cell portraits by re-posing the single dog to a
deterministic per-index yaw and **snapshotting each via `SubViewport.get_texture().get_image()`
→ `ImageTexture`** (a CPU readback of the render target). Verify gate was green, BUT the real
headless-Chromium capture (`105-kennel-01-grid.png`) showed **every dog INVISIBLE** — all 8 cells
rendered tint-only stripe backgrounds. Root cause: **`get_image()` readback of a render target
returns blank in the Web / GL-Compatibility (WebGL2) export** — you cannot reliably read a
viewport render target back to a CPU `Image` there. The original working kennel fed the **live
`ViewportTexture` directly** to each cell's TextureRect (a GPU texture, never read back), which is
why dogs were visible. The snapshot approach was reverted (working-tree restored to the committed
shared-texture kennel — dogs visible again). Do **not** re-attempt the `get_image()` route.

**Head-and-shoulders framing params from the attempt were web-safe and can be reused as-is:**
`PORTRAIT_VIEW_DIR = Vector3(0.18, 0.55, 1.0)` (nearly frontal, above), FOV `22°`,
`PORTRAIT_HEAD_FRAC = 0.72` (aim ~72% up the bbox at the head/neck), distance from upper-body
extent only. (Watch: on the CC0 local dog the tight FOV can clip the ears — validate in capture.)

## What it addresses

All 8 kennel cells read as the SAME Labrador rig in a different tint — one live `ViewportTexture`
is shared across every cell + the modal (X-7 "render once, reuse 8×"), only `modulate`-tinted per
`band_tint`. Distinct breed **silhouettes/models** stay owner-gated **BUST-068** — do NOT fake
them. The buildable slice: distinct **framing per cell** (face-on head-and-shoulders, per-cell
yaw) so no two cells look identical.

## Correct approach (web-safe — no CPU readback)

Give each distinct angle its **own live SubViewport + dog instance**, and feed each cell that
viewport's **live `ViewportTexture` directly** (exactly how the current single portrait works —
just N of them, never `get_image()`):

- Build a small set of live SubViewports (up to 8, one per distinct yaw), each with its own
  `World3D` + dog instance posed to a deterministic per-index yaw + the head-and-shoulders camera
  above. Assign cell *i*'s TextureRect `texture = viewport_i.get_texture()` (live, GPU).
- Keep the per-cell `band_tint` modulate on top (that layer is correct).
- **Cost guard:** 8 live skinned-dog instances is heavy — the kennel is a modal, not the main
  loop, so it is likely acceptable, but render at low viewport resolution and consider a bounded
  pool (e.g. render each viewport `UPDATE_ONCE` after it settles, then stop updating — a still
  portrait needs no continuous redraw, and a one-shot live texture avoids both per-frame cost AND
  the readback pitfall). Measure; if 8 instances is too heavy, reduce distinct angles and ensure
  at minimum no two *adjacent* cells match, and `log`/note the reduction honestly.
- Headless-safe: skip the viewport build under `DisplayServer.get_name() == "headless"` and fall
  back to tint-only (as today); verify gate must stay green with no hang.

Deterministic per-cell yaw only (no `randf()` — banned, and captures must be reproducible). A
non-monotonic spread reads best (adjacent grid cells clearly differ).

## Test / review

- Pure 3D/camera framing → **Visual Review**, not TDD. (If a pure helper maps index→yaw, unit-lock it.)
- Re-capture via `tools/web_capture_kennel.mjs build/web` at 390×844 and confirm **the dogs are
  visible** (regression guard) AND each cell is a face-on head-and-shoulders portrait, no two
  identical.

## Acceptance criteria

- [ ] Dogs are **visible** in every cell in the real browser capture (no readback-blank regression).
- [ ] Each kennel cell shows a **face-on head-and-shoulders** portrait (dog faces the viewer),
      not the full rear-quarter body.
- [ ] Per-cell framing/rotation differs by dog (deterministic, keyed to id/index) — no two cells
      look identical.
- [ ] Distinct framing achieved with **live `ViewportTexture`s, NOT `get_image()` CPU readback**.
- [ ] Coat tint per cell preserved; no faked breed silhouette (BUST-068 stays owner-gated).
- [ ] Skinned-transform-at-frame-0 gotcha respected (settle before the one-shot render).
- [ ] Visual Review PASS on kennel grid + scroll captures (390×844).
- [ ] verify gate green (import·boot·test·export); placeholder check clean; committed + pushed.
