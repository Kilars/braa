class_name KennelRoster
extends RefCounted
## The player's owned kennel-dog roster (109, Phase 8 K-3/K-4/K-7). A pure value object —
## the set of owned KennelDog ids + the one active id — mirroring BreedRoster exactly but in
## the KennelDog id-space ("bella", "nova", "balder", …, "trulte"), so the signed-off Phase-6
## save blob stays byte-compatible (a pre-109 save decodes to the Bella-only default).
##
## Invariants (mirrors BreedRoster verbatim):
##   - The STARTER dog (Bella, KennelDog.STARTER_ID == "bella") is ALWAYS owned. A corrupt /
##     legacy / empty save degrades to owning just Bella — the player can never be dog-less.
##   - The active id is ALWAYS one the player owns. Activating an unowned id is a no-op
##     returning false; a restored active that isn't owned clamps back to Bella.
##   - Only KNOWN KennelDog ids (KennelDog.is_known) are admitted on restore — a save naming
##     a ghost / unshipped id never grants it.

## The kennel dog every player owns from the first run.
const STARTER := KennelDog.STARTER_ID  # "bella"

## The owned kennel-dog ids (STARTER always present) and the currently active one.
var owned: Array
var active: String

func _init() -> void:
	# Set in _init (not a member initializer) so every instance gets its own array — no
	# shared-array aliasing across rosters.
	owned = [STARTER]
	active = STARTER

## True iff the player owns this kennel dog.
func owns(id: String) -> bool:
	return owned.has(id)

## Record ownership of a shipped kennel dog (idempotent; the starter is never dropped). An
## unknown or already-owned id is a no-op. Spending the coins is the caller's job (CoinPurse) —
## this only records.
func adopt(id: String) -> void:
	if KennelDog.is_known(id) and not owned.has(id):
		owned.append(id)

## Switch the active dog to one the player owns; returns whether it took. Activating an unowned
## dog is a no-op returning false (the active dog is left unchanged) — the never-activate-
## what-you-don't-own invariant.
func set_active(id: String) -> bool:
	if not owns(id):
		return false
	active = id
	return true

## Model -> save entry (TrickStore stays dumb about the rules; the roster owns its shape).
func to_dict() -> Dictionary:
	return {"owned": owned.duplicate(), "active": active}

## Restore from a saved entry. Rebuilds from the starter-only baseline, then re-admits only
## KNOWN owned ids and clamps the active to an owned dog — so a garbage / partial /
## unshipped-id save always lands on a valid roster that owns at least the starter and never
## activates a dog the player lacks.
func restore(d: Dictionary) -> void:
	owned = [STARTER]
	active = STARTER
	var raw: Variant = d.get("owned", [])
	if raw is Array:
		for id in raw:
			if id is String and KennelDog.is_known(id) and not owned.has(id):
				owned.append(id)
	var a: Variant = d.get("active", STARTER)
	if a is String and owned.has(a):
		active = a
