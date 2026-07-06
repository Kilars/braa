# 134 — VISUAL — Completion menu: DS typography + distinct "Marker words" section

**Source:** PO Review 2026-07-06, directive **#6 [MED]** (completion menu, Phase 6 surface).
**Phase:** current-phase X-4 quality (preempts the Phase-10 owner-gate).

## What it addresses

The completion menu typography and sectioning fall below the DS bar:
- Several rows/subheads appear to render in a **default sans**, not Baloo 2 / Nunito.
- The "Marker words" section is visually indistinct from the trick list, and its sub-line
  (`+15% · hviler 2`) is near-illegible.

**Acceptance (PO):** verify the DS fonts + type scale apply to **all** menu text; give
"Marker words" a heavier heading + divider and differentiate its rows from trick rows; raise
sub-labels to ≥12px Ink-Soft. **Do NOT re-open the just-shipped progressive disclosure — 127/128
hold.**

## Technical approach

All in `scripts/trick_menu.gd` (the completion menu dumb-renderer) + `scripts/design_system.gd`
tokens. Render glue — **Visual Review**, not TDD (unless a pure helper is added, then unit-lock).

**1. Audit every menu text node for the DS font.** Grep `trick_menu.gd` for every `Label` /
`add_theme_font_override` / text draw and confirm each carries the DS font (Baloo 2 for headings,
Nunito for body) via `DesignSystem`. Any node relying on Godot's default theme font (i.e. no
explicit font override) is the "default sans" the PO saw — route it through the DS font. Verify the
type scale (heading vs row vs sub-label sizes) matches `DesignSystem`'s scale rather than ad-hoc
`font_size` literals.

Before (a row Label with no font override → default sans):
```gdscript
var lbl := Label.new()
lbl.text = row_text          # inherits the engine default font
```
After (sketch — every menu Label carries the DS font + scale):
```gdscript
var lbl := Label.new()
lbl.text = row_text
DesignSystem.apply_body(lbl)   # Nunito body; or apply_heading for section titles
```

**2. Make "Marker words" a distinct section.** Today its heading looks the same weight as trick
rows. Give it a heavier Baloo-2 heading + a divider rule above it (like other DS section breaks),
and differentiate its rows from trick rows (e.g. a subtle indent, a leading dot/pill, or a lighter
row background) so the eye separates "tricks" from "marker words".

**3. Raise sub-labels to ≥12px Ink-Soft.** The `+15% · hviler 2` sub-line renders too small/faint.
Bump it to ≥12px in Ink-Soft `#5A6B7D` (DS `Ink-Soft`), same for any other micro sub-labels, so
the trade-off text is legible.

**Do NOT touch** `MenuReveal` / the progressive-disclosure gating (127/128) or which rows show —
this is purely typography + sectioning of the rows that already appear.

## Test / review

- Render glue → **Visual Review** at 390×844 (`tools/web_capture_menu.mjs`). No new logic branch →
  no TDD; if a font-application helper is added, unit-lock its mapping.
- Re-capture the completion menu and confirm: all text is Baloo 2 / Nunito (no default sans);
  "Marker words" reads as its own section with a heavier heading + divider; the `+15% · hviler 2`
  sub-line is legible (≥12px Ink-Soft).

## Acceptance criteria

- [x] Every menu text node renders in the DS font (Baloo 2 headings / Nunito body) — no default sans.
- [x] Menu type scale follows `DesignSystem` (heading vs row vs sub-label), not ad-hoc `font_size`
      (`TITLE_SIZE=T_TITLE`, `NAME_SIZE=T_TITLE`, `BADGE_SIZE=T_HEAD`, `HINT_SIZE=T_SMALL`).
- [x] "Marker words" is a distinct section: a hairline divider rule + a Baloo-2 display heading, its
      rows differentiated from trick rows by a leading filled pip + left indent.
- [x] Sub-labels (`+15% · hviler 2` and peers) are `HINT_SIZE`=`T_SMALL` (13px ≥12) in `DesignSystem.SLATE`
      Ink-Soft `#5A6B7D` and legible.
- [x] Progressive disclosure (127/128, `MenuReveal`) is untouched — only `scripts/trick_menu.gd` changed.
- [x] No new scattered `Color(...)`/font literals; go through `DesignSystem` (SLATE / PANEL_BORDER / T_*).
- [x] Visual Review PASS on the completion menu capture (phone-portrait 390×844).
      (`072-menu-open.png`, 2026-07-06: "Tricks" + "Marker words" headings render in rounded Baloo 2,
      rows in Nunito; a divider rule + heavier heading set the marker-words section apart; each word row
      (• Bra! / • Dyktig! / • Flink!) carries a leading pip + indent distinct from trick rows; the
      `+15% · hviler 2` sub-line is legible Ink-Soft.)
- [x] verify gate green (import·boot·test·export); placeholder check clean.

## Resolution (2026-07-06)

All in `scripts/trick_menu.gd` (58+/30- lines) — no logic touched, `MenuReveal` (127/128) untouched.

- **DS type scale:** the ad-hoc `TITLE_SIZE/NAME_SIZE/BADGE_SIZE/HINT_SIZE` literals now bind to
  `DesignSystem.T_TITLE` (26) / `T_HEAD` (18) / `T_SMALL` (13). Every draw goes through the DS Baloo-2
  display / Nunito body fonts — no engine-default sans left.
- **"Marker words" section:** new consts `WORD_DIVIDER_H`/`WORD_DIVIDER_GAP`/`WORD_HEADER_H` draw a
  hairline `PANEL_BORDER` divider rule above a Baloo-2 display heading (heavier than the body-bold
  "Breeds"/"Vanskelighet" subheads); `_words_top()` / row-rect math adjusted for the divider+heading.
- **Row differentiation:** each word row gets a leading filled pip (`WORD_PIP_R`, coloured by word
  state) + `WORD_ROW_INDENT`, so marker-word rows read distinctly from trick rows.
- **Legible sub-labels:** the cost hint (`+15%…`) and trade subtitle now use `WORD_COST_HINT =
  DesignSystem.SLATE` (Ink-Soft `#5A6B7D`) at `HINT_SIZE`=`T_SMALL` (13px ≥12).

Gate: `✓ verify gate green` (import·boot·test·export). Visual Review PASS (`072-menu-open.png`).
