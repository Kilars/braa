extends "res://tests/test_case.gd"
## Scene-level wiring for the BRA tap (024e, P1-5). The unit tests (test_sit_session)
## prove the scoring seam in isolation; these prove the running scene actually mounts
## the button and routes its press through the session — so a wiring regression
## (button missing, or never connected) can't read green. On the committed CC0 dog
## (no Sitt) a tap must be DEAD: the button works but does nothing, no penalty.

func _instantiate_main() -> Node:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(main)
	# The headless test runner quits inside _initialize() before any process frame,
	# so Godot defers _ready and the scene never builds itself. Invoke the real
	# _ready path explicitly so we assert against the *production* wiring (the same
	# code the boot leg runs through actual frames), not a stripped-down stub.
	if not main.is_node_ready():
		main._ready()
	return main

func _find_button(n: Node) -> Button:
	if n is Button:
		return n
	for c in n.get_children():
		var f := _find_button(c)
		if f != null:
			return f
	return null

func test_main_scene_mounts_the_bra_button() -> void:
	var main := _instantiate_main()
	var btn := _find_button(main)
	assert_true(btn != null, "the scene must mount a BRA button (the one verb, P1-5)")
	if btn != null:
		assert_eq(btn.text, "BRA", "the button reads BRA")
		# Configured as a wide bottom band — a thumb target, not a stray small
		# control. (Pixel-accurate size/reach is checked in the visual review.)
		assert_true(is_equal_approx(btn.anchor_right - btn.anchor_left, 1.0),
			"BRA spans the full width before margins")
		assert_true(btn.offset_bottom - btn.offset_top >= 140.0,
			"BRA is a tall, thumb-friendly band")
		assert_true(btn.focus_mode == Control.FOCUS_NONE,
			"no keyboard focus ring on a touch target")
	main.queue_free()

func test_tap_on_the_cc0_dog_is_dead_and_silent() -> void:
	var main := _instantiate_main()
	var got: Array[int] = []
	main.marked.connect(func(t: int) -> void: got.append(t))
	main._on_bra_pressed()
	assert_eq(got.size(), 1, "a tap emits exactly one marked signal")
	if got.size() == 1:
		assert_eq(got[0], SitWindow.Tier.DEAD,
			"the CC0 dog has no Sitt → every tap is DEAD (no penalty, P1-5)")
	main.queue_free()
