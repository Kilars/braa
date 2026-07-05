extends "res://tests/test_case.gd"
## Background grace (120, P4-5 "taps right after the app resumes are ignored so a notification/lock
## never causes a false mark"). BackgroundGrace is a pure, clock-injected value object: after a resume
## it swallows BRA taps for a short window so a stray resume-touch never lands a false mark. These pin
## the arm/expire logic render-free (no real timer). The wiring INTO main (arm on focus-in, swallow the
## tap) is proven in test_background_grace_wiring.gd.

func test_not_armed_is_never_in_grace() -> void:
	var g := BackgroundGrace.new()
	assert_false(g.is_grace_active(0.0), "a fresh grace (never armed) is not active")
	assert_false(g.is_grace_active(1000.0), "still not active at any later time when never armed")

func test_arm_then_a_tap_inside_the_window_is_in_grace() -> void:
	var g := BackgroundGrace.new()
	g.arm(10.0)
	assert_true(g.is_grace_active(10.0), "a tap at the instant of resume is in grace")
	assert_true(g.is_grace_active(10.0 + BackgroundGrace.GRACE_S * 0.5), "a tap mid-window is in grace")

func test_a_tap_at_or_after_the_window_is_not_in_grace() -> void:
	var g := BackgroundGrace.new()
	g.arm(10.0)
	# Just past the window is clearly not in grace (the exact GRACE_S boundary is float-fragile, so we
	# probe a hair beyond it — the window is half-open [arm, arm+GRACE_S), so past-the-edge is normal play).
	assert_false(g.is_grace_active(10.0 + BackgroundGrace.GRACE_S + 0.01), "a tap just past GRACE_S is NOT in grace")
	assert_false(g.is_grace_active(10.0 + BackgroundGrace.GRACE_S + 1.0), "a tap well after the window is not in grace")

func test_re_arm_extends_from_the_new_resume() -> void:
	var g := BackgroundGrace.new()
	g.arm(10.0)
	assert_false(g.is_grace_active(20.0), "the first window has long expired by t=20")
	g.arm(20.0)  # a second resume re-arms
	assert_true(g.is_grace_active(20.05), "re-arming starts a fresh window from the new resume")

func test_grace_window_is_short() -> void:
	# The grace must not block a legitimate tap once the window passes — keep it well under a second.
	assert_true(BackgroundGrace.GRACE_S > 0.0, "the grace window is positive")
	assert_true(BackgroundGrace.GRACE_S <= 0.6, "the grace window is short (only the resume-touch, not real play)")
