# 154 — X-6: completion-menu blue-on-light text clears WCAG AA

**Source:** PO father-pass-18 (`.docs/specs/po-review.md`, HEAD `58d78c9`). The last blue-on-light
menu text the 149→151→153 AA sweep left behind fails WCAG AA:
- «Gi tilbakemelding» ghost/secondary button label — `DesignSystem.BLUE` on PAPER ≈ **2.93:1**
- «Tilgjengelig» availability badges — `DesignSystem.BLUE` on CREAM ≈ **1.66:1**
- siblings all `DesignSystem.BLUE` on CREAM: `NAME_LEARNED`, `BADGE_LEARNED`, `BREED_NAME_ACTIVE`,
  and (same pattern, PO principle "every blue-on-light menu label ≥4.5:1") `WORD_NAME_ACTIVE`,
  `DIFF_NAME_ACTIVE`.

**Finding worth recording:** the PO suggested repointing to `BLUE_DARK` (`#2f6fbf`), but measured
`BLUE_DARK` on CREAM (`#f4efe6`) is only **4.42:1** — UNDER the 4.5 AA bar (the PO's 4.7 estimate was
optimistic). It clears on PAPER (4.88) / white but NOT on the CREAM row fill. So `BLUE_DARK` would be a
hollow fix for the CREAM badges. Add a dedicated DS token `BLUE_INK` (`#2a66b3`) = AA-legible blue text
on light (CREAM 5.02 / PAPER 5.55 / white 5.75), keeping BLUE (fills/identity) + BLUE_DARK (button depth /
cottage door) untouched.

**Plan (TDD):**
1. `design_system.gd`: add `BLUE_INK := Color("2a66b3")`.
2. `test_design_system.gd`: assert `wcag_contrast(BLUE_INK, CREAM) >= 4.5` and on PAPER; assert
   `BLUE` on CREAM is the sub-AA failing baseline.
3. `test_trick_menu_contrast.gd` (new): assert every blue-on-light menu token clears AA on its fill.
4. `trick_menu.gd`: repoint `NAME_LEARNED`, `BADGE_LEARNED`, `BADGE_AVAILABLE`, `SECONDARY_TEXT`,
   `SECONDARY_OUTLINE`, `BREED_NAME_ACTIVE`, `WORD_NAME_ACTIVE`, `DIFF_NAME_ACTIVE` → `BLUE_INK`;
   rebase the cooling-word dim (line ~1005) on `BLUE_INK` for hue coherence.

Keep the 152 ACTIVE row (dark-ink on pale-blue wash) + 153 primary CTA exactly as-is.
Blue identity kept — `BLUE_INK` is still clearly blue, just AA-legible on light.
