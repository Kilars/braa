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

func test_labrador_coat_tint_is_identity() -> void:
	# The yellow Labrador (breed #1) is the baked atlas's own colour — an identity tint, unchanged.
	assert_eq(BreedPersonality.labrador().coat_tint(), Color(1, 1, 1),
		"the yellow Labrador coat is the baked atlas colour (identity tint = no recolor)")

func test_neutral_personality_coat_tint_is_identity() -> void:
	# The default (no tint arg) is identity too — a breed is a temperament first; recolor is opt-in.
	assert_eq(BreedPersonality.new("x", "X").coat_tint(), Color(1, 1, 1),
		"a breed with no explicit tint leaves the atlas colour alone")

func test_chocolate_labrador_is_a_distinct_breed() -> void:
	# Breed #2 (BUST-074): the SAME licensed rig with a warm dark-brown coat tint + its own temperament —
	# a genuine second breed with no new owner model.
	var choc := BreedPersonality.chocolate_labrador()
	var lab := BreedPersonality.labrador()
	assert_eq(choc.coat_tint(), Color(0.50, 0.37, 0.26),
		"the chocolate Lab tints the coat atlas into a deep coffee-brown chocolate range (~#805E42, tuned vs the real render)")
	assert_true(choc.id != lab.id, "a distinct roster entry (distinct id)")
	# A distinct temperament, not just a recolor — the liveliness axes differ from the yellow Lab.
	assert_true(choc.distractibility != lab.distractibility or choc.energy != lab.energy,
		"the chocolate Lab has its own temperament (distractibility/energy differ from the Labrador)")
	assert_true(choc.perfect_gain() > TrickProgress.PERFECT_GAIN,
		"still very trainable (a retriever base — learns faster than the neutral baseline)")

# ---- the catalog / resolver the roster + adopt-select menu read (079) ------------------------------

func test_by_id_resolves_known_breeds() -> void:
	assert_eq(BreedPersonality.by_id("labrador").id, "labrador", "by_id resolves the Labrador")
	assert_eq(BreedPersonality.by_id("chocolate_labrador").id, "chocolate_labrador",
		"by_id resolves the chocolate Labrador")
	assert_eq(BreedPersonality.by_id("ghost").id, "labrador",
		"an unknown id falls back to the starter Labrador (never a dog-less resolve)")

func test_is_known_only_for_shipped_breeds() -> void:
	assert_true(BreedPersonality.is_known("labrador"), "the Labrador is a shipped breed")
	assert_true(BreedPersonality.is_known("chocolate_labrador"), "the chocolate Lab is a shipped breed")
	assert_false(BreedPersonality.is_known("border_collie"), "an unshipped breed is not known (owner-gated)")

func test_catalog_lists_both_shipped_breeds_in_order() -> void:
	var cat := BreedPersonality.catalog()
	assert_eq(cat.size(), 2, "the catalog holds exactly the two shipped breeds")
	assert_eq((cat[0] as BreedPersonality).id, "labrador", "the starter Labrador is first")
	assert_eq((cat[1] as BreedPersonality).id, "chocolate_labrador", "the chocolate Lab is second")

func test_swatch_colors_are_distinct_and_honest() -> void:
	# The menu thumbnail is an honest coat-colour chip (not a faked breed image): the two breeds read as
	# clearly different colours, and the chocolate reads darker than the yellow Lab.
	var lab := BreedPersonality.labrador().swatch_color()
	var choc := BreedPersonality.chocolate_labrador().swatch_color()
	assert_true(lab != choc, "the two breeds have distinct coat swatches")
	assert_true(choc.r < lab.r and choc.g < lab.g, "the chocolate coat swatch reads darker than the yellow Lab")

func test_set_gains_updates_fill_speed_live() -> void:
	# A live breed switch (079) re-applies the new learn_speed to an existing TrickProgress via set_gains,
	# so the felt fill speed matches the chosen dog without rebuilding the model.
	var p := TrickProgress.new()  # baseline gains
	p.set_gains(TrickProgress.PERFECT_GAIN * 2.0, TrickProgress.OK_GAIN * 2.0)
	p.apply(SitWindow.Tier.PERFECT)
	assert_true(p.value > TrickProgress.PERFECT_GAIN,
		"set_gains raises the applied fill so a more-trainable breed fills faster after a live switch")
