# 097 — VISUAL — apply the design system to the training-page hero surfaces (BRA button + HUD chrome)

**Type:** VISUAL (render/UI glue — Visual Review, not TDD) · **Phase:** 6 (design system + training-page visual enhancement) — **CURRENT**
**Story:** Phase 6 spec — *"The training page should read like this: coin balance + «Triks» in a
clean rounded HUD, the learned-bar under the trick label, the dog centered and grounded on a
stylized garden, and a big rounded **BRA** button anchored at the bottom… match the **composition,
grounding, and juice**."* Goal screen: `.docs/specs/assets/goal-training-screen.png`.

## What this addresses (spec gap)

096 builds the design-token vault (`DesignSystem`: palette, radius, spacing, shadow, the bundled
Baloo 2 / Nunito / JetBrains Mono fonts, `panel()`/`pill()`/`theme()`). This task **consumes** it to
make the live training page match the goal composition. Today the chrome is off-spec:
- **BRA button** is a translucent white pill (`Color(1,1,1,0.18)`, `corner_radius 9999`, fallback
  font, `main.gd:1216-1272`) — the goal is a **chunky blue** rounded button with a darker-blue
  bottom-lip (3D pressable) and white Baloo 2 text.
- **Coin readout** draws a bare coin disc + digits + "coins" caption directly on the sky
  (`coin_readout.gd`, `main.gd:1382`) — the goal is a **white rounded pill** (top-right) holding a
  gold coin + slate number.
- **"Triks" reopen button** (top-left, `main.gd:721`) is unstyled — the goal is a **white rounded
  pill** with slate Baloo 2 "Triks".
- **Learned bar + trick label** (`learned_bar.gd`, `main.gd:1362`) — the goal is the trick name
  ("Sitt") in slate Baloo 2 with the **percentage at the right**, over a clean rounded track with a
  blue fill.

## Why prioritized now

This is the phase's headline — "the training page reads like the goal." It is the highest-impact
visible surface and the first real proof the design system pays off. It depends only on 096 (built
immediately before it in the same backlog). The 3D garden + contact shadow are already close
(078/031), so this task is **chrome/HUD/button only** — no 3D scene work. Later Phase-6 tasks (the
completion menu, badges, finer components, garden-vs-DS cohesion) come in subsequent rounds once
this is reviewed.

## Technical approach

All colors/radii/shadows/fonts come from `DesignSystem` (096) — **no new scattered literals.**

### A. BRA button → chunky blue design-system button

```gdscript
# main.gd _setup_bra_button()  — BEFORE (translucent white pill, fallback font)
bra.add_theme_font_size_override("font_size", 96)
normal_style.bg_color = Color(1.0, 1.0, 1.0, 0.18)
normal_style.corner_radius_top_left = 9999   # ...pill on all corners
pressed_style.bg_color = Color(1.0, 1.0, 1.0, 0.32)

# AFTER — blue button, Baloo 2 white text, darker-blue bottom-lip depth (goal: 0 9px 0 #2f6fbf)
bra.add_theme_font_override("font", DesignSystem.font_display())
bra.add_theme_font_size_override("font_size", DesignSystem.T_DISPLAY)   # ~52, hero
bra.add_theme_color_override("font_color", DesignSystem.PAPER)          # white-ish text
var normal_style := DesignSystem.pill(DesignSystem.BLUE, DesignSystem.R_XL)  # rounded rect, not full pill
normal_style.border_width_bottom = 9            # the darker bottom-lip (3D pressable look)
normal_style.border_color = DesignSystem.BLUE_DARK
# card drop shadow (DesignSystem.SHADOW_CARD_*) so it lifts off the grass
var pressed_style := DesignSystem.pill(DesignSystem.BLUE_DARK, DesignSystem.R_XL)  # push-down on press
```

Keep it **bottom-anchored** with side + bottom margins (goal shows it inset from the edges), tall
enough to be a confident tap target. The mark logic (tap → score) is unchanged — style only.

### B. Coin balance → white rounded pill (top-right)

Wrap the existing `CoinReadout` drawing in a `DesignSystem.panel(PAPER)` pill background (or draw a
paper rounded-rect behind the coin+number inside `coin_readout.gd`). The coin disc stays gold
(`GOLD`/`GOLD_DARK`), the number becomes **slate** (`SLATE`) in JetBrains Mono / Baloo, the "coins"
caption can drop (the goal pill shows just coin + number). Right-aligned, top margin per the goal.

### C. "Triks" reopen button → white rounded pill

Style the top-left tricks button (`main.gd:721` region) with `DesignSystem.pill(PAPER)` + a soft
card shadow, slate Baloo 2 label "Triks". (A hamburger icon is a **nice-to-have**; if added, it
must be **drawn** — `draw_rect`/`draw_line` for three bars — NOT a font glyph, per the tofu lesson
089/coin_readout.gd:6. Omit rather than risk a tofu box.)

### D. Trick label + learned bar → goal treatment

Trick name ("Sitt") in **slate Baloo 2** at the label position, with the **percentage right-aligned**
on the same line (goal shows "Sitt … 60%"). The `LearnedBar` track becomes a clean rounded
(`R_PILL`) light track with a **blue** (`BLUE`) fill and the gold **mastery** latch still reading
as gold. Keep the existing fill/erosion/mastery behavior — restyle only.

### E. Root theme already applied by 096

096 sets `DesignSystem.theme()` on the UI root, so `Control` text already uses the bundled fonts.
This task adds the **per-surface** color/shape/shadow treatments above.

## Definition of done / Acceptance criteria

- [ ] BRA button is the design-system blue button: `BLUE` fill, `BLUE_DARK` bottom-lip + pressed
      state, white Baloo 2 (`T_DISPLAY`) text, rounded (`R_XL`), card drop-shadow, bottom-anchored
      with margins. Tapping still scores the mark (behavior unregressed).
- [ ] Coin balance renders as a white (`PAPER`) rounded pill top-right holding the gold coin +
      slate number, using `DesignSystem` tokens (no ad-hoc literals).
- [ ] "Triks" reopen button is a white rounded pill with slate Baloo 2 label; any icon is drawn
      (no font-glyph tofu).
- [ ] Trick label ("Sitt") is slate Baloo 2 with the percentage right-aligned; learned bar is a
      rounded track with a `BLUE` fill and the gold mastery latch preserved.
- [ ] **No new scattered color/radius literals** — all styling reads from `DesignSystem` (096).
      `grep -nE "Color\(0|corner_radius.*=.*9999" main.gd` in the touched functions shows the ad-hoc
      values replaced by `DesignSystem.*`.
- [ ] **Visual Review (blocking):** capture the real 390×844 web build (licensed Labrador) via a
      `tools/web_capture_*.mjs` harness (headless Chromium / SwiftShader). Compare against
      `.docs/specs/assets/goal-training-screen.png`: the training page reads like the goal —
      blue BRA button with depth at the bottom, white coin + Triks pills top, trick label + blue
      learned bar, dog centered/grounded on the garden. Text renders in the real fonts (no tofu,
      no fallback). Attach the screenshot path(s). Judge composition/grounding/juice, not exact px.
- [ ] Earlier phases unregressed: the Sitt→apex→BRA→PERFECT→payoff→loop still runs; the completion
      menu / breed showcase still open (their fuller restyle is a later Phase-6 round, not this task).
- [ ] `nix develop -c bash verify.sh` green (import → boot → test → export).
- [ ] Placeholder-check: no un-allowlisted placeholder/stub hits in the diff.
