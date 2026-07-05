# 117 — VISUAL: kennel coat tint reads as a natural dog coat (Bella not blue)

**Phase 8 (kennel) · sign-off blocker · PO Review 2026-07-05 @ HEAD `4e14c69`, Improvement #1**

## Directive (father, po-review.md)

The 116 kennel portrait modulates the neutral-coat dog toward each cell's raw
`band_tint` (`kennel_screen.gd:513` / `:966` `_band_dog_tint(row.band_tint)`). The
band colour is the **rarity/ownership** background hue — not a coat colour. For 7 dogs
the band happens to be a plausible dog hue (browns/greys/tans) so they read fine. But
**Bella (the OWNED starter) sits on a BLUE band** (`Color(0.29,0.565,0.886)`), so the
kennel renders her as a **blue-grey dog** — while the very same dog is a warm cream
Labrador on the signed-off training page (Bella's `coat_tint()` is identity → the
untouched yellow-Lab atlas). A player owns Bella, sees her cream in training, then blue
in the kennel: a jarring cohesion break on the flagship dog. **Not owner-gated — a
tint-calibration fix.**

*Good* = the dog coat modulate is **decoupled from the raw band-background colour** so
every dog reads as a plausible dog coat, and **Bella-the-Labrador specifically reads as
her warm training-page coat (cream/yellow), not blue**. The rarity band stays coloured
behind the bars (`band_tint` unchanged) — only the dog's coat needs a natural hue.

**Fold in (minor, PO):** in the modal header the «Bella» title text is centred directly
over the dog render — nudge the title clear of the portrait.

## Plan

1. **TDD** — new `KennelDog.portrait_tint()` returns the dog's natural COAT modulate for
   the neutral-grey kennel portrait: a warm Labrador cream for the starter Bella
   (decoupled from her blue band), each other dog its `band_tint` (the 7 PO-approved
   hues, unchanged). Pin: Bella's portrait_tint is warm (R>G>B, clearly not blue) and
   NOT her band_tint; the other 7 equal their band_tint.
2. **Wire** — `_make_band` (cell) + `_build_modal_band` (modal) feed `portrait_tint`
   (via the classify/detail dict) into `_band_dog_tint` instead of the raw `band_tint`.
   Band BG (`bg.color = row.band_tint`) stays the rarity colour.
3. **Modal title** — move the dog-name label clear of the portrait centre (anchor to the
   band bottom edge) so it no longer overlaps the dog's face.
4. Verify gate green + Visual Review on the running build: Bella reads cream, no blue
   Labrador; the other 7 unchanged; modal title clear of the render.

## Acceptance
- [x] `KennelDog.portrait_tint()` implemented, TDD red→green.
- [x] Cell + modal portraits modulate by `portrait_tint`, band BG still `band_tint`.
- [x] Bella renders warm cream (not blue) in grid + modal; other 7 unchanged.
- [x] Modal dog-name title no longer overlaps the portrait render.
- [x] `nix develop -c bash verify.sh` green; Visual Review pass.
