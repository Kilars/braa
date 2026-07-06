# 130 — VISUAL — Completion-menu primary CTA reads as the primary action

**Source:** PO Review 2026-07-06, directive **#7 [HIGH]** (completion menu, Phase 6 surface).
**Phase:** current-phase X-4 quality (preempts the Phase-10 owner-gate).

## What it addresses

Hierarchy inversion on the completion menu: the primary CTA **"Fortsett treningen"**
(`trick_menu.gd:161 LABEL_CLOSE`, drawn as the "primary BLUE pill" at ~line 734) renders as a
**desaturated pale blue with thin white text** — visually *weaker* than the secondary
**"Gi tilbakemelding"** pill (`LABEL_FEEDBACK`, line ~728) below it. The primary reads secondary.

The PO wants the primary CTA restyled to the **BRA-button treatment** — full Bra-Blue `#4A90E2`
with the baked gradient/weight from task 126, white text ≥700 (AA contrast) — and the feedback
pill **demoted** to a clear secondary/ghost style.

## Technical approach

Task 126 introduced the raised-blue BRA pill via `main._make_bra_pill_stylebox` (bright top →
deep bottom + darker lip + shadow), BRA-only. Reuse that same gradient treatment for the menu
primary CTA so the two primary actions match.

- **Primary CTA ("Fortsett treningen")**: draw with the 126 gradient pill treatment (bright-top
  → deep-bottom Bra-Blue `#4A90E2` + darker lip + shadow) and white Baloo-2 text at ≥700 weight.
  Factor the 126 stylebox/gradient so both BRA and this CTA share it rather than duplicating the
  gradient math (extract the helper if it is currently private to `main`).
- **Secondary ("Gi tilbakemelding")**: restyle to a clear secondary — ghost/outline paper pill
  (DS PAPER fill or transparent + Bra-Blue outline + Bra-Blue text), unmistakably lighter-weight
  than the primary. It must not compete with the primary for attention.

Before (menu draws a flat pale-blue primary pill + a similar-weight feedback pill):
```gdscript
# primary "Fortsett treningen": flat BLUE fill, thin white text  -> reads pale/disabled
# secondary "Gi tilbakemelding": similar-weight paper pill        -> competes with primary
```
After (sketch):
```gdscript
# primary: 126 gradient pill (bright top -> deep #4A90E2 bottom + lip + shadow), white >=700
# secondary: ghost pill (outline + blue text), clearly lighter than the primary
```

Keep `DesignSystem.BLUE` / `.pill()` general tokens intact (as 126 did) — the gradient is a
CTA-specific treatment, not a global token change. Do NOT touch the progressive disclosure
(127/128 hold).

## Test / review

- Pure render styling → **Visual Review**, not TDD.
- Capture the completion menu at 390×844 and confirm the primary CTA is the strongest element on
  the card and the feedback pill clearly reads secondary.

## Acceptance criteria

- [x] "Fortsett treningen" renders with the 126 gradient/weight (full Bra-Blue `#4A90E2`, white ≥700).
- [x] "Gi tilbakemelding" demoted to a clear secondary/ghost style, visibly lighter than the primary.
- [x] Primary reads as the dominant action; no more hierarchy inversion.
- [x] `DesignSystem.BLUE` / `.pill()` general tokens unchanged; gradient helper shared, not duplicated.
- [x] Progressive disclosure (127/128) untouched.
- [x] Visual Review PASS (phone-portrait 390×844). (`072-menu-open.png` @ 11:14: "Fortsett
      treningen" now a raised blue gradient pill matching the BRA button; "Gi tilbakemelding"
      demoted to a ghost pill (paper fill + blue outline + blue text). Hierarchy correct.)
- [x] verify gate green (import·boot·test·export); placeholder check clean; committed + pushed.

## Resolution

Extracted the raised-gradient bake out of `main` into a shared, size-parameterized baker on
`DesignSystem` so the BRA button (126) and the menu primary CTA now share one code path:

- `DesignSystem.gradient_pill(content_w, content_h, radius, top, bot, lip, pad, lip_h, shadow_dy,
  shadow_blur, shadow_max) -> StyleBoxTexture` (`scripts/design_system.gd`). `_sdf_round_rect` moved
  alongside it. The blue palette is homed as tokens `GRAD_PILL_TOP/BOT/LIP` (the exact goal-art
  samples the BRA bake used) and are the baker's defaults, so nothing re-hardcodes the gradient.
- `main._make_bra_pill_stylebox()` now just calls `DesignSystem.gradient_pill(...)` with the BRA
  content size (`cw`/`ch` from the BRA offsets) and the `BRA_PILL_*` constants. Those constants are
  byte-identical to the old values (and equal the new `GRAD_PILL_*` defaults), and the baker body is
  a verbatim move of the original loop → the BRA button is pixel-identical.
- `trick_menu.gd`: the "Fortsett treningen" CTA draws the shared gradient box (softer footer-scale
  lip/shadow/radius, same blue palette) instead of the flat `DesignSystem.pill(CLOSE_BG, ...)`. White
  `CLOSE_TEXT` at `CLOSE_SIZE` on `f_bold` (≥700) kept. The box is cached in `_cta_box` and rebaked
  only when `_cta_box_size` changes (never per frame). "Gi tilbakemelding" + "Vis frem hundene"
  demoted to a ghost pill (`_draw_ghost_pill`: PAPER fill + Bra-Blue hairline outline + Bra-Blue
  text) so they read clearly lighter than the CTA. `DesignSystem.BLUE`/`.pill()` untouched.

verify gate green (import · boot · test · export). Visual Review left for the main agent to capture.
