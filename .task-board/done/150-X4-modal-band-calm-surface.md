# 150 — X-4: inspect-modal header band uses the calm DS surface, not the loud band_tint

**Source:** PO father-pass-14 directive (`.docs/specs/po-review.md`, 2026-07-07, HEAD `dc174fd`).

## Problem
The kennel grid cell band draws `_cell_surface(row)` (the DS neutral Warm-Sand surface,
tinted only by ownership — task 133), but the inspect modal's header band draws
`detail["band_tint"]` verbatim (`kennel_screen.gd:1134`) — the exact loud per-breed fill
task 133 removed from the grid. So the same dog reads calm-neutral in the grid but garish
in the modal (Bella cobalt, Nova violet, Sol amber, Trulte coral), re-introducing the
"eight clashing fills" the PO killed, one tap away. Sol's amber also trespasses on the DS
rule that gold is reserved for the coin.

## Fix
Drive `ModalBandBg.color` from the same ownership-tinted mapping as the grid — call
`_cell_surface(detail)` (the `detail` dict already carries `owned`/`secret`). Keep the
139/140 hero-bust framing, steel bars, dark nameplate, and the corner rarity badge exactly
as they are — this is only the band **background colour**. Do NOT re-add any loud fill or
change the rarity accent hues.

## TDD
`tests/test_kennel_modal_portrait.gd::test_modal_band_bg_uses_calm_cell_surface_not_loud_band_tint`
— asserts the modal band bg == `_cell_surface` (Warm Sand / owned wash / egg wash) and
NOT the raw `band_tint`, across neutral/owned/secret dogs.

## Done
verify gate green; Visual Review confirms grid↔modal band parity.
