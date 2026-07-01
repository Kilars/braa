extends "res://tests/test_case.gd"
## Scene-level wiring for the P2-10 garden STYLIZATION step (062). The functional garden (047)
## is render glue (Visual-Review-gated), but the owner's 2026-07-01 directive asks for three
## concrete upgrades over the flat 047 look — a warmer/graded sky, a crisp HALOED sun, and
## PAINTERLY grass — and a regression back to the flat garden must not read green. So this pins
## the production material/mesh PROPERTIES that make each upgrade real:
##   - the sky gradient is graded AND warm at the horizon (a peach/cream, not the old flat pale);
##   - the sun is a billboard disc with an alpha halo texture (not the old opaque low-poly sphere);
##   - the grass carries an albedo texture for painterly variation (not a single flat colour).
## The *look* itself (does it read Pokémon-GO, is the dog still the focus) stays Visual-Review-gated;
## these asserts only guard that the ingredients that produce it are actually wired.
##
## Boots the CC0 dog (test_case default) — the garden is dog-agnostic (sky/grass/sun render the
## same for either model), and _ready builds _setup_environment unconditionally plus the ground
## plane + sun disc on the loaded dog. Types are spelled out because main's nodes are reached
## dynamically off a Node-typed handle.

func _sky_material(main: Node) -> ProceduralSkyMaterial:
	var we := main.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we == null or we.environment == null or we.environment.sky == null:
		return null
	return we.environment.sky.sky_material as ProceduralSkyMaterial

func test_the_sky_is_graded_and_warm_at_the_horizon() -> void:
	var main := instantiate_main()
	var sky := _sky_material(main)
	assert_true(sky != null, "the garden uses a ProceduralSkyMaterial sky (graded, not a flat BG colour)")
	# Graded: the zenith and the horizon are genuinely different colours (a gradient, not a band).
	assert_true(not sky.sky_top_color.is_equal_approx(sky.sky_horizon_color),
		"the sky is graded — zenith and horizon differ")
	# A blue zenith: more blue than red up top.
	assert_true(sky.sky_top_color.b > sky.sky_top_color.r, "the zenith reads blue (b > r)")
	# A WARM horizon: peachy/cream, so red leads green leads blue — the directive's 'warmer' sky.
	# The old 047 horizon was a flat pale yellow (r == g); a warm peach makes r strictly > g.
	assert_true(sky.sky_horizon_color.r > sky.sky_horizon_color.g,
		"the horizon is warm — red leads green (a peach/cream, not the flat pale-yellow band)")
	assert_true(sky.sky_horizon_color.g > sky.sky_horizon_color.b,
		"the horizon is warm — green leads blue")
	main.queue_free()

func test_the_sun_is_a_crisp_haloed_billboard_disc() -> void:
	var main := instantiate_main()
	var sun := main.get_node_or_null("SunDisc") as MeshInstance3D
	assert_true(sun != null, "the garden places an explicit sun disc")
	# A billboard QuadMesh always faces the camera → a perfect round disc (kills the low-poly
	# sphere's egg-shape the PO flagged in SwiftShader).
	assert_true(sun.mesh is QuadMesh, "the sun is a billboard quad, not a low-poly sphere")
	var mat := sun.material_override as BaseMaterial3D
	assert_true(mat != null, "the sun has a material")
	assert_true(mat.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED,
		"the sun billboards to the camera so it reads as a round disc at any pitch")
	# The halo IS the radial alpha falloff — so the material must be alpha-transparent and carry a
	# texture (the radial gradient). An opaque flat disc (no transparency, no texture) fails here.
	assert_true(mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED,
		"the sun is alpha-transparent so its edge fades into a halo")
	assert_true(mat.albedo_texture != null,
		"the sun carries a radial gradient texture (the crisp core → soft halo)")
	main.queue_free()

func test_the_grass_is_painterly_not_a_flat_colour() -> void:
	var main := instantiate_main()
	var grass := main.get_node_or_null("GrassGround") as MeshInstance3D
	assert_true(grass != null, "the garden lays a grass ground plane")
	var mat := grass.material_override as BaseMaterial3D
	assert_true(mat != null, "the grass has a material")
	# Painterly = tonal variation across the plane, carried by an albedo texture. The flat 047
	# grass had only a single albedo_color and no texture — that must no longer read green.
	assert_true(mat.albedo_texture != null,
		"the grass carries an albedo texture for painterly/mottled variation, not one flat colour")
	main.queue_free()
