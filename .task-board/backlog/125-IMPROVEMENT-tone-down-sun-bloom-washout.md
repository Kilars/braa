# 125 — IMPROVEMENT: tone down the sun bloom/haze that washes out the training page

**Type:** IMPROVEMENT (visual / rendering — Visual Review)
**Phase:** Preempts Phase 10 — owner training-page finish directive (PO Review 2026-07-05, Improvement 3, resolves 5)
**Priority:** Highest-impact improvement this round (scene-wide; the PO notes fixing this "largely resolves" the faint-HUD directive 5)

## What it addresses

Owner play-test (`.docs/specs/po-review.md` → PO Review 2026-07-05, Improvement 3): a **bright
hazy sun glare top-centre flattens contrast and mutes the sky, grass, and top HUD**, so the page
reads foggy / over-bright where the goal (`goal-training-screen.png`) is crisp and saturated.
Also carries Improvement 5 (the Triks + coin pills lose legibility under the wash — largely
resolved by toning the bloom, then verified).

## Root cause (grounded in the code)

Two sources over-brighten the scene:
- `main.gd` `_setup_sun_disc()` bakes a large radial sun quad — `QuadMesh` **2.4 × 2.4 m**, a
  near-white warm core (`Color(1.0, 0.99, 0.90)`), solid golden body to `offset 0.40`, then a soft
  halo fading out — unshaded and billboarded, sitting in the sky band. The wide bright halo is the
  scene-wide glare.
- `_build_garden()` sky/env: `sky_horizon_color = Color(0.99, 0.82, 0.62)` warm near-white
  horizon glow + `env.ambient_light_energy = 0.8` sky ambient. Together with the sun disc halo the
  upper frame washes toward white behind the HUD pills.

## Technical approach (pure rendering — Visual Review, TDD-exempt)

Tone the glare so **sky, grass, and HUD hold the goal's clean contrast and saturation** — the sun
may stay a **soft accent**, not a scene-wide wash. Do not remove the sun; the goal has a warm sky.

1. **Shrink / de-bloom the sun disc** (`_setup_sun_disc`): reduce the `QuadMesh` size (e.g.
   2.4 → ~1.4–1.6) and/or tighten the halo so the soft transparent falloff covers far less of the
   sky band. Pull the near-white core down toward warm gold so it stops reading as blown-out:
   ```gdscript
   # Before: quad.size = Vector2(2.4, 2.4); core Color(1.0, 0.99, 0.90)
   # After : smaller disc + a tighter halo so the sun is a crisp warm accent, not a scene wash.
   quad.size = Vector2(1.5, 1.5)
   # ...pull the halo offsets in (solid core smaller share, halo fades faster) and warm the core.
   ```
2. **Firm up the sky/ambient** (`_build_garden`): cool the horizon glow away from near-white and
   trim ambient so the sky band keeps saturation behind the HUD:
   ```gdscript
   # sky_horizon_color 0.99,0.82,0.62 → a cleaner, less-white warm horizon
   # env.ambient_light_energy 0.8 → slightly lower so highlights stop clipping toward white
   ```
   Keep the dog naturally lit (the DirectionalLight `Sun` key light is separate) — only reduce the
   atmospheric wash, not the scene's overall exposure into muddiness.
3. **Verify HUD legibility (Improvement 5):** after toning the bloom, confirm the **Triks pill and
   coin pill stay crisp and clearly legible** over the sky band; if still faint, firm the pill
   contrast/shadow (small, targeted — do not restyle the DS pill token that feeds the signed-off
   menu). This closes directive 5.

Tune against an actual 390×844 capture — the camera magnifies sky props, so judge in real pixels,
not headless unproject.

## Acceptance criteria

- [ ] The sun glare / atmospheric haze is toned down: sky, grass, and HUD hold clean contrast and
  saturation matching `goal-training-screen.png`; the sun remains a soft warm accent, not a
  scene-wide wash.
- [ ] The **Triks pill and coin pill are crisp and clearly legible** over the sky band (directive 5).
- [ ] The dog stays naturally, warmly lit (no muddy under-exposure) and centred/grounded — no
  regression to the signed-off Phase-1/6 training look.
- [ ] Visual Review at 390×844 on the real build: side-by-side vs the goal art shows the crisp,
  saturated finish (not foggy/over-bright); the completion menu / kennel / core loop still render
  clean (no regression).
- [ ] `nix develop -c bash verify.sh` green; placeholder check clean.
