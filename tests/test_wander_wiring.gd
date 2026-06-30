extends "res://tests/test_case.gd"
## Scene-level wiring for the P2-8 ambient wander (050). WanderField proves the bounded-patch
## math headless; the director test proves play_walk loops the gait. This proves the running
## scene GLUE composes them correctly: the dog actually leaves dead-centre and roams a BOUNDED
## patch, the wander PAUSES while a sit/feint is in progress (so the dip/seat reads), then
## resumes, and it never drags the dog out of the patch. A regression (a stuck dog, an unbounded
## drift, or a dog that keeps sliding through a sit) can then never read green.
##
## Boots the CC0 dog (test_case default): it carries a Walk clip but no Sitt, so SitLoop parks in
## IDLE forever and the wander runs continuously — the cleanest deterministic surface for the
## locomotion contract, independent of the gitignored licensed asset. Types are spelled out
## (not :=) because main's dog fields are reached dynamically off a Node-typed handle.

func test_the_dog_leaves_dead_centre_and_stays_in_the_patch() -> void:
	var main := instantiate_main()  # CC0: has walk, no sit -> wander runs every frame
	assert_true(main._wander != null, "a dog with a walk clip gets a wander field")
	assert_true(main._dog != null, "the dog root is held so the wander can drive it")
	var radius: float = main._wander.radius
	var maxr := 0.0
	for i in 300:
		main._process(0.1)
		var off: Vector3 = main._dog.transform.origin - main._dog_rest.origin
		maxr = maxf(maxr, off.length())
	assert_true(maxr > 0.05, "the dog actually wanders — it no longer sits dead-centre (the PO note)")
	assert_true(maxr <= radius + 0.05, "the dog never leaves the bounded patch")
	main.queue_free()

func test_wander_pauses_during_a_feint_then_resumes() -> void:
	var main := instantiate_main()
	for i in 40:
		main._process(0.1)  # let it amble off-centre first
	# An offer begins (here a feint): locomotion must freeze so the moment reads.
	main._begin_feint()
	var frozen: Vector3 = main._dog.transform.origin
	for i in 25:
		main._process(0.1)
	var held: Vector3 = main._dog.transform.origin
	assert_true(held.distance_to(frozen) < 1e-3,
		"the dog holds still while a feint is in progress (wander paused)")
	# The offer ends: ambling resumes.
	main._end_feint()
	var resumed_from: Vector3 = main._dog.transform.origin
	var moved := false
	for i in 80:
		main._process(0.1)
		var now: Vector3 = main._dog.transform.origin
		if now.distance_to(resumed_from) > 1e-3:
			moved = true
	assert_true(moved, "after the feint ends the dog resumes ambling the patch")
	main.queue_free()

func test_the_contact_shadow_tracks_the_wandering_dog() -> void:
	# The dog must stay grounded by its shadow as it roams (acceptance: "grounded by its contact
	# shadow on the grass") — the blob's XZ tracks the dog's wander offset.
	var main := instantiate_main()
	assert_true(main._contact_shadow != null, "the contact shadow is held so it can follow the dog")
	for i in 120:
		main._process(0.1)
	var dog_off: Vector3 = main._dog.transform.origin - main._dog_rest.origin
	var shadow_off: Vector3 = main._contact_shadow.position - main._shadow_rest
	assert_true(abs(dog_off.x - shadow_off.x) < 1e-3 and abs(dog_off.z - shadow_off.z) < 1e-3,
		"the contact shadow follows the dog's wander offset on the grass plane")
	main.queue_free()
