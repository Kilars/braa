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
