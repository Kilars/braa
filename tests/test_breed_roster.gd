extends "res://tests/test_case.gd"
## TDD for the persisted owned-breeds roster (079, P3-4 "persistent roster" / P3-D3 "spend to adopt").
## BreedRoster is a pure value object — the owned-breed set + the active breed id — with the same
## to_dict/restore shape TrickProgress / CoinPurse use so TrickStore stays dumb about the rules.
##
## The invariants these pin: the STARTER breed (the yellow Labrador) is ALWAYS owned (a corrupt /
## legacy / empty save degrades to "owns the Labrador," never a dog-less player); the active breed is
## ALWAYS one the player owns (activating an unowned breed is a no-op); restore admits only KNOWN breed
## ids and clamps an unowned/unknown active back to the starter.

func test_starter_labrador_owned_and_active_by_default() -> void:
	var r := BreedRoster.new()
	assert_true(r.owns(BreedRoster.STARTER), "the starter Labrador is owned from the first run")
	assert_eq(r.active, BreedRoster.STARTER, "the starter Labrador is the active breed by default")
	assert_eq(BreedRoster.STARTER, "labrador", "the starter is the yellow Labrador (breed #1)")

func test_adopt_adds_to_owned() -> void:
	var r := BreedRoster.new()
	assert_false(r.owns("chocolate_labrador"), "the chocolate Lab is not owned until adopted")
	r.adopt("chocolate_labrador")
	assert_true(r.owns("chocolate_labrador"), "adopt records ownership")
	assert_true(r.owns(BreedRoster.STARTER), "adopting a breed never drops the starter")

func test_set_active_only_among_owned() -> void:
	var r := BreedRoster.new()
	# Can't activate a breed you don't own — a no-op returning false, active unchanged.
	assert_false(r.set_active("chocolate_labrador"), "activating an unowned breed is a no-op (false)")
	assert_eq(r.active, BreedRoster.STARTER, "an unowned activation never changes the active breed")
	# Adopt it, then it becomes activatable.
	r.adopt("chocolate_labrador")
	assert_true(r.set_active("chocolate_labrador"), "an owned breed can be made active (true)")
	assert_eq(r.active, "chocolate_labrador", "the active breed switches to the chosen owned breed")

func test_to_dict_restore_round_trips() -> void:
	var r := BreedRoster.new()
	r.adopt("chocolate_labrador")
	r.set_active("chocolate_labrador")
	var back := BreedRoster.new()
	back.restore(r.to_dict())
	assert_true(back.owns("chocolate_labrador"), "owned breeds survive to_dict/restore")
	assert_true(back.owns(BreedRoster.STARTER), "the starter survives the round-trip")
	assert_eq(back.active, "chocolate_labrador", "the active breed survives the round-trip")

func test_restore_clamps_garbage_to_starter_only() -> void:
	var r := BreedRoster.new()
	r.restore({"owned": "not-an-array", "active": 42})
	assert_true(r.owns(BreedRoster.STARTER), "a garbage roster still owns the starter (never dog-less)")
	assert_false(r.owns("chocolate_labrador"), "garbage never grants an unearned breed")
	assert_eq(r.active, BreedRoster.STARTER, "a garbage active clamps to the starter")

func test_restore_ignores_unknown_breed_ids() -> void:
	var r := BreedRoster.new()
	r.restore({"owned": ["ghost_breed", "chocolate_labrador"], "active": "ghost_breed"})
	assert_false(r.owns("ghost_breed"), "an unknown (unshipped) breed id is never admitted")
	assert_true(r.owns("chocolate_labrador"), "a known breed id in the save IS restored")
	assert_eq(r.active, BreedRoster.STARTER, "an unowned/unknown active clamps back to the starter")

func test_restore_unowned_active_clamps_to_starter() -> void:
	var r := BreedRoster.new()
	# A save that names a valid active breed the owned list does NOT include → active clamps to starter.
	r.restore({"owned": ["labrador"], "active": "chocolate_labrador"})
	assert_eq(r.active, BreedRoster.STARTER, "the active breed must be one the player owns")
