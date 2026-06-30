extends "res://tests/test_case.gd"
## Scene-level wiring for the learned bar + confused beat (045, P2-4). The unit tests prove
## TrickProgress's math and LearnedBar's render-free behaviour in isolation; these prove the
## running scene actually mounts the bar, routes a tap into the progress model, and that the
## procedural confused beat always restores the dog to its rest transform (no drift / no
## framing regression). On the committed CC0 dog every tap is DEAD, so the bar floors at 0 —
## there is nothing to lose — which is the honest "you tapped with no real apex" read (P2-4).

func _find_learned_bar(n: Node) -> LearnedBar:
	if n is LearnedBar:
		return n
	for c in n.get_children():
		var f := _find_learned_bar(c)
		if f != null:
			return f
	return null

func test_scene_mounts_the_learned_bar() -> void:
	var main := instantiate_main()
	var bar := _find_learned_bar(main)
	assert_true(bar != null, "the scene must mount the learned bar (P2-4)")
	main.queue_free()

func test_dead_cc0_tap_keeps_the_bar_floored() -> void:
	# Every CC0 tap is DEAD → erosion from 0 floors at 0: the bar can't go negative and a
	# wrong-moment tap never masters anything.
	var main := instantiate_main()
	main._on_bra_pressed()
	assert_eq(main._progress.value, 0.0, "a DEAD tap can't drive learned progress below 0")
	assert_false(main._progress.mastered, "a wrong-moment tap never masters the trick")
	main.queue_free()

func test_confused_beat_leaves_no_drift() -> void:
	# A bad tap fires the procedural confused recoil; once it settles, the dog must be back at
	# EXACTLY the transform it recoiled FROM — the property that makes the nudge safe (no drift,
	# no centring regression). Since 050 the dog also WANDERS, so the recoil composes off its
	# current wander spot rather than boot rest; pause the roam to freeze that base, then prove
	# the wobble leaves no residual drift off it. Skipped only if the root isn't a Node3D.
	var main := instantiate_main()
	if main._dog == null:
		assert_true(true, "no Node3D dog root to nudge — confused beat is a safe no-op")
		main.queue_free()
		return
	for i in 30:
		main._process(0.1)  # let the dog amble off-centre so a non-trivial base is exercised
	main._pause_wander()    # freeze the roam so the recoil base is stable for the assertion
	main._process(0.0)      # place the dog on its (now frozen) wander base
	var base: Transform3D = main._dog.transform
	main._on_bra_pressed()  # DEAD → confused beat begins
	for i in 6:
		main._process(0.1)  # 0.6s > CONFUSED_DURATION → fully settled
	assert_true(main._dog.transform.is_equal_approx(base),
		"the confused beat settles the dog back to its wander base — no drift (045 ∘ 050)")
	main.queue_free()
