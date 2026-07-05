# 124 — BUGFIX: on-grass coins render as glowing translucent orbs, not flat coins

**Type:** BUGFIX (visual / rendering — Visual Review)
**Phase:** Preempts Phase 10 — owner training-page finish directive (PO Review 2026-07-05, Bugfix 2)
**Priority:** P0-tier of this round (owner-filed bugfix)

## What it addresses

Owner play-test (`.docs/specs/po-review.md` → PO Review 2026-07-05, Bugfix 2): the on-grass coins
**read as fat glowing translucent orbs, not coins** — oversized soft blobs flanking the dog rather
than the small flat gold coins in `goal-training-screen.png`. Task 101 shrank them (102 tuned
placement to `GARDEN_COIN_R = 0.12`) but the **glow / translucency remains**, so they still read
as blobs.

## Root cause (grounded in the code)

`main.gd` `_coin_texture()` bakes a **radial gradient** coin: a bright near-white core
(`GOLD.lerp(white, 0.35)`) fading out through GOLD to a `GOLD_DARK` rim at `dist > 0.82`, then
transparent. Combined with `SHADING_MODE_UNSHADED` + `TRANSPARENCY_ALPHA` billboard quads
(`_setup_ground_coins`), the soft radial falloff + the bright blooming core read as a glowing
translucent orb, not a crisp opaque disc. The goal art coins are small, solid, flat gold discs
with a crisp edge.

## Technical approach (pure rendering — Visual Review, TDD-exempt)

Make the grass coins read as **small, solid, flat gold coins**: opaque body, crisp edge, no soft
glow/translucency, grounded on the grass and clear of the dog silhouette.

In `_coin_texture()` — flatten the disc:

Before:
```gdscript
var core := DesignSystem.GOLD.lerp(Color(1, 1, 1), 0.35)  # bright warm highlight
...
if dist > 1.0:
    col = Color(0, 0, 0, 0)                       # outside the disc — transparent
elif dist > 0.82:
    col = DesignSystem.GOLD_DARK                  # the rim ring
else:
    col = core.lerp(DesignSystem.GOLD, clampf(dist / 0.82, 0.0, 1.0))
```
After (illustrative — a flat solid gold face with a crisp rim, opaque interior, only a 1-px
antialias at the very edge so it reads as a coin, not a hazy orb):
```gdscript
# Flat, solid coin (owner directive 2026-07-05): opaque GOLD face, crisp GOLD_DARK rim, hard
# alpha edge — no bright blooming core, no soft translucent falloff that read as a glowing orb.
if dist > 1.0:
    col = Color(0, 0, 0, 0)                       # outside the disc — transparent
elif dist > 0.86:
    col = DesignSystem.GOLD_DARK                  # crisp rim ring, fully opaque
else:
    col = DesignSystem.GOLD                       # flat solid gold face (optional faint face detail)
```
Keep the alpha edge crisp (opaque inside `dist <= 1.0`, transparent outside; a single-texel
feather at most for anti-aliasing — not the current wide fade). A small notch of face detail (a
subtle inner ring or a lighter upper-left glint that stays **opaque**) is fine, but the disc must
read solid, not luminous. Confirm `GARDEN_COIN_R` (0.12) still reads small like the mockup; nudge
only if Visual Review shows they're still too big. Leave placement (102's flanking spots),
`billboard_keep_scale = true`, and `SHADING_MODE_UNSHADED` (even gold, not sun-dimmed) untouched.

## Acceptance criteria

- [ ] The grass coins read as **small, solid, flat gold coins** — opaque, crisp edge, sized like
  the mockup — grounded on the grass, clear of the dog silhouette (no soft translucent glow, no
  bright blooming core).
- [ ] Visual Review at 390×844 on the real build (fresh training boot): capture the training page;
  a 3× zoom on a coin shows a solid gold disc with a crisp rim, matching `goal-training-screen.png`;
  an in-world gold-pixel scan still counts coin-gold flanking the dog (no regression to 102's
  visibility fix).
- [ ] The dog and BRA button are not occluded; the coins stay in the grass band.
- [ ] `nix develop -c bash verify.sh` green; placeholder check clean.
