# 205 — X-6: kennel modal «Trener nå» owned-status pill render-floor AA

**Source:** PO Review 2026-07-09 (father pass 82), `.docs/specs/po-review.md`. One buildable X-6.

## Directive (verbatim intent)
The kennel inspect-modal's non-tappable «Trener nå» owned-status pill (`_build_active_state`,
`kennel_screen.gd:~1624`) is the LAST un-outlined dark-token text on the surface. It is a disabled
`Button` whose `font_disabled_color` is the dark `C_TAG_INK` (task 151, analytic ~14.8:1 on
`active_state_fill()`) but it has **no `outline_size` override** — so it hits the identical
thin-stroke render-wash the 200→204 arc closed everywhere else: darkest stroke renders `[137,148,143]`
→ **2.70:1** on the mint pill fill despite the dark token. Task 151 was measured analytically only,
never render-floor-verified — the same analytic-vs-render trap the arc has been busting one surface
at a time.

## Fix
Reuse the exact arc lever, Button-typed: give the disabled pill Button a same-colour
`outline_size = SOFT_INK_OUTLINE (4)` + `font_outline_color = C_TAG_INK` so it renders its true dark
token (the `_apply_ink_outline` helpers are Label-typed, so apply the overrides directly on the Button).
**Audit the breed-showcase sibling active pill** (`breed_showcase_view.gd` `_make_commit_button`, its
disabled state sources fill from the same `active_state_fill()` via `commit_disabled_fill()` and sets
`font_disabled_color = COMMIT_DISABLED_INK` with no outline) — apply the identical Button outline so the
shared component stays unified.

Keep the muted non-tappable surface, the ownership-green identity, the pill shape, the 151 dark-ink
token, the K-5 semantics exactly — ink/render-coverage only.

## Done when
- `_build_active_state` Button carries `outline_size=SOFT_INK_OUTLINE` + `font_outline_color=C_TAG_INK`.
- Showcase `_make_commit_button` disabled pill carries the same outline (`font_outline_color=COMMIT_DISABLED_INK`).
- TDD render-floor test pins: token WASHES under AA at 0.60 coverage without the outline; outline present.
- verify gate green.
