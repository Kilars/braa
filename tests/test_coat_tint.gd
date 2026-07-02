extends "res://tests/test_case.gd"
## TDD for CoatTint (076, P3-1/P3-2, BUST-074) — the per-breed coat recolor that makes the chocolate
## Labrador a real second breed with NO new owner model. The licensed Labrador is ONE coat
## StandardMaterial3D whose colour is entirely the baked albedo atlas (its glTF baseColorFactor is
## white), so a second breed is a runtime albedo_color multiply over that atlas. CoatTint runs right
## after CoatOpaque.flatten() and tints ONLY the coat surface(s) CoatOpaque targets (the albedo-textured
## body); it works on a private override clone (never mutates a shared resource) and leaves textureless
## surfaces (an eye/glass albedo_color fade) alone — mirroring CoatOpaque's targeting. Built on synthetic
## meshes so it runs in public CI without the gitignored licensed glb (mirrors test_coat_opaque.gd).

# A mesh surface carrying an albedo atlas texture — the coat CoatOpaque leaves as an opaque override.
func _mesh_with_albedo_texture() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()  # one surface
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.fill(Color(0.8, 0.7, 0.5))  # a yellow-lab-ish coat atlas pixel
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mi.set_surface_override_material(0, mat)
	return mi

func test_apply_sets_albedo_color_on_the_textured_coat_surface() -> void:
	var mi := _mesh_with_albedo_texture()
	var tint := Color(0.668, 0.491, 0.321)  # the chocolate range (~#AA7D51)
	var tinted := CoatTint.apply(mi, tint)
	assert_eq(tinted, 1, "the one textured coat surface is tinted")
	var mat := mi.get_active_material(0) as StandardMaterial3D
	assert_eq(mat.albedo_color, tint, "the coat's albedo_color multiplies the atlas by the breed tint")
	assert_true(mat.albedo_texture != null, "the coat atlas texture is preserved (tint MULTIPLIES it, not replaces)")
	mi.free()

func test_apply_leaves_a_textureless_surface_alone() -> void:
	# A textureless surface (an eye/glass albedo_color fade — what CoatOpaque also skips) must NOT tint.
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.4)  # deliberate fade, no atlas texture
	mi.set_surface_override_material(0, mat)
	var tinted := CoatTint.apply(mi, Color(0.668, 0.491, 0.321))
	assert_eq(tinted, 0, "no albedo texture → not the coat → left untinted")
	var out := mi.get_active_material(0) as StandardMaterial3D
	assert_eq(out.albedo_color, Color(1, 1, 1, 0.4), "the eye/glass fade colour is untouched")
	mi.free()

func test_apply_never_mutates_a_shared_resource() -> void:
	# CoatTint works on a private override clone (mirrors CoatOpaque) — tinting one instance must not
	# bleed into another sharing the same source material.
	var shared := StandardMaterial3D.new()
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.fill(Color(0.8, 0.7, 0.5))
	shared.albedo_texture = ImageTexture.create_from_image(img)
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	mi.set_surface_override_material(0, shared)
	CoatTint.apply(mi, Color(0.668, 0.491, 0.321))
	assert_eq(shared.albedo_color, Color(1, 1, 1), "the source material is untouched (a clone was tinted)")
	mi.free()

func test_identity_tint_keeps_the_coat_unchanged() -> void:
	# The yellow Labrador uses Color(1,1,1): a harmless identity multiply — no regression to the default.
	var mi := _mesh_with_albedo_texture()
	var tinted := CoatTint.apply(mi, Color(1, 1, 1))
	assert_eq(tinted, 1, "the coat surface is still visited")
	var mat := mi.get_active_material(0) as StandardMaterial3D
	assert_eq(mat.albedo_color, Color(1, 1, 1), "identity tint = atlas colour unchanged")
	mi.free()
