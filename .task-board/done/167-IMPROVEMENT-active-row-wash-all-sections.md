# 167 — IMPROVEMENT: completion-menu active-row wash for breeds/words/difficulty

**Source:** PO Review 2026-07-07 (father pass 32, X-4), `.docs/specs/po-review.md`.

## Directive
Only the ACTIVE **trick** row got the pale-blue `ROW_BG_ACTIVE` wash (task 152); the
ACTIVE **breed**, ACTIVE **marker-word**, and SELECTED **difficulty** rows did not — the
four "read as one system" selection sections marked their current item inconsistently.
Give those three rows the **same** wash the active trick row uses. Keep each row's existing
blue name + badge word; only add the wash. Labels must stay ≥4.5:1.

## Fix
- New pure static `TrickMenu.row_fill(active, dim) -> Color` (`trick_menu.gd`) — the one
  place a row's background wash is decided: `active` → `ROW_BG_ACTIVE`, else `dim` →
  `ROW_BG_LOCKED`, else `ROW_BG`. Active always wins.
- Routed all four draw functions through it: `_draw_row` (trick, byte-identical behaviour),
  `_draw_breed_row` (`st == BreedState.ACTIVE`), `_draw_word_row` (`st == WordState.ACTIVE`),
  `_draw_difficulty_row` (`is_active`).
- Wash only sits behind the existing labels — no colour/badge change. BLUE_INK on the wash
  ≈4.93:1, still AA (verified by test).

## Tests (TDD, test_trick_menu.gd)
- `row_fill` active beats dim → `ROW_BG_ACTIVE`; dim → `ROW_BG_LOCKED`; plain → `ROW_BG`.
- BLUE_INK active-name ink on `ROW_BG_ACTIVE` clears WCAG AA.

Verify gate green.
