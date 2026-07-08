# 186 — X-6: completion-menu section subheadings clear WCAG AA

**Source:** PO father-pass-60 (`.docs/specs/po-review.md`), one buildable X-6 directive.

## Directive
The three completion-menu **section subheadings** — «Raser» (breeds), «Merkeord»
(marker words), «Vanskelighet» (difficulty) — rendered at `DesignSystem.SLATE_SOFT`
(#8a97a4) = **2.87:1 on the PAPER card** — a WCAG AA fail. They are meaningful active
labels naming each menu section, not disabled chrome, so the disabled-text exemption
does not apply. This is the same grey-on-light miss the kennel already fixed (task 156,
`C_MUTED`→`C_INK_SOFT`) but never applied to `trick_menu.gd`.

## Fix
Repoint `BREED_SUBHEAD` / `WORD_SUBHEAD` / `DIFF_SUBHEAD` (`trick_menu.gd:243/256/260`)
from `SLATE_SOFT` to `DesignSystem.SLATE` (#5a6b7d) — the identical Ink-Soft token the
kennel uses and the menu's own body text (`WORD_COST_HINT` / `DIFF_NAME_IDLE`) already
uses. Measured **5.28:1 on PAPER / 4.78:1 on CREAM** — clears AA, stays clearly
secondary. Locked-row `SLATE_SOFT` names/badges left as-is (intentional disabled
styling, WCAG-exempt).

## TDD
`tests/test_trick_menu_contrast.gd` — added:
- `test_section_subheadings_clear_aa_on_paper` (the three subheads ≥4.5:1 on PANEL_BG/PAPER)
- `test_slate_soft_subhead_baseline_failed_before` (SLATE_SOFT < 4.5:1 — the bug)
- `test_locked_row_labels_stay_soft` (NAME_LOCKED / BADGE_LOCKED stay SLATE_SOFT)

## Verify
Full gate green (import · boot · test · export).
