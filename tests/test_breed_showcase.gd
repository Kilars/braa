extends "res://tests/test_case.gd"
## TDD for the pure breed-showcase model (087, P3-4 "showcased, spotlit breed-select screen").
## BreedShowcase is a render-free pure value object — owns which owned breed is currently spotlit
## on the stage, and maps next/prev/focus/swatch to the ordered roster. The 3D staging/lighting is
## Visual Review only (exempt from TDD).
##
## The invariants these pin: the initially spotlit breed is the active one (the one the player is
## training now); next/prev cycle and wrap at the ends; focus(id) is a no-op for unowned/unknown ids
## (never spotlight a breed the player doesn't own); a single-owned breed is stable (no crash,
## spotlit_id always valid); swatch_color matches the real BreedPersonality.swatch_color.

func test_spotlights_active_breed_first() -> void:
	## After set_roster(owned, active), the initial spotlit breed is the active one.
	var showcase := BreedShowcase.new()
	showcase.set_roster(["labrador", "chocolate_labrador"], "chocolate_labrador")
	assert_eq(showcase.spotlit_id(), "chocolate_labrador", "the spotlit breed is the active one on first set_roster")
	assert_true(showcase.is_active("chocolate_labrador"), "is_active returns true for the spotlit/active breed")

func test_next_prev_cycle_and_wrap() -> void:
	## next() and prev() advance/retreat the cursor through the owned list and wrap at the ends.
	var showcase := BreedShowcase.new()
	showcase.set_roster(["labrador", "chocolate_labrador"], "labrador")

	# Start at labrador (active first)
	assert_eq(showcase.spotlit_id(), "labrador", "initial spotlit is the active breed")

	# next() wraps forward
	var next_id := showcase.next()
	assert_eq(next_id, "chocolate_labrador", "next() returns the new spotlit id")
	assert_eq(showcase.spotlit_id(), "chocolate_labrador", "spotlit_id reflects the new cursor")

	# next() again wraps back to start
	next_id = showcase.next()
	assert_eq(next_id, "labrador", "next() wraps to the first breed")
	assert_eq(showcase.spotlit_id(), "labrador", "spotlit_id wraps with next()")

	# prev() retreats and wraps backward
	var prev_id := showcase.prev()
	assert_eq(prev_id, "chocolate_labrador", "prev() wraps to the last breed")
	assert_eq(showcase.spotlit_id(), "chocolate_labrador", "spotlit_id reflects prev()")

	# prev() again goes back
	prev_id = showcase.prev()
	assert_eq(prev_id, "labrador", "prev() retreats to the previous breed")
	assert_eq(showcase.spotlit_id(), "labrador", "spotlit_id tracks prev()")

func test_focus_jumps_to_owned_only() -> void:
	## focus(id) moves the cursor to an owned id; focus on an unowned/unknown id is a no-op.
	var showcase := BreedShowcase.new()
	showcase.set_roster(["labrador", "chocolate_labrador"], "labrador")
	assert_eq(showcase.spotlit_id(), "labrador", "initial spotlight is labrador")

	# focus on an owned breed jumps the cursor
	showcase.focus("chocolate_labrador")
	assert_eq(showcase.spotlit_id(), "chocolate_labrador", "focus() jumps the cursor to the chosen owned breed")

	# focus on an unowned/unknown breed is a no-op
	showcase.focus("husky")
	assert_eq(showcase.spotlit_id(), "chocolate_labrador", "focus() on an unowned id is a no-op (spotlit unchanged)")

	# focus back to labrador
	showcase.focus("labrador")
	assert_eq(showcase.spotlit_id(), "labrador", "focus() can jump back to a different owned breed")

func test_single_owned_breed_is_stable() -> void:
	## A player with only one owned breed (the starter Labrador) stays stable — next/prev do not crash
	## and spotlit_id always returns that one valid breed.
	var showcase := BreedShowcase.new()
	showcase.set_roster(["labrador"], "labrador")

	assert_eq(showcase.spotlit_id(), "labrador", "single-breed roster spotlights the sole breed")

	# next() on a single breed stays on it (no crash)
	var next_id := showcase.next()
	assert_eq(next_id, "labrador", "next() on a single breed returns that same breed")
	assert_eq(showcase.spotlit_id(), "labrador", "spotlit_id stays valid after next() on single breed")

	# prev() on a single breed stays on it (no crash)
	var prev_id := showcase.prev()
	assert_eq(prev_id, "labrador", "prev() on a single breed returns that same breed")
	assert_eq(showcase.spotlit_id(), "labrador", "spotlit_id stays valid after prev() on single breed")

func test_swatch_is_the_real_coat_color() -> void:
	## swatch_color(id) returns the honest coat colour from BreedPersonality — no invented colour.
	var showcase := BreedShowcase.new()
	showcase.set_roster(["labrador", "chocolate_labrador"], "labrador")

	# The showcase's swatch must match the real BreedPersonality for each breed
	var lab_personality := BreedPersonality.by_id("labrador")
	var lab_swatch := showcase.swatch_color("labrador")
	assert_eq(lab_swatch, lab_personality.swatch_color(), "swatch_color('labrador') == BreedPersonality.labrador().swatch_color()")

	var choco_personality := BreedPersonality.by_id("chocolate_labrador")
	var choco_swatch := showcase.swatch_color("chocolate_labrador")
	assert_eq(choco_swatch, choco_personality.swatch_color(), "swatch_color('chocolate_labrador') == BreedPersonality.chocolate_labrador().swatch_color()")
