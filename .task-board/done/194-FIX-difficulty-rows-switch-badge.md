# 194 — FIX: badge selectable «Vanskelighet» rows with «Bytt» (PO father-pass-68, X-6/X-4)

## Directive (po-review.md, PO father-pass-68, HEAD 4740c31)
The «Vanskelighet» section is the only one of the four completion-menu selection
sections whose *selectable* alternate rows carry **no right-side action badge**.
Hard/Ekspert on a normal dog show their trade hint but nothing signalling they're
tappable, while the parallel «Markørord»/«Raser» switch rows all show a blue «Bytt».

## Fix
Give the selectable (non-active, non-locked) difficulty rows a right-aligned **«Bytt»**
action badge in the SAME blue action-ink (`BADGE_AVAILABLE` = `BLUE_INK`) the word/breed
switch rows use. Keep Normal's dark-ink «Valgt» current-state badge, keep the special-dog
locked «Låst» + the "why locked" note, keep the dimmed trade subtitle. AA-clean,
right-aligned at the same 14px inset as the other badges.

## Approach
- New const `DIFF_BADGE_SWITCH := "Bytt"` (== `WORD_BADGE[UNLOCKED]` / `BREED_BADGE[OWNED]`).
- Pure static `difficulty_badge(row)` + `difficulty_badge_ink(row)` so the badge text/ink
  are unit-locked (mirrors the breed/word BADGE dicts). `_draw_difficulty_row` routes
  through them.
- Selectable non-active row → «Bytt» in `BADGE_AVAILABLE`; active → «Valgt» dark; active
  locked → «Låst» grey; non-active locked → "" (still no badge — not tappable).
- TDD: `test_trick_menu_difficulty_badge.gd`.

## Done
- verify gate green, live menu capture shows «Bytt» on Hard/Ekspert.
