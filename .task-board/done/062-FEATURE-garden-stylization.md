# FEATURE: 062 — Push the garden stylization further (P2-10 improvement) (P2-10)

**Status**: Done

## Outcome (2026-07-01)

Built all three upgrades in `main.gd` and pinned them with `tests/test_garden_wiring.gd` (3 tests,
red → green): warmer/graded sky (peach horizon → blue zenith), a billboard `QuadMesh` sun with a
radial `GradientTexture2D` (crisp core → soft halo — the egg-shaped sphere is gone), and painterly
`NoiseTexture2D` color-ramp grass. Also warmed the ProceduralSky `ground_horizon_color` to kill a
light-blue horizon sliver the first capture surfaced (finite grass plane leaves a band of sky-ground
at the far edge). Verify gate green (235 tests). Visual Review at 390×844 (SwiftShader == deployed
GL Compatibility) confirms all three: `.screenshots/062-garden2-*.png` (free run — warm graded sky,
haloed sun, mottled grass, clean warm→green horizon, dog grounded/centred, "BRA" + learned bar
legible) and `.screenshots/062-apex/f003.png` (forced apex — licensed dog seated head-on, crisp gold
apex ring legible over the painterly grass, core loop intact). Dog stays the clear focus; modest
Phase-2 step, no Phase-7 props/depth/heavy-lighting. Placeholder check clean.
**Created**: 2026-07-01
**Type**: FEATURE (render / 3D / material glue — **Visual-Review gated**, TDD-exempt per the
mother prompt; an honest scene-wiring smoke test pins the new material/mesh properties so a
regression to the flat 047 garden can't read green)
**Priority**: High — the **one genuinely buildable current-phase (Phase 2) directive** the PO's
2026-07-01 re-play surfaces (`.docs/specs/po-review.md`, owner directive item 1). Preempts any
work-ahead. Everything else in Phase 2 is owner-gated (trick clips P2-1/P2-2/P2-3).
**Labels**: phase-2, render, environment, visual-review, p2-10
**Estimated Effort**: Medium (one focused session)

## What it addresses (PO directive + spec gap)

Owner directive 2026-07-01 (in `po-review.md`) item 1 + PO Improvements this pass: the **functional**
garden (task 047) reads but is plain — the PO's own live pixels show:

- a **flat blue→warm sky gradient band** → wants a **warmer, more graded** sky;
- a **flat, hard-edged, slightly egg-shaped pale-yellow sun disc with no halo/rays** → wants a
  **crisper, more deliberate, ideally haloed** sun;
- a **flat green grass gradient plane with no shape or painterly variation** → wants grass that
  reads **shaped/painterly**, not a single flat gradient.

The owner asked for a **more stylized Pokémon-GO-style** garden, and confirmed it's buildable now.
Commit `f9a7a6f` only committed the directive text — **no garden code changed since 047**.

## Scope / non-goals (keep it tight — the modest Phase-2 step, NOT Phase-7)

- **Cheap, clean, phone-legible, dog as the clear focus.** A modest step: warmer graded sky, a
  crisp haloed sun, painterly (mottled) grass.
- **NOT the full Phase-7 environment-art pass** — no props, grass blades, depth fog, or heavy
  lighting polish. Those still defer to Phase 7.
- **GL Compatibility / WebGL2 only.** Every choice must render in the deployed renderer and in the
  local SwiftShader capture — no Forward+-only feature, no custom shader. `ProceduralSkyMaterial`,
  `StandardMaterial3D`, `GradientTexture2D`, `NoiseTexture2D`, billboard quad — all Compatibility-safe.
- **Don't break Phase 1 / earlier Phase 2.** Dog stays centred, framed, readable, grounded at
  390×844; contact shadow, apex ring, readout band, learned bar all stay legible. The **grass plane
  stays flat** (no geometry undulation) so the dog's foot plane + contact shadow are untouched —
  painterly variation is tonal (texture), not geometric.

## Technical approach (render glue — Visual Review, not TDD)

1. **Sky — warmer, more graded** (`_setup_environment`): lift/soften the `ProceduralSkyMaterial`
   gradient — a soft sky-blue zenith → a warm peach/cream near-horizon, with a gentler curve so the
   warm band spreads (more graded, less banded).
2. **Sun — crisp haloed disc** (`_setup_sun_disc`): replace the low-poly `SphereMesh` (which reads
   egg-shaped in SwiftShader and has no halo) with a **billboard `QuadMesh`** carrying a **radial
   `GradientTexture2D`**: a bright warm core → golden body → a soft transparent halo falloff.
   Billboard = always a perfect round disc facing the camera (kills the egg), and the radial alpha
   IS the halo. Same world position as before (no framing regression).
3. **Grass — painterly mottled variation** (`_setup_ground_plane`): give the `StandardMaterial3D`
   an albedo `NoiseTexture2D` with a green `color_ramp` (deep shadowed green → mid grass → light
   sunny green) tiled a few patches across the plane, so the grass reads as painterly/mottled
   rather than one flat gradient. Plane geometry stays flat (grounding safe).

## Definition of done

- Verify gate green (import · boot · test · export).
- New `tests/test_garden_wiring.gd` pins the production garden: graded warm sky, a haloed (alpha,
  billboard) sun, a painterly (albedo-textured) grass — so a regression to the flat 047 garden fails.
- Visual Review captures (390×844) show the warmer graded sky, a crisp haloed sun, and painterly
  grass, with the dog still centred/framed/grounded and the UI legible.
- Placeholder check clean; commit + push.
