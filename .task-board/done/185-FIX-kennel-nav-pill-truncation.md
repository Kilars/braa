# 185 — FIX: widen the «Kennel» HUD nav pill so its label stops truncating to «Kennel.»

**Source:** PO Review — 2026-07-08 (father pass 58), X-6 directive (`.docs/specs/po-review.md`).
**Type:** cross-cutting polish (X-6), buildable, single-surface.

## Problem
On the training HUD the «Kennel» nav pill renders **«Kennel.»** — an overrun ellipsis, because the
pill was pinned to a bare hard-coded **96 px** (`main.gd:2195`, `... + 96.0`), too narrow for the
6-char label at `T_HEAD` (Baloo 2 bold 18) once internal side padding is subtracted. Its sibling
«Triks» pill had already been widened to `TRICKS_BTN_WIDTH := 128.0` for exactly this class of bug;
the Kennel pill never got the same treatment.

## Fix
- New named `const KENNEL_BTN_WIDTH := 118.0` beside `TRICKS_BTN_WIDTH` (parity + documented).
  Glyph-less, so narrower than Triks's 128 but clearly wider than the old 96.
- `main.gd:2195` `offset_right` bumped off the magic `96.0` onto `KENNEL_BTN_WIDTH`.
- No copy change (label was already "Kennel", no period), no colour/behaviour change.

## Tests (TDD, `tests/test_hud_kennel_pill_width.gd`)
Font-accurate width guard (mirrors `test_breed_personality`'s un-elided name check — measures the
real glyph run, would have caught the 96 px elision):
- pill width ≥ measured «Kennel» width + balanced side padding (no ellipsis)
- pill width > old truncating 96 px (regression guard)
- glyph-less pill narrower than the glyph-bearing «Triks» pill (named const, not a copy)

## Verify
`nix develop -c bash verify.sh` — green (import·boot·test·export). 819 → tests, 0 failures.
