# 115 — VISUAL: Kennel grid must fill the portrait (polish gate)

**Type:** VISUAL / polish
**Phase:** 8 (kennel) — current
**Story:** K-1 / Phase-8 Visual-Review acceptance ("`polish` pass has been run and independent review confirms it on the running build")
**Source:** PO Review 2026-07-05 (`po-review.md`, HEAD `f5b8efb`) — the **one** remaining directive keeping Phase 8 off the sign-off line.

## What it addresses

The father re-played the whole kennel spine and confirmed **every K story built and clean in
pixels** (grid dog renders, K-6 star, K-2 modal, K-3 gate, K-4 adopt, K-5 switch, K-7 persist,
no regression). The **only** blocker to sign-off:

> **The grid feels cut off — bottom ~40 % of the screen is dead grey.** With 8 cells in 4 rows
> the roster fills only the top ~55 % of the 844 px screen; everything below Trulte is a flat
> empty panel (`po-k-01-grid.png`). It reads as *unfinished / content-failed-to-load*, not a
> finished screen. Phase 8's Visual-Review acceptance explicitly requires the `polish` pass to
> have been run and independently confirmed on the running build — that bar is not yet met.
> **Not owner-gated** (pure layout).

## Why prioritized now

It is the sole current-phase buildable gap; every other Phase-8 residual (distinct breed MODELS,
camera-facing signature CLIPS) is owner-gated and already flagged (BUST-068 residual, P3-2). The
visual/rendering domain is saturated, but the saturation filter is overridden because this is the
**only** remaining gap in the current phase and it directly unblocks PO sign-off.

## Technical approach

Root cause: cells are fixed-height (`btn.custom_minimum_size = Vector2(160.0, BAND_H + 72.0)`,
`kennel_screen.gd:396`, i.e. 160×184) inside a top-anchored `ScrollContainer` whose `GridContainer`
sizes to content minimum. 4 rows × 184 + gaps ≈ top of the screen, leaving the lower portrait grey.

Run `/polish` on the kennel and make the 8-dog roster **fill** the 390×844 portrait with no large
dead panel, keeping the cool clinical read and at-a-glance legibility. Prefer sizing the cell/band
height so 4 rows span the available height over merely centering (centering would just move the grey
band, not fill the screen). Candidate levers — the polish pass picks the combination that reads best:

- Raise `BAND_H` (currently `112.0`) and/or the footer height so each cell grows; recompute the
  cell min-height from a single derived height rather than the literal `BAND_H + 72.0`.
- Derive the target cell height from the viewport: available = `844 - HEADER_H - GRID_PAD` minus the
  3 inter-row gaps, divided by 4 rows, so the grid exactly spans the portrait on a phone.
- Keep the portrait silhouette bottom-anchored and correctly scaled inside the taller band (no
  stretching — the baked `dog_portrait.png` must still read as a dog, tinted per band).

Before → after (illustrative — the polish pass tunes the exact number/derivation):

```gdscript
# before — fixed cell height, 4 rows leave the lower ~40% grey
btn.custom_minimum_size = Vector2(160.0, BAND_H + 72.0)
```

```gdscript
# after — cell height derived so 4 rows fill the portrait (constant homed, no scattered literal)
const FOOTER_BLOCK_H := 72.0
const GRID_ROWS := 4
# fill the viewport below the header: 4 rows + 3 gaps span (screen − header − pads)
const CELL_H := (844.0 - HEADER_H - GRID_PAD - (GRID_ROWS - 1) * CELL_GAP) / GRID_ROWS
...
btn.custom_minimum_size = Vector2(160.0, CELL_H)
band.custom_minimum_size = Vector2(0, CELL_H - FOOTER_BLOCK_H)
```

Do NOT regress any signed-off-ready behavior: cell tap → modal, pop-in tween, dog silhouette read,
name/breed/price/tag legibility, the K-6 easter tag. Keep colors homed in the existing `C_*`
constants (no scattered `Color(...)` literals).

## Testing / verification

Pure layout/rendering → **Visual Review**, not TDD. If a cell-height helper is extracted as a pure
value it may get a cheap assert, but the acceptance is pixels:

1. `nix develop -c bash verify.sh` green (import·boot·test·export).
2. Capture the kennel at 390×844 in headless Chromium against a fresh `build/web` (reuse
   `tools/web_capture_kennel*.mjs` pattern) — grid open, from the training page.
3. Independent review agent(s) on the phone-portrait screenshot confirm the 8-dog grid **fills the
   portrait** — no large empty grey panel below the last row — while staying legible and clean.
4. Confirm no regression: cell tap still opens the modal; training page intact after close.

## Outcome (2026-07-05)

Root cause: the project stretches `canvas_items` with `aspect="expand"` over a 720×1280 design, so
on a 390×844 phone the **logical** viewport height expands to ~1558. The fixed `BAND_H + 72 = 184`-unit
cells rendered at `184 × 0.54 ≈ 100 px`; 4 rows filled only ~52% of the ~1474 available logical units
→ the PO's "dead bottom 40%".

Fix (`scripts/kennel_screen.gd`): cell height is now **derived from the live logical viewport**
(`_viewport_h()` via `get_viewport().get_visible_rect()`, with `size.y` / `DESIGN_VP_H` fallbacks) so
the `ceil(dogs/GRID_COLS)` rows exactly span `viewport − header − pad − gaps` (`_target_cell_h()`),
floored at the natural `BAND_H + FOOTER_BLOCK_H` for short screens. The band takes `cell_h −
FOOTER_BLOCK_H`, so a taller cell shows a bigger dog (portrait keeps `KEEP_ASPECT_CENTERED` — scaled,
not stretched, never clipped). A `resized` → `_refresh()` hook re-fits on a late layout / orientation
change. Constants homed (`FOOTER_BLOCK_H`, `GRID_COLS`, `DESIGN_VP_H`); no scattered literals.

Visual Review: `105-kennel-01-grid.png` at 390×844 against the fresh `build/web` — grid fills ~95% of
the portrait, no dead panel; 8 dogs read at a glance, names/breeds/prices/tags legible, K-6 «★ Påskeegg»
intact; `105-kennel-03-closed.png` shows the training page fully intact (no regression).

**Adjudication (memory `visual-reviewers-diverge-adjudicate`):** the review agent also FAILed on "all
8 dogs are the same rear-facing model, distinguished only by tint." Out of scope for 115 and already
PO-accepted — the shared tinted CC0 silhouette is the flagged owner-gated stand-in (BUST-068 residual +
the 2026-07-05 CC0-portrait flag); the PO's own review at `f5b8efb` calls it "honest, NOT a blocker to
sign-off." This task only scaled that existing baked portrait — no new pose, no clipping. Distinct
per-breed MODELS stay the standing owner gate, not this layout task.

## Acceptance criteria

- [x] Cell/band height derived (constant-homed, no scattered literal) so 4 rows of 8 dogs span the 844 px portrait
- [x] `/polish`-class layout pass run on the kennel grid (viewport-derived fill)
- [x] Captured 390×844 kennel screenshot shows the roster filling the portrait — no large dead grey panel below the last row
- [x] Dog silhouettes still read (bottom-anchored, tinted per band, not stretched); names/breeds/prices/tags legible
- [x] Cell tap → modal, pop-in tween, K-6 easter tag all still work (no regression — modal/tween/tag code untouched; tag renders in capture)
- [x] Training page intact after closing the kennel (no Phase-6 regression) — `105-kennel-03-closed.png`
- [x] Independent Visual Review confirms the fill directive on the running build (owner-gated model distinctness adjudicated out of scope)
- [x] `nix develop -c bash verify.sh` green
