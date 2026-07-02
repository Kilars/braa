extends "res://tests/test_case.gd"
## Unit tests for the apex-band / scoring-window math (specs2.md P1-5), task 024a.
##
## This is the heart of "mark the moment": given one sit's timeline — when it
## becomes markable, when it stops, and the apex (the fully-seated scoring peak) —
## a tap is scored by closeness to the apex: PERFECT on the apex band, OK inside
## the window off-peak, MISS inside the active sit but outside the window, and DEAD
## when no sit is active (Phase 1: a dead tap does nothing, no penalty). The math
## is pure and deterministic so it's test-first; the visuals wire onto it later.

# A representative sit: markable over [0.0, 2.0]s, fully seated (apex) at 1.2s,
# a tight ±0.08s PERFECT band, a ±0.30s OK window.
func _window() -> SitWindow:
	return SitWindow.new(1.2, 0.08, 0.30, 0.0, 2.0)

func test_tap_exactly_on_apex_is_perfect() -> void:
	assert_eq(_window().score(1.2), SitWindow.Tier.PERFECT, "apex tap")

func test_tap_inside_perfect_band_either_side_is_perfect() -> void:
	var w := _window()
	assert_eq(w.score(1.15), SitWindow.Tier.PERFECT, "just before apex")
	assert_eq(w.score(1.25), SitWindow.Tier.PERFECT, "just after apex")

func test_perfect_band_edge_is_inclusive() -> void:
	var w := _window()
	assert_eq(w.score(1.2 - 0.08), SitWindow.Tier.PERFECT, "early edge inclusive")
	assert_eq(w.score(1.2 + 0.08), SitWindow.Tier.PERFECT, "late edge inclusive")

func test_just_outside_perfect_band_is_ok() -> void:
	var w := _window()
	assert_eq(w.score(1.2 - 0.12), SitWindow.Tier.OK, "early off-peak")
	# PO note 5 late-bias: 0.12 s after apex is now inside the PERFECT late edge
	# (perfect_radius 0.08 + late_bias 0.09 = 0.17 > 0.12), so this tap is PERFECT not OK.
	assert_eq(w.score(1.2 + 0.12), SitWindow.Tier.PERFECT, "late 120ms: now PERFECT due to late-bias (PO note 5)")

func test_ok_window_edge_is_inclusive() -> void:
	var w := _window()
	assert_eq(w.score(1.2 - 0.30), SitWindow.Tier.OK, "early ok edge inclusive")
	assert_eq(w.score(1.2 + 0.30), SitWindow.Tier.OK, "late ok edge inclusive")

func test_inside_active_sit_but_outside_window_is_miss() -> void:
	var w := _window()
	# Markable (within [0,2]) but well off the apex → MISS, not DEAD.
	assert_eq(w.score(0.5), SitWindow.Tier.MISS, "early in sit, far from apex")
	assert_eq(w.score(1.9), SitWindow.Tier.MISS, "late in sit, far from apex")

func test_tap_before_or_after_active_sit_is_dead() -> void:
	var w := _window()
	assert_eq(w.score(-0.1), SitWindow.Tier.DEAD, "before the sit is markable")
	assert_eq(w.score(2.1), SitWindow.Tier.DEAD, "after the sit ends")

func test_active_bounds_are_inclusive() -> void:
	var w := _window()
	# At the exact edges the sit is still active → scored (here MISS, off-peak),
	# never DEAD. Guards an off-by-one at the active/idle boundary.
	assert_eq(w.score(0.0), SitWindow.Tier.MISS, "sit_start is active")
	assert_eq(w.score(2.0), SitWindow.Tier.MISS, "sit_end is active")

func test_asymmetric_apex_uses_absolute_distance() -> void:
	# Apex near the end of the clip: distance must be measured both directions,
	# not assumed centered.
	var w := SitWindow.new(1.8, 0.1, 0.4, 0.0, 2.0)
	assert_eq(w.score(1.8), SitWindow.Tier.PERFECT, "apex")
	assert_eq(w.score(1.45), SitWindow.Tier.OK, "0.35 before apex")
	assert_eq(w.score(1.3), SitWindow.Tier.MISS, "0.5 before apex, still active")

func test_from_clip_derives_bounds_from_length() -> void:
	# Convenience for the gameplay layer: build the window straight from an
	# AnimationPlayer clip (length + apex keyframe time), bounds = [0, length].
	var w := SitWindow.from_clip(2.0, 1.2, 0.08, 0.30)
	assert_eq(w.sit_start, 0.0, "clip starts at 0")
	assert_eq(w.sit_end, 2.0, "clip ends at length")
	assert_eq(w.apex, 1.2, "apex carried through")
	assert_eq(w.score(1.2), SitWindow.Tier.PERFECT, "scores like a hand-built window")

func test_from_sit_clips_sets_apex_at_end_of_build() -> void:
	# Clip-driven sit (024b): the dog builds into the sit over `start_len` — the
	# apex (fully seated) is the END of that build — then holds the seated loop for
	# `loop_len`. The whole [0, start_len+loop_len] span is markable (the dog is
	# "sitting"); outside it the dog is idle and a tap is DEAD. Ties the apex to the
	# real Sitting_start clip length as the single source of truth.
	var w := SitWindow.from_sit_clips(0.8, 1.5, 0.08, 0.20)
	assert_eq(w.sit_start, 0.0, "active span opens at clip start")
	assert_eq(w.apex, 0.8, "apex = end of the build-in (fully seated)")
	assert_eq(w.sit_end, 2.3, "active span = build + hold")
	assert_eq(w.score(0.8), SitWindow.Tier.PERFECT, "apex tap is perfect")
	assert_eq(w.score(0.2), SitWindow.Tier.MISS, "early in the build, far from apex")
	assert_eq(w.score(2.3), SitWindow.Tier.MISS, "end of hold is still active, not dead")
	assert_eq(w.score(2.4), SitWindow.Tier.DEAD, "past the hold the dog is idle again")

func test_tier_name_is_human_readable() -> void:
	assert_eq(SitWindow.tier_name(SitWindow.Tier.PERFECT), "PERFECT", "perfect label")
	assert_eq(SitWindow.tier_name(SitWindow.Tier.OK), "OK", "ok label")
	assert_eq(SitWindow.tier_name(SitWindow.Tier.MISS), "MISS", "miss label")
	assert_eq(SitWindow.tier_name(SitWindow.Tier.DEAD), "DEAD", "dead label")

func test_canonical_scoring_radii_live_on_the_scoring_class() -> void:
	# 029: the apex ±80ms / ±200ms gameplay rule is a scoring concern, so its
	# canonical default belongs on SitWindow (not the AnimationPlayer driver). A
	# designer tuning the bands should find them here.
	assert_eq(SitWindow.DEFAULT_PERFECT_RADIUS, 0.08, "PERFECT band default = apex ±80ms")
	assert_eq(SitWindow.DEFAULT_OK_RADIUS, 0.20, "OK window default = apex ±200ms")

func test_window_from_canonical_defaults_scores_the_specced_bands() -> void:
	# A sit built with the canonical radii scores the spec's bands exactly.
	# PO note 5 late-bias: after-apex edges are widened by DEFAULT_LATE_BIAS (0.09 s).
	# PERFECT late edge = 0.08 + 0.09 = 0.17 s; OK late edge = 0.20 + 0.09 = 0.29 s.
	var w := SitWindow.from_sit_clips(0.8, 1.5,
		SitWindow.DEFAULT_PERFECT_RADIUS, SitWindow.DEFAULT_OK_RADIUS)
	assert_eq(w.score(0.8), SitWindow.Tier.PERFECT, "apex tap is perfect")
	assert_eq(w.score(0.8 + 0.08), SitWindow.Tier.PERFECT, "early edge of 80ms is still perfect")
	# +0.20 s > PERFECT late edge (0.17) but <= OK late edge (0.29) → OK (PO note 5 — late OK edge now 0.29 s, not 0.20 s)
	assert_eq(w.score(0.8 + 0.20), SitWindow.Tier.OK, "late 200ms: within the OK late-bias window (PO note 5)")
	# +0.29 s is exactly at the OK late edge (ok_radius + late_bias = 0.20 + 0.09), inclusive → OK (PO note 5)
	assert_eq(w.score(0.8 + 0.29), SitWindow.Tier.OK, "late 290ms: at the OK late edge exactly (PO note 5)")
	# +0.30 s is past the OK late edge (0.30 > 0.29) → MISS (PO note 5 — old MISS boundary was +0.20 s, now +0.29 s)
	assert_eq(w.score(0.8 + 0.30), SitWindow.Tier.MISS, "past the late ok edge is a miss (PO note 5)")

func test_scoring_tap_is_audible_only_on_perfect_or_ok() -> void:
	# P1-6 gate: the payoff (voice + SFX + reaction) fires on a successful mark
	# only — never on MISS or DEAD. Expose the predicate the audio layer keys off.
	var w := _window()
	assert_true(SitWindow.is_successful(w.score(1.2)), "PERFECT is a successful mark")
	assert_true(SitWindow.is_successful(w.score(1.0)), "OK is a successful mark")
	assert_false(SitWindow.is_successful(w.score(0.5)), "MISS is not a mark")
	assert_false(SitWindow.is_successful(w.score(3.0)), "DEAD is not a mark")

func test_slightly_late_tap_is_still_perfect() -> void:
	# A tap 120 ms AFTER the apex — a natural reaction delay — now lands PERFECT (was MISS at ±80).
	# PO note 5: players are typically late, so the after-apex edge should be more forgiving.
	var w := SitWindow.from_sit_clips(0.6, 0.5, SitWindow.DEFAULT_PERFECT_RADIUS,
		SitWindow.DEFAULT_OK_RADIUS)   # apex = 0.6
	assert_eq(w.score(0.6 + 0.12), SitWindow.Tier.PERFECT,
		"a 120 ms-late tap should be forgiven as PERFECT (PO note 5)")

func test_early_tap_stays_strict() -> void:
	# The before-apex edge is UNCHANGED — tapping 120 ms early is not PERFECT (dog not yet seated).
	# The late-bias must not loosen the early edge.
	var w := SitWindow.from_sit_clips(0.6, 0.5, SitWindow.DEFAULT_PERFECT_RADIUS,
		SitWindow.DEFAULT_OK_RADIUS)
	assert_ne(w.score(0.6 - 0.12), SitWindow.Tier.PERFECT,
		"an early tap must stay strict — late bias must not loosen the early edge")

func test_band_is_late_biased_not_symmetric() -> void:
	# The PERFECT band reaches further after the apex than before it.
	# The late edge should be at perfect_radius + late_bias, not perfect_radius.
	var w := SitWindow.from_sit_clips(0.6, 0.5, SitWindow.DEFAULT_PERFECT_RADIUS,
		SitWindow.DEFAULT_OK_RADIUS)
	assert_eq(w.score(0.6 + SitWindow.DEFAULT_PERFECT_RADIUS + SitWindow.DEFAULT_LATE_BIAS - 0.005),
		SitWindow.Tier.PERFECT, "late edge = perfect_radius + late_bias")
