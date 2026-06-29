extends SceneTree
## Verification (task 032): run the PRODUCTION CoatOpaque.flatten on the REAL licensed
## Labrador and prove it engages the actual fur-mask bug — count surfaces fixed, and
## confirm that AFTER the pass no MeshInstance3D surface still carries a stray albedo
## alpha or alpha-blended transparency. Headless, no display needed (the visual render
## conclusion was established by the A/B probe; this proves the data-level fix on the
## real asset). Run: godot --headless --script res://tools/verify_coat_fix.gd

const DOG := "res://assets/models/dog_licensed.glb"

func _initialize() -> void:
	if not ResourceLoader.exists(DOG):
		print("[verify] licensed dog not present: %s — skipping" % DOG)
		quit(0)
		return
	var dog := (load(DOG) as PackedScene).instantiate()
	var before := _alpha_surfaces(dog)
	var fixed := CoatOpaque.flatten(dog)
	var after := _alpha_surfaces(dog)
	print("\n── coat fix verification (licensed Labrador) ──")
	print("alpha/transparent surfaces BEFORE flatten: %d" % before)
	print("surfaces CoatOpaque.flatten() reported fixed: %d" % fixed)
	print("alpha/transparent surfaces AFTER  flatten: %d" % after)
	var ok := fixed > 0 and after == 0
	print("RESULT: %s" % ("PASS — fur-mask panels eliminated on the real asset" if ok \
		else "FAIL — fix did not clear all stray-alpha surfaces"))
	print("───────────────────────────────────────────────\n")
	quit(0 if ok else 1)

## Count MeshInstance3D surfaces whose resolved material would punch a hole — either a
## non-DISABLED transparency mode or an albedo texture still carrying a sub-opaque pixel.
func _alpha_surfaces(n: Node) -> int:
	var count := 0
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var surf := 0 if mi.mesh == null else mi.mesh.get_surface_count()
		for i in surf:
			var mat := mi.get_active_material(i)
			if mat is StandardMaterial3D:
				var sm := mat as StandardMaterial3D
				if sm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					count += 1
				elif sm.albedo_texture != null:
					var img := sm.albedo_texture.get_image()
					if img != null:
						if img.is_compressed():
							img = img.duplicate(); img.decompress()
						if img.detect_alpha() != Image.ALPHA_NONE:
							count += 1
	for child in n.get_children():
		count += _alpha_surfaces(child)
	return count
