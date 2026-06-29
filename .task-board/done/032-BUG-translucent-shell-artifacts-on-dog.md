# BUG: Translucent "shell" artifacts on the dog body (P1-1 / P1-9)

**Status**: Done (2026-06-29)
**Created**: 2026-06-28
**Priority**: High — P1-1 wants a clean real-dog silhouette and P1-9 "no bugs"; the
see-through flaps make the dog look broken. PO-flagged Phase-1 bugfix.
**Labels**: bug, godot, phase-1, visual, p1-1, p1-9, materials, asset-import
**Estimated Effort**: Medium
**Source**: `specs2.md` → Product Owner Review 2026-06-28 → Bugfixes → "Translucent
'shell' artifacts on the dog body (P1-1 / P1-9)."

## What's wrong (from the PO play-test of the licensed Labrador)

Magnified, the Labrador shows **semi-transparent ghost panels** — a vertical see-through
strip down the chest/belly and curved translucent surfaces across both flanks/haunches —
present in **every** pose, idle and seated. They are geometric and consistent (not render
noise): a model/material issue. Most likely a **coat/fur shell** (or a duplicated mesh)
importing as **alpha-blended / two-sided** instead of opaque.

This is on the **licensed Labrador** (`assets/models/dog_licensed.glb`, present in local
dev), so it is reproducible and fixable locally and the fix must carry into the encrypted
pack that ships (ADR-0006 / task 025) — i.e. prefer a **code-side material override at
load** over a per-file `.import` tweak, so it is dog-agnostic and travels with the build.

## Technical approach

1. **Identify the offending surface(s).** Walk the loaded dog's `MeshInstance3D`s (reuse
   `DogClips.find_animation_player`-style traversal) and log, per surface, the active
   `StandardMaterial3D`'s `transparency` and `cull_mode`. Find the surface(s) reporting
   `TRANSPARENCY_ALPHA` (or a two-sided/disabled cull) that produce the ghost panels —
   likely a fur/coat shell or a duplicated body mesh.

2. **Fix at load (model-agnostic, ships in the pck).** In a small pass after the dog is
   instantiated, force the body surfaces opaque and cull backfaces; if the artifact is a
   genuine duplicated shell mesh with no purpose, hide/drop that duplicate instead.

Representative new helper, called from `_load_dog` (or `_start_dog`) after instantiate:

Before (`scripts/main.gd` → `_load_dog`):
```gdscript
	var dog := packed.instantiate()
	dog.name = "Dog"
	add_child(dog)
	print("[Bra!] dog loaded: %s" % path)
	return dog
```

After:
```gdscript
	var dog := packed.instantiate()
	dog.name = "Dog"
	add_child(dog)
	_make_coat_opaque(dog)   # kill the translucent shell panels (P1-1/P1-9)
	print("[Bra!] dog loaded: %s" % path)
	return dog
```

Sketch of the override (force opaque + backface cull on the body surfaces):
```gdscript
## Force the dog's body surfaces opaque so the coat/fur shell can't import as
## alpha-blended see-through panels (PO 2026-06-28: ghost strips on chest/flanks).
## Walks every MeshInstance3D surface; dog-agnostic so it also no-ops cleanly on the
## CC0 dog (already opaque) and travels into the encrypted licensed pck.
func _make_coat_opaque(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			# read active material (override or mesh), clone to StandardMaterial3D,
			# set transparency = TRANSPARENCY_DISABLED, cull_mode = CULL_BACK,
			# assign back as a surface override.
			pass
	for child in node.get_children():
		_make_coat_opaque(child)
```

Confirm the exact offending surface from the diagnostic log before forcing **all**
surfaces opaque — a legitimately-transparent surface (e.g. an eye) must not be flattened.
Prefer targeting only the surfaces that report alpha + produce the ghost panels.

## Test-first (structural guard — the visual is the real proof)

- Headless test: after `_make_coat_opaque(dog)` on a mesh whose surface material is
  alpha-blended, that surface's resolved material reports
  `transparency == TRANSPARENCY_DISABLED` and `cull_mode == CULL_BACK`. (Construct a
  small `MeshInstance3D` with an alpha `StandardMaterial3D` in the test — no licensed
  asset needed, so the guard runs in public CI too.)
- The pass is a safe no-op on an already-opaque mesh (CC0 dog stays unchanged).

## Acceptance criteria

- [x] Diagnostic identifies the exact translucent surface(s) on the licensed Labrador
      (logged transparency/cull per surface) — `tools/diag_dog_materials.gd` +
      `tools/verify_coat_fix.gd`: exactly **1** body surface carries a stray albedo alpha.
- [x] Load-time material pass forces the offending body surface(s) opaque + backface-
      culled, model-agnostic and carried in code (`CoatOpaque.flatten`, called from
      `main._load_dog`), not a one-off `.import` edit → ships in the pck.
- [x] Headless test proves the pass flips an alpha surface to opaque and no-ops on an
      already-opaque one (`tests/test_coat_opaque.gd`, 3 tests, synthetic meshes so it
      runs in public CI without the licensed glb).
- [x] `nix develop -c bash verify.sh` green (import · boot · test · export; 109 tests, 0 fail).
- [x] **Pixel-verified on the 390×844 Web export of the licensed dog:** `.screenshots/
      032-opaque-coat.png` shows a solid, opaque, recognizable Labrador coat with **no
      see-through panels** (no blue backdrop bleeding through the body) — full frame and
      the `032-ab-{nofix,fix}-chest3x.png` before/after crops. *Caveat:* at 3× magnification
      faint **UV/normal shading seams** remain along the chest/flank UV boundaries — those
      are geometry shading, **not** transparency (proven: 0 alpha-bearing surfaces after the
      fix), and are not the PO's reported see-through defect. Note for PO judgement.
- [x] No legitimately-transparent surface (eyes, etc.) is wrongly flattened — only
      alpha-**textured** surfaces are touched; a deliberate `albedo_color` fade is left
      alone (`test_flatten_leaves_a_legit_textureless_transparent_surface_alone`).

## Completed (2026-06-29)

**Root cause (confirmed via A/B probe, not guessed):** the licensed Labrador's single
body material is OPAQUE-intended (glTF declares no `alphaMode`), but its albedo atlas
carries a baked **fur/hair-strand alpha mask** (~18% sub-255 pixels). Sampled by the
shipped GL Compatibility (WebGL2) renderer, that stray alpha renders as see-through ghost
panels — a vertical chest strip + curved flank arcs — in every pose. The A/B probe (flat-
colour vs texture-strip rendered near-identically) localised the artifact to the **albedo
alpha**, not the normal map.

**Fix:** `scripts/coat_opaque.gd` (`CoatOpaque.flatten`, called from `main._load_dog`).
At load it walks every `MeshInstance3D`; for each surface whose albedo texture carries an
alpha channel it clones the material, sets `transparency = DISABLED` + `cull_mode =
CULL_BACK`, and **strips the texture's alpha to RGB** (keeping the real coat texture and
normal map). Stripping the data — not just the mode — is robust to whatever transparency
state the export lands on. Dog-agnostic: a clean no-op on the CC0 placeholder (`0 surfaces
forced opaque`).

**⚠ Found the on-disk code mid-A/B-probe and fixed it before closing:** `_flatten_surface`
had been left in the flat-tan-colour probe variant (`albedo_texture = null`, a hardcoded
`albedo_color`, `normal_enabled = false`) **with a premature `return true` that made the
real texture-strip + `set_surface_override_material` assignment dead/unreachable** — i.e.
it both faked the asset (flat tan blob, violating P1-1) and never actually assigned the
fixed material. Restored to the production texture-strip fix the docstring/tests describe.

**Verification:** `tools/verify_coat_fix.gd` runs the production `flatten` on the real
licensed Labrador headlessly → **1 stray-alpha surface before, 1 fixed, 0 after** (exit 0).
Plus 3 unit tests + full verify gate green + the pixel captures above.
