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
##
## Per-word effect + constraint (093, P5-2 "stronger words, real trade-off"):
##   - Each catalog entry carries window_scale (>=1.0 widens the PERFECT hit window) and
##     cooldown_marks (int >= 0 — how many subsequent SUCCESSFUL marks the word rests after
##     firing before it is available again).
##   - Base "bra": window_scale 1.0, cooldown 0 — the always-available identity. Loading it
##     leaves Phase-1/2/3 play byte-identical (scale 1.0 = no widening, 0 marks = no rest).
##   - Stronger words: window_scale > 1.0 (widens PERFECT), cooldown > 0 (N successful marks
##     of rest). While a stronger word is cooling the effective fired word falls back to "bra"
##     (never a hard-fail — the round is still one tap).
##   - Tie-break rules (unit-tested, documented here):
##       1. Cooldown decrements ONLY on successful marks (fire_active(succeeded=true)).
##          A missed/dead tap (succeeded=false) does NOT decrement — a bad round doesn't
##          "tick the clock" on the word's rest.
##       2. Switching the active word away and back PRESERVES the per-word cooldown counter.
##          Per-word cooldowns are stored in a Dictionary keyed by word id, not by the active
##          slot — so dyktig's remaining rest survives a switch to super and back.
##   - Tuning values (defensible starting point; tune in play-test / PO review):
##       bra:       window_scale 1.00, cooldown 0  — identity, always available
##       dyktig:    window_scale 1.15, cooldown 2  — gentle widening, 2-mark rest
##       flink:     window_scale 1.20, cooldown 2  — small widening, 2-mark rest
##       super:     window_scale 1.30, cooldown 3  — moderate widening, 3-mark rest
##       kjempebra: window_scale 1.45, cooldown 4  — strongest widening, 4-mark rest

## The word every player has from the first run.
const BASE_ID := "bra"

## Ordered catalog: first entry = base (always unlocked); entries 2-5 unlock progressively as
## tricks are mastered. Order determines unlock order (unlock_up_to respects it). Each entry:
## {id, display, clip, window_scale, cooldown} — clip is the res:// path to the voiced line
## asset; window_scale widens the PERFECT hit window (1.0 = identity); cooldown is how many
## subsequent successful marks the word rests after firing (0 = never cools down).
## Tuning note: the numbers below are defensible starting values calibrated to make loading a
## stronger word a genuine choice (meaningful widening vs. meaningful rest), not a free upgrade.
## They are NOT stubs — adjust under play-test feedback; document changes here and in the task.
const CATALOG: Array = [
	{"id": "bra",       "display": "Bra!",       "clip": "res://assets/audio/bra_tts_placeholder.wav",       "window_scale": 1.00, "cooldown": 0},
	{"id": "dyktig",    "display": "Dyktig!",    "clip": "res://assets/audio/word_dyktig_placeholder.wav",    "window_scale": 1.15, "cooldown": 2},
	{"id": "flink",     "display": "Flink!",     "clip": "res://assets/audio/word_flink_placeholder.wav",     "window_scale": 1.20, "cooldown": 2},
	{"id": "super",     "display": "Super!",     "clip": "res://assets/audio/word_super_placeholder.wav",     "window_scale": 1.30, "cooldown": 3},
	{"id": "kjempebra", "display": "Kjempebra!", "clip": "res://assets/audio/word_kjempebra_placeholder.wav", "window_scale": 1.45, "cooldown": 4},
]

## The set of unlocked word ids (BASE_ID always present) and the currently active one.
var _unlocked := {"bra": true}
var _active := "bra"

## Per-word cooldown counters: id → remaining successful marks until available again (093, P5-2).
## Ephemeral session state — NOT persisted (to_dict/restore unchanged). A word not in this dict
## has remaining = 0 (available). Tied to the catalog id, not the active slot, so switching
## away and back preserves any in-flight rest (tie-break rule 2, above).
var _cooldown_remaining := {}

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

## The window_scale for a catalog id (093, P5-2): how much wider the PERFECT hit window is
## while this word is the active AND available word. Returns 1.0 (identity) for unknown ids so
## an unrecognised id can never accidentally widen the window.
func window_scale(id: String) -> float:
	for entry in CATALOG:
		if entry["id"] == id:
			return float(entry.get("window_scale", 1.0))
	return 1.0  # identity for unknown ids — safe default

## The cooldown_marks for a catalog id (093, P5-2): how many subsequent SUCCESSFUL marks this
## word rests after firing before it is available again. Returns 0 for unknown ids (never cools
## down — same safe default as BASE_ID).
func cooldown(id: String) -> int:
	for entry in CATALOG:
		if entry["id"] == id:
			return int(entry.get("cooldown", 0))
	return 0  # never cools down for unknown ids — safe default

## True iff `id` currently has remaining cooldown marks > 0 (093, P5-2).
## BASE_ID ("bra") never enters cooldown (its catalog cooldown is 0 and fire_active never
## arms it), so this is always false for "bra".
func is_on_cooldown(id: String) -> bool:
	return _cooldown_remaining.get(id, 0) > 0

## True iff the currently active word is NOT on cooldown, i.e. it will fire as itself on the
## next successful mark (093, P5-2). BASE_ID ("bra") is always available.
func active_is_available() -> bool:
	return not is_on_cooldown(_active)

## The effective window_scale for the current active word (093, P5-2): the active word's
## window_scale when it is available (not cooling), else 1.0 (base identity, no widening).
## Used by main._begin_sit to compose with the breed×difficulty scale; base "bra" (scale 1.0)
## leaves the window byte-identical to pre-093 play.
func effective_window_scale() -> float:
	return window_scale(_active) if active_is_available() else 1.0

## Fire the active word on a mark and return the EFFECTIVE word id that actually fired (093,
## P5-2). Optionally arms/decrements the cooldown depending on `succeeded`:
##
##   - succeeded=true (PERFECT or OK mark):
##       * If the active word is BASE_ID ("bra") or its cooldown is 0: returns "bra" /
##         active id, never enters cooldown (bra has no cooldown to arm).
##       * If the active word is a stronger word NOT on cooldown: returns the active word id
##         and arms its cooldown (sets remaining to its catalog cooldown value).
##       * If the active word is a stronger word ON cooldown: returns "bra" (fallback, audible)
##         and decrements the remaining counter by 1 (the rest ticks down, one step per good mark).
##
##   - succeeded=false (MISS or DEAD tap):
##       * Returns the effective word id WITHOUT touching any counter (no arm, no decrement).
##         A bad round does not tick the clock — tie-break rule 1.
##
## "fired" is the id whose clip the payoff should play: when the active word is cooling the
## player hears "bra" as the fallback (never a faked clip, never a hard-fail — the round is
## still one tap and always marks).
func fire_active(succeeded: bool) -> String:
	var id := _active
	if not succeeded:
		# Bad tap — do nothing to cooldown counters; return the effective id (fallback if cooling).
		return BASE_ID if is_on_cooldown(id) else id
	# Successful mark — arm or decrement:
	if id == BASE_ID or cooldown(id) == 0:
		# Base "bra" or a zero-cooldown word: never enters cooldown, fires as itself.
		return id
	if not is_on_cooldown(id):
		# Fresh stronger word: fires as itself and arms its cooldown.
		_cooldown_remaining[id] = cooldown(id)
		return id
	# Stronger word ON cooldown: falls back to "bra", and the rest decrements.
	_cooldown_remaining[id] = maxi(0, _cooldown_remaining.get(id, 0) - 1)
	return BASE_ID

## True iff `id` appears in CATALOG (guards against ghost/unknown ids).
func _is_catalog_id(id: String) -> bool:
	for entry in CATALOG:
		if entry["id"] == id:
			return true
	return false
