# 207 — FIX: «Gratis» coral price-chip label render-floor AA (X-6, PO father-pass-84)

**Type:** Bugfix / accessibility (render-floor WCAG AA)
**Source:** `.docs/specs/po-review.md` — PO father-pass-84 (HEAD `006fee9`)
**Phase:** 8 (kennel) — signed off; this is a cross-cutting X-6 polish directive, the tail of the 200→206 render-wash arc.

## Directive (verbatim intent)

The secret «Gratis» coral price chip label (Trulte) is the LAST un-outlined `C_TAG_INK`
text the whole 200→206 arc left. `_make_price_chip` sets the dark token
(`font_color = C_TAG_INK`) on the status-word branch but **never calls
`_apply_ink_outline`**, so at 11px bold Nunito it washes to a muted maroon
`[84,53,64]` → **4.27:1** (under AA) on the coral fill `C_PRICE_FREE`, where the true
token would be **6.84:1**.

## Fix (ink/render-coverage only — NO colour/layout/wording change)

Give the status-word Label in `_make_price_chip` (the `else` branch, coral «Gratis» /
green «Din» path, ~line 1075) the same `_apply_ink_outline(lbl, C_TAG_INK)` lever the
whole arc used (same-colour `outline_size=SOFT_INK_OUTLINE` + `font_outline_color=C_TAG_INK`).
Keep the coral fill, chip shape/radius/border, the 149 dark-ink token, and «Gratis»
wording exactly.

## Guard

- **In-pixel render-floor** assert (not analytic): `render_floor_contrast(C_TAG_INK,
  C_PRICE_FREE, NAV_STROKE_COVERAGE)` washes < 4.5 (regression pin), and the instantiated
  chip Label carries the outline + C_TAG_INK outline colour.

## Done

- TDD red→green, verify gate green, placeholder-check clean, commit + push.
