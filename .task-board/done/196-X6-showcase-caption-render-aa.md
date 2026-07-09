# 196 — X-6: lift the breed-showcase secondary caption tier to render-AA

**Source:** PO father-pass-70 (`.docs/specs/po-review.md`, 2026-07-09).

## Directive
The breed-showcase's two `SUBTLE` captions render **sub-AA in the shipped pixels**:
- breed subtitle «Labrador» (top header band): measured **2.40:1**
- «Adopter flere hunder for å bla» hint (bottom control band): measured **2.05:1**

169 set both to `SUBTLE = white@0.92`, an *analytic* ~5.3:1, but the real render lands ~2:1
because the thin 13–15px Nunito `font_body` strokes under-cover the **translucent** `BAND_BG`
(INK@0.72) as bright grass bleeds through it, so the brightest shipped pixel never reaches the
0.92 the calc assumed. The crisp white titles (heavier Baloo display) beside them are fine.

## What "good" looks like (PO)
Both SUBTLE captions clear **≥4.5:1 verified from the actual render** while staying subordinate
to the white title. Not a revert of 169 — closes the analytic-vs-render gap and extends the fix
to the 173 header subtitle (never independently AA-checked on the top band).

## Approach (two of the PO's three levers, render-robust)
1. Add a **dark outline halo** (`CAPTION_OUTLINE = DS.INK`, `CAPTION_OUTLINE_SIZE`) to both
   caption labels (`_subtitle_label`, `_hint`) so every thin glyph stroke composites against a
   stable opaque-dark base, not the bleeding translucent band — the render fix.
2. Nudge `SUBTLE` to **full-opaque white** so the glyph body itself lands at white (subordination
   now via the smaller body font + halo, not a lowered alpha).
Pure helper `caption_ink_over_outline()` pins the render-robust worst case for the test.

## Done when
- TDD: caption ink clears AA over its dark outline; outline is real + dark; SUBTLE opaque;
  both caption labels carry the outline theme override.
- verify gate green; no regression to 169/171/173 chrome.
