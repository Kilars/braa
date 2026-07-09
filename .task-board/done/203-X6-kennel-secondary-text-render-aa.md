# 203 — X-6: kennel grey secondary text renders washed under AA (thin-stroke coverage)

**Source:** PO father-pass-80 (`.docs/specs/po-review.md`, 2026-07-09). Board empty; one buildable X-6.

## Directive (verbatim intent)
The kennel is the last high-traffic text surface still on the bare no-outline `Label` path. Every
grey `C_INK_SOFT` secondary line in `kennel_screen.gd` is drawn through a Godot `Label` with **no**
`outline_size` / `font_outline_color` override, so at 13px the thin Nunito strokes cover only a
fraction of each edge pixel and the darkest core is a partial ink-over-fill blend. In the shipped
390×844 SwiftShader render the PO measured:
- grid breed subtitles «Labrador retriever»/«Border collie»/«Gravhund» (13px `T_SMALL` `C_INK_SOFT`) → **1.65–1.78:1** (near-invisible)
- header subtitle «Profesjonell fasilitet · 8 plasser» → **2.94:1**
- modal stat label «Læreevne» → **1.55:1**
- modal section heading «Raseegenskaper» → **1.70:1**
- modal «Kan lære: Sitt · Ligg · Legg deg» → **1.38:1** (nearly invisible)

Controls that PASS on the same surfaces render their true dark token: «Kennelen» title 11.44:1, dog
names «Bella» 9.34:1. So it is specifically the grey `C_INK_SOFT` secondary tier that fails — the
analytic ratio (test_kennel_secondary_text_contrast, task 156) passes (~4.78:1) but the *render*
overstates. Same class as 145/196/197/200/201/202; identical root cause on the `Label` draw path
that washed the nav pills to 2.43:1 until task 200 gave them `HUD_NAV_LABEL_OUTLINE=4`.

## Fix
Reuse the task 200 lever adapted to the `Label` path: a same-colour `outline_size` (≈4, matching
`HUD_NAV_LABEL_OUTLINE`) + `font_outline_color` = `C_INK_SOFT` on every `C_INK_SOFT` Label, raising
effective sub-pixel coverage to ~full so the muted grey renders its true token — WITHOUT changing
font size, layout, or wording. Route all 6 sites through one `_apply_soft_ink(lbl)` helper so they
can never diverge. Constant `SOFT_INK_OUTLINE := 4`.

**Keep every token HUE + state exactly** — `C_INK_SOFT` stays the muted grey (156), the dark `C_INK`
names/titles (already ~9–11:1) unchanged, the 149 dark-ink badges, 117 coats, 162 price pips, and
the modal layout all stay. Ink/render coverage fix only — not a token, layout, or wording change.

## Verify
- TDD `tests/test_kennel_secondary_text_render.gd`: render-floor WASH pin (C_INK_SOFT at 0.60
  coverage < AA) · outline constant present · hue unchanged · true-token analytic clears AA · wired
  footer breed label carries the outline.
- `nix develop -c bash verify.sh` green (import·boot·test·export).
- Placeholder grep clean.

## Status
done
