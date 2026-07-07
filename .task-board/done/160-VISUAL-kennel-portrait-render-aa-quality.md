# 160 — VISUAL: kennel portrait SubViewport render quality (MSAA + resolution) — kill muzzle/whisker speckle

**Source:** PO Review father-pass-24 (`.docs/specs/po-review.md`, HEAD `e1c0f9a`), the ONE new buildable
X-4/X-7 directive. Board was empty after 159; this is the PO-surfaced next buildable work.

## What the PO saw
The kennel grid (all 8 cells) **and** the inspect-modal hero bust render with dark **speckle noise**
around every dog's muzzle/mouth — fine whisker/lip geometry aliasing into dirt-like dots, some floating
in the empty cell air just past the snout (whisker tips aliased into disconnected specks). The same rig
renders **clean smooth fur** at the large training scale under the identical SwiftShader renderer, so it
is **not** the asset or a capture artifact — it is the small portrait render aliasing.

## Root cause (PO read the code, confirmed)
`kennel_screen.gd:87` `PORTRAIT_VP_SIZE := Vector2i(384, 340)` and the SubViewport built at `_build_one_portrait`
sets **no** `msaa_3d` / `screen_space_aa` — the dog is rasterised at 384 px with no anti-aliasing, then
upscaled into a ~195 px cell (and ~2× in the modal), turning thin whisker geometry into stair-stepped dark dots.

## Fix (buildable, no owner asset; confined to `kennel_screen.gd`)
1. Enable MSAA on every portrait SubViewport — `vp.msaa_3d = PORTRAIT_MSAA` where
   `PORTRAIT_MSAA := Viewport.MSAA_4X` (anti-aliases the thin whisker geometry edges that alias to specks).
2. Raise `PORTRAIT_VP_SIZE` (same aspect) so the SubViewport renders at/above the on-screen pixel size the
   modal upscales to (2×), instead of being magnified from 384. Double to `Vector2i(768, 680)`.

**Do NOT** change the pose, yaw (155), coat tint (117), or framing (140) — orthogonal to this render-quality
change. Keep UPDATE_ALWAYS (idle breathing).

## Definition of done
- `PORTRAIT_MSAA` const added, `vp.msaa_3d` set to it in `_build_one_portrait`.
- `PORTRAIT_VP_SIZE` raised, same aspect (framing math already derives aspect from it → self-consistent).
- New `tests/test_kennel_portrait_render_quality.gd` pins the render-config constants (RED before, GREEN after).
- verify gate green; Visual Review: 3× muzzle crop of a grid cell shows clean whisker lines, no floating specks.
