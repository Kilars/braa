# 168 — Completion menu: unify the active/selected badge INK across all four sections (X-4)

**Source:** PO Review 2026-07-07 (father pass 33), the one filed directive.

## Directive
After 167 gave all four completion-menu selection sections (tricks·breeds·words·difficulty)
the SAME pale-blue active-row *wash*, the active-row *badge ink* was the last cross-section
inconsistency: the active TRICK badge «Trener nå» drew in the dark current-state ink
(`ROW_ACTIVE_INK #141c26`, the kennel 151 / menu 152 treatment), but the active BREED «Aktiv»
(`BADGE_LEARNED`), active WORD «Aktiv» (`BADGE_LEARNED`), and SELECTED difficulty «Valgt»
(`DIFF_NAME_ACTIVE`) badges all drew in the SAME action-blue (`BLUE_INK`) as the tappable
«Tilgjengelig»/«Bytt» badges (`BADGE_AVAILABLE` is also `BLUE_INK`) — so on three of four
sections the "you are here" state marker read identically to an "available/actionable" one.

Fix: route every active-state badge through one shared `BADGE_ACTIVE` token = `ROW_ACTIVE_INK`.
Keep the section NAME colours (identity) unchanged; change only the active-state badge ink.

## Change
- `scripts/trick_menu.gd`: new `const BADGE_ACTIVE := ROW_ACTIVE_INK`. Repointed the four
  active-state badge draw sites onto it — trick `_draw_row` :921, breed `_draw_breed_row`
  ACTIVE :973, word `_draw_word_row` ACTIVE :1061, difficulty `_draw_difficulty_row`
  unlocked-active «Valgt» :1119 (+ its `badge_col` default). Cooling word «Hviler» stays
  SLATE_SOFT; OWNED «Bytt» / UNLOCKED «Bytt» stay `BADGE_AVAILABLE` blue (they ARE tappable
  actions); locked-active difficulty «Låst» stays `DIFF_NAME_LOCKED`.
- `tests/test_trick_menu_active_badge.gd`: 4 TDD asserts — `BADGE_ACTIVE == ROW_ACTIVE_INK`;
  distinct from `BADGE_AVAILABLE`/`BADGE_LEARNED`; reads darker than the action-blue on the
  wash; clears AA (≥4.5:1) on `ROW_BG_ACTIVE`.

## Result
TDD red (BADGE_ACTIVE missing → parse error) → green. 773 tests, 0 failures. Verify gate green.
Contrast improves, not regresses: `ROW_ACTIVE_INK` on `ROW_BG_ACTIVE` ~14.7:1 vs the blue's
4.93:1 — dark reads stronger as "current selection". Completes the 151/152/167 "read as one
system" arc on the badge. Headless harness can't accumulate mastery to reveal the word/
difficulty sections in pixels (known SwiftShader limit), so those two are covered by
construction + test, per the PO's own fallback.
