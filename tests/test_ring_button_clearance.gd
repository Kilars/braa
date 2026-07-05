extends "res://tests/test_case.gd"
## Geometry contract: the fully-expanded approach ring must not overlap the BRA button
## pill at any point in its animation (task 123, owner directive 2026-07-05).
##
## All placement values are read from the REAL mounted nodes after _ready so the tests
## encode what the live game actually does — not baked literals that can drift.
##
## Coordinate convention: offset_* are bottom-anchor offsets (anchor_top = anchor_bottom
## = 1.0), so more-negative values are HIGHER up the screen.  "Ring bottom" means the
## largest (least-negative / most-positive) vertical offset the ring reaches.
## Clearance holds iff: ring_bottom_y < button_top_y  (ring stays above the button top).

func _find_trainer_marker(n: Node) -> TrainerRingMarker:
	if n is TrainerRingMarker:
		return n
	for c in n.get_children():
		var f := _find_trainer_marker(c)
		if f != null:
			return f
	return null

func _find_bra_button(n: Node) -> Control:
	var ui := n.get_node_or_null("UI")
	if ui == null:
		return null
	return ui.get_node_or_null("BraButton") as Control

## The unit (half the marker square side) the ring_radius helper expects.
## Must match TrainerRingMarker.SIZE * 0.5 — read from the class constant so this
## stays in sync if SIZE ever changes.
func _ring_unit() -> float:
	return TrainerRingMarker.SIZE * 0.5

## The fully-expanded ring radius in pixels (render-space, same coordinate scale as
## the anchor offsets on a 720-wide viewport).
func _max_ring_radius() -> float:
	return TrainerRingMarker.ring_radius(_ring_unit(), 1.0)

## ── test 1 ──────────────────────────────────────────────────────────────────
## The ring's bottom edge at full expansion must sit ABOVE the BRA button top.
## RED now: the ring is concentric with the button (centre at BRA_CENTER_Y ≈ -184),
## so its bottom edge reaches ≈ -184 + 259 = +75 — well BELOW the button top (-280).
## GREEN after: the implementer repositions the ring above the button.
func test_fully_expanded_ring_bottom_clears_bra_button_top() -> void:
	var main := instantiate_main()
	var marker := _find_trainer_marker(main)
	var button := _find_bra_button(main)
	assert_true(marker != null, "trainer marker must be mounted")
	assert_true(button != null, "BRA button must be mounted")
	if marker == null or button == null:
		main.queue_free()
		return

	# Ring vertical centre in bottom-anchor offset space.
	var ring_center_y: float = (marker.offset_top + marker.offset_bottom) * 0.5
	# Ring bottom = centre + radius (less-negative = lower on screen).
	var ring_bottom_y: float = ring_center_y + _max_ring_radius()
	# Button top in the same coordinate space.
	var button_top_y: float = button.offset_top

	# Clearance: ring bottom must be ABOVE (more-negative than) button top.
	assert_true(ring_bottom_y < button_top_y,
		("fully-expanded ring bottom (%.1f) must be above BRA button top (%.1f) — "
		+ "ring centre %.1f, radius %.1f, button band [%.1f, %.1f]")
		% [ring_bottom_y, button_top_y, ring_center_y, _max_ring_radius(),
		   button.offset_top, button.offset_bottom])
	main.queue_free()

## ── test 2 ──────────────────────────────────────────────────────────────────
## The ring's top edge at full expansion must not overshoot the screen top
## (a sanity guard: moving the ring too far up would push it off screen).
## This stays GREEN both before and after the fix — it documents the valid range.
## offset < 0 means above the bottom anchor, i.e. on-screen; more-negative = higher.
## We require the ring top stays within reasonable on-screen bounds (> -VIEWPORT_H).
## RED now: because test 1 is RED and we only expect both green after the fix.
## NOTE: this is a soft sanity guard; it will also be GREEN today since the ring top
## = -184 - 259 = -443 which is above -1280. It complements test 1 — the two tests
## together bound the ring's legal vertical range.
func test_fully_expanded_ring_top_stays_on_screen() -> void:
	var main := instantiate_main()
	var marker := _find_trainer_marker(main)
	assert_true(marker != null, "trainer marker must be mounted")
	if marker == null:
		main.queue_free()
		return

	var ring_center_y: float = (marker.offset_top + marker.offset_bottom) * 0.5
	var ring_top_y: float = ring_center_y - _max_ring_radius()

	# The ring top must not go above the top of the 1280-px-tall viewport in
	# bottom-anchor space (offset > -1280 means still on screen).
	assert_true(ring_top_y > -1280.0,
		("ring top (%.1f) must stay within the 1280-px viewport — "
		+ "ring centre %.1f, radius %.1f")
		% [ring_top_y, ring_center_y, _max_ring_radius()])
	main.queue_free()

## ── test 3 ──────────────────────────────────────────────────────────────────
## Belt-and-braces: assert the ring band [ring_top, ring_bottom] does NOT contain
## the button centre. If the ring is concentric with the button the button centre is
## trivially inside the ring band; after the fix the ring lives entirely above.
## RED now: button centre = BRA_CENTER_Y = -184, ring band ≈ [-443, +75] → contains it.
func test_ring_band_does_not_contain_bra_button_centre() -> void:
	var main := instantiate_main()
	var marker := _find_trainer_marker(main)
	var button := _find_bra_button(main)
	assert_true(marker != null, "trainer marker must be mounted")
	assert_true(button != null, "BRA button must be mounted")
	if marker == null or button == null:
		main.queue_free()
		return

	var ring_center_y: float = (marker.offset_top + marker.offset_bottom) * 0.5
	var ring_radius: float = _max_ring_radius()
	var ring_top_y: float = ring_center_y - ring_radius
	var ring_bottom_y: float = ring_center_y + ring_radius

	var button_centre_y: float = (button.offset_top + button.offset_bottom) * 0.5

	# The button centre must lie OUTSIDE the ring's vertical band (below the ring bottom).
	var button_centre_inside_ring: bool = (button_centre_y >= ring_top_y and
		button_centre_y <= ring_bottom_y)
	assert_false(button_centre_inside_ring,
		("BRA button centre (%.1f) must not be inside the ring band [%.1f, %.1f] — "
		+ "ring must live above the button, not concentric with it")
		% [button_centre_y, ring_top_y, ring_bottom_y])
	main.queue_free()
