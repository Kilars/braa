# 153 — X-6: primary blue CTAs clear WCAG AA (BRA button + «Fortsett treningen»)

**Source:** PO father-pass-17 (`.docs/specs/po-review.md`, HEAD `0b1cd0a`), Improvement 1.
**Label:** X-6 cross-cutting contrast (signed-off Phase-1/Phase-6 surfaces).

## Defect
The game's two primary blue CTAs — the **BRA** mark button and the completion menu's
**«Fortsett treningen»** primary — render their white labels at only ~2.7:1 against a
too-light blue gradient, failing WCAG AA (4.5:1) and even the 3:1 large-text bar. The
gradient top sample `(121,176,250)` runs *lighter* than the DS `BLUE` token `#4a90e2`
itself, so the label the player taps every rep is the weakest-contrast text on screen —
incoherent after 149/151 held the small kennel badges to ≥4.5:1.

## Fix (buildable, no owner asset)
Both CTAs bake through `DesignSystem.gradient_pill` with the shared `GRAD_PILL_*` palette
(menu CTA uses the defaults; BRA button passes `BRA_PILL_*`, a duplicate of the same
values). Shift the **whole range darker** so the lightest face colour the white label can
touch still clears AA, keeping the blue identity + gradient depth + bottom lip:
- `GRAD_PILL_TOP` `(121,176,250)` → `#3472bd` (white 4.90:1)
- `GRAD_PILL_BOT` `(89,141,224)` → `#24589a` (white 7.15:1)
- `GRAD_PILL_LIP` `(61,108,188)` → `#1b4278` (deeper 3D lip)
Dedup `BRA_PILL_*` (main.gd) to reference `DesignSystem.GRAD_PILL_*` so the two dominant
actions stay one component (PO: "apply the same fix to both … so they stay one component").

## TDD
Pin with a canonical `DesignSystem.wcag_contrast` helper + asserts in `test_design_system.gd`:
white on the lightest face colour (`GRAD_PILL_TOP`) ≥ 4.5:1, bottom ≥ 4.5:1, range still
darkens top→bot (depth kept), and `main.gd`'s `BRA_PILL_TOP/BOT/LIP` == the DS tokens.

## Done when
verify green + Visual Review confirms the BRA button + menu CTA read as punchy primary
blue with legible white labels.

## Outcome (SHIPPED)
Deepened the shared `GRAD_PILL_*` palette (top `#3472bd` / bot `#24589a` / lip `#1b4278`)
and deduped `main.gd`'s `BRA_PILL_*` to reference the DS tokens — one component now, both
CTAs bake identically. Added canonical `DesignSystem.wcag_contrast` + `_rel_luminance`/`_lin`
and 5 TDD asserts (top ≥4.5:1, bottom ≥4.5:1, still darkens top→bot, BRA_PILL_*==GRAD_PILL_*,
white/black==21:1). Token contrast: TOP 4.9:1, label-region 5.9:1, BOT 7.15:1, LIP 10:1.
In-pixel on the fresh licensed bundle: BRA label region 5.64:1, «Fortsett treningen» 5.82:1
(was ~2.7:1). Verify green (import·boot·test·export), 720 tests. Visual Review PASS.
