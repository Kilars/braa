extends "res://tests/test_case.gd"
## Scene-level wiring for persistence (049, P2-5 "leave and come back"). The unit tests prove
## TrickStore's codec/disk round-trip and TrickProgress.to_dict/restore in isolation; these
## prove the running scene actually (a) saves progress after a mark and (b) restores it into
## both _progress AND the on-screen learned bar on a fresh boot — so a returning player sees
## their filled bar immediately. The save is local user:// (IndexedDB on web): no backend, no
## account, no network — X-7 offline. Hermetic: clear the shared save before/after each test.

func _clear_save() -> void:
	if FileAccess.file_exists(TrickStore.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TrickStore.SAVE_PATH))

func _find_learned_bar(n: Node) -> LearnedBar:
	if n is LearnedBar:
		return n
	for c in n.get_children():
		var f := _find_learned_bar(c)
		if f != null:
			return f
	return null

func test_fresh_boot_with_no_save_starts_empty() -> void:
	_clear_save()
	var main := instantiate_main()
	assert_eq(main._progress.value, 0.0, "first run (no save) boots a clean zero learned bar")
	assert_false(main._progress.mastered, "first run is not pre-mastered")
	main.queue_free()
	_clear_save()

func test_a_mark_persists_and_reloads_into_progress_and_bar() -> void:
	_clear_save()
	# Session A: seed some learned progress, then a real BRA tap runs the production save path.
	var a := instantiate_main()
	a._progress.value = 0.6
	a._on_bra_pressed()  # CC0 → DEAD → erodes to ~0.55 AND saves via _apply_progress → _save_progress
	var saved_value: float = a._progress.value
	assert_true(saved_value > 0.0 and saved_value < 0.6, "the DEAD tap eroded a bit (and triggered a save)")
	a.queue_free()

	# Session B: a fresh boot must restore that value into the model AND the visible bar.
	var b := instantiate_main()
	assert_true(absf(b._progress.value - saved_value) < 1e-4,
		"a fresh boot restores the saved learned value into _progress (P2-5)")
	var bar := _find_learned_bar(b)
	assert_true(bar != null, "the learned bar is mounted")
	assert_true(absf(bar.value - saved_value) < 1e-4,
		"the restored fill shows on the learned bar immediately on boot")
	b.queue_free()
	_clear_save()

func test_per_trick_progress_is_isolated_and_persists_by_id() -> void:
	# BUST-064 / 065: with Ligg wired alongside Sitt, learned progress is keyed per trick. A mark on
	# the current trick must persist under ITS id and never leak into the other trick's bar. Proves
	# main holds a per-trick map + saves the whole map, and a fresh boot restores each key on its own.
	_clear_save()
	var a := instantiate_main()
	assert_true(a._progress_by_trick.has("sitt"), "sitt progress exists in the per-trick map")
	assert_true(a._progress_by_trick.has("ligg"), "ligg progress exists in the per-trick map (Ligg is wired)")
	assert_eq(a._current_trick, "sitt", "default current trick is Sitt (no ?bra_trick reach off-web)")
	assert_true(a._progress == a._progress_by_trick["sitt"], "_progress aliases the CURRENT trick's model")
	a._progress_by_trick["sitt"].value = 0.5
	a._progress_by_trick["ligg"].value = 0.0
	a._save_progress()
	a.queue_free()

	var saved := TrickStore.new().load()
	assert_true(saved.has("sitt"), "the store persists the sitt key")
	assert_true(absf(float((saved["sitt"] as Dictionary).get("value", -1.0)) - 0.5) < 1e-4,
		"sitt's learned value round-trips under its own key")

	var b := instantiate_main()
	assert_true(absf(b._progress_by_trick["sitt"].value - 0.5) < 1e-4, "sitt restores its saved fill")
	assert_eq(b._progress_by_trick["ligg"].value, 0.0, "ligg stays empty — no cross-trick leak")
	b.queue_free()
	_clear_save()

func test_legg_deg_has_its_own_isolated_progress_slot() -> void:
	# 067 / P2-2: wiring Legg deg as the third trick gives it its own per-trick progress key, keyed
	# independently of Sitt and Ligg. Proves main holds a legg_deg slot that persists on its own key
	# and never leaks into the other tricks' bars.
	_clear_save()
	var a := instantiate_main()
	assert_true(a._progress_by_trick.has("legg_deg"), "legg_deg progress exists in the per-trick map (it's wired)")
	a._progress_by_trick["sitt"].value = 0.0
	a._progress_by_trick["ligg"].value = 0.0
	a._progress_by_trick["legg_deg"].value = 0.7
	a._save_progress()
	a.queue_free()

	var saved := TrickStore.new().load()
	assert_true(saved.has("legg_deg"), "the store persists the legg_deg key")

	var b := instantiate_main()
	assert_true(absf(b._progress_by_trick["legg_deg"].value - 0.7) < 1e-4, "legg_deg restores its saved fill")
	assert_eq(b._progress_by_trick["sitt"].value, 0.0, "sitt stays empty — no cross-trick leak")
	assert_eq(b._progress_by_trick["ligg"].value, 0.0, "ligg stays empty — no cross-trick leak")
	b.queue_free()
	_clear_save()

func test_mastery_checkpoint_survives_a_reload() -> void:
	_clear_save()
	# Session A: drive the model to mastered and save it through the production path.
	var a := instantiate_main()
	a._progress.value = 1.0
	a._progress.mastered = true
	a._save_progress()
	a.queue_free()

	# Session B: the safe checkpoint must survive — re-practice can't drop below mastery.
	var b := instantiate_main()
	assert_true(b._progress.mastered, "a mastered trick reloads still mastered (safe checkpoint)")
	b._progress.apply(SitWindow.Tier.MISS)
	assert_eq(b._progress.value, 1.0, "post-reload re-practice still can't un-master")
	b.queue_free()
	_clear_save()
