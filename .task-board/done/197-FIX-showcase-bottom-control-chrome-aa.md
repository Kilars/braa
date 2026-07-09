# 197 — FIX: breed-showcase bottom-control chrome clears WCAG AA in the ACTUAL render

**Source:** PO father-pass-71 (`.docs/specs/po-review.md`, 2026-07-09) — one buildable X-6 directive.
**Type:** X-6 (WCAG AA / render-vs-analytic gap). Sibling of task 196.

## Directive (verbatim gist)

196 fixed the two showcase *captions* by backing them with an opaque-dark scrim chip so
they clear AA in the shipped pixels. The SAME analytic-vs-render gap still stands on the
sibling **bottom-control chrome** on the identical spotlit surface:

- **«Tilbake» back pill** renders its white@0.96 label as a muted **grey** — brightest text
  pixel only lum 0.229 → **3.15:1** peak / **2.35:1** stroke body, well under 4.5:1. Root
  cause = 171 made `BTN_SECONDARY` a *translucent* `black@0.45` darkening overlay; over the
  bright-grass-bleeding translucent stage band it composites to only a ~grey pill, and the
  thin `font_body_bold` 17px strokes under-cover → grey ~0.23 peak. 171 pinned the
  *analytic* composite (~4.9:1), not the shipped pixels.
- **«Trener nå» non-tappable status pill** renders **4.03:1** — dark `INK` on the pale
  `commit_disabled_fill() = cfd6dd` (lum ~0.666). Just under AA in-pixel.

## Fix (reuse 196's proven opaque-backing lever on this same surface)

1. **«Tilbake» / chevron chrome:** make `BTN_SECONDARY` an **opaque** dark ink (= the
   `CAPTION_SCRIM` value, DS `INK`@1.0) instead of translucent `black@0.45`, and bump
   `BTN_SECONDARY_TEXT` to full-opaque white (was @0.96) — mirroring the caption `SUBTLE`.
   The pill is now a stable near-black base, so even the under-covered white strokes
   composite against near-black and clear AA (the render matches the analytic because the
   fill is opaque). The quiet recessed-ghost read survives — a solid dark caption-chip tag.
2. **«Trener nå» disabled pill:** lighten `commit_disabled_fill()` from `cfd6dd` (0.666)
   to a near-white muted slate `eef1f5` (~0.88) — matching the kennel 151 «Trener nå»
   precedent (dark ink on a near-white mint wash) that already clears AA in-pixel. Dark
   `INK` core on a near-white fill = ~12:1 analytic, clearing the in-pixel bar with headroom.

Keep the ghost-pill look subordinate (a quiet dark tag), the spotlight-glow translucent
band (`BAND_BG`), the titles/pips/commit-gradient as-is. NOT a revert of 171 — closes the
render gap 171's analytic fix left, exactly as 196 did for the captions.

## Tests (TDD, render-faithful)

- `BTN_SECONDARY` is opaque + near-black (the opaque-backing lever).
- the white chrome's modeled rendered peak (~0.46 lum, thin-stroke under-coverage) clears
  AA on the opaque pill.
- `BTN_SECONDARY_TEXT` is full-opaque white.
- disabled fill is a near-white pale tone (lum ≥ 0.82, kennel precedent) so the dark ink
  clears AA in-pixel; analytic INK-on-fill has render headroom (≥7:1).
- existing ghost-pill/disabled-ink asserts stay green.

## Root cause found in-pixel (the opaque scrim alone was NOT enough)

First cut (opaque `BTN_SECONDARY` scrim only) still rendered «Tilbake» a muted GREY —
in-pixel peak lum **0.20 → 3.49:1** (`.screenshots/P197-tilbake.png`). Root cause is the
SAME one 196 diagnosed for the captions: the `_make_button` chrome used the THIN Nunito
`font_body_bold()` face at 17px, whose strokes are sub-pixel on the GL/SwiftShader path —
no rendered pixel of the white label reaches full white. 196's fix was opaque scrim **+**
the THICK Baloo `font_display()` face; I had only applied the scrim half.

Final fix: added an optional `display_face` arg to `_make_button` and passed it for the
back + cycle buttons → they now use `font_display()`. In-pixel after: «Tilbake» peak
**0.758 → 11.17:1**, 99th-pct **4.62:1** (crisp white, `.screenshots/P197-tilbake.png`).
Pips keep the body face (unchanged). Chevrons are drawn polygons (full-coverage) so they
were never the grey-text problem.

«Trener nå»: fill lightened `cfd6dd`→`eef1f5` (lum 0.666→0.877). In-pixel by the PO's own
core-ink metric («brightest-dark ~0.128») now **~4.7–5.5:1** (was 4.03), darkest-core
**7.21:1** — clearly legible dark charcoal on the near-white pill (`.screenshots/P197-trener.png`).

## Verify
- `nix develop -c bash verify.sh` GREEN (import·boot·test·export); 868 tests, 0 failures
  (+5 new asserts). Zero console errors in the served-build capture.
- In-pixel capture (headless Chromium 390×844, served `build/web`, `env -u LD_LIBRARY_PATH`)
  confirms «Tilbake» 11.17:1 peak / 4.62:1 99th-pct and «Trener nå» ~4.7–5.5:1 core — both
  clear AA in the ACTUAL render.
