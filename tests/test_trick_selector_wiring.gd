extends "res://tests/test_case.gd"
## Scene-level wiring for the trick selector (066, P2-1 "Pick a trick"). The unit tests pin
## TrickSelector's mapping/signal in isolation; these prove the running scene mounts the selector,
## populates it with only the tricks the loaded dog can PERFORM (never a trick it can't — the
## never-fake gate), and that picking a trick routes _current_trick and repoints the per-trick
## learned model + the on-screen bar to THAT trick. On the committed CC0 dog no trick resolves, so
## the roster is empty (the honest read that the idle-only placeholder has nothing to train); the
## licensed Labrador fills it locally + on deploy. The routing itself is dog-agnostic — the selector
## is what filters to performable tricks — so it is exercised here on CC0 by calling select_trick.

func _find_selector(n: Node) -> TrickSelector:
	if n is TrickSelector:
		return n
	for c in n.get_children():
		var f := _find_selector(c)
		if f != null:
			return f
	return null

func test_scene_mounts_the_selector() -> void:
	var main := instantiate_main()
	assert_true(_find_selector(main) != null, "the scene must mount the trick selector (P2-1)")
	main.queue_free()

func test_roster_is_only_performable_tricks() -> void:
	# Every listed id must be one the director can actually perform (never a faked trick), and the
	# idle-only CC0 dog performs none → an empty roster.
	var main := instantiate_main()
	var sel := _find_selector(main)
	for id in sel.entry_ids():
		assert_true(main._director != null and main._director.has_trick(id),
			"the selector only offers tricks the dog can perform (never a faked trick)")
	assert_eq(sel.entry_count(), 0, "the idle-only CC0 dog offers no trick to select")
	main.queue_free()

func test_select_trick_routes_current_and_repoints_progress() -> void:
	# The routing contract: picking a trick sets _current_trick and repoints _progress (and the bar)
	# to THAT trick's own persisted model — proven by giving Ligg a distinct fill first, then showing
	# _progress/_bar carry it after the switch.
	var main := instantiate_main()
	main._progress_by_trick[DogClips.TRICK_LIGG].value = 0.5
	main.select_trick(DogClips.TRICK_LIGG)
	assert_eq(main._current_trick, DogClips.TRICK_LIGG, "picking Ligg makes it the trained trick")
	assert_eq(main._progress.value, 0.5, "_progress now aliases Ligg's own learned model")
	assert_eq(main._learned_bar.value, 0.5, "the learned bar reflects the picked trick")
	main.queue_free()

func test_select_same_trick_is_a_noop() -> void:
	var main := instantiate_main()
	var before: String = main._current_trick
	main.select_trick(before)
	assert_eq(main._current_trick, before, "re-picking the current trick changes nothing")
	main.queue_free()

func test_select_unknown_trick_is_ignored() -> void:
	var main := instantiate_main()
	var before: String = main._current_trick
	main.select_trick("no_such_trick")
	assert_eq(main._current_trick, before, "an unknown id never becomes the trained trick")
	main.queue_free()

func test_selector_highlights_the_selected_trick() -> void:
	var main := instantiate_main()
	main.select_trick(DogClips.TRICK_LEGG_DEG)
	var sel := _find_selector(main)
	assert_eq(sel.current_id(), DogClips.TRICK_LEGG_DEG, "the selector highlights the trick main switched to")
	main.queue_free()
