extends "res://tests/test_case.gd"
## TDD for the learned-progress model (045, P2-4 "feel the dog learning"). TrickProgress
## is the pure per-trick bar: a well-timed BRA fills it toward mastery (PERFECT more than
## OK); a mistimed tap (MISS) or a tap with no real apex (DEAD — a feint/ambient moment,
## P2-8) erodes it. Good play always nets forward, the bar floors at 0, 100% latches
## mastery as a safe checkpoint (re-practice can't un-master), and mastered tricks stay
## re-practiceable. No engine state is touched — the model is the testable seam, exactly
## like SitWindow/SitSession (024a/024e). main.gd feeds it the scored SitWindow.Tier.

func test_starts_empty_and_not_mastered() -> void:
	var p := TrickProgress.new()
	assert_eq(p.value, 0.0, "a fresh trick has zero learned progress")
	assert_false(p.mastered, "a fresh trick is not mastered")

func test_perfect_fills_more_than_ok() -> void:
	var perfect := TrickProgress.new()
	var ok := TrickProgress.new()
	perfect.apply(SitWindow.Tier.PERFECT)
	ok.apply(SitWindow.Tier.OK)
	assert_true(perfect.value > ok.value, "PERFECT fills more than OK (P2-4)")
	assert_true(ok.value > 0.0, "OK still fills some")

func test_mistimed_taps_erode() -> void:
	# Build up first so there is something to lose, then a bad tap removes learning.
	var p := TrickProgress.new()
	p.apply(SitWindow.Tier.PERFECT)
	p.apply(SitWindow.Tier.PERFECT)  # ~0.40
	var before := p.value
	var miss_delta := p.apply(SitWindow.Tier.MISS)
	assert_true(miss_delta < 0.0, "a MISS removes learning (negative delta)")
	assert_true(p.value < before, "the bar drops after a mistimed tap")
	var dead_delta := p.apply(SitWindow.Tier.DEAD)
	assert_true(dead_delta < 0.0, "a DEAD/feint tap also erodes (P2-4 wrong-moment)")

func test_dead_erodes_less_than_miss() -> void:
	var by_miss := TrickProgress.new()
	var by_dead := TrickProgress.new()
	by_miss.apply(SitWindow.Tier.PERFECT); by_miss.apply(SitWindow.Tier.PERFECT)
	by_dead.apply(SitWindow.Tier.PERFECT); by_dead.apply(SitWindow.Tier.PERFECT)
	by_miss.apply(SitWindow.Tier.MISS)
	by_dead.apply(SitWindow.Tier.DEAD)
	assert_true(by_dead.value > by_miss.value, "a no-window DEAD tap is gentler than a real mistime")

func test_good_play_nets_forward() -> void:
	# The invariant that keeps the game fair: a PERFECT adds clearly more than the worst
	# single bad tap removes, so a mistake never wipes out a clean mark.
	assert_true(TrickProgress.PERFECT_GAIN > TrickProgress.MISS_EROSION, "PERFECT outweighs a MISS")
	assert_true(TrickProgress.PERFECT_GAIN > TrickProgress.DEAD_EROSION, "PERFECT outweighs a DEAD tap")
	var p := TrickProgress.new()
	p.apply(SitWindow.Tier.PERFECT)  # ~0.20
	var start := p.value
	p.apply(SitWindow.Tier.MISS)     # erode
	p.apply(SitWindow.Tier.PERFECT)  # recover + then some
	assert_true(p.value > start, "a PERFECT after a bad tap nets strictly forward")

func test_floors_at_zero() -> void:
	var p := TrickProgress.new()
	for i in 10:
		p.apply(SitWindow.Tier.MISS)
	assert_eq(p.value, 0.0, "erosion can never drive the bar below 0")

func test_caps_and_masters_at_one() -> void:
	var p := TrickProgress.new()
	for i in 10:
		p.apply(SitWindow.Tier.PERFECT)  # overfill past 1.0
	assert_eq(p.value, 1.0, "the bar caps at 1.0 (100%)")
	assert_true(p.mastered, "reaching 100% masters the trick")

func test_mastery_is_a_safe_checkpoint() -> void:
	var p := TrickProgress.new()
	for i in 10:
		p.apply(SitWindow.Tier.PERFECT)
	# Re-practice a mastered trick badly — it must not lose mastery (P2-4 safe checkpoint).
	p.apply(SitWindow.Tier.MISS)
	p.apply(SitWindow.Tier.DEAD)
	assert_eq(p.value, 1.0, "a mastered trick can't be eroded below mastery (safe checkpoint)")
	assert_true(p.mastered, "mastery never un-latches")

func test_mastered_trick_is_still_re_practiceable() -> void:
	# Re-practicing a mastered trick still SCORES (apply returns, value stays valid) — it
	# just can't drop below mastery; the trick is not locked out.
	var p := TrickProgress.new()
	for i in 10:
		p.apply(SitWindow.Tier.PERFECT)
	var delta := p.apply(SitWindow.Tier.PERFECT)  # a clean re-practice tap
	assert_eq(delta, 0.0, "a mastered trick is already full, so a good tap nets no further gain")
	assert_eq(p.value, 1.0, "still full")
	assert_true(p.mastered, "still mastered")

func test_just_mastered_is_one_shot() -> void:
	var p := TrickProgress.new()
	# Fill to just under mastery without crossing it.
	var crossing := -1.0
	for i in 10:
		var d := p.apply(SitWindow.Tier.PERFECT)
		if p.just_mastered(d):
			assert_true(crossing < 0.0, "just_mastered fires on exactly one tap")
			crossing = float(i)
	assert_true(crossing >= 0.0, "just_mastered fired on the crossing tap")
	# A further tap after mastery must NOT re-fire it.
	var after := p.apply(SitWindow.Tier.PERFECT)
	assert_false(p.just_mastered(after), "just_mastered does not re-fire once mastered")

func test_value_stays_in_unit_range() -> void:
	var p := TrickProgress.new()
	var seq := [SitWindow.Tier.PERFECT, SitWindow.Tier.MISS, SitWindow.Tier.OK,
		SitWindow.Tier.DEAD, SitWindow.Tier.PERFECT, SitWindow.Tier.PERFECT]
	for t in seq:
		p.apply(t)
		assert_true(p.value >= 0.0 and p.value <= 1.0, "value always within [0, 1]")

# --- Persistence shape (049, P2-5): the model owns its own (de)serialization so the store
# stays dumb about the rules (mastery latch, floor). to_dict()/restore() round-trip it. ---

func test_to_dict_restore_round_trips_value() -> void:
	var p := TrickProgress.new()
	p.apply(SitWindow.Tier.PERFECT)  # value ~0.20
	var d := p.to_dict()
	var q := TrickProgress.new()
	q.restore(d)
	assert_eq(q.value, p.value, "restore() rebuilds the same learned value")
	assert_eq(q.mastered, p.mastered, "restore() rebuilds the mastered flag")

func test_restore_relatches_mastery_safe_checkpoint() -> void:
	# A saved {value:1.0, mastered:true} must restore the SAFE CHECKPOINT: re-practice still
	# can't drop a mastered trick below MASTERY (the apply() floor logic keys off `mastered`).
	var p := TrickProgress.new()
	p.restore({"value": 1.0, "mastered": true})
	assert_eq(p.value, 1.0, "a saved full trick restores full")
	assert_true(p.mastered, "a saved mastered flag re-latches on restore")
	p.apply(SitWindow.Tier.MISS)
	assert_eq(p.value, 1.0, "after restore, mastery still floors re-practice at MASTERY (safe checkpoint survives reload)")

func test_restore_clamps_and_defaults_garbage() -> void:
	# A partial / out-of-range / missing-key save degrades to a clean clamped state, never a crash.
	var p := TrickProgress.new()
	p.restore({"value": 5.0})  # out of range, no mastered key
	assert_eq(p.value, 1.0, "an over-range saved value clamps to MASTERY")
	assert_false(p.mastered, "a missing mastered key defaults to false")
	var q := TrickProgress.new()
	q.restore({})  # empty entry
	assert_eq(q.value, 0.0, "an empty saved entry restores a clean zero")
	assert_false(q.mastered, "an empty saved entry is not mastered")
