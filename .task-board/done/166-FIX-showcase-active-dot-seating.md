# 166 — FIX: breed-showcase «aktiv» dot seats cleanly on its pip (not on the dark band)

**Source:** PO Review 2026-07-07 (father pass 31, X-4) — the one buildable directive.

## Problem

The 165 «aktiv» dot (the quiet marker for the currently-training dog on the showcase pip
row) does not sit cleanly on the pill — roughly its upper half floats **above/outside** the
pill's rounded top-right corner, painting onto the dark INK band, reading as a detached dot
rather than a badge seated on the pip.

Root cause: `ActiveDot._draw()` centres the disc at `(size.x - INSET, INSET)` = `(w-8, 8)`
with `R=4`, while the pip stylebox corner radius is `12` (`_make_button`
`set_corner_radius_all(12)`). At inset 8 the dot's centre sits inside the corner *curve*, so
part of the disc spills into the transparent rounded-corner region and paints over the band.

## Fix

Seat the dot on the pill's flat top-right region, its right edge tangent to where the corner
curve begins: centre at `(size.x - CORNER - R, CORNER)` = `(w-16, 12)` with `CORNER=12`
mirroring the pip stylebox radius. This puts the whole disc left of the right corner-curve
start (`x + R = w-12`) and below the flat top edge, so the full disc lands on the pill fill —
in BOTH the solid spotlit-pill (active-spotlit) and faint-pill (active-not-spotlit) states.
Colour/adaptive `active_dot_color()` unchanged (still AA-legible dark BLUE_INK on the bright
pill / light BLUE_LIGHT on the faint pill).

## TDD

`test_breed_showcase_contrast.gd`: new assert that `ActiveDot.center_for(size)` places the
whole disc within the flat fill region (right edge ≤ `size.x - CORNER`, top edge ≥ 0), so it
never bleeds onto the band — RED on the old `(w-8, 8)` inset, GREEN after.

## Done when

- New seating test GREEN; existing showcase tests still GREEN.
- verify gate green.
- In-pixel (dsf3): the whole dot sits on the pip in both states, no bleed onto the band.
