extends "res://tests/test_case.gd"
## TDD for the global difficulty mode model (080, P4-1 "Choose how hard"). Difficulty is a pure
## value object holding six multiplier levers (window_scale, tell_intensity_scale, tell_speed_scale,
## feint_scale, erosion_scale, reward_scale) around 1.0. Normal is IDENTITY (1.0 on every lever) —
## reproduces today's tuning EXACTLY, no silent regression. Hard and Expert are monotonically harder
## than Normal on every lever: window_scale tightens (↓), tell fades (↓), tell speeds (↑), feints
## multiply (↑), erosion hardens (↑), reward rises (↑). Mirrors BreedPersonality: static factories,
## catalog(), is_known(), by_id() resolver with safe fallback.

func test_normal_difficulty_is_identity_on_every_lever() -> void:
	# The Normal mode reproduces today's tuning EXACTLY — all modifiers are 1.0, no regression.
	var n := Difficulty.normal()
	assert_eq(n.id, "normal", "Normal mode has id 'normal'")
	assert_eq(n.window_scale, 1.0, "Normal window_scale is 1.0 (identity, no timing change)")
	assert_eq(n.tell_intensity_scale, 1.0, "Normal tell_intensity_scale is 1.0 (tell as bright as today)")
	assert_eq(n.tell_speed_scale, 1.0, "Normal tell_speed_scale is 1.0 (tell animation speed as today)")
	assert_eq(n.feint_scale, 1.0, "Normal feint_scale is 1.0 (feint chance as today)")
	assert_eq(n.erosion_scale, 1.0, "Normal erosion_scale is 1.0 (bar loss as harsh as today)")
	assert_eq(n.reward_scale, 1.0, "Normal reward_scale is 1.0 (coins as plentiful as today)")

func test_hard_difficulty_is_monotonically_harder_than_normal() -> void:
	# Hard mode tightens the window (↓), fades the tell (↓), speeds it (↑), multiplies feints (↑),
	# hardens erosion (↑), and raises reward (↑). Each lever is harder in exactly one direction.
	var n := Difficulty.normal()
	var h := Difficulty.hard()
	assert_eq(h.id, "hard", "Hard mode has id 'hard'")
	assert_true(h.window_scale < n.window_scale, "Hard window_scale is tighter (<1, harder timing)")
	assert_true(h.tell_intensity_scale < n.tell_intensity_scale, "Hard tell_intensity_scale is fainter (<1)")
	assert_true(h.tell_speed_scale > n.tell_speed_scale, "Hard tell_speed_scale is faster (>1)")
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
	assert_true(e.tell_speed_scale > h.tell_speed_scale, "Expert tell_speed_scale is faster than Hard")
	assert_true(e.feint_scale > h.feint_scale, "Expert feint_scale is higher than Hard")
	assert_true(e.erosion_scale > h.erosion_scale, "Expert erosion_scale is harsher than Hard")
	assert_true(e.reward_scale > h.reward_scale, "Expert reward_scale is higher than Hard")

func test_expert_difficulty_is_monotonically_harder_than_normal() -> void:
	# Expert is harder than Normal on every lever (transitive across the stack).
	var n := Difficulty.normal()
	var e := Difficulty.expert()
	assert_true(e.window_scale < n.window_scale, "Expert window_scale is tighter than Normal")
	assert_true(e.tell_intensity_scale < n.tell_intensity_scale, "Expert tell_intensity_scale is fainter than Normal")
	assert_true(e.tell_speed_scale > n.tell_speed_scale, "Expert tell_speed_scale is faster than Normal")
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
	assert_eq(e.display_name, "Expert", "Expert mode has display_name 'Expert'")

func test_normal_display_name() -> void:
	var n := Difficulty.normal()
	assert_eq(n.display_name, "Normal", "Normal mode has display_name 'Normal'")
