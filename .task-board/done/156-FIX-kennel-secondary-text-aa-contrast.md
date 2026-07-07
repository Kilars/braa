# 156 — FIX: kennel grey secondary text clears WCAG AA (X-6)

**Source:** PO Review 2026-07-07 (father pass 20), Improvement 1.

## Problem
The kennel's grey `C_MUTED #9aa6b0` token is used for *meaningful* secondary text —
the breed subtitle under every one of the 8 grid cells, the modal «Raseegenskaper»
section heading, and the «Unikt trekk» card caption — all **13px bold** (`T_SMALL`,
below WCAG's large-text threshold, so the full 4.5:1 normal-text bar applies). Measured:

- breed subtitle on white cell footer (`C_CELL #ffffff`) = **2.31:1**
- modal section heading on modal body (`C_MODAL_SURFACE #fbfbf7`) = **2.48:1**
- «Unikt trekk» caption on cream card (`C_MODAL_CREAM #f4efe6`) = **2.17:1**

All well under 4.5:1. The 149→154 AA sweep only ever measured *blue-on-light* text,
never this *grey-on-light* secondary text, so it slipped.

## Fix
Repoint the three `C_MUTED`-**as-text** usages (`:999`, `:1335`, `:1390`) to the
already-in-palette AA-clear muted ink `C_INK_SOFT #5a6b7d` (introduced task-116 era
for "legible sub-labels"): **4.78:1** on cream / **5.1:1** on cell white / **5.48:1**
on pure white, still a visibly *muted* grey-blue quieter than the `C_INK` title, so
the hierarchy is preserved. The `:339` close-button `font_pressed_color` is a transient
state (PO called it optional) — leave `C_MUTED` there so the token still has a home.

Token-repoint only — no owner asset. TDD: contrast test + wiring assertion.

## Done when
- breed subtitle / section heading / «Unikt trekk» caption all measure ≥4.5:1 in-pixel
- new `tests/test_kennel_secondary_text_contrast.gd` green
- verify gate green
