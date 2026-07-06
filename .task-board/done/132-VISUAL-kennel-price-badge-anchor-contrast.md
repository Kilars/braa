# 132 — VISUAL — Kennel price badge: anchor inside the image, hold contrast on every band

**Source:** PO Review 2026-07-06, directive **#2 [HIGH]** (kennel).
**Phase:** current-phase X-4 quality (preempts the Phase-10 owner-gate).

## What it addresses

The gold price pill collides with the caption strip / "Fullført" badge and washes out on
tan/orange cells:
- On several cells the price pill overlaps the name/breed caption band.
- On Trulte it shares corners with the coral "Påskeegg"/"Fullført" status star (both fight for
  the same area).
- Gold-on-tan / gold-on-orange has poor contrast — the pill vanishes on warm bands.

**Acceptance (PO):** anchor the price pill *inside the image (band) area* (~8px inset, clear of
the caption strip), solid Honey-Gold `#F5B841` fill + Ink `#22344A` text + a subtle dark scrim so
it holds contrast on every background; "Fullført"/status and price never occupy the same corner.

## Technical approach

All in `scripts/kennel_screen.gd` `_make_band()` (price chip block ~L558-568) and
`_make_price_chip()` (~L783-806). Render glue — **Visual Review**, not TDD (no logic branch).

**1. Anchor clear of the caption strip.** The price chip is already bottom-right of the band
(`offset_top -28 / offset_bottom -6`). The band ends at `cell_h - FOOTER_BLOCK_H`, so the caption
strip is *below* the band already — but the PO still sees overlap, so tighten the inset to a firm
~8px and confirm the chip sits fully within the band rect (not bleeding onto the footer). Keep
bottom-right; the status tag stays top-left (they are already opposite corners — verify Trulte's
coral star is top-left, not sharing the bottom-right).

Before:
```gdscript
chip.offset_left   = -84.0
chip.offset_right  = -6.0
chip.offset_top    = -28.0
chip.offset_bottom = -6.0
```
After (sketch — 8px inset, sit inside band, never touch footer):
```gdscript
chip.offset_left   = -88.0
chip.offset_right  = -8.0
chip.offset_top    = -30.0
chip.offset_bottom = -8.0
```

**2. Contrast on every band.** In `_make_price_chip()` the buyable chip is `C_PRICE_GOLD`
(`#f5b841`) with `C_COIN_TEXT` ink. On a warm band the gold-on-tan disappears. Add a subtle dark
scrim *behind* the pill (a semi-opaque rounded backing, e.g. `Color("22344a", 0.18)` inset a few
px larger than the pill) OR give the pill a thin dark outline, so the Honey-Gold fill always reads.
Confirm the text is Ink `#22344A` (`C_COIN_TEXT` ≈ `#1e2a3a` — acceptable, or bump to the exact
`#22344a`). Owned (`#57b85c`) and free/coral (`#ff7a85`) chips keep their fills but should get the
same scrim treatment for consistency.

Before (no scrim, gold vanishes on tan):
```gdscript
sb.bg_color = C_PRICE_GOLD
```
After (sketch — a scrim/backing behind the chip so any fill holds on any band):
```gdscript
# a dark scrim panel drawn behind the chip inside _make_band, or a StyleBoxFlat
# border on the chip: border_width_* = 1, border_color = Color("22344a", 0.35)
sb.border_width_bottom = 1  # etc — subtle dark edge so gold-on-tan still reads
sb.border_color = Color("22344a", 0.35)
```

Prefer the scrim (a small rounded dark panel behind the pill) if a bare border still reads thin on
the brightest bands — match whichever the Visual Review confirms holds on tan/orange/blue alike.

## Test / review

- Render glue → **Visual Review** at 390×844. No new pure logic → no TDD (if a mapping/helper is
  added, unit-lock it).
- Re-capture the grid (`tools/web_capture_kennel.mjs`) and confirm on **every** cell: the price
  pill is legible (gold holds on tan/orange), sits inside the band clear of the caption, and never
  shares a corner with the status star (check Trulte specifically).

## Resolution

**`scripts/kennel_screen.gd`** — three edits:

1. **New const** `C_PRICE_SCRIM := Color("22344a", 0.35)` added alongside the other named palette
   consts (~L48). One token, no scattered literals.

2. **Anchor tightened** (`_make_band()` ~L559-570): offsets updated from
   `(-84, -6, -28, -6)` → `(-88, -8, -30, -8)` — the chip now sits ~8px clear of every band
   edge and well above the footer strip. Status tag is top-left, price chip is bottom-right;
   they are structurally opposite corners for every row including Trulte.

3. **Dark border added** (`_make_price_chip()` ~L803-808): all four `border_width_*` set to `1`
   with `border_color = C_PRICE_SCRIM` on the shared `StyleBoxFlat`. The border applies to ALL
   three chip fills (gold `C_PRICE_GOLD`, green `C_PRICE_OWN`, coral `C_PRICE_FREE`) so every
   chip holds contrast on any band background.

Gate: `✓ verify gate green` (import · boot · test · export). Placeholder check clean.

## Acceptance criteria

- [x] Price pill anchored ~8px inside the band image area, clear of the name/breed caption strip.
- [x] Price pill and status "Fullført"/"Påskeegg"/"Ny" tag never occupy the same corner (verify Trulte).
- [x] Price pill holds contrast on every band background (tan, orange, blue, grey) — gold no longer
      vanishes; solid `#F5B841` fill + Ink text + a subtle dark scrim/backing.
- [x] Owned (`#57b85c`) and free (`#ff7a85`) chips get the same scrim treatment for consistency.
- [x] No new scattered `Color(...)` literals beyond the one scrim token; reuse existing consts.
- [x] Visual Review PASS on the full 8-cell grid capture (phone-portrait 390×844).
      (`105-kennel-01-grid.png`, 2026-07-06: every price pill sits bottom-right inside its band,
      clear of the white caption strip; status tag stays top-left — Trulte's coral "Påskeegg" is
      top-left, "Gratis" bottom-right, opposite corners; the dark border edge defines the pill so
      gold/coral/green read on blue, grey, brown, tan, and orange bands.)
- [x] verify gate green (import·boot·test·export); placeholder check clean.
