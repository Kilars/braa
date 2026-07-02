extends "res://tests/test_case.gd"
## Scene-level wiring for the coin economy (068, Phase-3 P3-D3). The unit tests prove CoinPurse's
## earn/spend/round-trip in isolation; these prove the running scene actually (a) awards coins the
## instant a trick reaches mastery through the production _apply_progress path, (b) does NOT re-award
## on re-practice of an already-mastered trick (mastery's safe-checkpoint latch means just_mastered
## fires once), and (c) restores the earned balance on a fresh boot (a returning player keeps their
## coins, and they are not re-earned on load). Save is local user:// (IndexedDB on web) — X-7 offline.
## Hermetic: clear the shared save before/after each test.

func _clear_save() -> void:
	if FileAccess.file_exists(TrickStore.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TrickStore.SAVE_PATH))

func test_fresh_player_has_no_coins() -> void:
	_clear_save()
	var main := instantiate_main()
	assert_eq(main._purse.balance, 0, "a first-run player starts with an empty purse")
	main.queue_free()
	_clear_save()

func test_mastering_a_trick_earns_coins_once() -> void:
	_clear_save()
	var a := instantiate_main()
	assert_eq(a._purse.balance, 0, "no coins before any mastery")
	a._progress.value = 0.9                          # one PERFECT away from mastery
	a._apply_progress(SitWindow.Tier.PERFECT)        # crosses mastery -> just_mastered -> earn
	assert_true(a._progress.mastered, "the PERFECT reached mastery")
	assert_eq(a._purse.balance, a.COIN_REWARD_MASTERY,
		"mastering a trick awards COIN_REWARD_MASTERY through the production path")
	# Re-practising an already-mastered trick earns nothing more (no coin farming).
	a._apply_progress(SitWindow.Tier.PERFECT)
	assert_eq(a._purse.balance, a.COIN_REWARD_MASTERY,
		"re-practising a mastered trick earns no further coins (safe-checkpoint latch)")
	a.queue_free()
	_clear_save()

func test_earned_coins_survive_a_reload_and_are_not_re_awarded() -> void:
	_clear_save()
	var a := instantiate_main()
	a._progress.value = 0.9
	a._apply_progress(SitWindow.Tier.PERFECT)        # earns + persists via _save_progress
	var earned: int = a._purse.balance
	assert_true(earned > 0, "coins were earned in session A")
	a.queue_free()

	var b := instantiate_main()
	assert_eq(b._purse.balance, earned,
		"a fresh boot restores the earned balance (P2-5-style persistence, not re-awarded on load)")
	b.queue_free()
	_clear_save()

# ---- Difficulty-scaled reward (082, P4-3 "pain pays"): the mastery payout scales with active difficulty ----

func test_normal_difficulty_mastery_payout_is_exactly_coin_reward_mastery() -> void:
	# Dormancy regression guard: default Normal mode earns exactly COIN_REWARD_MASTERY per mastery,
	# reproducing the Phase-3 economy EXACTLY. No default-HUD change; the play-test is byte-identical.
	_clear_save()
	var main := instantiate_main()  # boots with default Normal difficulty
	assert_eq(main._difficulty.id, "normal", "default boot resolves to Normal difficulty")
	main._progress.value = 0.9
	main._apply_progress(SitWindow.Tier.PERFECT)    # PERFECT reaches mastery
	assert_true(main._progress.mastered, "the PERFECT reaches mastery")
	var base_payout: int = main.COIN_REWARD_MASTERY
	assert_eq(main._purse.balance, base_payout,
		"Normal mode earns exactly COIN_REWARD_MASTERY (10) per mastery — economy unregressed")
	main.queue_free()
	_clear_save()

func test_expert_difficulty_mastery_payout_scales_by_reward_scale() -> void:
	# With expert difficulty active, the mastery payout scales by expert's reward_scale (2.0).
	# Expert.mastery_reward(10) = 20, so mastery should award 20 coins, not the base 10.
	_clear_save()
	var main := instantiate_main()
	# Inject expert difficulty via the ?bra_difficulty= seam (used by Visual Review harness).
	# The wiring reads the URL query at boot time, so we must set it before the scene's _ready.
	# instantiate_main() loads the scene but has NOT called _ready yet, so we can inject first.
	# Actually, instantiate_main() DOES call _ready() immediately if not ready.
	# To inject the query, we need to override it BEFORE instantiate_main calls _ready.
	# Since we can't modify the JS bridge pre-boot in headless tests, we directly set _difficulty.
	main._difficulty = Difficulty.expert()
	assert_eq(main._difficulty.id, "expert", "difficulty injected as expert")

	main._progress.value = 0.9
	main._apply_progress(SitWindow.Tier.PERFECT)    # PERFECT reaches mastery
	assert_true(main._progress.mastered, "the PERFECT reaches mastery")
	var expected_payout: int = main._difficulty.mastery_reward(main.COIN_REWARD_MASTERY)
	assert_eq(expected_payout, 20, "expert.mastery_reward(10) == 20")
	assert_eq(main._purse.balance, expected_payout,
		"mastering a trick with expert difficulty awards the scaled payout (20), not the base (10)")
	main.queue_free()
	_clear_save()

func test_hard_difficulty_mastery_payout_scales_by_reward_scale() -> void:
	# With hard difficulty active, the mastery payout scales by hard's reward_scale (1.4).
	# Hard.mastery_reward(10) = 14, so mastery should award 14 coins, not the base 10.
	_clear_save()
	var main := instantiate_main()
	# Inject hard difficulty directly (same approach as expert test above).
	main._difficulty = Difficulty.hard()
	assert_eq(main._difficulty.id, "hard", "difficulty injected as hard")

	main._progress.value = 0.9
	main._apply_progress(SitWindow.Tier.PERFECT)    # PERFECT reaches mastery
	assert_true(main._progress.mastered, "the PERFECT reaches mastery")
	var expected_payout: int = main._difficulty.mastery_reward(main.COIN_REWARD_MASTERY)
	assert_eq(expected_payout, 14, "hard.mastery_reward(10) == 14")
	assert_eq(main._purse.balance, expected_payout,
		"mastering a trick with hard difficulty awards the scaled payout (14), not the base (10)")
	main.queue_free()
	_clear_save()
