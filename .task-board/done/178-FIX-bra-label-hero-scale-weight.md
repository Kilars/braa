# 178 — FIX: BRA button label scaled + weighted to read as the hero (PO father-pass-47 X-6)

**Source:** `.docs/specs/po-review.md` — PO Review 2026-07-08 (father pass 47), Improvement X-6.

## Problem
The primary «BRA» button label is under-scaled and under-weight vs the goal art
(`.docs/specs/assets/goal-training-screen.png`). The blue pill fills ~87% of screen
width (good), but the white «BRA» glyph run is only ~46px of 390 (~12% screen width)
at Baloo 2 **SemiBold** (wght 600), `T_DISPLAY = 52`. The goal art's «BRA» is a chunky,
oversized, extra-bold display label filling ~65px of 359 (~18% screen width) with a
visibly heavier stroke — roughly 1.5× wider / ~30% taller. The label reads timid, like a
secondary caption, not the one hero tap the whole game is built around. The 126/153 work
fixed the button gradient/shape/contrast but never scaled the *label*; the 129→176 sweeps
only measured colour/contrast, so the size/weight gap slipped.

## Fix (decoupled — nothing else moves)
- `T_DISPLAY` is BRA-only → bump `52 → 74` (≈1.42×). `font_display()` (wght 600) is shared
  across 8 surfaces (menu / coin readout / kennel titles / showcase) so its weight must NOT
  change globally. Add a dedicated **`font_display_black()`** = Baloo 2 **ExtraBold (wght 800)**
  and point ONLY the BRA button at it.
- Keep the deep-blue gradient, 3D lip, and AA-clear white ink from 153 untouched — only the
  glyph scale + weight change.
- Ring clearance holds: `WORD_HALF_WIDTH = 90` and resting ring radius ≈ 99px; the «BRA» glyph
  half-width at 74px ExtraBold (~70px) stays under both, so the apex ring still frames the
  word (no ring-marker change). Stale "font_size 96" comment corrected.

## Tests (TDD)
- `test_design_system.gd`: `T_DISPLAY == 74`; `font_display_black()` non-null Font, distinct
  from `font_display()`, ExtraBold; BRA size > T_TITLE.
- main.gd BRA button uses `font_display_black()` + `T_DISPLAY`.

## Done
verify GREEN; fresh 390×844 capture shows the white-pixel «BRA» box near the goal's ~18%
screen-width mark.
