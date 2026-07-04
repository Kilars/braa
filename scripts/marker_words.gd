class_name MarkerWords
extends RefCounted
## The marker-word catalog (091, P5-1 "progressive unlock"). A pure value object — the set of
## unlocked word ids + the one active word id — with the same to_dict/restore shape BreedRoster /
## TrickProgress use, so TrickStore stays dumb about the rules.
##
## Invariants this owns (never a wordless player):
##   - The BASE word "bra" is ALWAYS unlocked. A corrupt / legacy / empty save degrades to
##     "bra" only — the player is never left without a praise word.
##   - The active word is ALWAYS one the player has unlocked. Activating a locked word is a
##     no-op; a restored active that isn't unlocked clamps back to "bra".
##   - Only KNOWN (catalog) ids are admitted — a save naming a ghost word never grants it.

## The word every player has from the first run.
const BASE_ID := "bra"

## Ordered catalog: first entry = base (always unlocked); entries 2-5 unlock progressively as
## tricks are mastered. Order determines unlock order (unlock_up_to respects it). Each entry:
## {id, display, clip} — clip is the res:// path to the voiced line asset.
const CATALOG: Array = [
	{"id": "bra",       "display": "Bra!",       "clip": "res://assets/audio/bra_tts_placeholder.wav"},
	{"id": "dyktig",    "display": "Dyktig!",    "clip": "res://assets/audio/word_dyktig_placeholder.wav"},
	{"id": "flink",     "display": "Flink!",     "clip": "res://assets/audio/word_flink_placeholder.wav"},
	{"id": "super",     "display": "Super!",     "clip": "res://assets/audio/word_super_placeholder.wav"},
	{"id": "kjempebra", "display": "Kjempebra!", "clip": "res://assets/audio/word_kjempebra_placeholder.wav"},
]

## The set of unlocked word ids (BASE_ID always present) and the currently active one.
var _unlocked := {"bra": true}
var _active := "bra"

## True iff the player has unlocked this word id.
func is_unlocked(id: String) -> bool:
	return _unlocked.get(id, false)

## Unlock a single word by id. Returns true if newly unlocked, false if already unlocked or not
## a catalog id (no-op for ghost ids). BASE_ID is always unlocked; re-unlocking it returns false.
## Unlock ADDS to the collection but does NOT change the active word — base "bra" stays the
## default (P5-2) until the player deliberately loads the new word (P5-4). No auto-activate: a
## stronger word is a genuine choice, never a forced upgrade.
func unlock(id: String) -> bool:
	if not _is_catalog_id(id):
		return false
	if _unlocked.get(id, false):
		return false
	_unlocked[id] = true
	return true

## Unlock the first `count` catalog words BEYOND the base (i.e. treat the base as already
## granted; count=1 unlocks the 2nd catalog entry, count=2 unlocks the 2nd+3rd, etc.).
## Returns the array of newly-unlocked ids (ids that were locked before this call). Idempotent:
## a word already unlocked is skipped and not included in the returned array. count ≤ 0 is a no-op.
## Does NOT change the active word — unlocking is collection, not selection (see unlock()).
func unlock_up_to(count: int) -> Array:
	var newly: Array = []
	if count <= 0:
		return newly
	# CATALOG[0] is BASE_ID (already unlocked). Beyond-base entries start at index 1.
	var beyond_base_seen := 0
	for entry in CATALOG:
		var id: String = entry["id"]
		if id == BASE_ID:
			continue  # base is implicit; doesn't count toward the `count`
		beyond_base_seen += 1
		if beyond_base_seen > count:
			break  # we've consumed the requested count
		if not _unlocked.get(id, false):
			_unlocked[id] = true
			newly.append(id)
	return newly

## The currently active word id.
func active() -> String:
	return _active

## Switch the active word to `id`. Returns true if the switch happened; false if the word is
## locked or not a catalog id (no-op — the active word is left unchanged).
func set_active(id: String) -> bool:
	if not _is_catalog_id(id):
		return false
	if not _unlocked.get(id, false):
		return false
	_active = id
	return true

## The display string for a catalog id (e.g. "Dyktig!"). Returns "" for unknown ids.
func display_for(id: String) -> String:
	for entry in CATALOG:
		if entry["id"] == id:
			return entry["display"]
	return ""

## The res:// clip path for a catalog id. Returns "" for unknown ids.
func clip_for(id: String) -> String:
	for entry in CATALOG:
		if entry["id"] == id:
			return entry["clip"]
	return ""

## Model → save entry (TrickStore stays dumb; MarkerWords owns its shape).
## {"unlocked": [...ids in unlock order], "active": id}
func to_dict() -> Dictionary:
	# Preserve catalog order in the unlocked list for readability / round-trip stability.
	var ids: Array = []
	for entry in CATALOG:
		var id: String = entry["id"]
		if _unlocked.get(id, false):
			ids.append(id)
	return {"unlocked": ids, "active": _active}

## Restore from a saved entry. Rebuilds from the base-only baseline, then re-admits only KNOWN
## unlocked ids and clamps the active to an unlocked word — so a garbage / partial / ghost-id save
## always lands on a valid state that has at least "bra" and never activates a word not unlocked.
func restore(d: Dictionary) -> void:
	_unlocked = {"bra": true}
	_active = BASE_ID
	var raw: Variant = d.get("unlocked", [])
	if raw is Array:
		for id_v in raw:
			if id_v is String and _is_catalog_id(id_v) and not _unlocked.get(id_v, false):
				_unlocked[id_v] = true
	var a: Variant = d.get("active", BASE_ID)
	if a is String and _unlocked.get(a, false):
		_active = a
	# else: _active stays BASE_ID (clamp)

## True iff `id` appears in CATALOG (guards against ghost/unknown ids).
func _is_catalog_id(id: String) -> bool:
	for entry in CATALOG:
		if entry["id"] == id:
			return true
	return false
