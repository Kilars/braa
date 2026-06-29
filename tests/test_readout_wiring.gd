extends "res://tests/test_case.gd"
## Scene-level wiring for the timing readout + reduced motion (024g, P1-7/P1-8). The
## unit tests prove the readout's mapping/fade and the damping policy in isolation;
## these prove the running scene actually mounts the readout, routes a tap into it,
## and that prefers-reduced-motion really reaches the motion-scale the tell is built
## from — so a wiring regression (readout missing, never updated, or reduced motion
## ignored) can't read green. On the committed CC0 dog a tap is DEAD → the readout
## stays blank, matching the silent audio (no false feedback).

func _find_readout(n: Node) -> TierReadout:
	if n is TierReadout:
		return n
	for c in n.get_children():
		var f := _find_readout(c)
		if f != null:
			return f
	return null

func test_scene_mounts_the_readout() -> void:
	var main := instantiate_main()
	var readout := _find_readout(main)
	assert_true(readout != null, "the scene must mount the timing readout (P1-7)")
	main.queue_free()

func test_a_dead_cc0_tap_leaves_the_readout_blank() -> void:
	# Observable on the deployed CC0 dog: every tap is DEAD, so the readout must show
	# nothing — no false PERFECT/OK/MISS, consistent with the silent payoff (P1-5/P1-7).
	var main := instantiate_main()
	var readout := _find_readout(main)
	assert_true(readout != null, "readout present")
	main._on_bra_pressed()
	if readout != null:
		assert_false(readout.is_visible_now(), "a DEAD CC0 tap shows no readout")
	main.queue_free()

func test_full_motion_by_default() -> void:
	# With no reduced-motion preference (auto, headless), the scene runs full intensity —
	# the seam the tell is built from is 1.0.
	var main := instantiate_main(CC0_DOG, 0)
	assert_true(is_equal_approx(main.motion_scale(), 1.0),
		"no preference → full motion scale")
	main.queue_free()

func test_reduced_motion_preference_dampens_the_scene() -> void:
	# The real P1-8 wiring: forcing prefers-reduced-motion must dampen the scene's
	# motion-scale (the value ApexTell.from_window is built with) — not to zero.
	var main := instantiate_main(CC0_DOG, 1)
	var s: float = main.motion_scale()
	assert_true(s < 1.0, "reduced motion dampens the scene's motion scale (P1-8)")
	assert_true(s > 0.0, "but never removes it (dampened, not removed)")
	assert_true(is_equal_approx(s, ReducedMotion.scale_for(true)),
		"the scene uses the same damping policy the unit test locks")
	main.queue_free()
