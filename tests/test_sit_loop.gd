extends "res://tests/test_case.gd"
## The Phase-1 round loop (027, P1-9): the single mark must REPEAT — idle → sit →
## markable window → back to idle → next sit, indefinitely. SitLoop is the pure state
## machine that owns that timing; main.gd advances it each frame and acts on the Intent
## (start a sit, or stand the dog back up). These tests pin the loop's contract headless
## (no Node, no AnimationPlayer), the same way test_sit_window / test_sit_session pin the
## scoring core. Before 027 the dog sat exactly ONCE per load and then stalled.

# A brisk loop for deterministic tests: 0.5s idle gap before a sit, 0.4s seated hold past
# the markable window before standing back up.
func _loop() -> SitLoop:
	return SitLoop.new(0.5, 0.4)

func test_starts_idle() -> void:
	assert_eq(_loop().state(), SitLoop.State.IDLE, "the loop opens in IDLE (the dog is at rest)")

func test_cc0_dog_never_starts_a_sit() -> void:
	# has_sit = false (the CC0 placeholder ships no Sitt): the loop must park in IDLE
	# forever and never ask for a sit — no faked sit on the idle-only dog (P1-1 / 024b).
	var loop := _loop()
	for i in 20:
		assert_eq(loop.tick(0.1, false, 0.0, 1.0), SitLoop.Intent.NONE,
			"no sit intent on a dog that can't sit")
	assert_eq(loop.state(), SitLoop.State.IDLE, "stays IDLE on the CC0 dog")

func test_starts_a_sit_after_the_inter_sit_gap() -> void:
	var loop := _loop()  # gap = 0.5s
	assert_eq(loop.tick(0.3, true, 0.0, 1.0), SitLoop.Intent.NONE, "no sit before the gap elapses")
	assert_eq(loop.state(), SitLoop.State.IDLE, "still idling mid-gap")
	assert_eq(loop.tick(0.3, true, 0.0, 1.0), SitLoop.Intent.START_SIT,
		"sit starts once the 0.5s gap passes")
	assert_eq(loop.state(), SitLoop.State.SITTING, "now in the sit")

func test_holds_the_seat_then_ends_after_window_plus_hold() -> void:
	var loop := _loop()  # hold = 0.4s past the markable window
	loop.tick(0.3, true, 0.0, 1.0)
	loop.tick(0.3, true, 0.0, 1.0)  # -> START_SIT, now SITTING
	# the markable window ends at sit_end = 1.0; the dog holds ~0.4s past it before standing.
	assert_eq(loop.tick(0.1, true, 1.0, 1.0), SitLoop.Intent.NONE, "still seated at the window close")
	assert_eq(loop.tick(0.1, true, 1.35, 1.0), SitLoop.Intent.NONE, "still seated within the hold")
	assert_eq(loop.tick(0.1, true, 1.5, 1.0), SitLoop.Intent.END_SIT, "stands up after sit_end + hold")
	assert_eq(loop.state(), SitLoop.State.IDLE, "back to idle after the sit ends")

func test_the_loop_repeats_indefinitely() -> void:
	# P1-9: after a full sit it must return to idle and sit AGAIN — not stall after one.
	var loop := _loop()
	# cycle 1
	loop.tick(0.3, true, 0.0, 1.0)
	assert_eq(loop.tick(0.3, true, 0.0, 1.0), SitLoop.Intent.START_SIT, "cycle 1 sit starts")
	assert_eq(loop.tick(0.1, true, 1.5, 1.0), SitLoop.Intent.END_SIT, "cycle 1 sit ends")
	# cycle 2 — the gap timer reset on END_SIT, so a fresh sit must come round again
	assert_eq(loop.tick(0.3, true, 0.0, 1.0), SitLoop.Intent.NONE, "cycle 2 gap not yet elapsed")
	assert_eq(loop.tick(0.3, true, 0.0, 1.0), SitLoop.Intent.START_SIT,
		"cycle 2 sit starts — the loop repeats, it does not stall after one sit")

func test_tell_is_built_from_the_same_window_the_score_uses() -> void:
	# The honest-tell invariant (P1-4): main._begin_sit opens the session and builds the
	# tell from ONE window, so the glow peaks exactly where a tap scores PERFECT. Pin that
	# the tell's apex equals the scoring window's apex — one source of truth, no drift.
	var w := SitWindow.from_sit_clips(1.25, 2.0, 0.08, 0.20)
	var tell := ApexTell.from_window(w, 1.0)
	assert_eq(tell.apex, w.apex, "the tell peaks at the very apex the score uses")
