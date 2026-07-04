# 102 — VISUAL: garden composition round 2 (path off the dog, coins that read, cottage house)

**Phase:** 6 (design system + training-page ambiance). **Type:** VISUAL (Visual-Review-gated look +
parametric TDD regression asserts). **Source:** PO Review 2026-07-05 (`.docs/specs/po-review.md`, HEAD
`6096a41`) — three remaining garden directives after 101 fixed the fence.

## The PO's three findings (replayed at 390×844, SwiftShader == deployed GL Compatibility)

1. **The path over-corrected into a full-width dirt wedge — the dog sits on dirt, not grass.**
   101 fixed the inverted-perspective point but swung too far: `GARDEN_PATH_WIDTH_NEAR=1.0` at the
   `+2.4` foreground z, centred at the dog's x, fills the lower half (idle bottom-200px band scans 54 %
   tan). Goal: dog centred on **green grass**; the path is a **slim winding ribbon** (~¼ the foreground
   width) that runs **beside** the dog and recedes to the house — never under the dog's feet.
   → shrink `WIDTH_NEAR` hard + offset the near end to the RIGHT so it runs beside the dog on grass.
2. **The coins still don't read as coins — a gold-pixel scan finds ZERO in-world gold.** 101 shrank
   R 0.24→0.16 and they vanished (only a faint greenish tick at mid-field). Goal: small but
   unmistakable **gold discs resting low on the grass in the lower third**, framing the dog.
   → moderate size (readable, not an orb) + move to the **foreground lower-third** (higher +Z, closer
   to camera → bigger projection, lower in frame, on grass) — and verify a gold coin is visible in
   captured pixels, not just that the node exists. Keep `billboard_keep_scale=true` (GL-Compat edge-on
   collapse guard) — size via the mesh.
3. **Minor — the house reads as a blown-out tower.** Tall narrow cream box, face washed near-white by
   the bloom → reads silo, not cottage. Goal: a cozy **cottage** — wider than tall, simple gable roof,
   a small window/door, face not blown out.
   → wider-than-tall walls + a lower gable + a less-white (warm cream) albedo so it doesn't clip white
   + a small blue window/door. Re-confirm the grounding shadow ellipse reads once the dog is on grass.

Keep everything in the DS palette (sky/grass/BLUE/GOLD). Match the goal's layered composition +
grounding (dog on grass, slim path, grounded gold coins), not the exact pixels.

## Plan (all node-local off dog bounds, GL-Compat-safe, dog stays centred + unoccluded)

- **Path:** `GARDEN_PATH_WIDTH_NEAR` 1.0 → ~0.5, `WIDTH_FAR` 0.55 → ~0.32; new `GARDEN_PATH_NEAR_X`
  offset (~+0.6) so the near end sits to the RIGHT of the centred dog. Foreground reach (`NEAR_Z=2.4`)
  kept so the 101 foreground-reach assert holds.
- **Coins:** `GARDEN_COIN_R` 0.16 → ~0.20 (readable, still < the 0.24 orb); reposition all three to
  the foreground lower-third on grass (2 left + 1 right), clearing the slim path.
- **House:** walls wider+shorter, lower gable, warm-cream albedo (no white clip), add a small blue
  door + window child. Cottage proportions (width > height).

## TDD regression asserts (update `tests/test_garden_wiring.gd`)

- Path near end is NARROW (guards the wedge): `GARDEN_PATH_WIDTH_NEAR <= 0.6`, and the ribbon runs
  beside the dog (its AABB does not sprawl left across the whole floor).
- Coins read (guards BOTH the orb and the vanished-tick): coin diameter in a readable band
  (`0.34 <= diameter <= 0.46`) AND grounded in the foreground lower-third (`coin.z > c.z`).
- House cottage proportions: walls `size.x > size.y` (wider than tall) + a window/door child exists.

## Done when

verify green (import·boot·test·export), `po_p6_drive.mjs` idle capture shows the dog on green grass, a
slim path beside it, visible gold coins low in the lower third, and a cottage (not a tower); placeholder
grep clean; committed + pushed; po-review.md (the PO's 2026-07-05 pass) committed alongside.

## Outcome — SHIPPED

All three directives fixed; verify **561/0**, gate green; placeholder grep clean; `po_p6_drive.mjs`
idle capture (`.screenshots/po-p6-idle-a/b/c.png`) reviewed by eye + gold-pixel scan.

- **Path (1):** `WIDTH_NEAR` 1.0→0.5, `WIDTH_FAR` 0.55→0.32, new `GARDEN_PATH_NEAR_X=0.6` offsets the
  near end RIGHT of the dog. The full-width dirt wedge is gone — the dog now sits squarely on **green
  grass** with a **slim tan ribbon** winding up-right to the house.
- **Coins (2):** root-caused the PO's zero-gold scan — the 101 coins were at **|x|=1.4-1.7, entirely
  OFF-SCREEN** (never a size problem). Measured the camera analytically (`tools/diag_coin_project.gd`,
  a throwaway removed after): it sits **only ~1.2 m behind the dog**, so the narrow portrait FOV shows
  only **|x| < ~0.5 m** at this depth AND magnifies on-screen props. Re-placed the 3 coins at |x|≈0.42-
  0.47 flanking the dog (2 left, 1 right) and shrank `GARDEN_COIN_R` 0.16→0.12 so they read as small
  gold discs, not orbs. Gold-pixel scan: **9684 in-world gold px** (was 0). The goal's exact lower-third
  corners are unreachable without regressing the framing (the close camera couples low↔big) — small gold
  coins flanking the dog is the achievable, honest read (the 101 note, which the PO's own #2 anticipated).
- **House (3):** walls `1.6×1.4 → 2.0×1.05` (wider than tall), lower/wider gable, warm-**cream** albedo
  `0.96,0.94,0.87 → 0.85,0.82,0.72` (off near-white so the sun no longer blows the face out), + a small
  DS-blue **Door** + light-blue **Window** on the camera-facing wall. Reads as a cozy cottage, not a silo.

**TDD:** 4 garden asserts updated to the fixed contracts (path slim + beside the dog; coins in a readable
size band + flanking the dog within the FOV; house wider-than-tall + cream walls + window/door). RED→GREEN.

**Gotcha banked:** the training camera is only ~1.2 m behind the dog → narrow portrait FOV shows only
|x| < ~0.5 m of world width at the dog's depth and magnifies anything on-screen. Verify prop placement
with an **analytic 390×844 projection** (vfov=cam.fov, hfov from aspect), NOT the headless viewport
unproject (its landscape aspect lies) — the headless viewport reports ~836px wide, so on-screen ≠ browser.
