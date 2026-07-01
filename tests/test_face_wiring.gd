extends "res://tests/test_case.gd"
## Scene-level wiring for P2-11 "face me for the trick" (061). FaceTurn proves the turn MATH
## headless; this proves the running-scene GLUE composes it correctly: a real trick turns the dog
## to face the camera POV (apex reads head-on), the release eases back to the roam heading, and a
## FEINT keeps its wander heading (no forced turn). A regression — a dog that stays side-on for the
## sit, snaps back, or turns to face the camera on a feint — can then never read green.
##
## Boots the CC0 dog (test_case default): it carries a Walk clip (so the wander + a Camera exist)
## but no Sitt, so we drive the facing decision through the real production methods `_begin_sit`
## factors out — `_pause_wander()` + `_engage_face_for_sit()` (the turn-in) and `_release_face()`
## (the turn-out) — exactly as `_begin_sit`/`_end_sit` call them, without needing the gitignored
## licensed Sitt. The head-on visual itself is Visual-Review-gated on the licensed build (same split
## as the WanderField glue in 050). Types are spelled out because main's fields are reached
## dynamically off a Node-typed handle.

func test_a_walk_capable_dog_gets_a_camera_and_wander_but_no_face_until_a_trick() -> void:
	var main := instantiate_main()
	assert_true(main._camera != null, "the camera is held so the dog can be turned to face the POV")
	assert_true(main._wander != null, "a walk-capable dog wanders between offers")
	assert_true(main._face == null, "no face-turn is engaged until a real trick begins")
	main.queue_free()

func test_the_camera_facing_heading_points_at_the_camera() -> void:
	# The target the dog turns to must face the camera POV, not away. Reuse the wander convention:
	# the dog at yaw H faces (sin H, cos H) in XZ, so heading = atan2(dir.x, dir.z) faces `dir`.
	var main := instantiate_main()
	var dogp: Vector3 = main._dog.transform.origin
	var camp: Vector3 = main._camera.transform.origin
	var dir := Vector2(camp.x - dogp.x, camp.z - dogp.z)  # (worldX, worldZ)
	var expected := atan2(dir.x, dir.y)  # y holds worldZ (WanderField convention)
	var h: float = main._camera_facing_heading()
	assert_true(abs(h - expected) < 1e-3, "the camera-facing heading is atan2 of the dog->camera XZ vector")
	# And it genuinely points TOWARD the camera: the dog's forward at that yaw dotted with the
	# dog->camera direction is ~+1 (facing it), never ~-1 (rear-on).
	var facing := Vector2(sin(h), cos(h))
	assert_true(facing.dot(dir.normalized()) > 0.99, "the dog faces toward the camera, not away from it")
	main.queue_free()

func test_a_real_trick_turns_the_dog_to_face_the_camera() -> void:
	var main := instantiate_main()
	# Let it amble so its heading is genuinely off the camera before the trick (a turn to make).
	for i in 40:
		main._process(0.1)
	# Begin a real trick, the way _begin_sit does: freeze the roam, then engage the face-turn.
	main._pause_wander()
	main._engage_face_for_sit()
	assert_true(main._face != null, "a real trick engages the face-turn")
	assert_true(main._facing, "the dog is turning IN to face the camera")
	var target: float = main._sit_face_heading
	for i in 120:
		main._process(1.0 / 60.0)
	assert_true(main._face.is_facing(), "the turn completes — the dog reaches the camera-facing heading")
	# The glue actually yaws the dog ROOT by the face heading (apex reads head-on).
	var want: Basis = main._dog_rest.basis.rotated(Vector3.UP, main._face.heading())
	assert_true(main._dog.transform.basis.is_equal_approx(want), "the dog root is yawed to the faced heading")
	assert_true(abs(main._face.heading() - target) < 1e-3, "it faces exactly the cached camera target")
	main.queue_free()

func test_the_release_eases_back_to_the_roam_heading() -> void:
	var main := instantiate_main()
	main._pause_wander()
	main._engage_face_for_sit()
	for i in 120:
		main._process(1.0 / 60.0)  # turn in and hold facing the camera
	assert_true(main._face != null, "still engaged while facing the camera")
	# The trick ends: release, the way _end_sit does. Roam resumes and the turner eases back.
	main._resume_wander()
	main._release_face()
	assert_false(main._facing, "the release is no longer holding the camera facing")
	for i in 240:
		main._process(1.0 / 60.0)
	assert_true(main._face == null, "once re-aligned with the roam the face-turn is handed back to the wander")
	main.queue_free()

func test_a_feint_keeps_the_wander_heading() -> void:
	# A feint commits to no trick, so it must NOT force a face-camera turn (spec P2-11).
	var main := instantiate_main()
	for i in 40:
		main._process(0.1)
	main._begin_feint()
	assert_true(main._face == null, "a feint does not engage the face-turn")
	assert_false(main._facing, "a feint never sets the facing state")
	main._process(1.0 / 60.0)
	# With no face-turn, the dog root stays yawed to its wander heading, not the camera.
	var want: Basis = main._dog_rest.basis.rotated(Vector3.UP, main._wander.heading())
	assert_true(main._dog.transform.basis.is_equal_approx(want), "the dog keeps its wander heading through a feint")
	main.queue_free()
