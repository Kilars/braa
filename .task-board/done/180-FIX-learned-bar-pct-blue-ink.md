# 180 — FIX: learned-bar percentage readout blue (goal-art fidelity)

**Source:** PO father-pass-51 (`.docs/specs/po-review.md`, HEAD `b39dd9d`/179) — X-6 goal-art fidelity gap.

## Directive
The training-HUD learned-bar readout row draws «Sitt … 46 %» with the **percentage in
the same dark slate/ink as the «Sitt» label** (`learned_bar.gd:46` `PCT_COLOR := DesignSystem.INK`,
identical to `LABEL_COLOR` line 45). The goal art (`goal-training-screen.png`) renders the
trick name «Sitt» dark **but the «60 %» value in BLUE** — the same blue family as the fill —
giving the value a small hierarchy pop that reads as "this is your progress".

## Fix (surgical, one token)
Repoint **only** `PCT_COLOR` → `DesignSystem.BLUE_INK` (#2a66b3 — the AA-safe blue-text token
154 introduced, ~5.5:1 on the opaque 159 white PAPER panel, so it stays legible). Keep
`LABEL_COLOR` dark INK per 145; panel/track/145/159/179 untouched. The mastered (GOLD fill)
case leaves the value blue — still AA-legible on the panel and reads fine against the gold fill.

## TDD
- The existing `test_label_and_percent_are_dark_ink_for_contrast_on_sky` asserts
  `PCT_COLOR.get_luminance() < 0.20` — BLUE_INK's luminance ≈ 0.37, so that PCT assert must
  change. Split: keep the LABEL-is-dark-INK assert, add a new test that PCT is BLUE_INK and
  clears AA (≥4.5:1) on the PAPER panel.

## Done when
- verify gate GREEN, new/updated asserts pass, no regression to 145/159/179 asserts.
