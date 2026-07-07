# 157 — FIX: kennel modal «Kan laere» → «Kan lære» (Norwegian æ)

**Source:** PO father-pass-21 (`.docs/specs/po-review.md`, HEAD `0a1fe35`) — the single
buildable X-6/correctness directive filed after 156 was verified landed.

## Defect

The kennel inspect modal's trick line rendered «**Kan laere**: Sitt · Ligg · Legg deg» —
the Norwegian «æ» written as a bare ASCII "ae" — sitting directly under a correctly-spelled
«Læreevne» stat label in the same modal, same Baloo 2 body font (which renders æ fine). A
plain typo, not glyph-avoidance: every other Norwegian string in `kennel_screen.gd` uses
real æ/ø/å (19 lines: «Læreevne», «Påskeegg», «Din», …). A visible misspelling on the
modal's headline data row reads as unpolished.

## Fix

One string literal — `scripts/kennel_screen.gd:1419`:
`lbl.text = "Kan laere: " + …` → `lbl.text = "Kan lære: " + …`. The two nearby comments
(`:1113`, `:1405`) already spelled it correctly, so only the runtime literal was wrong.

## TDD

New `tests/test_kennel_trick_line_spelling.gd` (3 asserts): the wired `_build_modal_trick_list`
label (a) begins with «Kan lære: » (real æ), (b) contains no ASCII «laere», (c) renders the
full «Kan lære: Sitt · Ligg · Legg deg» payload. Went red on the misspelling first, green
after the one-char fix.

## Gate

`nix develop -c bash verify.sh` → **✓ verify gate green** (import · boot · test · export),
738 tests / 0 failures. Placeholder check on the scripts diff: clean.
