extends "res://tests/test_case.gd"
## TDD for the marker-words catalog (091, P5-1 "progressive unlock"). MarkerWords is a pure value
## object — the set of unlocked word ids + the one active word id — with the same to_dict/restore
## shape TrickProgress / BreedRoster use so TrickStore stays dumb about the rules.
##
## The invariants these pin: the BASE word "bra" is ALWAYS unlocked and the default active (a corrupt /
## legacy / empty save degrades to "bra only," never wordless); the active word is ALWAYS one the player
## has unlocked (activating a locked word is a no-op); restore admits only KNOWN word ids and clamps an
## inactive/unknown active back to "bra"; the catalog is stable in order (unlock_up_to respects that order).

func test_base_bra_unlocked_and_active_by_default() -> void:
	var w := MarkerWords.new()
	assert_true(w.is_unlocked("bra"), "the base word 'bra' is unlocked from the first run")
	assert_eq(w.active(), "bra", "the base word 'bra' is the active word by default")
	assert_eq(MarkerWords.BASE_ID, "bra", "the base id is named 'bra'")

func test_catalog_has_five_entries_in_stable_order() -> void:
	assert_eq(MarkerWords.CATALOG.size(), 5, "the catalog has 5 entries")
	var ids := []
	for entry in MarkerWords.CATALOG:
		ids.append(entry["id"])
	assert_eq(ids, ["bra", "dyktig", "flink", "super", "kjempebra"], "catalog order is stable")

func test_catalog_entries_have_display_and_clip() -> void:
	for entry in MarkerWords.CATALOG:
		assert_true(entry.has("id"), "each entry has an id")
		assert_true(entry.has("display"), "each entry has a display string")
		assert_true(entry.has("clip"), "each entry has a clip path")

func test_unlock_returns_true_first_time_false_on_repeat() -> void:
	var w := MarkerWords.new()
	assert_true(w.unlock("dyktig"), "unlocking a locked word returns true the first time")
	assert_false(w.unlock("dyktig"), "unlocking an already-unlocked word returns false")
	assert_true(w.is_unlocked("dyktig"), "is_unlocked reflects the unlock")

func test_unlock_unknown_word_is_noop() -> void:
	var w := MarkerWords.new()
	assert_false(w.unlock("ghost_word"), "unlocking an unknown word returns false (no-op)")
	assert_false(w.is_unlocked("ghost_word"), "the unknown word stays locked")

func test_unlock_up_to_unlocks_first_n_beyond_base() -> void:
	var w := MarkerWords.new()
	var newly_unlocked := w.unlock_up_to(2)
	assert_eq(newly_unlocked as Array, ["dyktig", "flink"], "unlock_up_to(2) returns the first two beyond base")
	assert_true(w.is_unlocked("dyktig"), "the first word beyond base is unlocked")
	assert_true(w.is_unlocked("flink"), "the second word beyond base is unlocked")
	assert_false(w.is_unlocked("super"), "the third word stays locked")

func test_unlock_up_to_is_idempotent() -> void:
	var w := MarkerWords.new()
	w.unlock_up_to(2)
	var again := w.unlock_up_to(2)
	assert_eq(again as Array, [], "calling unlock_up_to(2) again returns empty (idempotent)")
	assert_true(w.is_unlocked("dyktig"), "the words stay unlocked")
	assert_true(w.is_unlocked("flink"), "the words stay unlocked")

func test_unlock_up_to_zero_unlocks_nothing() -> void:
	var w := MarkerWords.new()
	var unlocked := w.unlock_up_to(0)
	assert_eq(unlocked as Array, [], "unlock_up_to(0) returns empty")
	assert_false(w.is_unlocked("dyktig"), "no words beyond base are unlocked")

func test_unlock_up_to_respects_catalog_order() -> void:
	var w := MarkerWords.new()
	var first := w.unlock_up_to(1)
	assert_eq(first as Array, ["dyktig"], "the first unlock is the second catalog entry (dyktig)")
	w.unlock("flink")  # manually unlock #3
	var second := w.unlock_up_to(3)
	# dyktig + flink already unlocked; unlock_up_to(3) -> super only (the third beyond base)
	assert_eq(second as Array, ["super"], "unlock_up_to respects catalog order and skips already-unlocked")

func test_set_active_to_locked_word_is_noop() -> void:
	var w := MarkerWords.new()
	assert_false(w.set_active("dyktig"), "activating a locked word is a no-op (false)")
	assert_eq(w.active(), "bra", "the active word stays 'bra'")

func test_set_active_to_unlocked_word_switches() -> void:
	var w := MarkerWords.new()
	w.unlock("dyktig")
	assert_true(w.set_active("dyktig"), "activating an unlocked word returns true")
	assert_eq(w.active(), "dyktig", "the active word switches to the chosen unlocked word")

func test_set_active_unknown_word_is_noop() -> void:
	var w := MarkerWords.new()
	assert_false(w.set_active("ghost_word"), "activating an unknown word is a no-op (false)")
	assert_eq(w.active(), "bra", "the active word stays 'bra'")

func test_to_dict_restore_round_trips() -> void:
	var w := MarkerWords.new()
	w.unlock("dyktig")
	w.unlock("flink")
	w.set_active("flink")
	var back := MarkerWords.new()
	back.restore(w.to_dict())
	assert_true(back.is_unlocked("dyktig"), "unlocked words survive to_dict/restore")
	assert_true(back.is_unlocked("flink"), "unlocked words survive to_dict/restore")
	assert_false(back.is_unlocked("super"), "locked words stay locked after restore")
	assert_eq(back.active(), "flink", "the active word survives the round-trip")
	assert_true(back.is_unlocked("bra"), "the base word 'bra' survives (always unlocked)")

func test_to_dict_format_is_unlocked_and_active() -> void:
	var w := MarkerWords.new()
	w.unlock("dyktig")
	var d := w.to_dict()
	assert_true(d.has("unlocked"), "to_dict has an 'unlocked' key")
	assert_true(d.has("active"), "to_dict has an 'active' key")
	var unlocked: Variant = d.get("unlocked")
	assert_true(unlocked is Array, "unlocked is an array")
	assert_true((unlocked as Array).has("bra"), "'bra' is in the unlocked array")
	assert_true((unlocked as Array).has("dyktig"), "newly-unlocked words are in the array")
	# Unlock ADDS to the collection but does NOT change the active word — base "bra" stays the
	# default (P5-2) until the player deliberately loads another word (P5-4). No auto-activate.
	assert_eq(d.get("active"), "bra", "unlocking a word does not change the active word")

func test_unlock_does_not_change_active_word() -> void:
	var w := MarkerWords.new()
	assert_true(w.unlock("dyktig"), "dyktig is newly unlocked")
	assert_eq(w.active(), "bra", "active stays 'bra' after unlock (no auto-activate)")
	w.unlock_up_to(3)
	assert_eq(w.active(), "bra", "active stays 'bra' after unlock_up_to (player chooses via set_active)")

func test_restore_with_unowned_active_clamps_to_base() -> void:
	var w := MarkerWords.new()
	# A save that names a valid word as active, but that word is NOT in unlocked -> active clamps to "bra".
	w.restore({"unlocked": ["bra", "dyktig"], "active": "flink"})
	assert_eq(w.active(), "bra", "an unlocked-list that doesn't include active clamps the active to 'bra'")

func test_restore_ignores_unknown_word_ids() -> void:
	var w := MarkerWords.new()
	w.restore({"unlocked": ["ghost_word", "dyktig"], "active": "ghost_word"})
	assert_false(w.is_unlocked("ghost_word"), "an unknown word id is never admitted")
	assert_true(w.is_unlocked("dyktig"), "a known word id in the save IS restored")
	assert_eq(w.active(), "bra", "an unknown active clamps back to 'bra'")

func test_restore_always_asserts_bra_unlocked() -> void:
	var w := MarkerWords.new()
	# A save that omits "bra" from the unlocked list -> restore re-asserts it (legacy-safe).
	w.restore({"unlocked": ["dyktig", "flink"], "active": "dyktig"})
	assert_true(w.is_unlocked("bra"), "'bra' is always unlocked after restore, even if omitted from the dict")
	assert_eq(w.active(), "dyktig", "the active word is restored correctly despite 'bra' being implicit")

func test_restore_clamps_garbage_to_base_only() -> void:
	var w := MarkerWords.new()
	w.restore({"unlocked": "not-an-array", "active": 42})
	assert_true(w.is_unlocked("bra"), "a garbage restore still has 'bra' unlocked")
	assert_false(w.is_unlocked("dyktig"), "garbage never grants an unearned word")
	assert_eq(w.active(), "bra", "a garbage active clamps to 'bra'")
