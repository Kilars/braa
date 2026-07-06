# 139 — VISUAL: kennel inspect-modal header portrait as a hero bust (nameplate clear of legs)

**Source:** PO Review 2026-07-06 (father pass 4), directive 1 — the one buildable
X-4 directive filed against HEAD `546ccb5`. Preempts the Phase-10 owner-gate.

## What the PO saw
`scripts/kennel_screen.gd:1022` `_build_modal_band`. The modal header band is a
wide-short strip (`MODAL_BAND_H = 100` px tall, card `MODAL_CARD_MAX_W = 362` px wide
→ 3.6:1), but the shared portrait texture is near-square (`PORTRAIT_VP_SIZE 384×340`
≈ 1.13:1) drawn `STRETCH_KEEP_ASPECT_CENTERED` — so it fits by height and renders the
dog only ~113 px wide, marooned between two big empty dark-steel margins, and the
bottom-anchored white «Nova» nameplate cuts straight across the dog's legs.

X-4 "reads first, looks the part" — the inspect modal is where you study the dog you're
about to adopt, so its portrait should be the hero of the card. Right now the grid cells
behind it (131, ~1.6:1 band, ~70% fill) read as big crisp posed dogs while the modal
header reads as a distant thumbnail with text through its body.

## What good looks like
- Frame the modal header dog as a prominent portrait bust like the grid cells: raise
  `MODAL_BAND_H` so the near-square render fills the band toward grid-cell parity
  (grid ≈ 70% width fill), making the dog the hero of the card.
- Lay the name on a **solid nameplate strip** at the band bottom, clear of the dog's
  body — never crossing its legs — in the same Baloo-2 white treatment. Inset the dog
  portrait's bottom so its feet rest *above* the strip.
- Keep the card under the 844 px portrait height (verify total card height still fits).

## Done when
- `MODAL_BAND_H` raised; modal dog reads as a hero bust at grid-cell-parity fill.
- Solid nameplate strip carries the white Baloo-2 name; dog's legs are never crossed.
- verify.sh green (import·boot·test·export).
- Visual Review PASS on a 390×844 headless capture of the Nova inspect modal.

## Notes
- Pure render/layout glue → Visual Review, not TDD (no test asserts these constants).
- Don't touch the grid `_make_band` framing — the PO praised it; only the modal band.
