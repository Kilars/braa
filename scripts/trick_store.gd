class_name TrickStore
extends RefCounted
## Local persistence for the player's saved state (049, P2-5 "leave and come back" / X-7): the
## per-trick learned progress map {trick_id: {value, mastered}} and (068, P3-D3) the coin balance,
## in ONE JSON blob at user:// — IndexedDB-backed on web, so a save needs no backend, no account,
## and no network: the game is fully offline-capable (X-7), and a returning player picks up their
## learned bars / mastery checkpoints AND their coins where they left off.
##
## The pure encode/decode codec is split from the disk I/O so the round-trip is unit-testable
## headless (test_trick_store.gd); the user:// read/write also works headless in Godot, so the
## full path is covered too. main.gd loads this on boot into TrickProgress (045) and saves
## after every change to the learned bar. The store stays DUMB about the model's rules
## (mastery latch, floor) — TrickProgress owns its own shape via to_dict()/restore().

const SAVE_PATH := "user://braa_save.json"
const SCHEMA_VERSION := 1

## Pure: model map (+ optional coin balance) -> JSON string. {sitt: {value: 0.6, mastered: false}}
## -> "{...}". Stamps the schema version so a future format change is detectable — decode() rejects
## a mismatched version rather than silently mis-reading an old or foreign blob. `coins` (068,
## P3-D3) rides the SAME save file so a returning player restores tricks and coins atomically; it
## defaults to 0 so every pre-068 caller (which passes only a tricks map) is unchanged. `roster`
## (079, P3-4) rides the same blob. `difficulty` (080, P4-1) rides the same blob and defaults to
## "normal" so every pre-080 caller is unchanged. `words` (091, P5-1) rides the same blob and
## defaults to {} so every pre-091 caller is unchanged. `kennel` (109, Phase 8 K-7) rides the same
## blob and defaults to {} so every pre-109 caller is unchanged — a missing kennel key decodes to
## the Bella-only default via decode_kennel, keeping all prior saves byte-compatible.
static func encode(tricks: Dictionary, coins: int = 0, roster: Dictionary = {}, difficulty: String = "normal", words: Dictionary = {}, kennel: Dictionary = {}) -> String:
	return JSON.stringify({"version": SCHEMA_VERSION, "tricks": tricks, "coins": coins, "roster": roster, "difficulty": difficulty, "words": words, "kennel": kennel})

## The owned-breeds roster a corrupt / empty / legacy (pre-079) save degrades to (079, P3-4): owning +
## active the starter Labrador, never empty — a broken save never strands the player with no dog. A
## fresh Dictionary each call (never a shared mutable). The literal "labrador" is BreedRoster.STARTER;
## the store stays a dumb byte-carrier, so it doesn't import the model to name its own default.
static func _default_roster() -> Dictionary:
	return {"owned": ["labrador"], "active": "labrador"}

## Pure: JSON string -> model map. Corrupt / empty / non-dictionary / wrong-version all degrade
## to {} — a clean zero state, never a crash. A broken save just starts the player fresh; the
## game always boots (P2-5). Returns the inner {trick_id: {value, mastered}} map.
static func decode(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	if parsed.get("version") != SCHEMA_VERSION:
		return {}
	var tricks: Variant = parsed.get("tricks")
	return tricks if typeof(tricks) == TYPE_DICTIONARY else {}

## Pure: JSON string -> coin balance (068, P3-D3). A coins-less legacy (049-era) save, a corrupt /
## empty / wrong-version blob, or a negative value all degrade to 0 — a broken save never hands the
## player debt or free coins, and the game always boots.
static func decode_coins(text: String) -> int:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return 0
	if parsed.get("version") != SCHEMA_VERSION:
		return 0
	return maxi(0, int(parsed.get("coins", 0)))

## Pure: JSON string -> the owned-breeds roster entry (079, P3-4). A missing (pre-079) / corrupt /
## empty / wrong-version blob degrades to the starter-only default, so a returning player always at
## least owns the Labrador. The invariants (starter always owned, active must be owned, only known ids)
## are re-asserted by BreedRoster.restore — this just hands back the stored dict or the safe default.
static func decode_roster(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _default_roster()
	if parsed.get("version") != SCHEMA_VERSION:
		return _default_roster()
	var roster: Variant = parsed.get("roster")
	return roster if typeof(roster) == TYPE_DICTIONARY and not (roster as Dictionary).is_empty() else _default_roster()

## The marker-words state a corrupt / empty / legacy (pre-091) save degrades to (091, P5-1):
## only the base "bra" unlocked and active — a broken save never strands the player without a
## praise word. A fresh Dictionary each call (never a shared mutable).
static func _default_words() -> Dictionary:
	return {"unlocked": ["bra"], "active": "bra"}

## Pure: JSON string -> the marker-words entry (091, P5-1). A missing (pre-091) / corrupt /
## empty / wrong-version blob degrades to the base-only default, so a returning player always
## at least has "bra". The invariants (bra always unlocked, active must be unlocked, only
## known ids) are re-asserted by MarkerWords.restore — this just hands back the stored dict
## or the safe default.
static func decode_words(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _default_words()
	if parsed.get("version") != SCHEMA_VERSION:
		return _default_words()
	var words: Variant = parsed.get("words")
	return words if typeof(words) == TYPE_DICTIONARY and not (words as Dictionary).is_empty() else _default_words()

## Pure: JSON string -> difficulty mode id (080, P4-1). A missing (pre-080) / corrupt /
## empty / wrong-version blob, or an unknown mode id, degrades to "normal" — the identity
## mode (no lever changes). So a legacy save or a corrupt setting always boots safely to Normal.
static func decode_difficulty(text: String) -> String:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return "normal"
	if parsed.get("version") != SCHEMA_VERSION:
		return "normal"
	var difficulty: Variant = parsed.get("difficulty", "normal")
	if typeof(difficulty) != TYPE_STRING:
		return "normal"
	var mode_id := difficulty as String
	if Difficulty.is_known(mode_id):
		return mode_id
	return "normal"

## The kennel-dog roster a corrupt / empty / legacy (pre-109) save degrades to (109, Phase 8 K-7):
## owning + active the starter Bella, never empty — a broken save never strands the player with no
## kennel dog. A fresh Dictionary each call (never a shared mutable). The literal "bella" is
## KennelRoster.STARTER / KennelDog.STARTER_ID; the store stays a dumb byte-carrier.
static func _default_kennel() -> Dictionary:
	return {"owned": ["bella"], "active": "bella"}

## Pure: JSON string -> the owned kennel-dog roster entry (109, Phase 8 K-7). A missing (pre-109) /
## corrupt / empty / wrong-version blob degrades to the starter-only default, so a returning player
## always at least owns Bella. The invariants (starter always owned, active must be owned, only
## known ids) are re-asserted by KennelRoster.restore — this just hands back the stored dict or
## the safe default.
func decode_kennel(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _default_kennel()
	if parsed.get("version") != SCHEMA_VERSION:
		return _default_kennel()
	var kennel: Variant = parsed.get("kennel")
	return kennel if typeof(kennel) == TYPE_DICTIONARY and not (kennel as Dictionary).is_empty() else _default_kennel()

## Write the model map (+ coin balance) to user:// (IndexedDB on web). Best-effort: if the file
## can't be opened we skip rather than crash mid-play — a momentarily lost save is never worth a
## runtime error, and the next progress change re-attempts the write. `coins` defaults to 0 so a
## pre-068 caller is unchanged. `roster` defaults to empty so a pre-079 caller is unchanged.
## `difficulty` defaults to "normal" so a pre-080 caller is unchanged. `words` defaults to {} so
## a pre-091 caller is unchanged. `kennel` defaults to {} so a pre-109 caller is unchanged.
func save(tricks: Dictionary, coins: int = 0, roster: Dictionary = {}, difficulty: String = "normal", words: Dictionary = {}, kennel: Dictionary = {}) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(encode(tricks, coins, roster, difficulty, words, kennel))

## Read the saved model map back. First run (no file) -> {} clean zero state, never a crash; a
## present-but-corrupt file also degrades to {} via decode().
func load() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	return decode(f.get_as_text()) if f != null else {}

## Read the saved coin balance back (068, P3-D3). First run (no file) or any corrupt/legacy save ->
## 0, never a crash.
func load_coins() -> int:
	if not FileAccess.file_exists(SAVE_PATH):
		return 0
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	return decode_coins(f.get_as_text()) if f != null else 0

## Read the saved owned-breeds roster back (079, P3-4). First run (no file) or any corrupt/legacy save
## -> the starter-only default, never a crash and never a dog-less player.
func load_roster() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_roster()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	return decode_roster(f.get_as_text()) if f != null else _default_roster()

## Read the saved difficulty mode id back (080, P4-1). First run (no file) or any corrupt/legacy save
## -> "normal" (the identity mode), never a crash and never an unknown mode.
func load_difficulty() -> String:
	if not FileAccess.file_exists(SAVE_PATH):
		return "normal"
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	return decode_difficulty(f.get_as_text()) if f != null else "normal"

## Read the saved marker-words state back (091, P5-1). First run (no file) or any corrupt/legacy
## save -> the base-only default {"unlocked": ["bra"], "active": "bra"}, never a crash and never
## a wordless player.
func load_words() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_words()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	return decode_words(f.get_as_text()) if f != null else _default_words()

## Read the saved kennel-dog roster back (109, Phase 8 K-7). First run (no file) or any
## corrupt/legacy save -> the Bella-only default, never a crash and never a dog-less kennel.
func load_kennel() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return _default_kennel()
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	return decode_kennel(f.get_as_text()) if f != null else _default_kennel()
