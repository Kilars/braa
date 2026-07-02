class_name BreedRoster
extends RefCounted
## The player's owned-breeds roster (079, P3-4 "persistent roster" / P3-D3 "spend to adopt"). A pure
## value object — the set of owned breed ids + the one active breed id — with the same to_dict/restore
## shape TrickProgress / CoinPurse use, so the save store (TrickStore) stays dumb about the rules.
##
## Invariants this owns (never a dog-less player):
##   - The STARTER breed (the yellow Labrador) is ALWAYS owned. A corrupt / legacy / empty save degrades
##     to owning just the starter — the player can never be stranded with no dog.
##   - The active breed is ALWAYS one the player owns. Activating an unowned breed is a no-op; a restored
##     active that isn't owned clamps back to the starter.
##   - Only KNOWN (shipped) breed ids are admitted (BreedPersonality.is_known) — a save naming an
##     unshipped/ghost breed never grants it.

## The breed every player owns from the first run — breed #1, the yellow Labrador.
const STARTER := "labrador"

## The owned breed ids (STARTER always present) and the currently active one.
var owned: Array
var active: String

func _init() -> void:
	# Set in _init (not a member initializer) so every instance gets its own array — no shared-array
	# aliasing across rosters.
	owned = [STARTER]
	active = STARTER

## True iff the player owns this breed.
func owns(id: String) -> bool:
	return owned.has(id)

## Record ownership of a shipped breed (idempotent; the starter is never dropped). An unknown or
## already-owned id is a no-op. Spending the coins is the caller's job (CoinPurse) — this only records.
func adopt(id: String) -> void:
	if BreedPersonality.is_known(id) and not owned.has(id):
		owned.append(id)

## Switch the active breed to one the player owns; returns whether it took. Activating an unowned breed
## is a no-op returning false (the active breed is left unchanged) — the never-activate-what-you-don't-own
## invariant.
func set_active(id: String) -> bool:
	if not owns(id):
		return false
	active = id
	return true

## Model -> save entry (TrickStore stays dumb about the rules; the roster owns its shape).
func to_dict() -> Dictionary:
	return {"owned": owned.duplicate(), "active": active}

## Restore from a saved entry. Rebuilds from the starter-only baseline, then re-admits only KNOWN owned
## ids and clamps the active to an owned breed — so a garbage / partial / unshipped-id save always lands
## on a valid roster that owns at least the starter and never activates a breed the player lacks.
func restore(d: Dictionary) -> void:
	owned = [STARTER]
	active = STARTER
	var raw: Variant = d.get("owned", [])
	if raw is Array:
		for id in raw:
			if id is String and BreedPersonality.is_known(id) and not owned.has(id):
				owned.append(id)
	var a: Variant = d.get("active", STARTER)
	if a is String and owned.has(a):
		active = a
