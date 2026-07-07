# 145 — Training progress readout must read on the bright sky (PO father-pass-10, X-4/X-6)

**Source:** `.docs/specs/po-review.md` — PO Review 2026-07-07 (father pass 10), Improvement 1.
**Phase:** 6 (signed) — cross-cutting polish directive (X-4 typography/legibility + X-6),
permitted on a signed surface by the polish lens. No owner asset. Preempts the terminal idle.

## The gap (measured by the PO)

Task 143 brightened the sky; the training progress readout (`LearnedBar`) now washes into it
and is effectively illegible (`.screenshots/ZOOM-hud.png`, `PO9-01/03`):
- «Sitt» label sampled `(151,192,237)`, track `(153,193,239)`, «%» `(151,191,236)` — all within
  a few points of bare sky `(168,197,228)`. Not a 0%-fill artefact (identical on both frames).
- The bright sun disc (143) sits **right behind the bar** and bleaches its midsection to
  `(192,201,188)`.

Root cause in `scripts/learned_bar.gd`: the label/% are drawn in mid-grey `SLATE`/`SLATE_SOFT`
(low contrast on the pale sky), and the track is `BORDER` at **alpha 0.9** — a translucent cream
that dissolves into the sky and lets the sun bleed through.

## Goal-art target (`.docs/specs/assets/goal-training-screen.png`)

Dark slate «Sitt» label, a distinct **opaque** light track with a solid **blue** fill, a dark
legible «60 %» — all clearly readable on the pale-blue sky.

## Definition of done

- Label «Sitt» and «%» rendered in dark DS ink (AA on the sky, ≥~4.5:1).
- Track is an **opaque** light DS surface (a defined rail), not a translucent cream that
  dissolves — blue fill unchanged, gold mastery latch unchanged.
- Sun no longer bleaches the readout (opaque track + a subtle light scrim behind the readout so
  the label text also has backing / matches the goal's soft top halo).
- TDD: render-free assertions on the styling constants (label dark, track opaque+light, scrim
  present). Verify gate green. Visual Review vs goal art on a 390×844 capture.
