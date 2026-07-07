# 162 — X-6: completion-menu «Adopter 30» breed-price badge → WCAG AA

**Source:** PO father-pass-27 (`.docs/specs/po-review.md`, 2026-07-07), one buildable X-6 directive.
**Label:** X-6 (AA contrast polish)

## Problem
The completion menu's «Raser» breed section draws the buyable breed's price badge
«Adopter 30» entirely in `COIN_GOLD` (= `DesignSystem.GOLD` #f5b841) over the CREAM row
fill #f4efe6 (`trick_menu.gd:172`, applied at `:939-942`). Gold-on-cream is two light warm
tones → ~1.55:1, far under the 4.5:1 AA bar. It is the ONE price/adopt badge the 149→156
AA sweep never measured (that sweep did BLUE-on-light→BLUE_INK in 154 and GREY-on-light→
C_INK_SOFT in 156), so it is the last sub-AA label on an otherwise fully-legible card — and
it is the price, the first thing a would-be adopter reads.

## Fix (mirror the kennel `_make_price_chip`, kennel_screen.gd:919-964)
Render the «Adopter»/number in a dark AA-legible ink instead of gold, and prefix a small
gold coin pip so the "gold = coin" DS signal is preserved on an actual coin glyph (never as
text). Dark ink = `DesignSystem.SLATE` #5a6b7d (4.78:1 on CREAM — the SAME ink the buyable
breed *name* already uses, `BREED_NAME_BUYABLE` :216). `COIN_GOLD` stays, but only as the pip
fill (gold reserved to a real coin glyph, the DS rule).

## TDD
`tests/test_breed_price_badge_contrast.gd`:
- BADGE_PRICE_INK clears AA 4.5:1 on ROW_BG (CREAM) — RED on the old gold.
- old GOLD-on-CREAM documented sub-AA baseline (< 2:1).
- coin pip fill stays GOLD (coin signal preserved).

## Verify
- `nix develop -c bash verify.sh` green.
- In-pixel: «Adopter 30» reads dark-on-cream, clears 4.5:1, gold coin pip to its left.

## DONE
- `BADGE_PRICE_INK := DesignSystem.SLATE` (#5a6b7d, 4.78:1 on CREAM) replaces `COIN_GOLD`
  for the BUYABLE price-badge TEXT (`trick_menu.gd:965`). `COIN_GOLD` kept — now only the pip fill.
- New `PRICE_PIP_R`/`PRICE_PIP_GAP`; buyable rows draw a small gold coin pip (GOLD_DARK rim + GOLD
  face, no glyph) left of the price text, `name_max_w` reserves its width so no name overlap.
- TDD: `tests/test_breed_price_badge_contrast.gd` (3 asserts) RED on missing BADGE_PRICE_INK → GREEN.
- verify gate green (import·boot·test·export). In-pixel (fresh export, po_pass26 capture, dsf3):
  «Adopter 30» renders dark ink ~4.7-5.9:1 on CREAM with a gold coin pip, no ellipsis (`/tmp/p27_row2.png`).
