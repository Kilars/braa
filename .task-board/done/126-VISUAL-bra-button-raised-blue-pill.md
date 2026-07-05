# 126 — VISUAL — BRA button reads as a deep glossy raised blue pill

**Type:** VISUAL (pure render — Visual Review, not TDD)
**Phase:** 10 current-but-unspecced; this is a father-pass PO directive (`po-review.md`
2026-07-05, Improvement #1) that **preempts** Phase-10 scaffolding per X-4.
**Addresses:** PO directive — "The BRA button is still pale and flat vs the goal's saturated
blue 3D pill." Deepen the blue to the design-token blue and restore the crisp lower
drop-shadow / bevel so it reads as the raised pill in `goal-training-screen.png`. **Do NOT
restyle the shared DS pill token** that feeds the signed-off completion menu — BRA button only.

## Why now

Four of the owner's six finish directives (123/124/125 + HUD) are fixed and signed. This is one
of the two that remain before Phase-10 work. It is the visual anchor of the whole composition.

## Diagnosis (measured against the goal art)

Sampled `.docs/specs/assets/goal-training-screen.png` vs the live render `.screenshots/PO10-train-00.png`:

- **Current button** (`_setup_bra_button`): a **flat** single fill `DesignSystem.BLUE` = `(74,144,226)`
  end-to-end, a **1-row** `BLUE_DARK` lower lip (border_width_bottom 9 barely reads), and the default
  card shadow (alpha .08) which is **invisible over grass** — so it reads as a flat rectangle.
- **Goal button**: a **vertical gradient** face — bright `(121,176,250)` at the top smoothly deepening
  to `(89,141,224)` at the bottom — over a **distinct darker-blue 3D lower lip** `~(61,108,188)`, with
  a **real drop shadow** lifting it off the grass. That gradient sheen + lip + shadow is what makes it
  read as a confident raised pill.

`StyleBoxFlat` cannot express a light-top→dark-bottom gradient (one border colour only), so the honest
match is a **baked rounded-rect gradient texture** used as the button's `normal` StyleBox.

## Technical Approach

Add a private helper in `scripts/main.gd` that bakes the pill face once at load, and swap the BRA
button's `normal`/`hover`/`disabled` styleboxes to a `StyleBoxTexture` of it. Keep tap→score logic
and all offsets unchanged. The whole canvas scales uniformly under the `expand` stretch, so a
design-resolution baked texture scales without corner distortion.

**Before** (`scripts/main.gd`, `_setup_bra_button`):
```gdscript
var normal_style := DesignSystem.pill(DesignSystem.BLUE, DesignSystem.R_XL)
normal_style.border_width_bottom = 9
normal_style.border_color        = DesignSystem.BLUE_DARK
normal_style.shadow_color  = DesignSystem.SHADOW_CARD_COLOR
normal_style.shadow_size   = DesignSystem.SHADOW_CARD_SIZE
normal_style.shadow_offset = DesignSystem.SHADOW_CARD_OFFSET
```

**After**:
```gdscript
var normal_style := _make_bra_pill_stylebox()   # baked gradient + lip + shadow (goal match)
# pressed stays a flat BLUE_DARK pill so the button reads "pushed in".
```

`_make_bra_pill_stylebox()` bakes an `Image` (RGBA8) at design resolution with:
- a rounded-rect face (radius ~46 design px), anti-aliased edge,
- a **vertical gradient** top `(0.475,0.690,0.980)` → bottom `(0.349,0.553,0.878)`,
- a **darker lower lip** band `~(0.239,0.424,0.737)`,
- a soft **drop shadow** baked into the transparent padding,
and wraps it in a `StyleBoxTexture` with `expand_margin_*` so the shadow draws outside the button rect.

## Acceptance Criteria

- [x] The BRA button renders as a **deep, saturated blue** pill with a visible **top→bottom gradient
      sheen**, matching the goal art's richer blue (not the flat mid-blue).
- [x] A **distinct darker-blue lower lip / bevel** reads clearly along the bottom edge.
- [x] A **drop shadow** lifts the button off the grass (visible, not the invisible .08 card shadow).
- [x] Pressed state still reads as "pushed in" (BLUE_DARK), tap→score behaviour byte-identical.
- [x] `DesignSystem.BLUE` and `DesignSystem.pill(...)` are **unchanged** — the completion-menu / kennel
      pills that consume the shared token are untouched (grep confirms no shared-token edit).
- [x] Visual Review at 390×844 vs `goal-training-screen.png`: the button reads as the confident raised
      pill that anchors the composition.
- [x] `nix develop -c bash verify.sh` green (import · boot · test · export).
