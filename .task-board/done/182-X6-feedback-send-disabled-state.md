# 182 — Feedback form: muted disabled «Send» state (X-6)

**Source:** PO father-pass-55 (`.docs/specs/po-review.md`, HEAD `20c7c6e`).

## Directive
The feedback form's disabled «Send» primary reads as a fully-active blue CTA in the
common blank state. `_style_button` reuses the SAME deep-blue `GRAD_PILL_BOT` stylebox
for the `disabled` state and only drops the **label** to 40 % alpha — so on first open
(no text, no tag) the disabled Send looks solid/tappable but no-ops, with no cue why.

This is a **wrong disabled state** on the primary CTA, inconsistent with the game's own
disabled convention (menu greys/mutes unavailable rows, «Låst»). DS rule: solid-blue pill
= an *active* primary.

## What "good" looks like
- Disabled «Send» gets a clearly non-actionable look: a muted/desaturated fill (pale
  grey-blue / `SLATE_SOFT`-toned surface) with muted ink — reads "not ready yet".
- When the gate flips (text OR a tag present) it snaps back to the full deep-blue CTA.
- Keep the existing enable gate (`_refresh_send`) + submit/telemetry wiring — **style only,
  no behaviour change**.
- All `DesignSystem` tokens, no raw literals, no gold.

## Plan (TDD)
1. Add `send_disabled_bg()` / `send_disabled_ink()` (DS-token derived, muted/desaturated).
2. Red: assert disabled fill is distinct from `SEND_BG`, is not the live blue, is
   desaturated vs `SEND_BG`, and ink is not the white live label.
3. Green: apply a distinct `disabled` stylebox + `font_disabled_color` to the Send button.
4. verify gate green; Visual Review of the blank vs filled form.

## Done when
verify green, style test passes, Visual Review confirms disabled Send reads muted and
snaps to blue when text/tag present. Commit + push.
