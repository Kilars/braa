# 151 — FIX: owned-dog «Trener nå» / «Tren med» status pills clear WCAG AA (X-6)

**Source:** PO Review 2026-07-07 (father pass 15), `.docs/specs/po-review.md` — one buildable X-6 defect.
**Phase:** 8 (kennel) — signed off; X-6 polish on a signed surface.

## Defect
The owned dog's **«Trener nå»** current-dog status pill (`_build_active_state`,
`kennel_screen.gd:1506`) draws its label in the full green `C_STATUS_OWNED` over a 14%-opacity
wash of the *same* green (`C_STATUS_OWNED @ 0.14` over the `C_MODAL_SURFACE` card) — a measured
**1.39:1** contrast (PO sampled fill `(228,242,225)`, label `(166,216,167)`). Far below the AA
4.5:1 bar the loop itself set for the kennel in task 149. It is the ONE control a player sees when
they open **their own dog** — the payoff-of-ownership moment — rendered as the faintest thing on
the card.

The tappable **«Tren med [navn]»** owned-switch button (`_build_train_with_button`, `:1476`) is
white on the full green `C_STATUS_OWNED` = **~2.49:1**, also below AA — same green-family
illegibility once a second dog is adopted. PO: "fix both".

## Fix (buildable, no owner asset)
- Keep both surfaces exactly as they read (the active pill stays the **muted, non-tappable** pale
  wash — must NOT look like a dead pressable button; the switch button stays the full green
  tappable pill). Change only the **label ink** to the shared dark ink `C_TAG_INK` (`#141c26`,
  the 149 badge ink) so both clear AA ≥ 4.5:1.
- Make the active pill's wash **opaque** via a static `active_state_fill()` helper
  (`C_MODAL_SURFACE.lerp(C_STATUS_OWNED, 0.14)` — the identical pixel, but deterministic/testable)
  instead of an alpha over the parent.
- Do NOT change the coral «Adopter gratis ♥» / blue «Adopter» / menu CTAs, the rarity accent hues,
  or the framing.

## TDD
`tests/test_kennel_owned_status_contrast.gd`:
- `C_TAG_INK` clears AA (≥4.5) on the composited active-pill fill (`active_state_fill()`).
- `C_TAG_INK` clears AA (≥4.5) on the full `C_STATUS_OWNED` switch-button green.
- The old green-on-wash / white-on-green are the sub-3:1 failing baseline.
- `active_state_fill()` reproduces the PO-sampled `(228,242,225)` composite.

## Done
verify green; live modal capture shows «Trener nå» reading clearly; commit + push; hand to father pass 16.
