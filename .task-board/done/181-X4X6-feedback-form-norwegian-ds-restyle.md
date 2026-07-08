# 181 — Feedback form: Norwegian copy + Design-System restyle (X-4/X-6)

**Source:** PO father-pass-54 directive (`.docs/specs/po-review.md`, 2026-07-08). The
feedback modal (`scripts/feedback_form_view.gd`, task 085) is the last un-polished
persistent surface — off-brand on three axes in an otherwise Norwegian, blue-primary,
light-DS-paper game:

1. **English copy** while the whole game is Norwegian (title, placeholder, "Quick tags:",
   the six tag chips, privacy line, Cancel/Send).
2. **GOLD as UI chrome** — gold is reserved strictly for the coin. It's the Send fill,
   selected chips, panel border, rating buttons.
3. **Dark navy card with raw `Color(...)` literals** — ignores the light DS PAPER card
   style every other modal uses; pulls zero `DesignSystem` tokens.

Buildable, NOT owner-gated (the form renders + is reachable regardless of `POSTHOG_TOKEN`;
that flag only gates the *send*, not display). Copy + restyle, **no behaviour change** —
keep the submit/telemetry wiring and the "enabled only with text or a tag" gate.

## What "good" looks like (from the directive)

- **(a) Norwegian copy:** title «Fortell oss hva du synes», placeholder «Hva funker? Hva
  funker ikke?», «Hurtigvalg:», tags «Feil · Idé · For vanskelig · For lett · Forvirrende ·
  Annet», privacy «Fritekst kan brukes til å forbedre spillet — ingenting lagres på enheten
  din.», buttons «Avbryt» / «Send». Rating label «Overall:» → «Helhet:».
- **(b) Light DS PAPER card** matching the completion menu — `DesignSystem` tokens not
  literals, INK text, a **BLUE** primary «Send» (deep GRAD_PILL blue, AA-safe white label),
  a neutral/outlined secondary «Avbryt», BLUE-wash selected chips (mirror 152/167
  `ROW_BG_ACTIVE` pale-blue + `ROW_ACTIVE_INK` dark ink).
- **(c) Remove GOLD from everything but the coin.**

## Tests (TDD where pure)

- `tests/test_feedback_form.gd` — assert `TAG_LABELS` values are the Norwegian set.
- New `tests/test_feedback_form_view_style.gd` — assert the view's style constants pull DS
  tokens (PANEL_BG==PAPER, PANEL_BORDER==BORDER, TITLE==INK), the primary Send fill is a
  blue token, and **no** style constant equals `DesignSystem.GOLD` (the anti-gold guard).

## Done

- Norwegian copy in view + model; DS-token restyle; no gold; verify gate green;
  Visual Review of the reachable modal at 390×844.
