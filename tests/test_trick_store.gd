extends "res://tests/test_case.gd"
## TDD for the save store (049, P2-5 "leave and come back" / X-7 offline). TrickStore is the
## local persistence for per-trick learned progress: one JSON map {trick_id: {value, mastered}}
## at user:// (IndexedDB-backed on web — no backend, no account, no network). The pure
## encode/decode codec is unit-testable in isolation; the user:// read/write also works
## headless in Godot, so the full disk round-trip is covered here too. A corrupt / empty /
## missing / wrong-version save degrades to a clean zero state ({}), never a crash — a broken
## save just starts the player fresh, the game always boots.

## Disk tests share user://braa_save.json; clear it before AND after so they are hermetic and
## leave user:// clean for the boot/export legs and every scene-mount test that follows.
func _clear_save() -> void:
	if FileAccess.file_exists(TrickStore.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TrickStore.SAVE_PATH))

func _approx(a: float, b: float) -> bool:
	return absf(a - b) < 1e-6

# 1. Round-trip — encode then decode returns the same model map.
func test_round_trip_preserves_a_trick_entry() -> void:
	var model := {"sitt": {"value": 0.6, "mastered": false}}
	var back := TrickStore.decode(TrickStore.encode(model))
	assert_true(back.has("sitt"), "the decoded map keeps the trick key")
	var sitt: Dictionary = back["sitt"]
	assert_true(_approx(sitt["value"], 0.6), "value survives the round-trip")
	assert_eq(sitt["mastered"], false, "mastered survives the round-trip")

# 2. (mastery survival is asserted at the model level in test_trick_progress.gd::
#    test_restore_relatches_mastery — the store just carries the bytes.)

# 3. Corrupt / empty / missing → {} clean zero state, no crash.
func test_empty_string_decodes_to_clean_zero() -> void:
	assert_eq(TrickStore.decode("").size(), 0, "an empty save decodes to a clean zero state")

func test_garbage_decodes_to_clean_zero() -> void:
	assert_eq(TrickStore.decode("{garbage not json").size(), 0, "a corrupt save decodes to {} — no crash")
	assert_eq(TrickStore.decode("[1,2,3]").size(), 0, "a non-dictionary JSON value decodes to {}")

func test_missing_file_loads_to_clean_zero() -> void:
	_clear_save()
	var store := TrickStore.new()
	assert_eq(store.load().size(), 0, "first run (no file) loads a clean zero state, never a crash")

# 4. Wrong schema version → {} (forward-compat guard: never mis-read an old/foreign blob).
func test_wrong_version_decodes_to_clean_zero() -> void:
	var blob := JSON.stringify({"version": 0, "tricks": {"sitt": {"value": 0.9, "mastered": true}}})
	assert_eq(TrickStore.decode(blob).size(), 0, "a wrong-version save is rejected to {} (forward-compat)")

# 5. Unknown trick id in the saved map is ignored; a known trick is found.
func test_unknown_trick_id_is_ignored_known_restores() -> void:
	var model := {"wobble": {"value": 0.4, "mastered": false}, "sitt": {"value": 0.5, "mastered": false}}
	var back := TrickStore.decode(TrickStore.encode(model))
	# A consumer keys by the trick it cares about; an unknown id is simply never looked up.
	assert_false(back.get("sitt", {}).is_empty(), "the known trick is present to restore")
	var p := TrickProgress.new()
	p.restore(back.get("sitt", {}))
	assert_true(_approx(p.value, 0.5), "restoring by the known key picks the right entry, not the unknown one")

# 6. Disk round-trip through the real user:// path (not just the pure codec).
func test_disk_round_trip_through_user_path() -> void:
	_clear_save()
	var model := {"sitt": {"value": 0.7, "mastered": false}}
	var writer := TrickStore.new()
	writer.save(model)
	# A FRESH store reads the same map back off disk — proves SAVE_PATH actually works.
	var reader := TrickStore.new()
	var back := reader.load()
	assert_true(back.has("sitt"), "the saved trick reads back off user://")
	assert_true(_approx(back["sitt"]["value"], 0.7), "the saved value reads back off user://")
	_clear_save()

# Named constants, not scattered literals (cf. 029).
func test_constants_are_named() -> void:
	assert_eq(TrickStore.SCHEMA_VERSION, 1, "schema version is a named constant")
	assert_true(TrickStore.SAVE_PATH.begins_with("user://"), "the save lives under user:// (X-7 offline, no backend)")
