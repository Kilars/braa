# 136 — VISUAL — Kennel header: solid DS band + one baseline for ✕ / title / coin

**Source:** PO Review 2026-07-06 (father pass 2), directive **#2 [LOW]** (kennel).
**Phase:** current-phase X-4 quality (preempts the Phase-10 owner-gate).

## What it addresses

`105-kennel-01-grid.png` / `-02-scroll.png` — the «Kennelen» title, its faint «Profesjonell
fasilitet · 8 plasser» subtitle, the close «✕», and the coin pill float over the busy first grid
row with **no solid band** clearly separating header from cells, and the ✕ / title / coin pill
**don't share one baseline**.

**Acceptance (PO):**
- A **solid DS surface band** behind the header (reads as a distinct header, not floating over the
  top cells).
- ✕ + title block + coin pill on **one baseline**.
- Subtitle **≥12px Ink-Soft**, legible on the band rather than bleeding over the top cells.

## Technical approach

All in `scripts/kennel_screen.gd` `_build_header()` (~L275) + `_build_scroll_grid()` (~L358).

**1. Solid band (render).** The header PanelContainer already fills a `HEADER_H`(72) band with
`C_CELL` bg + a 1px bottom hairline — but the PO still reads it as floating. Firm it up: give
`hdr_style` a subtle bottom **shadow** (`shadow_color`/`shadow_size`/`shadow_offset = (0,3)`) or a
slightly stronger surface so it visually sits *above* the grid, and **confirm the ScrollContainer's
top starts at `HEADER_H`** (grep `_build_scroll_grid` — the scroll must be offset down by HEADER_H
so no cell renders under the band; if it currently starts at 0, that is the "bleeds over the top
cells" bug — set `scroll.offset_top = HEADER_H`).

**2. One baseline (render).** The header `HBoxContainer` stacks close(36px) · title_col(title+
subtitle) · coin_readout, all vertically fill/centre — but the title_col is a 2-line VBox so its
optical baseline sits above the single-line ✕ and coin. Align them: give the HBox
`ALIGNMENT_CENTER` vertical treatment (set each child `size_flags_vertical = SIZE_SHRINK_CENTER`),
and nudge the title_col so the **title's** baseline lines up with the ✕ glyph and the coin number
(the subtitle can drop below without breaking the shared baseline of the primary row). Verify by eye
in capture that ✕, "Kennelen", and the coin number sit on one line.

**3. Subtitle legibility (render).** Subtitle is `T_SMALL`(13, ≥12 ✓) in `C_MUTED`; switch its
colour to the explicit Ink-Soft `#5A6B7D` (reuse the `C_INK_SOFT` token added in 135, or add it if
135 hasn't landed) so it reads on the band. Keep it centred under the title.

Pure render glue — **Visual Review**, no logic branch, no TDD.

## Definition of done
- `nix develop -c bash verify.sh` green.
- Visual Review at 390×844 (grid + scrolled): a clearly solid header band, no cell bleeding under
  it, ✕ / «Kennelen» / coin number on one baseline, legible Ink-Soft subtitle.
- Placeholder-grep clean on the diff.
