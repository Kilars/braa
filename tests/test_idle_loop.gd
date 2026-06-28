extends "res://tests/test_case.gd"
## Scene-level guard for "alive at rest" + centring (P1-2, 024c), asserted against the
## production scene (not a stub). Two regressions this catches:
##   1. The CC0 idle clip imports as loop_mode NONE — played raw it runs ONCE and
##      freezes. main.gd must loop it so the dog stays alive.
##   2. The camera must aim at the dog's real centre. The scaffold aimed at (0, 0.5, 0),
##      ~0.4 below the dog's true centre (0, 0.928, 0.279) — the dog read high with
##      empty space below (the 024b finding). This fails on that old camera.

func _instantiate_main() -> Node:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(main)
	# The headless runner quits before any process frame, so _ready is deferred;
	# invoke it explicitly to build the production wiring (mirrors test_bra_button).
	if not main.is_node_ready():
		main._ready()
	return main

func test_idle_is_playing_and_loops_seamlessly() -> void:
	var main := _instantiate_main()
	var ap := _find_ap(main)
	assert_true(ap != null, "the loaded dog must have an AnimationPlayer")
	if ap != null:
		var clips := DogClips.resolve(ap.get_animation_list())
		assert_ne(clips.idle, "", "the dog must expose an idle clip")
		if clips.idle != "" and ap.has_animation(clips.idle):
			assert_ne(ap.get_animation(clips.idle).loop_mode, Animation.LOOP_NONE,
				"idle must loop — raw it imports as NONE and would freeze (P1-2)")
		assert_true(ap.is_playing(), "the dog is alive: the idle is playing, not frozen")
	main.queue_free()

# The committed dog's true visual centre (measured headless from the glb). Asserting
# against this constant — not an AABB recomputed in-test — keeps the guard honest: the
# at-_ready global AABB reads ~origin (skinned bounds propagate only after a frame), so
# recomputing here would be both a tautology and wrong.
const DOG_CENTRE := Vector3(0.0, 0.928, 0.279)

func test_camera_is_aimed_at_the_dog_centre() -> void:
	var main := _instantiate_main()
	# The active camera, not a tree search: the dog glb ships its own embedded
	# Camera3D, so we must assert against the one main actually made current.
	var cam := main.get_viewport().get_camera_3d()
	assert_true(cam != null, "the scene must have an active camera")
	if cam != null:
		# Perpendicular distance from the dog centre to the camera's forward ray ≈ 0
		# when the camera is aimed at the centre. The old scaffold aimed at (0,0.5,0),
		# ~0.36 off — so this fails on that camera; it's a real guard, not a tautology.
		var o := cam.global_position
		var d := -cam.global_transform.basis.z.normalized()
		var to := DOG_CENTRE - o
		var perp := (to - to.dot(d) * d).length()
		assert_true(perp < 0.1, "camera must point at the dog centre, perp=%.3f" % perp)
	main.queue_free()

func _find_ap(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var f := _find_ap(c)
		if f != null:
			return f
	return null

