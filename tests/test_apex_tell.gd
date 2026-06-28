extends "res://tests/test_case.gd"
## Unit tests for the apex tell envelope (specs2.md P1-4), task 024d.
##
## The tell is the honest "now" cue: a soft pulse that builds to and peaks at the
## sit's apex — the SAME apex SitWindow scores PERFECT at (024a/024b), one source
## of truth, so the glow can't drift from the band. ApexTell is the pure envelope
## (intensity in [0, damping] over seconds-into-the-sit); the visual marker just
## renders whatever intensity this returns. Keeping it pure is what makes "peaks
## exactly at the apex" and "never fires during idle" test-first, not eyeballed.

# A representative tell over the same shape test_sit_window uses: markable [0,2]s,
# apex (fully seated) at 1.2s, ramp = the OK window half-width (0.30s) so the glow
# spans exactly the scorable window and is brightest at the PERFECT centre.
func _tell() -> ApexTell:
	return ApexTell.new(1.2, 0.30, 0.0, 2.0, 1.0)

func test_peaks_to_full_exactly_at_the_apex() -> void:
	# The honest core: the tell is at its maximum (1.0) at exactly the apex — the
	# instant a tap scores PERFECT — not a frame before or after.
	assert_true(is_equal_approx(_tell().intensity(1.2), 1.0), "full intensity at apex")

func test_falloff_is_symmetric_around_the_apex() -> void:
	var t := _tell()
	assert_true(is_equal_approx(t.intensity(1.2 - 0.15), t.intensity(1.2 + 0.15)),
		"equal distance either side of the apex glows equally")

func test_intensity_strictly_decreases_away_from_the_apex() -> void:
	# No early false peak: every step away from the apex (both directions) is dimmer
	# than the last, so the brightest instant the eye sees IS the scoring peak.
	var t := _tell()
	assert_true(t.intensity(1.05) < t.intensity(1.15), "rising into the apex")
	assert_true(t.intensity(1.15) < t.intensity(1.20), "brightest at the apex")
	assert_true(t.intensity(1.25) < t.intensity(1.20), "fading after the apex")
	assert_true(t.intensity(1.35) < t.intensity(1.25), "still fading")

func test_half_ramp_is_the_cosine_bell_midpoint() -> void:
	# A soft pulse (cosine bell), not a hard triangle: halfway out the ramp it reads
	# 0.5 — a smooth build, no snap. Pins the exact curve so the feel can't silently
	# change to a linear ramp.
	var t := _tell()
	assert_true(is_equal_approx(t.intensity(1.2 - 0.15), 0.5), "half-ramp early = 0.5")
	assert_true(is_equal_approx(t.intensity(1.2 + 0.15), 0.5), "half-ramp late = 0.5")

func test_dormant_at_and_beyond_the_ramp_edge() -> void:
	var t := _tell()
	assert_true(is_equal_approx(t.intensity(1.2 - 0.30), 0.0), "early ramp edge = dark")
	assert_true(is_equal_approx(t.intensity(1.2 + 0.30), 0.0), "late ramp edge = dark")
	assert_true(is_equal_approx(t.intensity(0.7), 0.0), "well before the ramp = dark")

func test_never_fires_during_idle_outside_the_active_sit() -> void:
	# P1-4: the tell only marks an actual sit. Outside the markable span the dog is
	# idle and there is nothing to mark — the tell is exactly 0, never a stray glow.
	var t := _tell()
	assert_true(is_equal_approx(t.intensity(-0.1), 0.0), "before the sit is dark")
	assert_true(is_equal_approx(t.intensity(2.1), 0.0), "after the sit is dark")

func test_from_window_ties_the_tell_to_the_scoring_apex() -> void:
	# Single source of truth: built from the SitWindow, the tell peaks at the very
	# time that window scores PERFECT — so the cue and the score can never disagree.
	var w := SitWindow.from_sit_clips(0.8, 1.5, 0.08, 0.20)
	var t := ApexTell.from_window(w)
	assert_true(is_equal_approx(t.intensity(w.apex), 1.0), "tell peaks at the window's apex")
	assert_eq(w.score(w.apex), SitWindow.Tier.PERFECT, "and that apex is the PERFECT instant")
	# The ramp tracks the OK window, so the glow is visible across exactly the
	# scorable window and dark at/outside the OK edge where a tap would MISS/DEAD.
	assert_true(t.intensity(w.apex - 0.19) > 0.0, "glowing just inside the OK window")
	assert_true(is_equal_approx(t.intensity(w.apex - 0.20), 0.0), "dark at the OK edge")

func test_reduced_motion_dampens_but_never_removes_the_tell() -> void:
	# P1-8: reduced motion DAMPENS — it must not delete the cue. The peak drops but
	# stays clearly above zero, and the shape (peak still at the apex) is preserved
	# so the tell remains distinguishable.
	var calm := ApexTell.new(1.2, 0.30, 0.0, 2.0, 0.35)
	assert_true(is_equal_approx(calm.intensity(1.2), 0.35), "dampened peak = the damping")
	assert_true(calm.intensity(1.2) > 0.0, "still visible — dampened, not removed")
	assert_true(calm.intensity(1.2) > calm.intensity(1.1), "peak still at the apex")
	assert_true(is_equal_approx(calm.intensity(-0.1), 0.0), "still silent during idle")
