extends "res://tests/test_case.gd"
## Unit tests for apex tell marker framing geometry (037).
##
## The marker's ring must encircle the "BRA" word, not cross it. These tests verify the
## named radius constants and helpers (SIZE, WORD_HALF_WIDTH, ring_radius, halo_radius) that
## make this geometry render-free testable. Task 037 adds these symbols to ApexTellMarker;
## before they exist, these tests FAIL (red phase).

## Test 1: Framing Invariant — the resting ring's inner edge clears the word.
## The core fix: at the owned SIZE, the ring must sit outside the "BRA" glyph run.
func test_framing_invariant_resting_ring_clears_word() -> void:
	# The resting ring inner edge must clear WORD_HALF_WIDTH with the ring width margin.
	var unit := ApexTellMarker.SIZE * 0.5
	var ring_radius_resting := ApexTellMarker.ring_radius(unit, 0.0)
	var ring_inner_edge := ring_radius_resting - ApexTellMarker.RING_WIDTH * 0.5
	assert_true(ring_inner_edge >= ApexTellMarker.WORD_HALF_WIDTH,
		"resting ring inner edge (%.1f) must clear word half-width (%.1f) — ring frames, not crosses" % [ring_inner_edge, ApexTellMarker.WORD_HALF_WIDTH])


## Test 2: Ring Monotonic — ring_radius grows monotonically toward the apex.
## The ring blooms as intensity rises; it never shrinks.
func test_ring_monotonic_in_intensity() -> void:
	var unit := 160.0  # sample: half the SIZE constant
	var ring_at_rest := ApexTellMarker.ring_radius(unit, 0.0)
	var ring_at_peak := ApexTellMarker.ring_radius(unit, 1.0)
	assert_true(ring_at_peak >= ring_at_rest,
		"ring blooms toward apex: at-peak (%.1f) >= at-rest (%.1f)" % [ring_at_peak, ring_at_rest])


## Test 3: Halo Encloses Ring — the soft halo sits outside the crisp ring at all intensities.
## The bloom must not pinch inward at the peak.
func test_halo_encloses_ring_at_rest() -> void:
	var unit := 160.0  # sample
	var halo := ApexTellMarker.halo_radius(unit, 0.0)
	var ring := ApexTellMarker.ring_radius(unit, 0.0)
	assert_true(halo >= ring,
		"at rest: halo (%.1f) >= ring (%.1f) — soft bloom surrounds crisp ring" % [halo, ring])

func test_halo_encloses_ring_at_peak() -> void:
	var unit := 160.0  # sample
	var halo := ApexTellMarker.halo_radius(unit, 1.0)
	var ring := ApexTellMarker.ring_radius(unit, 1.0)
	assert_true(halo >= ring,
		"at peak: halo (%.1f) >= ring (%.1f) — bloom surrounds the peak ring" % [halo, ring])


## Test 4a: Size Sanity — SIZE is positive.
func test_size_is_positive() -> void:
	assert_true(ApexTellMarker.SIZE > 0.0,
		"ApexTellMarker.SIZE must be positive (got %.1f)" % ApexTellMarker.SIZE)

## Test 4b: Size Sanity — resting ring radius is comfortably larger than the old 200px size would give.
## The old size was 200 → unit 100 → resting ring = 100*0.62 = 62 px. The new size must yield
## a much larger ring (> 90 px) so it frames the ~90 px word half-width with margin.
func test_resting_ring_is_larger_than_old_size() -> void:
	var unit := ApexTellMarker.SIZE * 0.5
	var ring_resting := ApexTellMarker.ring_radius(unit, 0.0)
	assert_true(ring_resting > 90.0,
		"resting ring radius (%.1f) must be comfortably larger than old size's ~62px (old would give only 62)" % ring_resting)
