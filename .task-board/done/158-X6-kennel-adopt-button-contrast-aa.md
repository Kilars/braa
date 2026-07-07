# 158 — X-6: kennel adopt button clears WCAG AA in all three states

**Source:** PO father-pass-22 (`.docs/specs/po-review.md`, HEAD `9f5ac36`). The kennel
inspect-modal **adopt button** — the modal's primary CTA, the whole point of the kennel —
fails WCAG AA in **all three** of its states. It is the one button the long 149→156 AA
sweep never measured, because it uses its own flat `C_ADOPT_*` fills, not the deepened
`GRAD_PILL_*` gradient the BRA / «Fortsett treningen» CTAs got at 153.

Measured (PO, near-native deviceScaleFactor-3 crops):
- **Affordable** — white on flat `C_ADOPT_BLUE #4a90e2` (`kennel_screen.gd:1591`) = **3.29:1**.
- **Unaffordable** (the default a fresh 0-coin player sees on 6/8 dogs) — `C_INK_SOFT #5a6b7d`
  on `C_ADOPT_DISABLED #c3cdd6` (`:1605`/`:1625`) = **3.4:1**.
- **Free-adopt** (Trulte «Adopter gratis ♥») — white on coral `C_ADOPT_FREE #ff7a85`
  (`:1698`) = **2.51:1** (worst offender).

The label is `T_BODY` 15px → below the large-text threshold → full 4.5:1 bar applies.

## Fix (token repoints reusing the sweep's established patterns — no owner asset)

1. **Affordable:** repoint `C_ADOPT_BLUE` to the DS deep-pill blue `#24589a`
   (= `DesignSystem.GRAD_PILL_BOT`, the deep face of the 153 primary-CTA gradient) so white
   clears AA at ~7.1:1 and the kennel CTA shares the app's primary-CTA blue palette. Stays
   solid blue identity.
2. **Unaffordable:** keep the muted-grey `C_ADOPT_DISABLED` *fill* (the correct disabled
   signal) but darken the *text* from `C_INK_SOFT` to the shared dark tag ink `C_TAG_INK
   #141c26` (the same ink 149/151 use for kennel badges/status) → ~10.6:1. Coin pip stays gold.
3. **Free-adopt:** keep the coral `C_ADOPT_FREE` identity (matches the «Påskeegg» tag) but put
   the shared dark ink `C_TAG_INK` on it — exactly what the «Påskeegg» badge already does on
   this same coral (`test_kennel_badge_contrast` already proves `C_TAG_INK` on `C_STATUS_EGG`
   ≥ 4.5:1). Both the label and the drawn `_HeartPip` switch to `C_TAG_INK` (add a `tint`
   property to `_HeartPip`, default white so no other caller changes).

## TDD
`tests/test_kennel_adopt_button_contrast.gd` — assert each state's (text, fill) pair clears
4.5:1 via `KennelScreen.wcag_contrast`, and assert the OLD pairs were below the bar (documents
the regression). RED before, GREEN after.

## Done when
verify gate green; placeholder check clean; committed + pushed.
