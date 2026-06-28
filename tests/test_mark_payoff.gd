extends "res://tests/test_case.gd"
## TDD for the mark payoff decision (024f, P1-6). MarkPayoff is the pure source of
## truth for the reward beat: given a scored tier it decides whether the voice / click /
## dog reaction fire and how BRIGHT, gating every cue off SitWindow.is_successful so a
## MISS or DEAD tap is provably silent. The node layer (payoff_player / director
## reaction) only renders this — so proving the gate here proves the whole beat is fair.

func test_perfect_and_ok_play() -> void:
	assert_true(MarkPayoff.for_tier(SitWindow.Tier.PERFECT).plays(),
		"a PERFECT mark plays the payoff")
	assert_true(MarkPayoff.for_tier(SitWindow.Tier.OK).plays(),
		"an OK mark plays the payoff")

func test_miss_and_dead_are_silent() -> void:
	# The P1-6 gate: nothing plays on a miss or a dead tap (no false reward).
	assert_false(MarkPayoff.for_tier(SitWindow.Tier.MISS).plays(),
		"a MISS plays nothing")
	assert_false(MarkPayoff.for_tier(SitWindow.Tier.DEAD).plays(),
		"a DEAD tap plays nothing")

func test_plays_matches_is_successful_exactly() -> void:
	# plays() must be the SAME gate the scoring math exposes — one source of truth,
	# so the payoff can never diverge from what counts as a successful mark (024a).
	for tier in [SitWindow.Tier.PERFECT, SitWindow.Tier.OK,
			SitWindow.Tier.MISS, SitWindow.Tier.DEAD]:
		assert_eq(MarkPayoff.for_tier(tier).plays(), SitWindow.is_successful(tier),
			"plays() tracks SitWindow.is_successful for tier %d" % tier)

func test_perfect_is_brighter_than_ok() -> void:
	# "PERFECT sounds/feels brighter than OK" (P1-6): a strictly higher brightness the
	# player maps to louder/crisper, but both are positive (a real reward).
	var perfect := MarkPayoff.for_tier(SitWindow.Tier.PERFECT).brightness
	var ok := MarkPayoff.for_tier(SitWindow.Tier.OK).brightness
	assert_true(perfect > ok, "PERFECT is brighter than OK")
	assert_true(ok > 0.0, "OK is still a positive, rewarding cue")
	assert_true(perfect <= 1.0, "brightness stays within [0,1]")

func test_silent_tiers_have_zero_brightness() -> void:
	assert_true(is_equal_approx(MarkPayoff.for_tier(SitWindow.Tier.MISS).brightness, 0.0),
		"a MISS has no brightness")
	assert_true(is_equal_approx(MarkPayoff.for_tier(SitWindow.Tier.DEAD).brightness, 0.0),
		"a DEAD tap has no brightness")

func test_voice_cue_is_stable_per_tier() -> void:
	# The owner's real Maren "Bra!" drops in under these exact ids — so they must be
	# stable, distinct per success tier, and empty when nothing should speak.
	assert_eq(MarkPayoff.for_tier(SitWindow.Tier.PERFECT).voice_cue,
		MarkPayoff.VOICE_PERFECT, "PERFECT uses the stable PERFECT voice cue")
	assert_eq(MarkPayoff.for_tier(SitWindow.Tier.OK).voice_cue,
		MarkPayoff.VOICE_OK, "OK uses the stable OK voice cue")
	assert_ne(MarkPayoff.VOICE_PERFECT, MarkPayoff.VOICE_OK,
		"PERFECT and OK are distinguishable cues")
	assert_ne(MarkPayoff.VOICE_PERFECT, "", "the PERFECT cue id is non-empty")
	assert_eq(MarkPayoff.for_tier(SitWindow.Tier.MISS).voice_cue, "",
		"a MISS speaks no cue")
	assert_eq(MarkPayoff.for_tier(SitWindow.Tier.DEAD).voice_cue, "",
		"a DEAD tap speaks no cue")

func test_reaction_gate_follows_success() -> void:
	# The dog only reacts on a successful mark — same gate as the audio.
	assert_true(MarkPayoff.for_tier(SitWindow.Tier.PERFECT).reacts(),
		"the dog reacts on a PERFECT")
	assert_true(MarkPayoff.for_tier(SitWindow.Tier.OK).reacts(),
		"the dog reacts on an OK")
	assert_false(MarkPayoff.for_tier(SitWindow.Tier.MISS).reacts(),
		"the dog does not react on a MISS")
	assert_false(MarkPayoff.for_tier(SitWindow.Tier.DEAD).reacts(),
		"the dog does not react on a DEAD tap")
