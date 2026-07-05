extends "res://tests/test_case.gd"
## TDD for the persisted owned-kennel-dogs roster (109, Phase 8 K-3/K-4/K-7).
## KennelRoster is a pure value object — the set of owned KennelDog ids + the one active id —
## mirroring BreedRoster exactly but in the KennelDog id-space ("bella", "nova", …, "trulte").
##
## The invariants these pin:
##   - The STARTER dog (Bella, KennelDog.STARTER_ID == "bella") is ALWAYS owned. A corrupt /
##     legacy / empty save degrades to owning only Bella — the player can never be dog-less.
##   - The active id is ALWAYS one the player owns. Activating an unowned id is a no-op
##     returning false; a restored active that isn't owned clamps back to Bella.
##   - Only KNOWN KennelDog ids (KennelDog.is_known) are admitted on restore — a save naming a
##     ghost / unshipped id never grants it.

func test_kennel_roster_starts_owning_only_bella() -> void:
	var script = load("res://scripts/kennel_roster.gd")
	assert_true(script != null, "kennel_roster.gd must exist (KennelRoster not yet implemented)")
	var r = script.new()
	assert_true(r.owns(KennelDog.STARTER_ID),
		"a fresh KennelRoster owns the starter (Bella) from the first run")
	assert_eq(r.active, KennelDog.STARTER_ID,
		"the starter (Bella) is the active dog by default")
	assert_eq(KennelDog.STARTER_ID, "bella",
		"sanity: the starter is Bella (id='bella')")
	assert_eq((r.owned as Array).size(), 1,
		"a fresh roster owns exactly one dog (the starter only)")
	assert_false(r.owns("nova"),
		"Nova is not owned until adopted")

func test_adopt_adds_a_known_dog_and_ignores_unknown_or_duplicate() -> void:
	var script = load("res://scripts/kennel_roster.gd")
	assert_true(script != null, "kennel_roster.gd must exist")
	var r = script.new()
	# Adopt a known dog.
	r.adopt("sol")
	assert_true(r.owns("sol"), "adopt() records ownership of a known dog (Sol)")
	assert_true(r.owns(KennelDog.STARTER_ID), "adopting a dog never drops the starter (Bella)")
	# Unknown / ghost id is silently ignored (no crash, no grant).
	r.adopt("ghost_husky_99")
	assert_false(r.owns("ghost_husky_99"), "an unknown id is never admitted by adopt()")
	# Duplicate adopt is idempotent: the owned list doesn't grow.
	var owned_before: int = (r.owned as Array).size()
	r.adopt("sol")
	assert_eq((r.owned as Array).size(), owned_before,
		"adopting an already-owned id is a no-op — owned list doesn't grow")

func test_set_active_rejects_unowned_returns_false() -> void:
	var script = load("res://scripts/kennel_roster.gd")
	assert_true(script != null, "kennel_roster.gd must exist")
	var r = script.new()
	# Cannot activate a dog that isn't owned — no-op returning false.
	assert_false(r.set_active("nova"),
		"activating an unowned dog is a no-op returning false")
	assert_eq(r.active, KennelDog.STARTER_ID,
		"an unowned activation never changes the active dog")
	# Adopt it, then it becomes activatable.
	r.adopt("nova")
	assert_true(r.set_active("nova"),
		"an owned dog can be made active (returns true)")
	assert_eq(r.active, "nova",
		"the active dog switches to the chosen owned dog")

func test_restore_degrades_garbage_to_bella_only_and_clamps_active() -> void:
	var script = load("res://scripts/kennel_roster.gd")
	assert_true(script != null, "kennel_roster.gd must exist")
	# Garbage dictionary — owned is not an array, active is not a string.
	var r = script.new()
	r.restore({"owned": "not-an-array", "active": 42})
	assert_true(r.owns(KennelDog.STARTER_ID),
		"a garbage owned field still owns the starter (never dog-less)")
	assert_false(r.owns("nova"),
		"garbage never grants an unearned dog")
	assert_eq(r.active, KennelDog.STARTER_ID,
		"a non-string active clamps to the starter")
	# Known dog in owned, but active names one NOT in owned → clamp to starter.
	var r2 = script.new()
	r2.restore({"owned": ["bella"], "active": "sol"})
	assert_eq(r2.active, KennelDog.STARTER_ID,
		"an active dog not in the owned list clamps back to the starter")
	# Unknown / ghost id in owned is not admitted; only known ids pass.
	var r3 = script.new()
	r3.restore({"owned": ["bella", "ghost_dog"], "active": "bella"})
	assert_false(r3.owns("ghost_dog"),
		"an unknown id in the owned array is not admitted on restore")
	assert_true(r3.owns(KennelDog.STARTER_ID),
		"the starter is still owned after restoring a partially-invalid owned list")
	# Empty dict → Bella-only default.
	var r4 = script.new()
	r4.restore({})
	assert_true(r4.owns(KennelDog.STARTER_ID),
		"an empty dict restores to the Bella-only default")
	assert_eq(r4.active, KennelDog.STARTER_ID,
		"an empty dict active clamps to the starter")

func test_owns_returns_true_only_for_owned_ids() -> void:
	var script = load("res://scripts/kennel_roster.gd")
	assert_true(script != null, "kennel_roster.gd must exist")
	var r = script.new()
	assert_true(r.owns("bella"), "owns('bella') is true (starter)")
	assert_false(r.owns("balder"), "owns('balder') is false before adoption")
	assert_false(r.owns(""), "owns('') is false (empty string is never owned)")
	r.adopt("balder")
	assert_true(r.owns("balder"), "owns('balder') is true after adoption")

func test_to_dict_restore_round_trips_owned_and_active() -> void:
	var script = load("res://scripts/kennel_roster.gd")
	assert_true(script != null, "kennel_roster.gd must exist")
	var r = script.new()
	r.adopt("pontus")
	r.adopt("lykke")
	r.set_active("pontus")
	var back = script.new()
	back.restore(r.to_dict())
	assert_true(back.owns("pontus"), "pontus survives to_dict/restore")
	assert_true(back.owns("lykke"), "lykke survives to_dict/restore")
	assert_true(back.owns(KennelDog.STARTER_ID), "the starter survives the round-trip")
	assert_eq(back.active, "pontus", "the active dog survives the round-trip")
