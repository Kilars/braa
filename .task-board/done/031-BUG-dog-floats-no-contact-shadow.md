# BUG: The dog floats — no contact shadow anchoring it (P1-1)

**Status**: Done (2026-06-29)
**Created**: 2026-06-28
**Priority**: High — P1-1 explicitly requires the dog "anchored by a contact shadow
(not floating)." A floating dog breaks the grounded read and the Pokémon-GO look; the
PO flagged it as a Phase-1 bugfix.
**Labels**: bug, godot, phase-1, visual, p1-1, rendering
**Estimated Effort**: Medium
**Source**: `specs2.md` → Product Owner Review 2026-06-28 → Bugfixes → "The dog floats
— no contact shadow (P1-1)."

## What's wrong (from the PO play-test)

In every pose (idle, build, seat, stand) the paws end against flat blue with nothing
beneath, and the front paws dangle over the top of the BRA button. The cause is in
`main._setup_light()`: the `DirectionalLight3D` is created **with shadows off**, and
there is **no blob/decal or ground plane** to catch a contact shadow.

```gdscript
func _setup_light() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.light_energy = 1.2
	add_child(sun)
```

## Technical approach

Give the dog a **cheap contact shadow** that reads as grounded at phone size and stays
within the mobile rendering budget (Phase 7 constraint applies now: cheap backdrop, blob
shadow, no heavy post-processing). Prefer a **blob shadow** (a flat, soft-edged dark
decal/quad on the ground under the feet) over real-time shadow mapping — it's cheaper,
reduced-motion-safe, and model-agnostic (works for the CC0 dog *and* the licensed
Labrador, so it's verifiable locally and ships in the encrypted pck unchanged).

The shadow must sit at the dog's **foot plane**. Reuse the existing pure
`DogBounds.measure(dog)` (already used for framing) to find the feet-on-floor Y and the
footprint width, so the blob scales to whichever dog ships — no per-model tuning, same
principle as `_frame_camera`.

Representative change (a new `_setup_contact_shadow(dog)` called from `_ready` after the
dog loads, plus its placement off `DogBounds`):

Before (`_ready`, after the dog is started/framed):
```gdscript
	if dog != null:
		_start_dog(dog)
		_frame_camera(dog)
	else:
		_fallback_camera()
```

After:
```gdscript
	if dog != null:
		_start_dog(dog)
		_frame_camera(dog)
		_setup_contact_shadow(dog)   # anchor the dog to the ground (P1-1)
	else:
		_fallback_camera()
```

New helper (sketch — a soft dark blob decal/quad at the foot plane, sized off bounds):
```gdscript
## A cheap blob contact shadow under the feet so the dog reads as standing ON something
## (P1-1), not floating. Placed at the dog's foot plane and sized to its footprint via
## the same DogBounds the camera frames from, so it's model-agnostic (CC0 + licensed).
func _setup_contact_shadow(dog: Node) -> void:
	var box := DogBounds.measure(dog)
	if box.size == Vector3.ZERO:
		return
	# ... Decal (or unshaded soft-alpha quad) flat on the ground at box.position.y,
	# centred under box, radius ≈ footprint half-width; soft falloff, low opacity.
```

Decide blob-decal vs. enabling `sun.shadow_enabled` with a thin ground plane during
implementation — whichever pixel-verifies as a clean soft contact shadow at 390×844
without tanking the mobile budget. A blob is the recommended default.

## Test-first (structural guard — the visual is the real proof)

This is primarily a **visual** task (Visual Review acceptance below), but add a cheap
headless guard so the shadow can't silently disappear:

- After `_ready` with a measurable dog, a contact-shadow node exists in the scene and is
  positioned at the dog's foot-plane Y (`≈ DogBounds.measure(dog).position.y`), centred
  under the dog's footprint — assertable without a framebuffer.

## Acceptance criteria

- [x] A cheap contact shadow (blob decal preferred) is added under the dog at its foot
      plane, sized off `DogBounds` so it's model-agnostic (CC0 + licensed Labrador).
- [x] Headless test asserts the shadow node exists and sits at the foot plane under the
      dog (TDD: red-first per `.claude/skills/tdd/SKILL.md`).
- [x] `nix develop -c bash verify.sh` green (import → boot → tests → export).
- [x] **Pixel-verified on a 390×844 Web export:** a soft contact shadow is visible under
      the dog at idle (dog clearly stands *on* something, no flat-blue gap) — captured to
      `.screenshots/031-contact-shadow.png`.
- [x] Stays within the mobile rendering budget (no heavy post-processing / per-frame
      shadow-map cost) and is reduced-motion-safe.

## Implementation (2026-06-29)

A **flat unshaded soft-alpha disc** laid on the ground under the feet — chosen over real-
time shadow mapping (cheaper: one quad, no per-frame shadow-map cost; reduced-motion-safe:
static; needs no separate ground plane to catch a projected shadow).

- **`scripts/contact_shadow.gd`** (new, pure + unit-tested, like `DogFraming`/`DogBounds`):
  `ContactShadow.position(box)` = foot-plane Y (`box.position.y`) under the footprint centre;
  `ContactShadow.radius(box)` = larger horizontal half-extent × `FOOTPRINT_SCALE` (1.15) so
  the soft edge falls off *outside* the paws. Sized off the **same `DogBounds` AABB the
  camera frames from**, so it's model-agnostic and ships unchanged in the encrypted pck.
- **`scripts/main.gd`**: `_setup_contact_shadow(dog)` (called from `_ready` after framing)
  mounts a `PlaneMesh` blob at that position; `_contact_shadow_material()` is a
  `StandardMaterial3D` (unshaded, alpha-blended, double-sided) whose albedo is a procedural
  **radial `GradientTexture2D`** (black centre α0.45 → transparent rim). No shader to
  compile → headless-safe (the boot leg's `SCRIPT ERROR` grep stays clean).
- **`tests/test_contact_shadow.gd`** (TDD red-first): 3 pure placement tests + 1 scene-mount
  wiring test (`instantiate_main` → the `ContactShadow` node sits at the dog's foot plane,
  centred under the footprint). Runs in public CI (no licensed glb needed).

**Gate:** `verify.sh` green — import · boot · test (106 tests, 0 failures) · export.
**Pixel proof:** `.screenshots/031-contact-shadow.png` — captured on the real 390×844 web
build (the local export ships the **licensed Labrador**) via `tools/web_capture_shadow.mjs`
(headless Chromium, SwiftShader GL == the deployed GL Compatibility renderer). A soft dark
oval now grounds the dog where before it met flat blue. The bold/placement read is the
PO/father's call on the live site; this closes the "no shadow at all" defect.
