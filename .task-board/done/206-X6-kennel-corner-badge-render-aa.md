# 206 — X6: kennel rarity/owned CORNER BADGE labels render below WCAG AA in-pixel

**Source:** PO father-pass-83 (`.docs/specs/po-review.md`, 2026-07-09, HEAD `4766d71`) — one buildable X-6.
**Type:** FIX / accessibility (render-floor AA). Phase 8 kennel polish. Tail of the 200→205 thin-stroke render-wash arc.

## What the PO saw (their own pixels)
The kennel rarity/owned **corner badge** labels — «Din hund» (green) / «Episk» (violet) /
«Sjelden» (blue) / «Vanlig» (slate) / «Påskeegg» (coral) — are the LAST un-outlined dark-token
text left by the whole 200→205 arc. Measured in the shipped 390×844 SwiftShader render:
- Bella «Din hund» darkest `[66,136,75]` vs green fill `[87,184,92]` → **1.73:1**
- Nova «Episk» `[107,89,150]` vs violet `[155,123,212]` → **1.77:1**
- Balder/Sol «Sjelden» blue → **1.79 / 1.77:1**
- Pontus «Vanlig» slate + Trulte «Påskeegg» coral wash (lighter fills, less extreme, still washed)
- Modal corner badge «Episk» carries the identical wash → **1.81:1** (same `_make_tag`).

Controls that pass beside them: 203 subtitles 5.48:1, «Kennelen» header 11.44:1 — so this is the
**one specific** un-swept text tier, not a blanket wash.

## Root cause
`kennel_screen.gd` `_make_tag()` (line ~975): BOTH badge-label branches — the secret star-pip
label (~1008–1014) and the buyable/owned label (~1016–1022) — set `font_color = C_TAG_INK` but
NEITHER has an `outline_size` / `font_outline_color` override. At 10px bold Nunito the strokes reach
only ~0.60 coverage, so the analytically-AA dark ink (149: green ~6.9:1, violet ~5.1:1, blue ~5.2:1)
renders a mid-tone blend under AA. Task 149 verified only ANALYTICALLY — the same analytic-vs-render
trap the whole arc has been busting one surface at a time. Grid (line ~705) and modal (line ~1352)
share this one `_make_tag`, so both wash from a single cause.

## The fix (reuse the exact arc lever)
Route both `_make_tag` badge Labels through the existing `_apply_ink_outline(lbl, C_TAG_INK)` helper
(same-colour `outline_size = SOFT_INK_OUTLINE` + `font_outline_color = C_TAG_INK`) so they render
their true dark token. The dark ink on each accent is analytically 5–7:1, so the outline alone is
sufficient — **do NOT change any accent fill or badge colour identity**.

## Keep exactly (PO constraints)
- accent HUES (green owned / coral secret / slate·blue·violet rarity) — no recolour
- corner position, pill shape + radius, the star pip, the 149 dark-ink token
- every badge WORD (199 «Din hund»/«Påskeegg» parity)
This is an ink/render-coverage fix only — not colour, layout, or wording.

## TDD (mirror test_kennel_secondary_text_render.gd)
- badge ink C_TAG_INK washes under AA at 0.60 coverage on the darker accents (regression pin)
- SOFT_INK_OUTLINE > 0
- outline-restored full-coverage clears AA on every accent
- WIRED: instantiate `_make_tag` for buyable / owned / secret rows; assert the badge Label carries
  `outline_size == SOFT_INK_OUTLINE` and `font_outline_color == C_TAG_INK`, covering BOTH branches.

## Done when
verify.sh green (import·boot·test·export); placeholder check clean; committed + pushed.
