# 193 — X-6/X-4: unify the completion-menu section headings (PO father-pass-67)

**Source:** `.docs/specs/po-review.md` PO father-pass-67 (2026-07-09), one buildable X-6/X-4 directive.
Board was empty; HEAD `c77deff` (192). Pass 66's Trulte icy-blue directive (192) re-verified + pruned.

## Directive (verbatim intent)

The completion menu's three peer selection-section headings render **inconsistently**:
- **«Markørord»** draws in `f_display` (Baloo-2) at `TITLE_SIZE` = **26px** with a hairline **divider
  rule** above it — the *exact* font+size the panel's own «Triks» card title uses.
- **«Raser»** and **«Vanskelighet»** draw in `f_bold` (Nunito) at `BADGE_SIZE` = **18px** with **no**
  divider (`trick_menu.gd:788-822`; the :802 comment even names the split).

All three are peers ("pick one of these" lists inside the same paper card). Rendering one at the
panel-title font+size (with a divider the others lack) breaks the card's typographic rhythm — a mid-card
*sub*-heading reading as prominent as the whole panel title. Leftover from task 134's words-only
typography upgrade, never propagated to siblings.

**What "good" looks like (PO):** unify the three subheadings onto ONE treatment, clearly subordinate to
the «Triks» panel title. Preferred: **demote** «Markørord» to the 18px Nunito `f_bold` + SLATE the
siblings use, and make the divider treatment uniform (drop «Markørord»'s unique rule). Keep all three
SLATE/AA-clean (186); don't touch the row treatments (152/167/170) or the «Triks» card title.

## Approach

Structural unification (the "one place decides it" pattern the codebase uses for `row_fill`): route all
three section subheadings through one private `_draw_subheading(top_y, label, color)` helper drawing
`subhead_font()` (= `font_body_bold`, Nunito) at a shared `SUBHEAD_SIZE` (= `BADGE_SIZE` = 18) — so they
cannot diverge again. Demote «Markørord» accordingly + drop its divider; reduce `WORD_HEADER_H` 38→30 to
match `BREED_HEADER_H`/`DIFFICULTY_HEADER_H`, dropping the divider terms from the words geometry
(`_words_block_h`, `_word_row_rect`). The word ROW treatment (indent + pip, 134) is untouched — this is a
heading-only change. Breeds/difficulty rendering stays byte-identical (same font/size/baseline).

## TDD

New `tests/test_trick_menu_section_headings.gd`:
- word subheading band `WORD_HEADER_H` == `BREED_HEADER_H` == `DIFFICULTY_HEADER_H` (RED: 38≠30).
- shared `SUBHEAD_SIZE` == `BADGE_SIZE` and != `TITLE_SIZE` (demotion).
- `subhead_font()` == `font_body_bold()` and != `font_display()` (font-family demotion — the crux).
- the three `*_SUBHEAD` colours are equal (regression guard, stays SLATE/AA per 186).

## Done when

Test-first RED→GREEN, verify gate green, placeholder check clean, committed+pushed.

## Result (SHIPPED)

- **RED**: new `tests/test_trick_menu_section_headings.gd` referenced `TrickMenu.SUBHEAD_SIZE` /
  `subhead_font()` (not yet present) → parse-fail, 1 failure.
- **GREEN**: unified all three section subheadings onto ONE `_draw_subheading(top_y, label, color)`
  helper drawing `subhead_font()` (= `DesignSystem.font_body_bold`, Nunito) at `SUBHEAD_SIZE`
  (= `BADGE_SIZE` = 18) — «Raser»/«Vanskelighet» rendering byte-identical (same font/size/baseline),
  «Markørord» **demoted** from `f_display`/`TITLE_SIZE`(26)/divider to the shared treatment. Dropped
  the divider (`WORD_DIVIDER_H`/`WORD_DIVIDER_GAP` removed) so the section-break treatment is uniform
  (none), `WORD_HEADER_H` 38→30 to match sibling bands, and cleaned the words geometry
  (`_words_block_h`, `_word_row_rect`). Word ROW treatment (indent + pip, 134) untouched; «Triks»
  panel title, row treatments (152/167/170) untouched. Colours stay SLATE/AA (186).
- **Gate**: `verify.sh` green (import·boot·test·export); **850 tests, 0 failures** (was 846, +4).
- **Self-review capture** (`tools/po_pass67_menu.mjs` → `.screenshots/P67M-menu-full.png`, gitignored):
  menu opens with **zero console errors**, «Triks» title unchanged. The «Raser»/«Markørord»/
  «Vanskelighet» sections are progression-gated (reveal after mastery #1+word-unlock / #2 / coins —
  `MenuReveal`), so a quick autotap (Sitt 23%) doesn't surface them; the fix is structurally
  guaranteed (one shared code path) + unit-pinned. Full-reveal in-pixel review is the father PO
  pass-68's job (established cadence — pass 67 verified 192 the same way).
- Placeholder check on `scripts/` diff: clean.
