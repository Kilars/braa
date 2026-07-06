extends "res://tests/test_case.gd"
## TDD for the global difficulty mode model (080, P4-1 "Choose how hard"). Difficulty is a pure
## value object holding five multiplier levers (window_scale, tell_intensity_scale, feint_scale,
## erosion_scale, reward_scale) around 1.0. Normal is IDENTITY (1.0 on every lever) — reproduces
## today's tuning EXACTLY, no silent regression. Hard and Expert are monotonically harder than Normal
## on every lever: window_scale tightens (↓), tell fades (↓), feints multiply (↑), erosion hardens
## (↑), reward rises (↑). No independent tell_speed_scale — the tell's narrowness/speed follows the
## difficulty-tightened window (one source of truth). Mirrors BreedPersonality: static factories,
## catalog(), is_known(), by_id() resolver with safe fallback.

func test_normal_difficulty_is_identity_on_every_lever() -> void:
	# The Normal mode reproduces today's tuning EXACTLY — all modifiers are 1.0, no regression.
	var n := Difficulty.normal()
	assert_eq(n.id, "normal", "Normal mode has id 'normal'")
	assert_eq(n.window_scale, 1.0, "Normal window_scale is 1.0 (identity, no timing change)")
	assert_eq(n.tell_intensity_scale, 1.0, "Normal tell_intensity_scale is 1.0 (tell as bright as today)")
	assert_eq(n.feint_scale, 1.0, "Normal feint_scale is 1.0 (feint chance as today)")
	assert_eq(n.erosion_scale, 1.0, "Normal erosion_scale is 1.0 (bar loss as harsh as today)")
	assert_eq(n.reward_scale, 1.0, "Normal reward_scale is 1.0 (coins as plentiful as today)")

func test_hard_difficulty_is_monotonically_harder_than_normal() -> void:
	# Hard mode tightens the window (↓), fades the tell (↓), multiplies feints (↑),
	# hardens erosion (↑), and raises reward (↑). Each lever is harder in exactly one direction.
	var n := Difficulty.normal()
	var h := Difficulty.hard()
	assert_eq(h.id, "hard", "Hard mode has id 'hard'")
	assert_true(h.window_scale < n.window_scale, "Hard window_scale is tighter (<1, harder timing)")
	assert_true(h.tell_intensity_scale < n.tell_intensity_scale, "Hard tell_intensity_scale is fainter (<1)")
	assert_true(h.feint_scale > n.feint_scale, "Hard feint_scale is higher (>1, more distractions)")
	assert_true(h.erosion_scale > n.erosion_scale, "Hard erosion_scale is harsher (>1, bar drains faster)")
	assert_true(h.reward_scale > n.reward_scale, "Hard reward_scale is higher (>1, pain pays)")

func test_expert_difficulty_is_monotonically_harder_than_hard() -> void:
	# Expert mode is harder than Hard on every lever, maintaining the monotonic stack.
	var h := Difficulty.hard()
	var e := Difficulty.expert()
	assert_eq(e.id, "expert", "Expert mode has id 'expert'")
	assert_true(e.window_scale < h.window_scale, "Expert window_scale is tighter than Hard")
	assert_true(e.tell_intensity_scale < h.tell_intensity_scale, "Expert tell_intensity_scale is fainter than Hard")
	assert_true(e.feint_scale > h.feint_scale, "Expert feint_scale is higher than Hard")
	assert_true(e.erosion_scale > h.erosion_scale, "Expert erosion_scale is harsher than Hard")
	assert_true(e.reward_scale > h.reward_scale, "Expert reward_scale is higher than Hard")

func test_expert_difficulty_is_monotonically_harder_than_normal() -> void:
	# Expert is harder than Normal on every lever (transitive across the stack).
	var n := Difficulty.normal()
	var e := Difficulty.expert()
	assert_true(e.window_scale < n.window_scale, "Expert window_scale is tighter than Normal")
	assert_true(e.tell_intensity_scale < n.tell_intensity_scale, "Expert tell_intensity_scale is fainter than Normal")
	assert_true(e.feint_scale > n.feint_scale, "Expert feint_scale is higher than Normal")
	assert_true(e.erosion_scale > n.erosion_scale, "Expert erosion_scale is harsher than Normal")
	assert_true(e.reward_scale > n.reward_scale, "Expert reward_scale is higher than Normal")

func test_is_known_returns_true_for_shipped_modes() -> void:
	# is_known() validates against shipped modes: Normal, Hard, Expert.
	assert_true(Difficulty.is_known("normal"), "Normal is a shipped mode")
	assert_true(Difficulty.is_known("hard"), "Hard is a shipped mode")
	assert_true(Difficulty.is_known("expert"), "Expert is a shipped mode")

func test_is_known_returns_false_for_unknown_mode() -> void:
	# An unshipped / garbage / typo id is not known.
	assert_false(Difficulty.is_known("impossible"), "an unknown mode is not known")
	assert_false(Difficulty.is_known("nightmare"), "a non-shipped mode is not known")
	assert_false(Difficulty.is_known(""), "an empty id is not known")

func test_by_id_resolves_known_modes() -> void:
	# by_id() resolves a shipped mode id to its difficulty bundle.
	assert_eq(Difficulty.by_id("normal").id, "normal", "by_id('normal') resolves to the Normal mode")
	assert_eq(Difficulty.by_id("hard").id, "hard", "by_id('hard') resolves to the Hard mode")
	assert_eq(Difficulty.by_id("expert").id, "expert", "by_id('expert') resolves to the Expert mode")

func test_by_id_falls_back_to_normal_for_unknown_mode() -> void:
	# An unknown id falls back to Normal — never a dead resolve, so a corrupt/legacy setting still boots.
	var unknown := Difficulty.by_id("garbage")
	assert_eq(unknown.id, "normal", "an unknown mode id falls back to Normal (safe default)")
	assert_eq(unknown.window_scale, 1.0, "the fallback resolves to Normal's identity window_scale")

	var empty := Difficulty.by_id("")
	assert_eq(empty.id, "normal", "an empty id falls back to Normal")

func test_catalog_lists_all_shipped_modes_in_order() -> void:
	# catalog() returns all shipped modes: Normal, Hard, Expert in that order.
	var cat := Difficulty.catalog()
	assert_eq(cat.size(), 3, "the catalog holds exactly three shipped modes")
	assert_eq((cat[0] as Difficulty).id, "normal", "Normal is first in the catalog")
	assert_eq((cat[1] as Difficulty).id, "hard", "Hard is second in the catalog")
	assert_eq((cat[2] as Difficulty).id, "expert", "Expert is third in the catalog")

func test_hard_display_name() -> void:
	# Each mode carries a human-readable display name for the UI.
	var h := Difficulty.hard()
	assert_eq(h.display_name, "Hard", "Hard mode has display_name 'Hard'")

func test_expert_display_name() -> void:
	var e := Difficulty.expert()
	assert_eq(e.display_name, "Ekspert", "Expert mode has Norwegian display_name 'Ekspert'")

func test_normal_display_name() -> void:
	var n := Difficulty.normal()
	assert_eq(n.display_name, "Normal", "Normal mode has display_name 'Normal'")

# ---- Composition accessors (P4-2/P4-4): pure resolved accessors mirror BreedPersonality style ----

func test_scale_radius_normal_is_identity() -> void:
	# Normal mode's scale_radius() is the identity — returns the input unchanged.
	var n := Difficulty.normal()
	assert_eq(n.scale_radius(0.08), 0.08, "Normal.scale_radius(0.08) == 0.08 (identity)")
	assert_eq(n.scale_radius(0.20), 0.20, "Normal.scale_radius(0.20) == 0.20 (identity)")

func test_scale_radius_hard_tightens_window() -> void:
	# Hard mode's scale_radius() tightens the window by multiplying the input by hard's window_scale.
	var h := Difficulty.hard()
	var scaled: float = h.scale_radius(0.08)
	assert_eq(scaled, 0.08 * h.window_scale, "Hard.scale_radius(0.08) == 0.08 * hard.window_scale")
	assert_true(scaled < 0.08, "Hard's scaled radius is strictly smaller (tighter window)")

func test_scale_radius_expert_tighter_than_hard() -> void:
	# Expert mode tightens more than Hard — expert.window_scale < hard.window_scale.
	var h := Difficulty.hard()
	var e := Difficulty.expert()
	assert_true(e.scale_radius(0.08) < h.scale_radius(0.08),
		"Expert.scale_radius(0.08) < Hard.scale_radius(0.08) — Expert is tighter")

func test_scale_feint_normal_is_identity() -> void:
	# Normal mode's scale_feint() is the identity.
	var n := Difficulty.normal()
	assert_eq(n.scale_feint(0.1), 0.1, "Normal.scale_feint(0.1) == 0.1 (identity)")
	assert_eq(n.scale_feint(0.5), 0.5, "Normal.scale_feint(0.5) == 0.5 (identity)")

func test_scale_feint_hard_multiplies_and_clamps() -> void:
	# Hard mode's scale_feint() multiplies the input by hard's feint_scale and clamps to [0,1].
	var h := Difficulty.hard()
	var scaled: float = h.scale_feint(0.1)
	assert_eq(scaled, clampf(0.1 * h.feint_scale, 0.0, 1.0),
		"Hard.scale_feint(0.1) == clampf(0.1 * hard.feint_scale, 0, 1)")
	assert_true(scaled > 0.1, "Hard's scaled feint is strictly larger (more distractors)")
	assert_true(scaled <= 1.0, "Hard's scaled feint clamps at 1.0")

func test_scale_feint_expert_higher_than_hard() -> void:
	# Expert mode's feint_scale is larger than Hard's.
	var h := Difficulty.hard()
	var e := Difficulty.expert()
	assert_true(e.scale_feint(0.1) > h.scale_feint(0.1),
		"Expert.scale_feint(0.1) > Hard.scale_feint(0.1) — Expert has more feints")

func test_scale_feint_clamps_at_one() -> void:
	# scale_feint() never exceeds 1.0, even with a high feint_scale and high input.
	var e := Difficulty.expert()
	var scaled: float = e.scale_feint(0.8)
	assert_true(scaled <= 1.0, "Expert.scale_feint(0.8) clamps at 1.0, never exceeds it")
	assert_eq(scaled, clampf(0.8 * e.feint_scale, 0.0, 1.0), "Expert.scale_feint(0.8) respects clamp")

func test_scale_erosion_normal_is_identity() -> void:
	# Normal mode's scale_erosion() is the identity.
	var n := Difficulty.normal()
	assert_eq(n.scale_erosion(0.10), 0.10, "Normal.scale_erosion(0.10) == 0.10 (identity)")
	assert_eq(n.scale_erosion(0.05), 0.05, "Normal.scale_erosion(0.05) == 0.05 (identity)")

func test_scale_erosion_hard_scales_up() -> void:
	# Hard mode's scale_erosion() multiplies the input by hard's erosion_scale (higher damage on mistaps).
	var h := Difficulty.hard()
	var scaled: float = h.scale_erosion(0.10)
	assert_eq(scaled, 0.10 * h.erosion_scale,
		"Hard.scale_erosion(0.10) == 0.10 * hard.erosion_scale")
	assert_true(scaled > 0.10, "Hard's scaled erosion is strictly larger (harsher)")

func test_scale_erosion_expert_harsher_than_hard() -> void:
	# Expert mode's erosion_scale is larger than Hard's.
	var h := Difficulty.hard()
	var e := Difficulty.expert()
	assert_true(e.scale_erosion(0.10) > h.scale_erosion(0.10),
		"Expert.scale_erosion(0.10) > Hard.scale_erosion(0.10) — Expert is harsher")

func test_scale_tell_intensity_normal_is_identity() -> void:
	# Normal mode's scale_tell_intensity() is the identity.
	var n := Difficulty.normal()
	assert_eq(n.scale_tell_intensity(1.0), 1.0, "Normal.scale_tell_intensity(1.0) == 1.0 (identity)")
	assert_eq(n.scale_tell_intensity(0.5), 0.5, "Normal.scale_tell_intensity(0.5) == 0.5 (identity)")

func test_scale_tell_intensity_hard_fades_and_clamps() -> void:
	# Hard mode's scale_tell_intensity() multiplies by tell_intensity_scale (<1 fainter) and clamps to X-5 floor.
	var h := Difficulty.hard()
	var scaled: float = h.scale_tell_intensity(1.0)
	assert_true(scaled < 1.0, "Hard.scale_tell_intensity(1.0) is fainter (<1.0)")
	assert_true(scaled > 0.0, "Hard.scale_tell_intensity(1.0) stays > 0 (respects X-5 floor)")

func test_scale_tell_intensity_expert_fainter_than_hard() -> void:
	# Expert mode fades the tell more than Hard.
	var h := Difficulty.hard()
	var e := Difficulty.expert()
	assert_true(e.scale_tell_intensity(1.0) < h.scale_tell_intensity(1.0),
		"Expert.scale_tell_intensity(1.0) < Hard.scale_tell_intensity(1.0) — Expert is fainter")
	assert_true(e.scale_tell_intensity(1.0) > 0.0,
		"Expert.scale_tell_intensity(1.0) > 0 — never collapses to zero (X-5 respects)")

func test_scale_tell_intensity_respects_x5_floor_on_reduced_motion() -> void:
	# Even with a reduced-motion input (0.5), the tell intensity stays distinguishable (> 0).
	var e := Difficulty.expert()
	var scaled: float = e.scale_tell_intensity(0.5)
	assert_true(scaled > 0.0,
		"Expert.scale_tell_intensity(0.5) > 0 — reduced motion still shows information (X-5)")

# ---- Reward accessor (082, P4-3 "pain pays"): pure arithmetic, Normal = identity ----

func test_mastery_reward_normal_is_identity() -> void:
	# Normal mode's mastery_reward() is the identity — returns the base exactly, no payout scaling.
	# This is the dormancy guarantee: with default Normal, the economy is unregressed and byte-identical.
	var n := Difficulty.normal()
	assert_eq(n.mastery_reward(10), 10, "Normal.mastery_reward(10) == 10 exactly (identity, no scaling)")
	assert_eq(n.mastery_reward(5), 5, "Normal.mastery_reward(5) == 5 exactly (identity)")
	assert_eq(n.mastery_reward(42), 42, "Normal.mastery_reward(42) == 42 exactly (identity)")

func test_mastery_reward_hard_scales_up() -> void:
	# Hard mode's mastery_reward() multiplies by hard's reward_scale (> 1.0 — "pain pays").
	# reward_scale 1.4 × 10 = 14 exactly.
	var h := Difficulty.hard()
	var result: int = h.mastery_reward(10)
	assert_eq(result, 14, "Hard.mastery_reward(10) == 14 (1.4 × 10, rounded to whole coin)")
	assert_true(result > 10, "Hard.mastery_reward(10) > 10 (more than Normal's payout)")
	assert_eq(typeof(result), TYPE_INT, "mastery_reward returns a whole integer (TYPE_INT)")

func test_mastery_reward_expert_scales_higher() -> void:
	# Expert mode's mastery_reward() scales more than Hard — expert.reward_scale > hard.reward_scale.
	# reward_scale 2.0 × 10 = 20 exactly.
	var e := Difficulty.expert()
	var result: int = e.mastery_reward(10)
	assert_eq(result, 20, "Expert.mastery_reward(10) == 20 (2.0 × 10, rounded to whole coin)")
	assert_true(result > 10, "Expert.mastery_reward(10) > 10 (more than Normal's payout)")
	assert_eq(typeof(result), TYPE_INT, "mastery_reward returns a whole integer")

func test_mastery_reward_expert_strictly_higher_than_hard() -> void:
	# Expert mode's payout is strictly higher than Hard's, maintaining the monotonic stack.
	var h := Difficulty.hard()
	var e := Difficulty.expert()
	var hard_payout: int = h.mastery_reward(10)
	var expert_payout: int = e.mastery_reward(10)
	assert_true(expert_payout > hard_payout,
		"Expert.mastery_reward(10) > Hard.mastery_reward(10) — higher risk pays strictly more")
	assert_eq(expert_payout, 20, "Expert payout is 20")
	assert_eq(hard_payout, 14, "Hard payout is 14")

func test_mastery_reward_rounds_to_whole_coin() -> void:
	# mastery_reward() rounds to a whole integer. With an odd-result scale, it rounds correctly.
	# Normal × 10 = 10; Hard 1.4 × 10 = 14; Expert 2.0 × 10 = 20 (all whole already).
	# Test that the rounding is applied: if reward_scale × base gives a fractional result, it rounds.
	var h := Difficulty.hard()
	# Hard 1.4 × 7 = 9.8, should round to 10.
	var result: int = h.mastery_reward(7)
	assert_eq(typeof(result), TYPE_INT, "mastery_reward always returns TYPE_INT")
	assert_true(result >= 9 and result <= 10, "Hard.mastery_reward(7) rounds 9.8 to a whole coin (9 or 10)")

	# Expert 2.0 × 10 = 20 (exact).
	var e := Difficulty.expert()
	assert_eq(e.mastery_reward(10), 20, "Expert.mastery_reward(10) == 20 (exact, no rounding needed)")
