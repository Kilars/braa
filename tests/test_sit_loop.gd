extends "res://tests/test_case.gd"
## The round loop (027, P1-9; extended in 048, P2-8). The single mark must REPEAT —
## idle → sit → markable window → back to idle → next sit, indefinitely — but P2-8 kills
## the metronome: the idle gap now VARIES, and the dog sometimes FEINTS (starts a sit then
## aborts). A feint opens NO markable window, so a tap during it is a wrong-moment DEAD
## (→ P2-4 erosion). SitLoop is the pure state machine that owns that timing; main.gd
## advances it each frame and acts on the Intent. These tests pin the loop's contract
## headless (no Node, no AnimationPlayer), with a SEEDED RNG so the varying cadence and the
## feint coin-flips are fully deterministic.

# A seeded RNG so the gap draws + feint decisions are reproducible run to run.
func _rng(seed_val := 12345) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_val
	return r

# A loop driven by a seeded RNG, 0.4s seated hold past the markable window.
func _loop(seed_val := 12345) -> SitLoop:
	return SitLoop.new(_rng(seed_val), 0.4)

# Tick the idle gap until an offer opens; return the opening Intent (START_SIT or
# START_FEINT). NONE if none opened within the cap.
func _open_next_offer(loop: SitLoop) -> int:
	for i in 100:
		var intent := loop.tick(0.1, true, 0.0, 1.0)
		if intent == SitLoop.Intent.START_SIT or intent == SitLoop.Intent.START_FEINT:
			return intent
	return SitLoop.Intent.NONE

# Drive whatever offer is currently open to completion (back to IDLE). session_elapsed is
# held high so a real sit ends as soon as it opens; a feint ends after its own FEINT_HOLD.
func _complete_open_offer(loop: SitLoop) -> void:
	for i in 100:
		var intent := loop.tick(0.1, true, 5.0, 1.0)
		if intent == SitLoop.Intent.END_SIT or intent == SitLoop.Intent.END_FEINT:
			return

# From IDLE, open the next offer and drive it through to completion — one full cycle, which
# draws a fresh gap for the next.
func _advance_one_cycle(loop: SitLoop) -> void:
	_open_next_offer(loop)
	_complete_open_offer(loop)

# Drive the loop until a REAL sit opens (completing any feints on the way), so a hold/repeat
# test always has a markable sit to exercise regardless of the seed's coin-flips.
func _drive_to_sit(loop: SitLoop) -> void:
	for i in 200:
		var opened := _open_next_offer(loop)
		if opened == SitLoop.Intent.START_SIT:
			return
		_complete_open_offer(loop)  # it was a feint — stand back up and try the next cycle

func test_starts_idle() -> void:
	assert_eq(_loop().state(), SitLoop.State.IDLE, "the loop opens in IDLE (the dog is at rest)")

func test_cc0_dog_never_starts_a_sit_or_feint() -> void:
	# has_sit = false (the CC0 placeholder ships no Sitt): the loop must park in IDLE forever
	# and ask for NEITHER a sit NOR a feint — no faked behaviour on the idle-only dog
	# (P1-1 / 024b; the feint reuses the real sit build-in, so a sit-less dog can't feint).
	var loop := _loop()
	for i in 40:
		var intent := loop.tick(0.1, false, 0.0, 1.0)
		assert_ne(intent, SitLoop.Intent.START_SIT, "no sit intent on a dog that can't sit")
		assert_ne(intent, SitLoop.Intent.START_FEINT, "no faked feint on a dog that can't sit")
	assert_eq(loop.state(), SitLoop.State.IDLE, "stays IDLE on the CC0 dog")

func test_no_offer_before_the_drawn_gap_elapses() -> void:
	# The gap is drawn from [MIN, MAX]; no offer (sit or feint) opens until it elapses.
	var loop := _loop()
	var gap := loop.next_gap()
	assert_true(gap >= SitLoop.MIN_INTER_SIT_GAP and gap <= SitLoop.MAX_INTER_SIT_GAP,
		"the idle gap is drawn from [MIN_INTER_SIT_GAP, MAX_INTER_SIT_GAP]")
	var t := 0.0
	while t + 0.1 < gap:
		assert_eq(loop.tick(0.1, true, 0.0, 1.0), SitLoop.Intent.NONE, "no offer mid-gap")
		t += 0.1
	assert_eq(loop.state(), SitLoop.State.IDLE, "still idling until the drawn gap elapses")
	var intent := loop.tick(0.2, true, 0.0, 1.0)  # cross it
	assert_true(intent == SitLoop.Intent.START_SIT or intent == SitLoop.Intent.START_FEINT,
		"an offer opens once the drawn gap elapses")

func test_the_gap_varies_across_cycles() -> void:
	# P2-8: no metronome to game — the gap between offers is drawn fresh each cycle and varies.
	var loop := _loop()
	var gaps: Array[float] = []
	for i in 6:
		var g := loop.next_gap()
		gaps.append(g)
		assert_true(g >= SitLoop.MIN_INTER_SIT_GAP and g <= SitLoop.MAX_INTER_SIT_GAP,
			"each drawn gap lands in [MIN, MAX]")
		_advance_one_cycle(loop)  # complete the offer → a fresh gap is drawn for the next
	var all_same := true
	for g in gaps:
		if g != gaps[0]:
			all_same = false
	assert_false(all_same, "the gap is not a fixed metronome — it varies cycle to cycle")

func test_a_feint_opens_no_markable_window() -> void:
	# A feint emits START_FEINT and puts the loop in FEINTING — NOT a markable sit, so main
	# keeps the session closed and a tap during it is a wrong-moment DEAD (P2-8 / P2-4).
	var loop := _loop()
	var feinted := false
	for cycle in 50:
		var opened := _open_next_offer(loop)
		if opened == SitLoop.Intent.START_FEINT:
			feinted = true
			assert_true(loop.is_feinting(), "a feint puts the loop in FEINTING")
			assert_false(loop.is_sitting(), "a feint is NOT a markable sit (no scoring window opens)")
			_complete_open_offer(loop)
			break
		_complete_open_offer(loop)
	assert_true(feinted, "feints occur (FEINT_CHANCE > 0)")

func test_a_feint_ends_and_the_loop_resumes() -> void:
	# After FEINT_HOLD the feint emits END_FEINT, returns to IDLE, and the next cycle proceeds.
	var loop := _loop()
	for cycle in 50:
		var opened := _open_next_offer(loop)
		if opened == SitLoop.Intent.START_FEINT:
			var ended := false
			for i in 100:
				if loop.tick(0.1, true, 0.0, 1.0) == SitLoop.Intent.END_FEINT:
					ended = true
					break
			assert_true(ended, "a feint ends with END_FEINT after FEINT_HOLD")
			assert_eq(loop.state(), SitLoop.State.IDLE, "the loop returns to IDLE after a feint")
			var next := _open_next_offer(loop)
			assert_true(next == SitLoop.Intent.START_SIT or next == SitLoop.Intent.START_FEINT,
				"the loop comes round to the next offer after a feint — it does not stall")
			return
		_complete_open_offer(loop)
	assert_true(false, "expected a feint within 50 cycles (FEINT_CHANCE ~0.35)")

func test_real_sits_still_happen() -> void:
	# Feints don't replace all sits — FEINT_CHANCE < 1, so real markable sits still come round.
	var loop := _loop()
	var sits := 0
	for cycle in 40:
		if _open_next_offer(loop) == SitLoop.Intent.START_SIT:
			sits += 1
		_complete_open_offer(loop)
	assert_true(sits > 0, "real markable sits still come round (feints don't replace every sit)")

func test_holds_the_seat_then_ends_after_window_plus_hold() -> void:
	var loop := _loop()  # hold = 0.4s past the markable window
	_drive_to_sit(loop)
	assert_eq(loop.state(), SitLoop.State.SITTING, "a real sit opened")
	# the markable window ends at sit_end = 1.0; the dog holds ~0.4s past it before standing.
	assert_eq(loop.tick(0.1, true, 1.0, 1.0), SitLoop.Intent.NONE, "still seated at the window close")
	assert_eq(loop.tick(0.1, true, 1.35, 1.0), SitLoop.Intent.NONE, "still seated within the hold")
	assert_eq(loop.tick(0.1, true, 1.5, 1.0), SitLoop.Intent.END_SIT, "stands up after sit_end + hold")
	assert_eq(loop.state(), SitLoop.State.IDLE, "back to idle after the sit ends")

func test_the_loop_repeats_indefinitely() -> void:
	# P1-9: after a full sit it must return to idle and come round AGAIN — not stall after one.
	var loop := _loop()
	_drive_to_sit(loop)
	assert_eq(loop.tick(0.1, true, 1.5, 1.0), SitLoop.Intent.END_SIT, "cycle 1 sit ends")
	# cycle 2 — a fresh offer (sit or feint) must come round again from a freshly drawn gap
	_drive_to_sit(loop)
	assert_eq(loop.state(), SitLoop.State.SITTING,
		"cycle 2 sit comes round — the loop repeats, it does not stall after one sit")

func test_tell_is_built_from_the_same_window_the_score_uses() -> void:
	# The honest-tell invariant (P1-4): main._begin_sit opens the session and builds the
	# tell from ONE window, so the glow peaks exactly where a tap scores PERFECT. Pin that
	# the tell's apex equals the scoring window's apex — one source of truth, no drift.
	var w := SitWindow.from_sit_clips(1.25, 2.0, 0.08, 0.20)
	var tell := ApexTell.from_window(w, 1.0)
	assert_eq(tell.apex, w.apex, "the tell peaks at the very apex the score uses")
