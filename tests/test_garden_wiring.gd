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
	# 099: depth still comes from a baked normal map even after the noise was softened — a
	# regression that drops the relief (back to a flat lit fill) must not read green.
	assert_true(mat.normal_enabled and mat.normal_texture != null,
		"the grass keeps its baked normal-map depth (099 dialled the noise down but kept relief)")
	main.queue_free()

## 099 (Phase 6 — garden ambiance to the goal training screen). The composed garden is render glue
## (Visual-Review-gated for the LOOK), but a regression back to the bare field — path/house/fence/
## bushes/coins deleted — must not read green. These pin that each new layer's ingredients are wired.

func test_a_path_winds_back_to_a_house() -> void:
	var main := instantiate_main()
	var path := main.get_node_or_null("GardenPath") as MeshInstance3D
	assert_true(path != null, "a garden path is laid (099)")
	assert_true(path.mesh != null and path.mesh.get_surface_count() > 0,
		"the path is a real ribbon mesh with geometry, not an empty node")
	var house := main.get_node_or_null("GardenHouse") as Node3D
	assert_true(house != null, "a house sits at the end of the path (099)")
	var walls := house.get_node_or_null("Walls") as MeshInstance3D
	var roof := house.get_node_or_null("Roof") as MeshInstance3D
	assert_true(walls != null and roof != null, "the house has walls and a gable roof")
	# The house sits in the upper-right of the garden — right of centre (+X) and ahead (-Z, far).
	assert_true(house.position.x > 0.0, "the house reads upper-RIGHT of the dog (+X)")
	assert_true(house.position.z < 0.0, "the house reads in the DISTANCE ahead of the dog (-Z)")
	# The roof is the goal's BLUE, not warm like the walls (b > r).
	var roof_mat := roof.material_override as BaseMaterial3D
	assert_true(roof_mat != null and roof_mat.albedo_color.b > roof_mat.albedo_color.r,
		"the roof reads blue (b > r) — the goal's blue-roofed house")
	main.queue_free()

func test_a_picket_fence_crosses_the_midground() -> void:
	var main := instantiate_main()
	var fence := main.get_node_or_null("PicketFence") as Node3D
	assert_true(fence != null, "a picket fence crosses the mid-ground (099)")
	# Several pickets + rails — a real fence row, not one token post.
	assert_true(fence.get_child_count() >= 8,
		"the fence has many pickets + rails (got %d)" % fence.get_child_count())
	# The pickets read white (the goal's white picket fence): every channel high.
	var first := fence.get_child(0) as MeshInstance3D
	var mat := first.material_override as BaseMaterial3D
	assert_true(mat != null and mat.albedo_color.r > 0.8 and mat.albedo_color.g > 0.8 and mat.albedo_color.b > 0.8,
		"the pickets read white")
	main.queue_free()

func test_border_bushes_frame_the_corners() -> void:
	var main := instantiate_main()
	var bushes := main.get_node_or_null("BorderBushes") as Node3D
	assert_true(bushes != null, "low bushes frame the garden corners (099)")
	assert_true(bushes.get_child_count() >= 3,
		"a few bushes frame the corners (got %d)" % bushes.get_child_count())
	# They read green (g leads r and b) and are squashed low domes (scaled down in Y).
	var b0 := bushes.get_child(0) as MeshInstance3D
	var mat := b0.material_override as BaseMaterial3D
	assert_true(mat != null and mat.albedo_color.g > mat.albedo_color.r and mat.albedo_color.g > mat.albedo_color.b,
		"the bushes read green (g leads)")
	assert_true(b0.scale.y < b0.scale.x,
		"the bushes are squashed low domes, not full spheres")
	main.queue_free()

func test_ambient_coins_rest_on_the_grass() -> void:
	var main := instantiate_main()
	var coins := main.get_node_or_null("GardenCoins") as Node3D
	assert_true(coins != null, "ambient gold coins rest on the grass (099)")
	assert_true(coins.get_child_count() >= 2,
		"two or three ground coins (got %d)" % coins.get_child_count())
	# Billboard discs carrying a gold gradient texture — they read as clean coins from the near-
	# horizontal look-down camera (a flat ground disc would be edge-on and vanish).
	var c0 := coins.get_child(0) as MeshInstance3D
	var mat := c0.material_override as BaseMaterial3D
	assert_true(mat != null and mat.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED,
		"the coins billboard to the camera so they read as discs, not edge-on slivers")
	assert_true(mat.albedo_texture != null, "the coins carry a gold gradient texture (the coin face)")
	main.queue_free()

## 101 (Phase 6 — refine the garden composition to the goal). The PO found three composed elements
## reading as broken at 390×844: the path perspective was INVERTED (wide at the far house, tapering to
## a floating point at the dog's chest — no foreground), the coins were oversized/screen-constant orbs
## floating mid-field, and the fence's gate gap was so wide the right side never showed. These pin the
## fixed invariants so a regression back to the broken composition can't read green. The LOOK stays
## Visual-Review-gated; these asserts guard the structural ingredients of the fix.

func test_the_path_runs_from_the_foreground_back_to_the_house() -> void:
	var main := instantiate_main()
	var path := main.get_node_or_null("GardenPath") as MeshInstance3D
	assert_true(path != null, "the garden path is laid (099/101)")
	var c: Vector3 = main._dog_bounds(main._dog).get_center()
	var box := path.get_aabb()  # path node sits at origin → local AABB == world
	var near_z := box.position.z + box.size.z  # the nearest (+Z / foreground) edge of the ribbon
	var far_z := box.position.z                # the farthest (-Z / house) edge
	# 101: the ribbon reaches into the FOREGROUND past the dog centre (runs down past/around the dog
	# toward the bottom), not a stub that floats between the dog's chest and the house (the PO's
	# "narrows to a floating point at the dog's chest").
	assert_true(near_z > c.z + 0.8,
		"the path's near end reaches the foreground past the dog (near_z %.2f > dog_z %.2f + 0.8)" % [near_z, c.z])
	# And it still recedes a long way toward the distant house — a real receding ribbon, not a patch.
	assert_true(far_z < c.z - 6.0,
		"the path recedes far toward the house (far_z %.2f < dog_z %.2f - 6.0)" % [far_z, c.z])
	main.queue_free()

func test_the_fence_shows_pickets_on_both_sides_of_the_gate() -> void:
	var main := instantiate_main()
	var fence := main.get_node_or_null("PicketFence") as Node3D
	assert_true(fence != null, "the picket fence crosses the mid-ground (099/101)")
	var c: Vector3 = main._dog_bounds(main._dog).get_center()
	var gate_x: float = c.x + main.GARDEN_FENCE_PATH_X
	# Pickets are the square-footprint posts (BoxMesh size.x == picket width); the rails are wide.
	var left := 0
	var right := 0
	for child in fence.get_children():
		var mi := child as MeshInstance3D
		if mi == null:
			continue
		var bm := mi.mesh as BoxMesh
		if bm == null or absf(bm.size.x - main.GARDEN_PICKET_W) > 0.001:
			continue  # skip the wide rails — count posts only
		if mi.position.x < gate_x:
			left += 1
		else:
			right += 1
	# 101: the PO saw "a short segment left of the path and nothing on the right" — the gate gap was so
	# wide it ate the whole visible right side. Both sides must carry real pickets, and the gate must be
	# narrow enough that the right segment actually renders on-screen.
	assert_true(left >= 3, "the fence has pickets LEFT of the gate (got %d)" % left)
	assert_true(right >= 3, "the fence has pickets RIGHT of the gate (got %d)" % right)
	assert_true(main.GARDEN_FENCE_GAP_HALF <= 0.9,
		"the gate gap is narrow enough that the right fence shows (gap_half %.2f <= 0.9)" % main.GARDEN_FENCE_GAP_HALF)
	main.queue_free()

func test_the_coins_are_small_and_grounded_not_floating_orbs() -> void:
	var main := instantiate_main()
	var coins := main.get_node_or_null("GardenCoins") as Node3D
	assert_true(coins != null, "ambient coins rest on the grass (099/101)")
	var c0 := coins.get_child(0) as MeshInstance3D
	var quad := c0.mesh as QuadMesh
	assert_true(quad != null, "the coin is a billboard quad")
	# 101: the PO saw "big golden orbs hovering in mid-field". The fix is SMALL discs (the old R=0.24 →
	# 0.48 m diameter read as orbs); this caps the coin size so a regression back to the big orb can't
	# read green. (Smallness comes from the radius, NOT from turning keep_scale off — the GL-Compat
	# billboard collapses edge-on without keep_scale, so it must stay true; the size cap is the guard.)
	assert_true(quad.size.x <= 0.34,
		"the coin is small (diameter %.2f <= 0.34 m — not an oversized orb)" % quad.size.x)
	main.queue_free()
