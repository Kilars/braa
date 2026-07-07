# 171 — FIX: breed-showcase ghost-pill chrome clears WCAG AA (PO father-pass-36, X-6)

**Source:** `.docs/specs/po-review.md` — PO father pass 36 directive.

## Problem
169 fixed the showcase **hint caption** (which sits directly on the dark stage band).
But the «Tilbake» back-button label (~3.9:1) and the ◀▶ chevron glyphs (~4.0:1) sit on
the white@0.14 ghost **pills**, which *lighten* the translucent band to a ~112–116-grey
pill. The white@0.92 chrome text only reaches ~3.9–4.0:1 on that lifted pill — sub-AA.
On the active-dog view «Tilbake» is the only tappable action, so the lowest-contrast
element is also the primary exit.

## Fix
`scripts/breed_showcase_view.gd`: change `BTN_SECONDARY` from a white@0.14 *lightening*
fill to a *darkening* ink overlay so the pill is genuinely dark and the near-opaque
white label/glyph clears ≥4.5:1 on its own composited pill. Keep the quiet "ghost
secondary" read, the band translucency (169 — spotlight glow), and the pip/hint/aktiv-dot
treatments (165/166/169) exactly as-is. Only the two pill-backed chrome controls change.

## TDD
Extend `tests/test_breed_showcase_contrast.gd`: the composited «Tilbake»/chevron
label-over-pill contrast must be ≥4.5:1 against the father's measured worst-case
bright-grass band. Add pure `chrome_pill_over`/`chrome_ink_over` helpers so the test
pins the real composited chrome.

## Verify
Full gate green + in-pixel re-check at dsf3 that «Tilbake» + chevrons clear AA on pills.
