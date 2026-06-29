extends "res://tests/test_case.gd"
## Reduced-motion damping factor (specs2.md P1-8), task 024g. The pure mapping from
## prefers-reduced-motion → the one motion-scale factor every authored cue routes
## through (main._motion_scale → ApexTell.damping). The acceptance is precise and
## test-first: reduced motion DAMPENS the cue, it never REMOVES it — the sit/apex
## still read, just softer. (The actual web media-query read in ReducedMotion.query()
## is exercised live in the browser; the policy it feeds is what's unit-locked here.)

func test_full_motion_when_not_reduced() -> void:
	assert_true(is_equal_approx(ReducedMotion.scale_for(false), 1.0),
		"no reduced-motion preference → full intensity (factor 1.0)")

func test_reduced_motion_dampens_the_cue() -> void:
	var s := ReducedMotion.scale_for(true)
	assert_true(s < 1.0, "reduced motion must dampen below full (P1-8)")

func test_reduced_motion_never_removes_the_cue() -> void:
	# The whole point of P1-8: "dampened, not removed" — a strictly positive factor so
	# the apex tell still pulses (just softer) and the cue stays distinguishable.
	var s := ReducedMotion.scale_for(true)
	assert_true(s > 0.0, "reduced motion must NOT zero the cue out (dampened, not removed)")

func test_damped_constant_is_in_open_unit_interval() -> void:
	# Lock the named constant itself to the (0, 1) contract so a future tweak can't
	# silently set it to 0 (removes the cue) or >= 1 (no damping at all).
	assert_true(ReducedMotion.DAMPED > 0.0, "DAMPED > 0 (cue survives)")
	assert_true(ReducedMotion.DAMPED < 1.0, "DAMPED < 1 (cue is actually dampened)")
