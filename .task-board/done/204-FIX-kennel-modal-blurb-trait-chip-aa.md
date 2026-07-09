# 204 — FIX: kennel modal blurb / unique-trait value / trait chips clear WCAG AA in-pixel

**Source:** PO father-pass-81 (`.docs/specs/po-review.md`) X-6 (Bugfix / AA).

**Type:** Bugfix / AA render-coverage. Tail of the 200/201/202/203 thin-stroke
render-wash arc — the last modal text tier still on the bare no-outline `Label` path.

## What the PO saw (shipped 390×844 SwiftShader pixels)
The 203 sweep lifted the kennel modal's `C_INK_SOFT` labels (stat labels, section
headings, captions) but three text elements beside them stayed washed:
1. **Personality BLURB** (`_build_modal_blurb`) — `C_INK` token, no `outline_size` →
   renders 1.76–3.00:1.
2. **«Unikt trekk» VALUE** (`_build_modal_unique_trait` trait_lbl) — `C_INK`, no
   outline → 1.76–2.32:1.
3. **Raseegenskaper trait CHIPS** (`_build_modal_traits`) — `C_TRAIT_INK` on
   `C_TRAIT_BG`, no outline → ~1.62:1 (external sampler flagged the token itself at
   3.71:1; project `wcag_contrast` reads the old token at 4.92, a thin margin).

## Root cause
Identical to the arc: at `T_BODY`/`T_SMALL` a bare `Label` reaches only
~`NAV_STROKE_COVERAGE` (0.60) stroke coverage, so even the dark `C_INK` (analytic
~11:1) render-floors to ~3.5:1. Even a near-black blue only reaches 3.63:1 at 0.60
coverage — so the **outline** (restoring ~full coverage) is the decisive lever; the
trait token also gets a small **deepen** for analytic margin.

## Fix
- Generalize the 203 helper: `_apply_ink_outline(lbl, ink)` sets `font_color` +
  same-colour `outline_size = SOFT_INK_OUTLINE` + `font_outline_color`. `_apply_soft_ink`
  delegates to it (203 behaviour byte-identical); add `_apply_dark_ink` = C_INK.
- Route the blurb + unique-trait-value through `_apply_dark_ink` (renders true C_INK).
- Deepen `C_TRAIT_INK #3a6a9a → #285681` (still blue-family, ~6.66:1 analytic) and route
  the chip label through `_apply_ink_outline(chip_lbl, C_TRAIT_INK)`.

Keep every layout, font size, wording, the pale-blue chip identity, the cream Unikt-trekk
card, 149 badges, 117 coats, 162 pips exactly. Ink/render-coverage fix + one token deepen.

## Test (TDD)
`tests/test_kennel_modal_text_render.gd` — render-floor wash pins (< 4.5 @ 0.60 cov),
outline-restored analytic AA (≥ 4.5), token-deepen margin guard, wired-label outline checks.

## Done
- [ ] Failing test → green
- [ ] verify.sh green
- [ ] committed + pushed

## Outcome — DONE
Shipped: `_apply_ink_outline(lbl, ink)` generalizes the 203 helper; `_apply_soft_ink`/`_apply_dark_ink` delegate. Blurb + «Unikt trekk» value routed through `_apply_dark_ink` (C_INK). `C_TRAIT_INK` deepened `#3a6a9a → #285681` (blue-family, 6.66:1 analytic) and chip label routed through `_apply_ink_outline(chip_lbl, C_TRAIT_INK)`. 7 TDD asserts in `tests/test_kennel_modal_text_render.gd`, verify gate GREEN (import·boot·test·export).
