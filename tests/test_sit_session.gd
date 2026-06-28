extends "res://tests/test_case.gd"
## TDD for the BRA-tap session (024e, specs2.md P1-5). SitWindow (024a) is the pure
## per-sit math; SitSession is the thin state layer the button taps into: it owns
## whether a sit is OPEN right now and how many seconds we are INTO it, and turns a
## tap into a scored Tier. With no sit open every tap is DEAD — on the CC0
## placeholder (no Sitt clip) that's *every* tap: the BRA button still works, it
## just does nothing, no penalty (P1-5). The moment a sit-capable dog opens a window
## (025/ADR-0006), the same taps start scoring PERFECT/OK/MISS with no gameplay
## change. This is the slice's testable seam: "when is a window open, what's t at tap".

# Matches DogDirector's bands: PERFECT ±0.08s, OK ±0.20s; a sit that builds for
# 0.8s (apex = fully seated) then holds 1.5s → markable over [0, 2.3], apex at 0.8.
func _window() -> SitWindow:
	return SitWindow.from_sit_clips(0.8, 1.5, 0.08, 0.20)

func test_fresh_session_is_closed_and_taps_are_dead() -> void:
	var s := SitSession.new()
	assert_false(s.is_open(), "a session with no sit is closed")
	assert_eq(s.tap(), SitWindow.Tier.DEAD, "a tap with no sit open is DEAD — no penalty (P1-5)")

func test_open_makes_the_session_active() -> void:
	var s := SitSession.new()
	s.open(_window())
	assert_true(s.is_open(), "open() activates the session")
	assert_true(is_equal_approx(s.elapsed(), 0.0), "a freshly opened sit starts at t=0")

func test_tap_at_apex_after_advancing_is_perfect() -> void:
	var s := SitSession.new()
	s.open(_window())
	s.advance(0.8)  # build complete → fully seated = apex
	assert_true(is_equal_approx(s.elapsed(), 0.8), "elapsed tracks time into the sit")
	assert_eq(s.tap(), SitWindow.Tier.PERFECT, "a tap at the apex is PERFECT")

func test_tap_just_off_apex_is_ok() -> void:
	var s := SitSession.new()
	s.open(_window())
	s.advance(0.95)  # 0.15s past apex → inside OK (±0.20), outside PERFECT (±0.08)
	assert_eq(s.tap(), SitWindow.Tier.OK, "a tap just off the apex is OK")

func test_tap_far_from_apex_but_during_sit_is_miss() -> void:
	var s := SitSession.new()
	s.open(_window())
	s.advance(0.2)  # early in the build, far from apex, but the sit is active
	assert_eq(s.tap(), SitWindow.Tier.MISS, "active sit, far from apex → MISS, not DEAD")

func test_advance_accumulates_elapsed() -> void:
	var s := SitSession.new()
	s.open(_window())
	s.advance(0.3)
	s.advance(0.3)
	assert_true(is_equal_approx(s.elapsed(), 0.6), "advance accumulates frame deltas")

func test_advance_does_nothing_while_closed() -> void:
	# Time only runs while a sit is open — a closed session can't drift its clock,
	# so the first tap after a future open() is honestly t=0, not a stale value.
	var s := SitSession.new()
	s.advance(1.0)
	assert_true(is_equal_approx(s.elapsed(), 0.0), "a closed session does not accumulate time")
	assert_eq(s.tap(), SitWindow.Tier.DEAD, "still DEAD after advancing while closed")

func test_close_makes_taps_dead_again() -> void:
	# The dog stands up / the sit sequence ends → the window closes and late taps
	# are DEAD again (no penalty), exactly as before the sit.
	var s := SitSession.new()
	s.open(_window())
	s.advance(0.8)
	assert_eq(s.tap(), SitWindow.Tier.PERFECT, "scores while open")
	s.close()
	assert_false(s.is_open(), "close() deactivates the session")
	assert_eq(s.tap(), SitWindow.Tier.DEAD, "a tap after the sit ends is DEAD")

func test_reopening_restarts_the_clock() -> void:
	# Each new sit starts timing fresh, so the apex aligns with the new build-in.
	var s := SitSession.new()
	s.open(_window())
	s.advance(0.8)
	s.open(_window())
	assert_true(is_equal_approx(s.elapsed(), 0.0), "re-opening resets elapsed to 0")
	assert_eq(s.tap(), SitWindow.Tier.MISS, "t=0 of a fresh sit is far from the apex")
