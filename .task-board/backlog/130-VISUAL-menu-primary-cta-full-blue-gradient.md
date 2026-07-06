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

- [ ] "Fortsett treningen" renders with the 126 gradient/weight (full Bra-Blue `#4A90E2`, white ≥700).
- [ ] "Gi tilbakemelding" demoted to a clear secondary/ghost style, visibly lighter than the primary.
- [ ] Primary reads as the dominant action; no more hierarchy inversion.
- [ ] `DesignSystem.BLUE` / `.pill()` general tokens unchanged; gradient helper shared, not duplicated.
- [ ] Progressive disclosure (127/128) untouched.
- [ ] Visual Review PASS (phone-portrait 390×844).
- [ ] verify gate green (import·boot·test·export); placeholder check clean; committed + pushed.
