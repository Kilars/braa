class_name BreedShowcase
extends RefCounted
## Pure model for the spotlit breed-select screen (087, P3-4 "persistent, showcased roster"). Owns the
## ordered list of OWNED breed ids and which one is currently spotlit (previewed) on the 3D stage —
## render-free + unit-testable like CoinPurse / BreedRoster. main feeds it the roster (owned ids +
## active id) and it answers "which breed to render/tint now", "is this the active one" (highlight), and
## maps a next/prev/card tap to a breed id. The 3D staging + lighting live in main (Visual Review only).
##
## Invariants: the initially spotlit breed is the ACTIVE one (the dog the player trains now); next/prev
## cycle and wrap at the ends; focus(id) never spotlights a breed the player doesn't own (no-op for an
## unowned/unknown id); a single-owned roster is stable (spotlit_id always valid, next/prev never crash);
## the swatch is the REAL BreedPersonality coat colour, never an invented one.

## The owned breed ids in roster order and the active breed (the one being trained, highlighted).
var _owned: Array = []
var _active: String = ""
## Index into _owned of the breed currently spotlit/previewed on the stage.
var _cursor: int = 0

## Rebuild from the roster (owned ids + active id), spotlighting the active breed first. The cursor
## clamps to a valid index, so an active id missing from owned (shouldn't happen — the roster guards it)
## still lands on a valid spotlight rather than out of range.
func set_roster(owned: Array, active: String) -> void:
	_owned = owned.duplicate()
	_active = active
	_cursor = _owned.find(active)
	if _cursor < 0:
		_cursor = 0

## The breed the stage should render/tint to right now (the spotlit one). Empty roster -> "".
func spotlit_id() -> String:
	if _owned.is_empty():
		return ""
	return _owned[_cursor]

## True iff `id` is the active breed (the one being trained) — main draws the highlight ring/badge on it.
func is_active(id: String) -> bool:
	return id == _active

## Advance the spotlight to the next owned breed (wraps), returning the new spotlit id. A single-owned
## roster stays on its one breed. Empty roster -> "".
func next() -> String:
	if _owned.is_empty():
		return ""
	_cursor = (_cursor + 1) % _owned.size()
	return spotlit_id()

## Retreat the spotlight to the previous owned breed (wraps), returning the new spotlit id.
func prev() -> String:
	if _owned.is_empty():
		return ""
	_cursor = (_cursor - 1 + _owned.size()) % _owned.size()
	return spotlit_id()

## Jump the spotlight to a specific breed — ONLY if the player owns it (a card tap). An unowned/unknown
## id is a no-op (never spotlight a breed you don't own), leaving the current spotlight unchanged.
func focus(id: String) -> void:
	var idx := _owned.find(id)
	if idx >= 0:
		_cursor = idx

## The breed's honest coat-colour swatch, straight from BreedPersonality — the real coat colour, never a
## faked breed image or invented colour (the same swatch the adopt/select menu shows, 079).
func swatch_color(id: String) -> Color:
	return BreedPersonality.by_id(id).swatch_color()
