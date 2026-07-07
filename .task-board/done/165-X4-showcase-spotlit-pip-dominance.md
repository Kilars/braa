# 165 — X-4: breed showcase — the SPOTLIT (previewed) pip must read as the dominant selection

**Source:** PO father-pass-30 (`.docs/specs/po-review.md`, HEAD `412ceff`). One buildable directive.
Polish-lens: hierarchy / wrong selected-state.

## What the PO saw
With 2 owned dogs, cycling ▶ to spotlight «Brun lab» (chocolate Labrador): the 3D stage re-tints
brown, the title reads «Brun lab», «Tren denne» goes enabled-blue — all correct. **But in the pip
row the «Labrador» pip is a solid bright-white pill with bold dark text while the spotlit «Brun lab»
pip is a faint translucent chip** — visually identical to how it looked when NOT spotlit. The eye is
pulled to the dog you are *not* previewing.

## Root cause (read in `scripts/breed_showcase_view.gd:307-320`)
- Pip fill is keyed to **active** (`PIP_ON` solid PAPER for `id == _active`).
- The only thing marking the **spotlit** pip is `add_theme_constant_override("outline_size", 2)` with
  **no `font_outline_color` set** (line 316-317) → over the dark INK band that 2px outline is
  imperceptible. The stale comment even still says "the active one gold, the spotlit one outlined".

## Fix
Re-key the dominant fill to **spotlit** (the current selection), and give the **active** dog a quiet,
band-adaptive marker so the two states never compete:
- **Spotlit pip** → solid bright `PIP_ON` (PAPER) + dark `PIP_ON_TEXT` (INK) — the dominant selection,
  AA-clear.
- **Non-spotlit pip** → faint `PIP_OFF` + white text.
- **Active dog** → a small drawn "aktiv" dot (a `ActiveDot` child, like the drawn `Chevron`/coin —
  never a font glyph), colour ADAPTS to the pip background: dark `BLUE_INK` on the bright spotlit
  pill, light `BLUE_LIGHT` on the faint-over-dark-band pill. Blue echoes the trick-menu ACTIVE row +
  BRA primary (one system).
- Remove the invisible `outline_size` override + fix the stale comment.
- When spotlit == active (default single-active view) the pip is BOTH the solid dominant fill AND
  carries the active dot — reads cleanly as both.

## TDD
- `tests/test_breed_showcase_view.gd`: spotlit pip carries the solid dominant fill / non-spotlit active
  pip is faint (not the reverse); active pip mounts a quiet `ActiveDot`, spotlit-non-active does not;
  spotlit==active reads as both.
- `tests/test_breed_showcase_contrast.gd`: the adaptive active-dot colour clears the ≥3:1 UI-graphic
  bar on BOTH its intended backgrounds (BLUE_INK on PAPER, BLUE_LIGHT on INK), and the two differ.

## Verify
`nix develop -c bash verify.sh` green. No pip below 4.5:1; previewing a non-active dog makes ITS pip
the obviously-selected one, active stays quietly flagged.
