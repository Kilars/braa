extends "res://tests/test_case.gd"
## Scene-level wiring for the apex tell (024d, P1-4). The envelope's honesty is
## unit-proven in test_apex_tell (peak at the apex, dark during idle); these tests
## prove the running scene actually mounts the marker, holds it DARK on the CC0 dog
## (no Sitt → no sit ever opens → the tell never fires during idle), and never lets
## the marker steal a tap from the BRA button it overlays. So a wiring regression —
## marker missing, glowing at rest, or blocking the button — can't read green.

func _instantiate_main() -> Node:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	# Pin the CC0 dog so this scene-mount test is deterministic whether or not the
	# gitignored licensed Labrador is present locally. (025)
	main.dog_path_override = "res://assets/models/dog.glb"
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(main)
	# The headless runner quits before any process frame, so _ready is deferred —
	# invoke the real _ready path so we assert the production wiring (see test_bra_button).
	if not main.is_node_ready():
		main._ready()
	return main

func _find_marker(n: Node) -> ApexTellMarker:
	if n is ApexTellMarker:
		return n
	for c in n.get_children():
		var f := _find_marker(c)
		if f != null:
			return f
	return null

func test_scene_mounts_the_tell_marker() -> void:
	var main := _instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "the scene must mount the apex-tell marker (P1-4)")
	main.queue_free()

func test_marker_never_eats_a_bra_tap() -> void:
	# It sits on top of the BRA button — it must pass touches straight through, or it
	# would silently break the one verb (P1-5).
	var main := _instantiate_main()
	var marker := _find_marker(main)
	if marker != null:
		assert_eq(marker.mouse_filter, Control.MOUSE_FILTER_IGNORE,
			"the marker ignores mouse so the BRA button still receives taps")
	main.queue_free()

func test_tell_is_dark_during_idle_on_the_cc0_dog() -> void:
	# The acceptance criterion observable on the deployed CC0 dog: with no Sitt clip
	# no sit ever opens, so the tell must stay dark through idle frames — it only ever
	# lights up once 025/ADR-0006 ships the sit-capable dog and a real sit opens.
	var main := _instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "marker present")
	if marker != null:
		assert_false(marker.is_showing(), "dark at rest right after _ready")
		# Drive a second of frames — the CC0 session never opens, so the tell holds dark.
		for i in 30:
			main._process(1.0 / 30.0)
		assert_false(marker.is_showing(), "still dark after idle frames (no sit to mark)")
		assert_true(is_equal_approx(marker.self_modulate.a, 0.0),
			"fully transparent while dormant")
	main.queue_free()

func test_marker_opacity_tracks_intensity() -> void:
	# The marker is a dumb renderer: its whole opacity follows the intensity ApexTell
	# feeds it, so 0 is genuinely invisible and 1.0 is the full pulse — asserted
	# without a framebuffer via self_modulate.a.
	var marker := ApexTellMarker.new()
	marker.set_intensity(1.0)
	assert_true(marker.is_showing(), "showing at full intensity")
	assert_true(is_equal_approx(marker.self_modulate.a, 1.0), "opaque at intensity 1")
	marker.set_intensity(0.0)
	assert_false(marker.is_showing(), "dark at intensity 0")
	assert_true(is_equal_approx(marker.self_modulate.a, 0.0), "transparent at intensity 0")
	marker.set_intensity(1.7)
	assert_true(is_equal_approx(marker.self_modulate.a, 1.0), "intensity is clamped to 1")
	marker.free()
