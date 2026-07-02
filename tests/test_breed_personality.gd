extends "res://tests/test_case.gd"
## TDD for the breed-personality model (075, P3-3 "Training has no breed-personality
## dimension yet"). BreedPersonality is a pure value object holding four temperament
## traits as multipliers around 1.0 (learn_speed, distractibility, window_stability,
## energy), plus resolved-lever accessors. Multipliers are 1.0 = today's baseline
## (no silent regression), so later breeds are deliberate deltas from the Labrador (#1).
## Personalities resolve against the EXISTING constants (TrickProgress.PERFECT_GAIN / OK_GAIN,
## SitLoop.FEINT_CHANCE / MIN_INTER_SIT_GAP / MAX_INTER_SIT_GAP, SitWindow.DEFAULT_PERFECT_RADIUS
## / DEFAULT_OK_RADIUS).

func test_neutral_personality_reproduces_baseline() -> void:
	# All-1.0 multipliers resolve to exactly today's constants (no silent regression).
	var p := BreedPersonality.new("x", "X")   # defaults 1.0
	assert_eq(p.perfect_gain(), TrickProgress.PERFECT_GAIN, "neutral learn_speed=1.0 reproduces PERFECT_GAIN")
	assert_eq(p.ok_gain(), TrickProgress.OK_GAIN, "neutral learn_speed=1.0 reproduces OK_GAIN")
	assert_eq(p.feint_chance(), SitLoop.FEINT_CHANCE, "neutral distractibility=1.0 reproduces feint_chance")
	assert_eq(p.perfect_radius(), SitWindow.DEFAULT_PERFECT_RADIUS, "neutral window_stability=1.0 reproduces perfect_radius")
	assert_eq(p.ok_radius(), SitWindow.DEFAULT_OK_RADIUS, "neutral window_stability=1.0 reproduces ok_radius")
	assert_eq(p.min_gap(), SitLoop.MIN_INTER_SIT_GAP, "neutral energy=1.0 reproduces min_gap")
	assert_eq(p.max_gap(), SitLoop.MAX_INTER_SIT_GAP, "neutral energy=1.0 reproduces max_gap")

func test_labrador_has_defined_temperament() -> void:
	# Breed #1 is a deliberate temperament, not the neutral default.
	var lab := BreedPersonality.labrador()
	assert_true(lab.learn_speed > 1.0, "the Labrador learns a touch fast (learn_speed > 1.0)")
	assert_true(lab.distractibility < 1.0, "the Labrador has steady focus (distractibility < 1.0)")
	assert_true(lab.window_stability >= 1.0, "the Labrador has forgiving timing (window_stability >= 1.0)")
	assert_true(lab.feint_chance() < SitLoop.FEINT_CHANCE, "steady focus → fewer feints than baseline")
	assert_true(lab.perfect_gain() > TrickProgress.PERFECT_GAIN, "higher learn_speed → faster fill")

func test_higher_learn_speed_fills_bar_faster() -> void:
	# A trick progress with higher per-instance gains (from a personality's learn_speed)
	# fills the bar faster than the baseline.
	var fast := TrickProgress.new(0.20 * 1.5, 0.08 * 1.5)  # 50% faster gains
	var base := TrickProgress.new()  # defaults to PERFECT_GAIN=0.20, OK_GAIN=0.08
	fast.apply(SitWindow.Tier.PERFECT)
	base.apply(SitWindow.Tier.PERFECT)
	assert_true(fast.value > base.value, "a higher learn_speed fills the learned bar faster")

func test_more_energy_shortens_offer_gap() -> void:
	# A personality with more energy (>1.0) divides the inter-sit gaps by the energy
	# multiplier, making offers come quicker.
	var lab := BreedPersonality.new("l", "L", 1.0, 1.0, 1.0, 2.0)  # double energy
	assert_true(lab.min_gap() < SitLoop.MIN_INTER_SIT_GAP, "more energy → shorter min gap")
	assert_true(lab.max_gap() < SitLoop.MAX_INTER_SIT_GAP, "more energy → quicker offers")
	assert_true(lab.max_gap() == SitLoop.MAX_INTER_SIT_GAP / 2.0, "max_gap is divided by energy multiplier")
