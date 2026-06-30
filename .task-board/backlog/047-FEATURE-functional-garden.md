# FEATURE: 047 — The functional garden (look-down view, ground, sun) (P2-10)

**Status**: Backlog
**Created**: 2026-06-30
**Type**: FEATURE (render / 3D / scene glue — **Visual-Review gated**, TDD-exempt per the mother
prompt; any pure framing math touched stays unit-tested via the existing `DogBounds`/`DogFraming`
tests)
**Priority**: Medium — foundational for the *living dog* half of Phase 2: **P2-8** (the dog
wanders a bounded patch) needs **ground to roam on**. Independent of 045/046, so it can run in
parallel. The PO scoped the **functional** garden to Phase 2; richer environment art defers to
Phase 7.
**Labels**: phase-2, render, environment, camera, visual-review, p2-10
**Estimated Effort**: Medium (one focused session)

## What it addresses (spec gap)

`.docs/specs/phase2.md` **P2-10 — The garden** is unimplemented. Today the scene is a flat
sky-blue void: `_setup_environment` (`main.gd:223`) sets `Environment.BG_COLOR` to
`Color(0.53, 0.81, 0.92)`, `_setup_light` adds a `DirectionalLight3D` with **no visible sun
disc**, the camera frames tightly on the dog's bounds, and a blob contact shadow (031) grounds
the dog over **nothing**. There is no ground plane, no horizon, no place for the dog to *be*.

Acceptance from the spec (P2-10, PO-Directive 2026-06-29, X-4 stylized-realism):

- A Pokémon-GO-style **look-down** view with a **horizon split**: stylized **sky + a visible
  sun** above, green **grass** ground below; the dog stands and roams on the grass. Replaces
  today's flat sky-blue void + blob shadow.
- The **BRA** button **floats over the grass** (lower area) — **not** a separate opaque control
  band.
- The **functional** garden (ground + horizon + sun + look-down camera) lands here; richer
  environment art (props, depth, lighting polish) defers to **Phase 7**.

## Scope / non-goals (keep it tight)

- **Functional, not pretty.** Stylized flat-ish grass + a clean sky gradient + a sun disc is the
  bar — *honest* real geometry/materials, **not** a faked or primitive stand-in for art, and
  **not** Phase-7 polish (no props, grass blades, depth fog, fancy lighting).
- **Don't break Phase 1.** The dog must stay **centred, framed, readable, and grounded** at
  390×844 (P1-1/P1-2 quality bar); the apex tell ring + readout band stay legible (P1-4/P1-7,
  037/038); no regression to the signed-off core loop. **GL Compatibility / WebGL2** only — every
  choice must work in the deployed renderer (no Forward+-only features).
- **No wandering here.** The dog still sits in place; P2-8 adds roaming on top of this ground.

## Technical approach (render glue — Visual Review, not TDD)

### 1. Sky + visible sun — `ProceduralSkyMaterial` (GL-Compatibility-safe)

**Before (`scripts/main.gd:223`):**

```gdscript
func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.53, 0.81, 0.92)
	...
```

**After (sketch — tune in Visual Review):**

```gdscript
func _setup_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.30, 0.60, 0.95)
	sky_mat.sky_horizon_color = Color(0.75, 0.88, 0.98)
	sky_mat.sun_angle_max = 12.0          # a clean, readable sun disc
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	...
```

The **sun disc** aligns with the `DirectionalLight3D` direction (`_setup_light`), so the existing
sun light *is* the visible sun — tilt it so the disc sits in the upper sky for the look-down view.

### 2. Grass ground plane at the foot plane

A large `MeshInstance3D` (`PlaneMesh`, e.g. 40×40 m) at the dog's **foot plane** (the same
ground height the contact shadow (031) already computes from `DogBounds`), with a stylized green
`StandardMaterial3D`. Model-agnostic (CC0 + licensed) — measure the foot plane, don't hardcode.
The horizon split emerges where this plane meets the sky under the look-down camera.

### 3. Look-down camera

`_frame_camera` (`main.gd:280`) currently aims a `Camera3D` at the dog from the dog's bounds.
Add a **downward pitch** so the camera looks *down into* the garden (Pokémon-GO angle) with the
horizon high in frame, **while keeping the dog centred and fully framed** (reuse the `DogBounds`
fit — don't regress P1-2 centring). Any pure framing math added/changed stays covered by the
existing `tests/test_dog_framing.gd` / `tests/test_dog_bounds.gd`; the *composition* (does it read
as a look-down garden?) is Visual Review.

### 4. BRA button floats over the grass

In `_setup_bra_button`, drop the button's **opaque band background** so the verb floats over the
grass in the lower area (keep its position + the apex-tell marker coupling — `TELL_OFFSET_*` are
expressed relative to the button on purpose, `main.gd:260`). The button stays a big thumb target
(P1-5); it just no longer sits on an opaque control strip.

### 5. Grounding on the grass

With real ground, re-check the blob contact shadow (031): it should now read as a shadow **on
the grass**. Keep it (cheap, model-agnostic, ships in the encrypted pck per ADR-0006) unless
Visual Review finds a real cast shadow reads materially better in GL Compatibility at phone size
— decide by pixels, not by guess. Either way the dog must not look like it floats.

## Acceptance criteria

- [ ] Flat sky-blue void replaced by a **look-down garden**: stylized sky gradient + a **visible sun disc** above, green **grass** ground below, with a clear **horizon split**.
- [ ] The dog **stands on the grass** and reads as grounded (no floating); it stays **centred and fully framed** at 390×844 — no Phase-1 framing/centring regression (P1-1/P1-2).
- [ ] Apex tell ring + timing readout stay legible against the new backdrop (no P1-4/P1-7 regression; 037/038 spacing intact).
- [ ] BRA button **floats over the grass** (no opaque control band) while staying a big thumb target; apex-tell marker still rings the verb.
- [ ] Every rendering choice works under **GL Compatibility / WebGL2** (verify export leg green; no Forward+-only feature).
- [ ] Any pure framing math touched stays green in `test_dog_framing` / `test_dog_bounds` (no hollow/skipped assertions).
- [ ] **Placeholder check** clean on the diff — real geometry/materials, no faked/primitive art stand-in; no Phase-7 polish smuggled in.
- [ ] Visual Review (phone-portrait 390×844, ideally on a forced-tell/forced-tier capture so the ring + readout are visible against the garden) — findings blocking.
- [ ] `nix develop -c bash verify.sh` green (import · boot · test · export).
