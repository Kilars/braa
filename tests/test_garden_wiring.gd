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

func test_the_sky_reads_as_a_clear_blue_day() -> void:
	# 143 (PO father-pass-8, X-4): the warm-peach horizon (062 "Pokémon-GO warmth") dominated the
	# look-down camera's near-horizon band, so the visible sky read a muddy grey-brown haze with no
	# blue at all — the PO measured (166,156,127) vs the goal art's clean pale-blue (184,213,240).
	# The newer directive SUPERSEDES the old warm-horizon intent for the sky: the horizon must now
	# read COOL/BLUE so the whole sky reads a bright sunny day. Pin blue-leads so a regression back
	# to the warm-peach haze can't read green.
	var main := instantiate_main()
	var sky := _sky_material(main)
	assert_true(sky != null, "the garden uses a ProceduralSkyMaterial sky (graded, not a flat BG colour)")
	# Graded: the zenith and the horizon are genuinely different colours (a gradient, not a band).
	assert_true(not sky.sky_top_color.is_equal_approx(sky.sky_horizon_color),
		"the sky is graded — zenith and horizon differ")
	# A blue zenith: more blue than red up top.
	assert_true(sky.sky_top_color.b > sky.sky_top_color.r, "the zenith reads blue (b > r)")
	# A COOL/BLUE horizon — the directive's verification: sky should read blue with B > R and B > G
	# by a clear margin (the near-horizon band is what the look-down camera actually shows).
	assert_true(sky.sky_horizon_color.b > sky.sky_horizon_color.r + 0.08,
		"the horizon reads blue — blue leads red by a clear margin (kills the warm-peach haze)")
	assert_true(sky.sky_horizon_color.b > sky.sky_horizon_color.g + 0.02,
		"the horizon reads blue — blue leads green")
	main.queue_free()

func test_the_grass_reads_a_bright_saturated_green() -> void:
	# 143 (PO father-pass-8, X-4): the PO measured the build grass at a dark low-saturation olive
	# (85,148,94) vs the goal art's bright saturated green (136,185,104). The painterly ramp's tones
	# were pulled too dark/desaturated. Pin the named tone table so the lightest tone is a genuinely
	# BRIGHT, SATURATED green near the goal — a regression back to the dark olive can't read green.
	var main := instantiate_main()
	var tones: Array = main.GRASS_TONES
	assert_true(tones.size() >= 3, "the grass ramp carries shadow/mid/light tones (got %d)" % tones.size())
	var light: Color = tones[tones.size() - 1]
	# Bright: the lightest sunny tone lifts toward the goal's g≈0.73 — brighter than the old 0.64.
	assert_true(light.g >= 0.70, "the lightest grass tone is bright (g %.2f >= 0.70)" % light.g)
	# Saturated green: green clearly leads red and blue (a lawn, not a grey-olive).
	assert_true(light.g > light.r and light.g > light.b, "the light tone reads green — green leads")
	assert_true(light.g - light.b >= 0.28, "the light tone is saturated (g-b %.2f >= 0.28)" % (light.g - light.b))
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
	# 102: the PO read the house as a "blown-out tower" — tall + narrow. The goal is a cozy COTTAGE:
	# wider than tall, with a small window/door on its face. Pin cottage proportions + the face detail so
	# a regression back to the tower can't read green. (The bloom softening is a warm-cream albedo — the
	# walls must not sit at near-white, which clips to the blown-out face; g < 0.9 keeps them off white.)
	var wall_size: Vector3 = (walls.mesh as BoxMesh).size
	assert_true(wall_size.x > wall_size.y,
		"the house is a cottage — wider than tall (w %.2f > h %.2f)" % [wall_size.x, wall_size.y])
	var wall_mat := walls.material_override as BaseMaterial3D
	assert_true(wall_mat != null and wall_mat.albedo_color.g < 0.9,
		"the walls are a warm cream, not near-white (won't blow out under the sun): g %.2f < 0.9" % wall_mat.albedo_color.g)
	assert_true(house.get_node_or_null("Door") != null or house.get_node_or_null("Window") != null,
		"the cottage has a small window/door on its face (reads as a home, not a silo)")
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
	# 102: the PO found 101 over-corrected into a full-width dirt WEDGE — the near end was 1.0 m wide and
	# centred on the dog, filling the lower half so the dog sat on dirt (54 % of the foreground scanned
	# tan). The fix is a SLIM ribbon that runs BESIDE the centred dog on grass: pin the near width small,
	# and pin the ribbon's leftmost extent to the right of the dog's left flank so it never sprawls back
	# under the dog's feet. (The old wedge's near end reached c.x - 0.5; the fix stays right of c.x - 0.35.)
	assert_true(main.GARDEN_PATH_WIDTH_NEAR <= 0.6,
		"the path's near end is slim, not a full-width wedge (WIDTH_NEAR %.2f <= 0.6)" % main.GARDEN_PATH_WIDTH_NEAR)
	assert_true(box.position.x > c.x - 0.35,
		"the path runs beside the dog, not sprawling under it (left edge %.2f > dog_x %.2f - 0.35)" % [box.position.x, c.x])
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

func test_the_coins_read_as_gold_discs_grounded_in_the_foreground() -> void:
	var main := instantiate_main()
	var coins := main.get_node_or_null("GardenCoins") as Node3D
	assert_true(coins != null, "ambient coins rest on the grass (099/101/102/142)")
	var c: Vector3 = main._dog_bounds(main._dog).get_center()
	var c0 := coins.get_child(0) as MeshInstance3D
	var quad := c0.mesh as QuadMesh
	assert_true(quad != null, "the coin is a billboard quad")
	# 142 (PO father-pass-7): the PO gold-pixel-scanned the 102 coins at 70×69 / 63×51 px (~18 % of the
	# 390-wide screen) — ~4.5× the goal art's small (~14 px / ~4 %) scatter, so they read as oversized HUD
	# tokens crowding the dog. The camera sits ~1.2 m off the dog, so ~292 px/m at coin depth → the goal's
	# 20–26 px band means a diameter of ~0.07–0.09 m ⇒ radius ~0.035–0.045. Pin the SMALL band so a
	# regression back to the 0.24 m orb can't read green. (Smallness still comes from the radius; keep_scale
	# stays true — the GL-Compat billboard collapses edge-on without it.)
	assert_true(quad.size.x >= 0.06 and quad.size.x <= 0.12,
		"the coin reads small like the goal art, not an HUD orb (diameter %.3f in [0.06, 0.12] m)" % quad.size.x)
	# 142: the coins FLANK the centred dog at the on-screen margins. Measured via an analytic 390×844
	# projection: the camera sits only ~1.2 m behind the dog, so the narrow portrait FOV shows only
	# |x| < ~0.5 m at this depth — 101's coins at |x|=1.4-1.7 were entirely OFF-SCREEN (the PO's zero-gold
	# scan). This pins each coin to a lateral band — far enough out to clear the dog silhouette, near
	# enough to stay inside the FOV — so a regression back UNDER the dog OR off-screen can't read green.
	for child in coins.get_children():
		var coin := child as MeshInstance3D
		var dx: float = absf(coin.position.x - c.x)
		assert_true(coin != null and dx >= 0.32 and dx <= 0.5,
			"the coin flanks the dog within the narrow FOV (|dx| %.2f in [0.32, 0.5] m)" % dx)
	main.queue_free()

## 142 (PO father-pass-7 — X-4 polish): the PO measured the 102 coins as oversized (70×69 px),
## OVERLAPPING (a left cluster of two touching discs), and single-tone flat gold — diverging from the
## goal art's small, clearly-spaced, TWO-TONE (gold + red/pink) scatter. These pin the fix's structural
## invariants: a loose non-overlapping scatter, and at least one rose accent coin. The LOOK stays
## Visual-Review-gated; these guard that a regression to the crowded monochrome cluster can't read green.

func test_the_coins_are_a_loose_non_overlapping_scatter() -> void:
	var main := instantiate_main()
	var coins := main.get_node_or_null("GardenCoins") as Node3D
	assert_true(coins != null, "ambient coins rest on the grass (142)")
	# The goal is a small scatter that FRAMES the dog — enough coins to read as a scatter, split on both
	# flanks, and never a stacked cluster like the two touching left coins the PO caught.
	var kids: Array = coins.get_children()
	assert_true(kids.size() >= 4, "a loose scatter of coins frames the dog (got %d, want >= 4)" % kids.size())
	# No two coin centres sit within their combined footprint (2×radius) — the ground-plane (x,z) distance
	# between every pair must exceed the coin diameter, so none overlaps on-screen.
	var r: float = main.GARDEN_COIN_R
	for i in range(kids.size()):
		for j in range(i + 1, kids.size()):
			var a := kids[i] as MeshInstance3D
			var b := kids[j] as MeshInstance3D
			var d := Vector2(a.position.x - b.position.x, a.position.z - b.position.z).length()
			assert_true(d > 2.0 * r,
				"coins %d,%d don't overlap (ground gap %.3f m > diameter %.3f m)" % [i, j, d, 2.0 * r])
	main.queue_free()

func test_at_least_one_coin_is_a_rose_accent_two_tone() -> void:
	var main := instantiate_main()
	var coins := main.get_node_or_null("GardenCoins") as Node3D
	assert_true(coins != null, "ambient coins rest on the grass (142)")
	# Two-tone: the scatter carries BOTH the gold coin material and a red/pink (rose) accent one, matching
	# the goal art's gold + red/pink pair. Detect by the two distinct baked textures on the coins.
	var textures := {}
	for child in coins.get_children():
		var coin := child as MeshInstance3D
		var mat := coin.material_override as BaseMaterial3D
		assert_true(mat != null and mat.albedo_texture != null, "each coin carries a baked face texture")
		textures[mat.albedo_texture.get_instance_id()] = true
	assert_true(textures.size() >= 2,
		"the scatter is two-tone — gold + a rose accent coin (got %d distinct coin textures)" % textures.size())
	# The rose token is a genuine red/pink (r leads g and b), distinct from gold (which leads r≈g high).
	assert_true(DesignSystem.ROSE.r > DesignSystem.ROSE.g and DesignSystem.ROSE.r > DesignSystem.ROSE.b,
		"ROSE reads red/pink — r leads g and b")
	main.queue_free()
