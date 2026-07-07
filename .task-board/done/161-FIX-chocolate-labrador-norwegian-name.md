# 161 — FIX: chocolate Lab breed name → Norwegian, un-elided in «Raser» menu

**Source:** PO father-pass-26 (`.docs/specs/po-review.md`, HEAD `5050877`). One buildable directive.

## Problem
The adoptable second breed rendered its **English** display name `"Chocolate Labrador"`
(`scripts/breed_personality.gd:52`) in the completion menu's «Raser» section — the ONE English
string left in an otherwise 100%-Norwegian menu — and, being long, `trick_menu.gd:946` `_elide()`d
it to «Chocolate…» (trailing ellipsis, identifying word dropped) right beneath the un-elided
«Labrador» active row. Both a localization slip (class of 138/157) and a typography defect.

## Fix (display-only, one string)
`breed_personality.gd:52` display name `"Chocolate Labrador"` → **`"Brun labrador"`** (13 chars,
same short band as the yellow «Labrador» = 8 chars; the fully-correct «Sjokoladelabrador» is 17 —
LONGER than the English — and would still truncate, so a short form is required per the PO). The
`id` stays `"chocolate_labrador"` (roster/save/resolve untouched). The single display-name field
feeds both the «Raser» menu row and the breed showcase, so one change fixes both.

## TDD
`tests/test_breed_personality.gd::test_chocolate_labrador_display_name_is_norwegian_and_short`
(3 asserts: no ASCII "Chocolate", no "Labrador" (mixed-string) spelling, length ≤ 13) — RED (3 fails)
before, GREEN after. id-unchanged assert guards the display-only scope.

## Verify
Full gate green. In-pixel: «Brun labrador» renders complete (no ellipsis) in the «Raser» row and
the showcase.

Do NOT change the `id`, coat tint (076), or temperament — display-only.
