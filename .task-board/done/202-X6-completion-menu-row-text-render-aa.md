# 202 — X-6: completion-menu row text renders washed under AA (thin-stroke coverage)

**Source:** PO father-pass-79 (`.docs/specs/po-review.md`, 2026-07-09). Board empty; one buildable X-6.

## Directive (verbatim intent)
The «Triks» completion menu is the last high-traffic surface still on the bare `draw_string`
path. `trick_menu.gd._draw_text()` (line 786) draws every row through plain `draw_string` with
**no** stroke-thickening outline, so at the row-name / subtitle sizes the thin Nunito strokes
cover only ~0.60 of each edge pixel and the darkest core is a partial ink-over-fill blend. In the
shipped 390×844 SwiftShader render the PO measured:
- «Labrador» breed subtitle (13px `WORD_COST_HINT`=SLATE, active row) → **1.58:1** (near-invisible)
- «Ligg»/«Legg deg» available trick names (26px `NAME_AVAILABLE`=SLATE) → **2.35:1**
- «Brun lab» buyable breed name (26px `BREED_NAME_BUYABLE`=SLATE) → **2.88:1**
- «Sitt» active trick name (26px `ROW_ACTIVE_INK #141c26`) → **3.64:1**
- «Bella» owned breed name (SLATE) → **4.48:1** (on the line)

Controls that pass on the same card (rendered near their true token): «Raser» heading 5.55:1,
«Aktiv» badge 6.13:1 — so it is specifically the **row-name/subtitle tier** on the bare draw path.
The analytic ratio (test_trick_menu_contrast) passes for all of these — the wash is a *render*
defect the analytic overstates. Same class as 145/196/197/200/201.

## Fix
Reuse the task 200/201 lever **inside `_draw_text`**: a same-colour `draw_string_outline` pass
before the crisp `draw_string`, raising effective sub-pixel coverage to ~full so every row renders
its true token — WITHOUT changing text advance/geometry, token hue, or row state. Constant
`ROW_LABEL_OUTLINE := 4` matches `HUD_NAV_LABEL_OUTLINE` / `LearnedBar.LABEL_OUTLINE`.

**Keep every token HUE + state exactly** — 170 active-name `ROW_ACTIVE_INK`, 154 `BLUE_INK` learned
name, SLATE available/owned/buyable names, intentionally-greyed `SLATE_SOFT` locked rows, 195
flush-left name column, 162 gold price pip. Ink/render coverage fix only — not a token, layout, or
wording change.

## Verify
- TDD `tests/test_trick_menu_row_contrast.gd`: render-floor WASH pin (SLATE/ROW_ACTIVE_INK at 0.60
  coverage < AA) · outline constant present · tokens unchanged · true-token analytic clears AA.
- `nix develop -c bash verify.sh` green (import·boot·test·export).
- Placeholder grep clean.

## Status
done
