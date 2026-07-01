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
## defaults to 0 so every pre-068 caller (which passes only a tricks map) is unchanged.
static func encode(tricks: Dictionary, coins: int = 0) -> String:
	return JSON.stringify({"version": SCHEMA_VERSION, "tricks": tricks, "coins": coins})

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

## Write the model map (+ coin balance) to user:// (IndexedDB on web). Best-effort: if the file
## can't be opened we skip rather than crash mid-play — a momentarily lost save is never worth a
## runtime error, and the next progress change re-attempts the write. `coins` defaults to 0 so a
## pre-068 caller is unchanged.
func save(tricks: Dictionary, coins: int = 0) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(encode(tricks, coins))

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
