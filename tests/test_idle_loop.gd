extends "res://tests/test_case.gd"
## Scene-level guard for "alive at rest" + centring (P1-2, 024c), asserted against the
## production scene (not a stub). Two regressions this catches:
##   1. The CC0 idle clip imports as loop_mode NONE — played raw it runs ONCE and
##      freezes. main.gd must loop it so the dog stays alive.
##   2. The camera must aim at the dog's real centre. The scaffold aimed at (0, 0.5, 0),
##      ~0.4 below the dog's true centre (0, 0.928, 0.279) — the dog read high with
##      empty space below (the 024b finding). This fails on that old camera.

func test_idle_is_playing_and_loops_seamlessly() -> void:
	var main := instantiate_main()
	var ap := DogClips.find_animation_player(main)
	assert_true(ap != null, "the loaded dog must have an AnimationPlayer")
	if ap != null:
		var clips := DogClips.resolve(ap.get_animation_list())
		assert_ne(clips.idle, "", "the dog must expose an idle clip")
		if clips.idle != "" and ap.has_animation(clips.idle):
			assert_ne(ap.get_animation(clips.idle).loop_mode, Animation.LOOP_NONE,
				"idle must loop — raw it imports as NONE and would freeze (P1-2)")
		assert_true(ap.is_playing(), "the dog is alive: the idle is playing, not frozen")
	main.queue_free()

# The committed dog's true visual centre — now its skeleton REST-POSE BONE-SPAN centre,
# measured headless from the glb (DogBounds switched from the mesh AABB to the bone span
# to fix the licensed-dog framing; the CC0 bone span centres at (0, 0.920, 0.037), barely
# moved in y from the old mesh-box centre 0.928, but its z drops from 0.279 to 0.037).
# Asserting against this constant — not an AABB recomputed in-test — keeps the guard
# honest: the at-_ready global AABB reads ~origin (skinned bounds propagate only after a
# frame), so recomputing here would be both a tautology and wrong.
const DOG_CENTRE := Vector3(0.0, 0.920, 0.037)

func test_camera_target_is_the_dog_centre() -> void:
	# main aims the camera at _dog_bounds().get_center() (the scaffold regression aimed at
	# (0,0.5,0), ~0.36 below it). The APPLIED look_at transform can't be asserted in the
	# --script unit tree — look_at requires a running SceneTree, which the headless runner
	# never starts, so the camera stays at identity here regardless of correctness. The
	# live aim is gated in verify.sh's boot leg (a real tree; it now fails on the
	# `!is_inside_tree()` error a pre-add_child look_at would emit). Here we pin the two
	# deterministic facts: the target the aim is built from is the real dog centre, and
	# main actually creates a Camera3D. (026)
	var main := instantiate_main()
	var dog := main.get_node_or_null("Dog")
	assert_true(dog != null, "the dog must be loaded")
	if dog != null:
		var centre: Vector3 = main._dog_bounds(dog).get_center()
		assert_true(centre.distance_to(DOG_CENTRE) < 0.05,
			"camera target (dog bounds centre) must be the dog centre, got %s" % centre)
	assert_true(main.get_node_or_null("Camera3D") != null, "main must create a Camera3D")
	main.queue_free()

