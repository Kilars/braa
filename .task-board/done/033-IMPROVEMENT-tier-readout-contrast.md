# IMPROVEMENT: 033 — Tier readout pops against the bright sky (P1-7)

**Status**: Done
**Created**: 2026-06-29
**Priority**: High — open **PO directive** (Improvements) blocking the Phase-1
Visual-Review sign-off (P1-10). The only-remaining-gap override applies (visual
domain is saturated, but this is one of just two open Phase-1 PO findings).
**Labels**: visual, ui, phase-1, po-directive
**Estimated Effort**: Small

## What it addresses (PO directive, `.docs/specs/po-review.md` → Improvements)

> **Tier readout is too low-contrast to read (P1-7).** The PERFECT/OK/MISS word
> flashes at full opacity in the upper third, but OK (pale green) and especially
> MISS (light grey, `0.72`) sit at almost the same luminance as the bright-blue sky
> and are barely legible — "MISS" nearly disappears. It's a contrast problem, not
> opacity. *Good looks like:* a dark outline / drop-shadow (or higher-contrast
> fills) so every tier pops against the bright backdrop, PERFECT still the brightest
> — each word crisply readable at 390×844.

Confirmed in code (audit 2026-06-29): `scripts/tier_readout.gd` renders a plain
`Label` (`add_theme_font_size_override("font_size", 88)`), flat fills, no outline /
shadow anywhere. The sky is `Color(0.53, 0.81, 0.92)`; `COLOR_OK` (luminance ~0.71)
and `COLOR_MISS` (~0.72) are near-isolumine with it.

## Technical Approach

Give the readout a **dark text outline** (the PO's first suggestion) so every tier
reads against the bright sky, while preserving the existing PERFECT-brighter-than-OK
emphasis invariant. Godot `Label` supports this with a theme **color** override
(`font_outline_color`) **plus** a non-zero **constant** override (`outline_size`) —
both are required for the stroke to render. The outline rides the existing
`self_modulate.a` fade, so the word and its stroke fade together (contrast preserved
through the readable HOLD).

This is mostly a rendering change, but the override wiring is an **observable seam**
(`has_theme_color_override` / `get_theme_constant`), so it is **test-first** for that
part; the legibility itself is closed by **Visual Review**.

**Before** (`scripts/tier_readout.gd` `_init`, lines 36–43):

```gdscript
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 88)
	self_modulate.a = 0.0  # start blank — nothing tapped yet
```

**After** (add a dark stroke so every tier pops against the bright backdrop):

```gdscript
## A dark stroke so every tier reads against the bright Pokémon-GO sky (P1-7).
## Both the colour AND the size override are required for Godot to draw the outline.
const OUTLINE_COLOR := Color(0.07, 0.07, 0.10, 1.0)  # near-black
const OUTLINE_SIZE := 12                              # px, at font_size 88

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 88)
	add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	add_theme_constant_override("outline_size", OUTLINE_SIZE)
	self_modulate.a = 0.0  # start blank — nothing tapped yet
```

Keep the three tier fills as-is (PERFECT brightest); if Visual Review still finds OK
or MISS muddy *with* the outline, the second lever is to lift `COLOR_MISS` /
`COLOR_OK` value while keeping `COLOR_PERFECT.v >= COLOR_OK.v >= COLOR_MISS.v`. Do not
touch the fade math or `display()`/`advance()` behaviour.

### TDD steps (logic seam)

1. **Red** — in `tests/test_tier_readout.gd` (extend the existing file) add a test
   that mounts a `TierReadout` and asserts the outline is configured:
   `has_theme_color_override("font_outline_color")` is true, the override equals
   `OUTLINE_COLOR`, and `get_theme_constant("outline_size")` (or the override) is
   `>= 8`. Run the test → it fails (no overrides yet).
2. **Green** — add the two overrides in `_init` (above) → test passes.
3. **Invariant guard** — assert `COLOR_PERFECT.v >= COLOR_OK.v >= COLOR_MISS.v` stays
   true (locks "PERFECT brightest" so a later contrast tweak can't silently break the
   emphasis-tracks-reward rule). Keep the existing DEAD-shows-nothing / fade tests
   green.

Follow `.claude/skills/tdd/SKILL.md` (red → green → refactor).

## Visual Review (the real gate)

Run `polish`, then spawn review agents looking at the **running local licensed web
export** at 390×844: flash each tier and capture a frame mid-HOLD. PERFECT, OK, and
**MISS** must each be crisply readable against the bright sky, PERFECT still the
brightest. Findings are blocking. Save the proof frame under `.screenshots/`.

## Acceptance Criteria

- [x] Failing test written first (outline overrides absent) per `tdd`.
- [x] `TierReadout` sets `font_outline_color` (dark) + a non-zero `outline_size`; test
      asserts both overrides are present and the size is `>= 8`.
- [x] Emphasis invariant test: `COLOR_PERFECT.v >= COLOR_OK.v >= COLOR_MISS.v`.
- [x] Existing readout tests stay green (DEAD shows nothing; immediate-then-fade).
- [x] Visual Review on the running 390×844 licensed export confirms PERFECT / OK /
      **MISS** are each crisply legible against the bright sky, PERFECT brightest —
      with a captured proof frame in `.screenshots/`.

## Resolution (2026-06-29)

Dark outline shipped: `OUTLINE_COLOR` (near-black) + `OUTLINE_SIZE` (12 px) overrides
in `TierReadout._init` (`scripts/tier_readout.gd`). Tier fills unchanged, so the
PERFECT-brightest emphasis holds. Three new tests in `tests/test_tier_readout.gd`
(outline-color override, `outline_size >= 8`, emphasis-value invariant); existing
DEAD/fade tests stay green.

**Visual Review — PASS.** Added a web-only capture seam `?bra_force_tier=miss|ok|perfect`
(`main.gd` `_query_force_tier` / `_force_tier`, off by default — desktop/headless/normal
play untouched) and `tools/web_capture_readout.mjs`, which boots the real Web bundle in
SwiftShader Chromium at 390×844, pins each tier, screenshots, and fails closed if the
dark stroke is missing/thin. Ran it: every tier ~33k outline px (floor 200), `PASS`.
Eyeballed all three frames (`.screenshots/033-readout-{miss,ok,perfect}.png`) — MISS
(grey), OK (green), PERFECT (gold, brightest) each read crisply against the bright sky.
P1-7 closed.

Gate: `nix develop -c bash verify.sh` green (import · boot · test · export).
- [x] `nix develop -c bash verify.sh` green (import → boot → test → export).
