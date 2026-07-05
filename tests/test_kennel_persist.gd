extends "res://tests/test_case.gd"
## TDD for the kennel-roster persistence slot (109, Phase 8 K-7 "remembered & offline").
## Extends the TrickStore single-blob codec with a trailing `kennel` param on encode() and
## a new decode_kennel(text) decoder — mirroring the decode_roster / decode_words pattern
## exactly, including the byte-compat guarantee: a pre-109 save (no "kennel" key) decodes
## to the Bella-only default {"owned": ["bella"], "active": "bella"}.
##
## Implementation strategy for RED tests: since TrickStore.decode_kennel does not exist yet,
## GDScript would resolve the call at parse time and fail the whole file. Instead, we guard
## each test with a has_method() existence check — that assert is the RED assertion. If the
## method is missing, the test fails with a clear message and stops; once the implementation
## lands, the gate unlocks the rest of the assertions automatically.

## Disk tests share user://braa_save.json; clear before AND after so they are hermetic.
func _clear_save() -> void:
	if FileAccess.file_exists(TrickStore.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TrickStore.SAVE_PATH))

## True iff TrickStore (the class) has a method with this name.
## We cannot call TrickStore.has_method() directly (it's not static), so we instantiate.
func _ts_has(method_name: String) -> bool:
	return TrickStore.new().has_method(method_name)

# 1. decode_kennel: a missing "kennel" key (pre-109 save) → Bella-only default.
func test_decode_kennel_missing_key_defaults_to_bella_only() -> void:
	assert_true(_ts_has("decode_kennel"),
		"TrickStore.decode_kennel must be implemented (not yet present)")
	if not _ts_has("decode_kennel"):
		return
	# A Phase-6 / pre-109 save has no "kennel" key; decoding it must yield the starter default.
	var old_blob := JSON.stringify({
		"version": TrickStore.SCHEMA_VERSION, "tricks": {}, "coins": 10,
		"roster": {"owned": ["labrador"], "active": "labrador"},
		"difficulty": "normal",
		"words": {"unlocked": ["bra"], "active": "bra"}
	})
	var back: Dictionary = TrickStore.new().call("decode_kennel", old_blob)
	assert_eq(back.get("active"), "bella",
		"a pre-109 (Phase-6) save's active kennel dog defaults to 'bella'")
	var owned: Variant = back.get("owned")
	assert_true(owned is Array, "owned is an array in the default")
	assert_true((owned as Array).has("bella"),
		"a pre-109 save owns the starter Bella in the kennel default")
	assert_eq((owned as Array).size(), 1,
		"a pre-109 save owns exactly one dog (Bella only) in the kennel default")

# 2. encode(..., kennel) then decode_kennel round-trips owned and active.
func test_encode_then_decode_kennel_roundtrips_owned_and_active() -> void:
	assert_true(_ts_has("decode_kennel"),
		"TrickStore.decode_kennel must be implemented (not yet present)")
	if not _ts_has("decode_kennel"):
		return
	var kennel := {"owned": ["bella", "sol", "balder"], "active": "sol"}
	# The 6th trailing param on encode() is the new kennel dict.
	# Call encode via an instance to avoid a parse-time arity check on the static.
	var blob: String = TrickStore.new().call("encode", {}, 0, {}, "normal", {}, kennel)
	var back: Dictionary = TrickStore.new().call("decode_kennel", blob)
	assert_eq(back.get("active"), "sol",
		"the active kennel dog round-trips through encode/decode_kennel")
	var owned: Variant = back.get("owned")
	assert_true(owned is Array, "owned is an array after round-trip")
	assert_true((owned as Array).has("bella"), "bella survives the kennel round-trip")
	assert_true((owned as Array).has("sol"), "sol survives the kennel round-trip")
	assert_true((owned as Array).has("balder"), "balder survives the kennel round-trip")
	assert_eq((owned as Array).size(), 3, "exactly 3 dogs in the round-tripped kennel roster")

# 3. decode_kennel: corrupt / garbage / wrong-version → Bella-only default (no crash).
func test_decode_kennel_corrupt_degrades_to_default() -> void:
	assert_true(_ts_has("decode_kennel"),
		"TrickStore.decode_kennel must be implemented (not yet present)")
	if not _ts_has("decode_kennel"):
		return
	for bad in ["", "{garbage not json", "[1,2,3]"]:
		var back: Dictionary = TrickStore.new().call("decode_kennel", bad)
		assert_eq(back.get("active"), "bella",
			"corrupt/empty blob decodes kennel active to 'bella': input='%s'" % bad)
		var owned: Variant = back.get("owned")
		assert_true((owned as Array).has("bella"),
			"corrupt/empty blob degrades to Bella-owned: input='%s'" % bad)
	# Wrong schema version → degrade (forward-compat guard, same as every other decode_* method).
	var wrong_version := JSON.stringify({
		"version": 0, "tricks": {}, "kennel": {"owned": ["bella", "nova"], "active": "nova"}
	})
	var back_wv: Dictionary = TrickStore.new().call("decode_kennel", wrong_version)
	assert_eq(back_wv.get("active"), "bella",
		"a wrong-version save degrades kennel to the starter default (forward-compat)")

# 4. Byte-compat: the 5-param encode() call must still decode_kennel to the Bella-only default.
#    A pre-109 encode() call (no kennel arg) → decode_kennel yields Bella-only.
func test_encode_without_kennel_param_stays_byte_compatible() -> void:
	assert_true(_ts_has("decode_kennel"),
		"TrickStore.decode_kennel must be implemented (not yet present)")
	if not _ts_has("decode_kennel"):
		return
	# Call the existing 5-param encode (no new kennel arg) — no arity workaround needed here.
	var blob := TrickStore.encode({"sitt": {"value": 0.5, "mastered": false}}, 20,
		{"owned": ["labrador"], "active": "labrador"}, "normal",
		{"unlocked": ["bra"], "active": "bra"})
	# All existing decoders must still work (byte-compat guarantee).
	assert_eq(TrickStore.decode_coins(blob), 20,
		"coins still round-trip when encode is called without the kennel param")
	assert_true(TrickStore.decode(blob).has("sitt"),
		"tricks still round-trip when encode is called without the kennel param")
	var back_roster := TrickStore.decode_roster(blob)
	assert_eq(back_roster.get("active"), "labrador",
		"BreedRoster still round-trips when encode is called without the kennel param")
	# decode_kennel on a no-kennel-param blob → Bella-only default (no kennel key present).
	var back_kennel: Dictionary = TrickStore.new().call("decode_kennel", blob)
	assert_eq(back_kennel.get("active"), "bella",
		"decode_kennel on a 5-param encode blob yields the Bella-only default")

# 5. All other fields survive adding the kennel param (no accidental collision).
func test_kennel_key_does_not_collide_with_existing_fields() -> void:
	assert_true(_ts_has("decode_kennel"),
		"TrickStore.decode_kennel must be implemented (not yet present)")
	if not _ts_has("decode_kennel"):
		return
	var kennel := {"owned": ["bella", "sniff"], "active": "sniff"}
	var blob: String = TrickStore.new().call("encode",
		{"ligg": {"value": 0.8, "mastered": true}}, 55,
		{"owned": ["labrador", "chocolate_labrador"], "active": "chocolate_labrador"},
		"hard",
		{"unlocked": ["bra", "dyktig"], "active": "dyktig"},
		kennel
	)
	# Every existing decode_* must still return its value unperturbed.
	assert_eq(TrickStore.decode_coins(blob), 55,
		"coins survive alongside the kennel field")
	assert_true(TrickStore.decode(blob).has("ligg"),
		"tricks survive alongside the kennel field")
	var back_roster := TrickStore.decode_roster(blob)
	assert_eq(back_roster.get("active"), "chocolate_labrador",
		"BreedRoster active survives alongside the kennel field")
	assert_eq(TrickStore.decode_difficulty(blob), "hard",
		"difficulty survives alongside the kennel field")
	var back_words := TrickStore.decode_words(blob)
	assert_eq(back_words.get("active"), "dyktig",
		"marker-words active survives alongside the kennel field")
	# And the new kennel field itself round-trips correctly.
	var back_kennel: Dictionary = TrickStore.new().call("decode_kennel", blob)
	assert_eq(back_kennel.get("active"), "sniff",
		"kennel active round-trips alongside all other fields")

# 6. Disk round-trip: the full save/load_kennel path works end-to-end.
func test_disk_round_trip_carries_kennel() -> void:
	assert_true(_ts_has("load_kennel"),
		"TrickStore.load_kennel must be implemented (not yet present)")
	if not _ts_has("load_kennel"):
		return
	_clear_save()
	var writer := TrickStore.new()
	var kennel_in := {"owned": ["bella", "pontus"], "active": "pontus"}
	writer.call("save",
		{"sitt": {"value": 0.4, "mastered": false}}, 30,
		{"owned": ["labrador"], "active": "labrador"}, "normal",
		{"unlocked": ["bra"], "active": "bra"}, kennel_in)
	var reader := TrickStore.new()
	var back: Dictionary = reader.call("load_kennel")
	assert_eq(back.get("active"), "pontus",
		"kennel active reads back off user://")
	var owned: Variant = back.get("owned")
	assert_true((owned as Array).has("pontus"),
		"pontus reads back off user:// as owned")
	assert_true((owned as Array).has("bella"),
		"bella reads back off user:// as owned")
	assert_eq(reader.load_coins(), 30,
		"coins still read back alongside the kennel field")
	assert_true(reader.load().has("sitt"),
		"tricks still read back alongside the kennel field")
	_clear_save()
