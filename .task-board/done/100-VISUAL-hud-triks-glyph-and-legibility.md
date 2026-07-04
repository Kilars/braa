# 100 — VISUAL: Add the "Triks" menu glyph and hold HUD legibility over the sky

**Type:** VISUAL (drawn glyph + StyleBox tuning — Visual Review gated)
**Phase:** 6 (current) — PO Review 2026-07-04, Polish #3 (minor)
**Priority:** P2 (minor polish; ship after 098/099)

## What it addresses

Spec gap (PO directive #3, minor). The goal HUD pill reads **"☰ Triks"**; ours is just
**"Triks"** with no menu glyph (097 shipped the Triks pill "no glyph icon"), and the whole
top HUD **washes out faint against the bright sun band** at 1×. The hamburger signals "menu"
(the goal shows it), and the HUD must stay legible over the bright sky.

Evidence: `.screenshots/po-p6-hud-zoom.png`, `po-p6-idle-a.png` (PO).

## Why now

Phase 6 is current; the PO named it as part of "not sign-off ready." Small, self-contained,
non-owner-gated. Sequence it **after** 098/099 (it is the minor of the three).

## Technical approach

The Triks pill is the `Triks` button styled in 097 (`main.gd` HUD setup + `panel(PAPER)`
pill + `font_body_bold()` slate label). Two changes:

1. **Drawn menu glyph** — add a **hamburger** (☰) to the pill, **drawn**, never a tofu /
   font-fallback box (CLAUDE.md never-tofu rule; cf. 089's drawn chevrons via
   `draw_colored_polygon` instead of a font glyph). Draw three short rounded horizontal bars
   to the **left** of the "Triks" text, in `DesignSystem.SLATE`.
   - **Before:** the Triks pill draws only the text `"Triks"` (no icon).
   - **After:** a small custom-drawn 3-bar glyph precedes the text. Implement as a tiny
     `Control` with a `_draw` (three `draw_rect`/`draw_rounded`... bars) added into the pill,
     **or** a `_draw` override on the Triks button that paints the bars left of the label and
     pads the text right. Bars: ~2px tall, ~14px wide, ~4px apart, SLATE, vertically centered.
     Do **not** use a `"☰"` string (fallback-font tofu risk).
2. **Legibility over the bright sky** — the PAPER pills wash out against the sun band. Give
   the top HUD pills (Triks + coin) enough fill opacity / a subtle DS shadow to read over the
   bright sky:
   - **Before:** `DesignSystem.panel(PAPER)` / coin `pill` at current opacity — faint over sky.
   - **After:** ensure the pill fill is near-opaque PAPER and carries the DS **card shadow**
     (`shadow_*` tokens) so the white pills lift off the bright sky. If a soft drop is not
     already on these pills, add the DS shadow token; nudge fill alpha toward 1.0. Keep it
     subtle — a lift, not a heavy box.

Consume `DesignSystem` tokens only (SLATE glyph, PAPER fill, shadow token) — no new ad-hoc
`Color(...)` literals. If the glyph geometry uses constants, home them as named `const`s.

## Visual Review (blocking — VISUAL task)

Spawn phone-portrait (390×844) review agents. Capture the top HUD at 1× **over the bright
sun band** and zoomed (extend `tools/web_capture_training.mjs` / the PO's `po_p6_zoom.mjs`).
Confirm the glyph renders as clean bars (no tofu) and the pills read clearly over the sky.
Orchestrator verifies the actual frame.

## Acceptance criteria

- [ ] The Triks pill shows a **drawn hamburger glyph** (three rounded SLATE bars) to the left
      of "Triks" — **not** a `"☰"` string, no tofu/fallback box.
- [ ] The top HUD pills (Triks + coin) **read legibly over the bright sun band** at 1× — near-
      opaque PAPER fill + a subtle DS card shadow lifting them off the sky.
- [ ] Only `DesignSystem` tokens used (SLATE / PAPER / shadow); no new ad-hoc `Color(...)`
      literals; any glyph geometry homed in named `const`s.
- [ ] `nix develop -c bash verify.sh` → `✓ verify gate green`.
- [ ] **Visual Review PASS** (orchestrator-verified frame): glyph reads as a clean menu icon
      and the HUD holds legibility over the bright sky.
- [ ] Placeholder check clean on the diff.
