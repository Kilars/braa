extends "res://tests/test_case.gd"
## TDD for CoatOpaque (032, PO 2026-06-28). The licensed Labrador's single body material
## is OPAQUE-intended (its glTF declares no alphaMode → OPAQUE), but its albedo atlas
## carries a baked FUR/HAIR-STRAND alpha mask (≈18% sub-255 pixels, streaky hair cards over
## the chest + flanks). Sampled by the GL Compatibility (WebGL2) renderer that ships, that
## stray alpha renders as see-through "ghost panels" — a vertical strip down the chest and
## curved arcs across both flanks, in every pose (P1-1 clean silhouette / P1-9 no bugs).
##
## The fix is a load-time, model-agnostic pass: any surface whose albedo texture carries an
## alpha channel is forced fully opaque — transparency DISABLED, backface CULL_BACK, and the
## texture's stray alpha STRIPPED so nothing can be blended or alpha-tested away. Strips the
## DATA, not just the mode, so it's robust to whatever transparency state the export lands on.
## Built on synthetic meshes so it runs in public CI without the gitignored licensed glb.

# A mesh surface that imports OPAQUE-intended but carries a stray-alpha albedo texture —
# the licensed fur-mask bug in miniature.
func _mesh_with_alpha_texture() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()  # one surface
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.8, 0.7, 0.5, 1.0))
	img.set_pixel(0, 0, Color(0.8, 0.7, 0.5, 0.0))  # a "fur strand" hole — sub-255 alpha
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA  # whatever the export lands on
	mi.set_surface_override_material(0, mat)
	return mi

func test_flatten_forces_an_alpha_textured_surface_fully_opaque() -> void:
	var mi := _mesh_with_alpha_texture()
	var fixed := CoatOpaque.flatten(mi)
	assert_eq(fixed, 1, "the one alpha-bearing surface is fixed")
	var mat := mi.get_active_material(0) as StandardMaterial3D
	assert_eq(mat.transparency, BaseMaterial3D.TRANSPARENCY_DISABLED,
		"transparency forced DISABLED so the fur alpha can't blend/scissor through")
	assert_eq(mat.cull_mode, BaseMaterial3D.CULL_BACK,
		"backface culled so you never see the inside of the far flank")
	# The stray alpha is gone from the texture DATA — not just the mode — so no renderer
	# path (blend, scissor, hash) can punch a hole regardless of the transparency value.
	var img := mat.albedo_texture.get_image()
	assert_eq(img.detect_alpha(), Image.ALPHA_NONE,
		"the texture's stray fur alpha is stripped (opaque RGB only)")
	mi.free()

# An already-opaque surface with no alpha texture (the CC0 dog) must be left untouched —
# the pass is a safe no-op there, never re-skinning a clean model.
func _opaque_mesh() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	var mat := StandardMaterial3D.new()  # default: transparency DISABLED, no texture
	mi.set_surface_override_material(0, mat)
	return mi

func test_flatten_is_a_noop_on_an_already_opaque_surface() -> void:
	var mi := _opaque_mesh()
	var fixed := CoatOpaque.flatten(mi)
	assert_eq(fixed, 0, "no alpha-bearing surface → nothing to fix (CC0 dog unchanged)")
	var mat := mi.get_active_material(0) as StandardMaterial3D
	assert_eq(mat.transparency, BaseMaterial3D.TRANSPARENCY_DISABLED, "stays opaque")
	mi.free()

# A genuinely-transparent surface that does NOT lean on a texture alpha mask (a deliberate
# albedo_color fade) is left alone — criterion #6: don't flatten legit transparency (eyes, etc).
func test_flatten_leaves_a_legit_textureless_transparent_surface_alone() -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 1, 1, 0.4)  # a deliberate fade, no alpha-mask texture
	mi.set_surface_override_material(0, mat)
	var fixed := CoatOpaque.flatten(mi)
	assert_eq(fixed, 0, "no alpha TEXTURE → not the fur-mask bug → left transparent")
	var out := mi.get_active_material(0) as StandardMaterial3D
	assert_eq(out.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA, "deliberate transparency preserved")
	mi.free()
