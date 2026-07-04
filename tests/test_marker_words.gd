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

## TDD for task 093 (P5-2): per-word effect + cooldown model. Stronger words widen
## the PERFECT window but carry a cooldown; base "bra" is the always-available default
## with no window widening and no cooldown. The cooldown tracker ensures a stronger
## word is not a free upgrade — it's a genuine choice with a downside.

func test_bra_has_identity_window_scale_and_no_cooldown() -> void:
	var w := MarkerWords.new()
	assert_eq(w.window_scale("bra"), 1.0, "base 'bra' has window_scale 1.0 (identity)")
	assert_eq(w.cooldown("bra"), 0, "base 'bra' has cooldown 0 (never cools down)")

func test_stronger_word_has_widened_window_and_cooldown() -> void:
	var w := MarkerWords.new()
	w.unlock("kjempebra")
	assert_true(w.window_scale("kjempebra") > 1.0, "'kjempebra' has window_scale > 1.0")
	assert_true(w.cooldown("kjempebra") > 0, "'kjempebra' has cooldown > 0")

func test_all_stronger_words_have_window_scale_and_cooldown() -> void:
	var w := MarkerWords.new()
	w.unlock_up_to(4)
	for entry in MarkerWords.CATALOG:
		var id: String = entry["id"]
		if id != "bra":
			assert_true(w.window_scale(id) > 1.0, id + " has window_scale > 1.0")
			assert_true(w.cooldown(id) > 0, id + " has cooldown > 0")

func test_bra_active_firing_never_enters_cooldown() -> void:
	var w := MarkerWords.new()
	assert_eq(w.active(), "bra", "start with bra active")
	for i in range(5):
		var fired: String = w.fire_active(true)
		assert_eq(fired, "bra", "fired word is 'bra'")
		assert_false(w.is_on_cooldown("bra"), "'bra' never enters cooldown (iteration " + str(i) + ")")
	assert_eq(w.active_is_available(), true, "bra is always available")

func test_bra_effective_window_scale_always_identity() -> void:
	var w := MarkerWords.new()
	w.set_active("bra")
	for _i in range(3):
		var ews: float = w.effective_window_scale()
		assert_eq(ews, 1.0, "effective_window_scale is 1.0 for bra (identity)")
		w.fire_active(true)

func test_stronger_word_active_and_available_fires_and_arms_cooldown() -> void:
	var w := MarkerWords.new()
	w.unlock("kjempebra")
	w.set_active("kjempebra")
	assert_true(w.active_is_available(), "stronger word is available at start")
	var fired: String = w.fire_active(true)
	assert_eq(fired, "kjempebra", "fire_active returns the stronger word when not on cooldown")
	assert_true(w.is_on_cooldown("kjempebra"), "kjempebra enters cooldown after firing")

func test_while_stronger_word_on_cooldown_effective_word_falls_back_to_bra() -> void:
	var w := MarkerWords.new()
	w.unlock("dyktig")
	w.set_active("dyktig")
	w.fire_active(true)  # arm cooldown
	assert_true(w.is_on_cooldown("dyktig"), "dyktig is on cooldown")
	var fired: String = w.fire_active(true)
	assert_eq(fired, "bra", "while on cooldown, the effective fired word is 'bra'")

func test_while_stronger_word_on_cooldown_effective_window_scale_is_base() -> void:
	var w := MarkerWords.new()
	w.unlock("super")
	w.set_active("super")
	w.fire_active(true)  # arm cooldown
	assert_eq(w.effective_window_scale(), 1.0, "while on cooldown, effective_window_scale is 1.0 (base)")

func test_cooldown_decrements_only_on_successful_marks() -> void:
	var w := MarkerWords.new()
	w.unlock("dyktig")
	w.set_active("dyktig")
	var cooldown_count: int = w.cooldown("dyktig")
	assert_true(cooldown_count > 0, "dyktig has a non-zero cooldown")
	w.fire_active(true)  # arm cooldown
	# Fire with succeeded=false; cooldown should NOT decrement
	w.fire_active(false)
	assert_true(w.is_on_cooldown("dyktig"), "cooldown persists after a failed mark (succeeded=false)")
	# Fire with succeeded=true; cooldown should decrement by 1
	w.fire_active(true)
	assert_true(w.is_on_cooldown("dyktig"), "cooldown still active after one successful mark")

func test_cooldown_decrements_by_one_per_successful_mark_until_available() -> void:
	var w := MarkerWords.new()
	w.unlock("dyktig")
	w.set_active("dyktig")
	var cooldown_count: int = w.cooldown("dyktig")
	w.fire_active(true)  # arm cooldown for cooldown_count marks
	# Exhaust the cooldown with successful marks
	for i in range(cooldown_count):
		assert_true(w.is_on_cooldown("dyktig"), "dyktig is on cooldown (iteration " + str(i) + ")")
		w.fire_active(true)
	# After exactly cooldown_count successful marks, it should be available
	assert_false(w.is_on_cooldown("dyktig"), "after exactly cooldown_count marks, dyktig is available again")
	var fired: String = w.fire_active(true)
	assert_eq(fired, "dyktig", "now fire_active returns dyktig again (no longer cooling)")

func test_switch_word_mid_cooldown_and_switch_back_preserves_cooldown_state() -> void:
	var w := MarkerWords.new()
	w.unlock("dyktig")
	w.unlock("super")
	w.set_active("dyktig")
	w.fire_active(true)  # arm dyktig's cooldown
	assert_true(w.is_on_cooldown("dyktig"), "dyktig is on cooldown")
	w.set_active("super")  # switch to super
	w.fire_active(true)  # arm super's cooldown too
	assert_true(w.is_on_cooldown("super"), "super is on cooldown")
	# Switch back to dyktig: its cooldown state should persist
	w.set_active("dyktig")
	assert_true(w.is_on_cooldown("dyktig"), "switching back to dyktig preserves its cooldown state")
	var fired: String = w.fire_active(true)
	assert_eq(fired, "bra", "dyktig is still cooling, so effective word is 'bra'")
