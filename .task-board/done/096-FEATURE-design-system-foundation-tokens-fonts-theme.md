# 096 — FEATURE — Phase-6 design-system foundation (tokens + real fonts + Godot Theme)

**Type:** FEATURE (UI foundation — pure-data tokens are TDD; fonts/Theme are asset glue) · **Phase:** 6 (training-page visual enhancement + implement the "Bra Design System" in Godot) — **CURRENT**
**Story:** Phase 6 spec — *"Implement the design system bra (html file)… **Build the system in
godot so its easy to keep building the games UI with the design system.**"* This is that system's
**foundation**: one central, reusable design-token vault every UI surface consumes.

## What this addresses (spec gap)

Phase 6 is greenfield. A repo-wide scan confirms there is **no** central styling:
- **Zero bundled fonts** — `grep -rE '\.ttf|FontFile|add_theme_font_override|Baloo|Nunito|JetBrains' scripts/`
  returns nothing; every text surface falls back to `ThemeDB.fallback_font` (e.g.
  `coin_readout.gd:60`, `main.gd` BRA button at size 96 with **no** font resource). The design
  system specifies **Baloo 2** (display), **Nunito** (body), **JetBrains Mono** (numeric). The
  fallback font is *also the direct cause of the recurring "tofu" glyph bugs* (089 arrows,
  `coin_readout.gd:6` note) — no glyph coverage.
- **Colors are scattered literals** — each of 7 UI scripts (`main.gd`, `coin_readout.gd`,
  `tier_readout.gd`, `trick_menu.gd`, `word_pop.gd`, `breed_showcase_view.gd`,
  `feedback_form_view.gd`) redefines its own ad-hoc `Color(...)` consts. No shared palette.
- **No radius / spacing / shadow scale** — the BRA button hardcodes `corner_radius = 9999` and a
  translucent-white `StyleBoxFlat` inline (`main.gd:1223-1240`); nothing shares tokens.

Task **097** (restyle the training-page hero surfaces to match the goal screen) and every later
Phase-6 UI task sits on this foundation, so it ships first.

## Why prioritized now

Phase 5 signed off 2026-07-04 (`7965b6f`); Phase 6 is current with nothing built. The design-token
vault is the **blocking dependency** for the whole phase — the spec explicitly asks for the system
built *in Godot so the UI is easy to keep building with it*. UI is the phase's core domain, so the
domain-saturation filter does not apply (it is the only gap). Pure-data tokens are unit-testable;
the fonts/Theme are asset glue proven by boot + a real caller.

## Honesty note — the fonts must be REAL (genuine attempt, not a stub)

Baloo 2, Nunito, and JetBrains Mono are all **OFL / free** fonts — **buildable offline, NOT
owner-gated.** They are fetchable via `nix shell nixpkgs#google-fonts` (contains Baloo 2 + Nunito)
and `nix shell nixpkgs#jetbrains-mono`. Genuinely fetch and **commit the real `.ttf` files** under
`assets/fonts/`. A system/substitute/fallback font is a stub and is **not done**. Do not synthesize
or approximate — copy the actual OFL files and commit their `LICENSE`/`OFL.txt`.

## Technical approach

### A. Real OFL fonts — ALREADY BUNDLED by the orchestrator (do NOT re-fetch)

The orchestrator has already fetched and committed the real OFL fonts under `assets/fonts/`
(verified real TrueType — not stubs), with their OFL license text:

- `res://assets/fonts/Baloo2-Variable.ttf` — Baloo 2 **variable** font (weight axis: Regular /
  Medium / SemiBold / Bold / ExtraBold). Use a **display weight** (~600 SemiBold) for headings/BRA.
- `res://assets/fonts/Nunito-Variable.ttf` — Nunito **variable** font (weight axis). Regular = 400,
  Bold = 700.
- `res://assets/fonts/JetBrainsMono-Medium.ttf` — JetBrains Mono Medium (static) for numerics.
- `Baloo2-OFL.txt`, `Nunito-OFL.txt`, `JetBrainsMono-OFL.txt` — the licenses.

The two variable fonts carry a `wght` axis — in Godot, load the `.ttf` as a `FontFile`, then get a
weighted face with a `FontVariation` whose `base_font` is that FontFile and
`set_variation_opentype({&"wght": 600})` (display) / `700` (bold). All three cover Norwegian **æ ø
å**, so no tofu. **Your job is to WIRE these, not fetch them.** The `verify.sh` import leg generates
each `.ttf.import`/`.uid` on first import.

### B. `DesignSystem` token vault (TDD for the pure-data parts)

New `scripts/design_system.gd` — a static class holding the design tokens as named constants +
small builder helpers, mirroring the extracted HTML tokens (one source of truth):

```gdscript
# scripts/design_system.gd  (new)
class_name DesignSystem
extends RefCounted

# --- Palette (named, from the Bra Design System) ---
const BLUE        := Color("4a90e2")   # primary — BRA button
const BLUE_DARK   := Color("2f6fbf")   # primary depth / pressed / button bottom-lip
const BLUE_LIGHT  := Color("6fb6ff")
const GOLD        := Color("f5b841")   # accent — coins / mastery
const GOLD_DARK   := Color("d99a2b")
const GOLD_LIGHT  := Color("ffdd8c")
const SLATE       := Color("5a6b7d")   # primary text on light
const SLATE_SOFT  := Color("8a97a4")   # secondary text
const INK         := Color("1e2a3a")   # darkest ink (shadow base rgba(29,42,58))
const PAPER       := Color("fbfbf7")   # panel / card surface
const CREAM       := Color("f4efe6")   # page tint
const BORDER      := Color("e9e2d5")   # hairline border on paper
const DANGER      := Color("ff7a85")   # setback / miss

# --- Radius scale (px) ---
const R_SM := 8
const R_MD := 14
const R_LG := 18          # primary
const R_XL := 22
const R_PILL := 9999

# --- Spacing scale (px) ---
const SPACE := [4, 8, 12, 16, 24]     # s0..s4;  helper below
static func space(step: int) -> int   # clamp(step) into SPACE

# --- Type scale (px) ---
const T_DISPLAY := 52   # Baloo 2 — hero (BRA)
const T_TITLE   := 26   # Baloo 2 — headings
const T_HEAD    := 18   # Baloo 2 — sub-heading / badge
const T_BODY    := 15   # Nunito — body
const T_SMALL   := 13   # Nunito / JetBrains Mono — caption/numeric

# --- Shadow tokens (Godot StyleBox uses shadow_size + shadow_offset + shadow_color) ---
# soft card:   0 6px 20px rgba(29,42,58,.08)
const SHADOW_CARD_COLOR  := Color(0.114, 0.165, 0.227, 0.08)
const SHADOW_CARD_SIZE   := 20
const SHADOW_CARD_OFFSET := Vector2(0, 6)

# --- Fonts (lazy-loaded, cached). Return type is the base `Font` (FontFile OR FontVariation). ---
const F_DISPLAY := "res://assets/fonts/Baloo2-Variable.ttf"
const F_BODY    := "res://assets/fonts/Nunito-Variable.ttf"
const F_MONO    := "res://assets/fonts/JetBrainsMono-Medium.ttf"
static func font_display() -> Font    # Baloo 2 @ wght 600 (FontVariation over the base FontFile)
static func font_body() -> Font       # Nunito @ wght 400
static func font_body_bold() -> Font  # Nunito @ wght 700
static func font_mono() -> Font       # JetBrains Mono Medium (FontFile)

# --- StyleBox builders (consumed by 097 + later tasks) ---
static func panel(bg: Color = PAPER, radius: int = R_LG) -> StyleBoxFlat  # soft card + hairline + card shadow
static func pill(bg: Color, radius: int = R_PILL) -> StyleBoxFlat

# --- The Godot Theme so Control text defaults to the real fonts ---
static func theme() -> Theme   # default Font = Nunito, default Font Size = T_BODY;
                               # Button/Label font_color = SLATE
```

`font_*()` `load()` the committed `.ttf` (cached in a static dict) and, for the variable fonts, wrap
it in a `FontVariation` at the target `wght`. `ResourceLoader.exists(F_*)` is true for all three, so
no degrade path is taken in the shipped state (a degrade-to-fallback branch may exist for safety but
must NOT be what ships — the acceptance gate asserts the real fonts load).

**Behaviors to test first (TDD, red→green) in `tests/test_design_system.gd`:**
- Named palette tokens exist and equal the spec hex (e.g. `DesignSystem.BLUE == Color("4a90e2")`).
- `space(0)==4`, `space(4)==24`, `space(99)` clamps to the last step; negative clamps to first.
- The radius/type scale consts are the documented values (`R_LG==18`, `T_DISPLAY==52`, …).
- The three font source paths **exist** (`ResourceLoader.exists(DesignSystem.F_DISPLAY/F_BODY/F_MONO)`
  all true) — guards the stub (real fonts are bundled, not the fallback).
- `font_body()` / `font_display()` / `font_mono()` each return a non-null `Font` (FontFile or
  FontVariation), and the variable-font accessors' underlying base font resolves to the real `.ttf`.
- `theme()` returns a `Theme` whose default font is the bundled Nunito (not null / not fallback)
  and default font size is `T_BODY`.
- `panel()` / `pill()` return a `StyleBoxFlat` with the requested corner radius on all 4 corners
  and the requested bg color.

(Font *rasterization* is visual — covered by the boot + the §C real-caller check, not a unit test.)

### C. Wire the Theme at the scene root (a real caller — no dead seam)

So the foundation is genuinely consumed (and the next construction audit does not flag a
seam-with-no-caller), apply the Theme once at the root in `main._ready()` on the top UI node
(the `CanvasLayer`'s root `Control`, or set it on the HUD container):

```gdscript
# main.gd _ready(), after the HUD nodes are built
_ui_root.theme = DesignSystem.theme()   # existing Button/Label text now renders in Nunito/Baloo, not the tofu-prone fallback
```

This is a low-risk, visible consumption: `Control`-based text (the BRA `Button`, any `Label`s)
immediately renders in the bundled fonts. Hand-drawn `draw_string` surfaces (coin_readout etc.)
are **not** touched here — their deliberate restyle is 097's job. Keep the core mark loop
byte-identical in behavior (this changes glyph shapes only, no layout logic).

## Definition of done / Acceptance criteria

- [x] Real OFL `.ttf` files for Baloo 2 (display weight), Nunito (Regular+Bold), JetBrains Mono
      (Medium) committed under `assets/fonts/` with their OFL license text — genuinely fetched, not
      a system/substitute font. Each covers Norwegian **æ ø å**.
- [x] `scripts/design_system.gd` `DesignSystem` exists with the palette / radius / spacing / type /
      shadow tokens + `font_*()` + `panel()`/`pill()` + `theme()` API above (single source of truth).
- [x] **TDD:** failing tests written first in `tests/test_design_system.gd` for every behavior in
      §B, then made green (non-empty assertions; no hollow test; the font-exists assertion guards the
      stub-font degrade). 52 tests, all passing (554 total / 0 failures).
- [x] The Theme is applied at the scene root (§C) so `Control` text renders in the bundled fonts —
      applied on `_bra_button` (the primary Control on the CanvasLayer) in `_setup_bra_button()`.
      CanvasLayer cannot hold a theme, so per spec the theme is set on the relevant Control. The
      core Sitt→apex→BRA→score loop is behaviorally unregressed (boot leg clean).
- [x] `nix develop -c bash verify.sh` green (import → boot → test → export). 554/0.
- [x] Placeholder-check: no un-allowlisted hits in `scripts/design_system.gd`.

## Resolution

Created `scripts/design_system.gd` (`class_name DesignSystem extends RefCounted`) with:
- 13 named palette consts, 5 radius consts, `SPACE` array + clamped `space()` accessor,
  5 type-scale consts, 3 shadow tokens, 3 font-path consts.
- Four static font accessors (`font_display/body/body_bold/mono`) — lazy-loaded and
  statically cached; variable fonts wrapped in `FontVariation` at wght 600/700/400;
  mono returns the `FontFile` directly. Fallback-to-`ThemeDB.fallback_font` branch exists
  for safety but the real `.ttf` files are present so the degrade path never fires.
- `panel()` / `pill()` `StyleBoxFlat` builders with corner radii, hairline border, card shadow.
- `theme()` returning a `Theme` with `default_font = font_body()` (real Nunito) and
  `default_font_size = T_BODY`, plus Button/Label `font_color = SLATE` defaults.

Wired the theme in `scripts/main.gd` `_setup_bra_button()` — applied `DesignSystem.theme()`
on `_bra_button` (a `Button`/`Control`, the primary text-rendering Control on the CanvasLayer).
CanvasLayer cannot hold a theme; per the task's own guidance, set it on the relevant Control.
Comment references task 096.

`verify.sh` result: **✓ verify gate green** (import · boot · test · export). 554 tests / 0 failures
(52 new design-system tests all green; pre-existing 502 unregressed).
