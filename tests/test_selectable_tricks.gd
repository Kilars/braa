extends "res://tests/test_case.gd"
## TDD for K-8 wiring (113): the training trick menu must reflect the ACTIVE breed's OWN trick list,
## not a global const. `main._performable(wanted, director)` is the pure gate — it keeps only the ids
## the loaded rig can actually perform, in the ACTIVE-list order (never-fake gate). Today every dog
## shares the core, so the observable menu is unchanged; these tests pin that the SOURCE is the active
## dog's `trick_ids`, so a breed whose list differs (once an owner signature clip lands) is honoured
## rather than every dog offered the same static set.

const Main := preload("res://scripts/main.gd")

# A stand-in for DogDirector: has_trick(id) is true only for ids in the given set.
class FakeDirector:
	var _can := {}
	func _init(ids: Array) -> void:
		for id in ids:
			_can[id] = true
	func has_trick(id: String) -> bool:
		return _can.has(id)

func test_performable_keeps_only_what_the_rig_can_do() -> void:
	# The rig can do sitt + legg_deg but NOT ligg → ligg is filtered out (never-fake gate).
	var dir := FakeDirector.new(["sitt", "legg_deg"])
	var out: Array = Main._performable(["sitt", "ligg", "legg_deg"], dir)
	assert_eq(out, ["sitt", "legg_deg"], "a trick the rig can't perform is never offered")

func test_performable_preserves_wanted_order() -> void:
	var dir := FakeDirector.new(["sitt", "ligg", "legg_deg"])
	var out: Array = Main._performable(["legg_deg", "sitt", "ligg"], dir)
	assert_eq(out, ["legg_deg", "sitt", "ligg"], "output follows the active breed's list order")

func test_active_breed_list_is_the_source_not_a_global_const() -> void:
	# The rig CAN perform ligg, but the active breed's list omits it → it is NOT offered. This is the
	# heart of K-8: which dog is active decides what can be trained, even when the rig could do more.
	var dir := FakeDirector.new(["sitt", "ligg", "legg_deg"])
	var out: Array = Main._performable(["sitt", "legg_deg"], dir)
	assert_eq(out, ["sitt", "legg_deg"], "ligg is NOT offered because the active list omits it")

func test_performable_empty_wanted_is_empty() -> void:
	var dir := FakeDirector.new(["sitt", "ligg", "legg_deg"])
	assert_eq(Main._performable([], dir), [], "no active-list tricks → nothing offered")

func test_active_dog_trick_ids_are_legacy_safe() -> void:
	# The active-list source is KennelDog.by_id(active).trick_ids. by_id resolves an empty/legacy/breed
	# id to a real dog (the starter), so the menu never goes trick-less on a corrupt or pre-kennel save.
	var core: Array = KennelDog.core_tricks()
	assert_eq(KennelDog.by_id("").trick_ids, core, "empty active id falls back to the starter's core list")
	assert_eq(KennelDog.by_id("labrador").trick_ids, core, "a legacy breed id falls back to the starter's core list")
	assert_eq(KennelDog.by_id("bella").trick_ids, core, "the starter trains the shared core")
