extends "res://tests/test_case.gd"
## Scene-level wiring for the completion menu (072, PO note 1 "one active trick + a completion menu").
## The unit tests pin TrickMenu's classify/hit-map/signals in isolation; these prove the running scene
## mounts the menu (hidden), pops it on MASTERY while PAUSING offers, routes a chosen Available trick
## through select_trick and resumes, keeps the current trick on dismiss, and never lets a Locked
## (owner-gated, absent) trick switch or play. They also pin the PO's headline change: the always-on
## chip row is GONE (the menu is the chooser), and a persistent "Tricks" affordance reopens it.
##
## CC0-safe: the committed idle-only dog performs no trick, so mastery is driven directly through the
## per-trick TrickProgress (dog-agnostic), exactly as the learned-bar wiring test drives progress.

func _find_by_class(n: Node, klass) -> Node:
	if is_instance_of(n, klass):
		return n
	for c in n.get_children():
		var f := _find_by_class(c, klass)
		if f != null:
			return f
	return null

func _find_by_name(n: Node, nm: String) -> Node:
	if n.name == nm:
		return n
	for c in n.get_children():
		var f := _find_by_name(c, nm)
		if f != null:
			return f
	return null

func _find_menu(main: Node) -> TrickMenu:
	return _find_by_class(main, TrickMenu) as TrickMenu

func test_scene_mounts_the_menu_hidden() -> void:
	var main := instantiate_main()
	var menu := _find_menu(main)
	assert_true(menu != null, "the scene must mount the completion menu (PO note 1)")
	assert_false(menu.visible, "the menu starts hidden — it pops on mastery / the Tricks button")
	main.queue_free()

func test_always_on_chip_row_is_gone() -> void:
	# PO note 1 supersedes the 066 always-on chip row: no TrickSelector node in default play.
	var main := instantiate_main()
	assert_true(_find_by_name(main, "TrickSelector") == null,
		"the always-on selector chip row is retired (the menu is the chooser now)")
	main.queue_free()

func test_scene_mounts_a_reopen_affordance() -> void:
	var main := instantiate_main()
	assert_true(_find_by_name(main, "TricksButton") != null,
		"a persistent Tricks affordance reopens the menu between rounds (not a dead-end)")
	main.queue_free()

func test_mastering_the_active_trick_opens_the_menu() -> void:
	# Drive the current trick to the mastery edge, then land a PERFECT: the crossing must pop the menu.
	var main := instantiate_main()
	main._progress.value = 0.9
	main._apply_progress(SitWindow.Tier.PERFECT)  # 0.9 -> 1.0 crosses mastery
	assert_true(main._menu_open, "mastering the active trick pops the completion menu (PO note 1)")
	assert_true(_find_menu(main).visible, "the menu is shown on mastery")
	main.queue_free()

func test_open_menu_pauses_offers() -> void:
	# While the menu is up no offer may fire — _advance_loop must not even tick the loop. A tick-counting
	# spy proves the guard: 0 ticks while open, a tick once closed.
	var main := instantiate_main()
	var spy := _LoopSpy.new()
	main._loop = spy
	main._menu_open = true
	main._advance_loop(1.0)
	assert_eq(spy.ticks, 0, "no offer is advanced while the completion menu is open")
	main._menu_open = false
	main._advance_loop(1.0)
	assert_eq(spy.ticks, 1, "offers resume once the menu closes")
	main.queue_free()

func test_open_menu_resets_loop_to_idle() -> void:
	var main := instantiate_main()
	main._open_trick_menu()
	assert_false(main._loop.is_sitting(), "opening the menu parks the loop in idle so no half-offer lingers")
	assert_true(main._menu_open, "the menu-open guard is set")
	main.queue_free()

func test_choosing_available_trick_switches_and_resumes() -> void:
	# Choosing a performable trick routes through select_trick (repoints _current_trick) and closes the
	# menu so offers resume. Ligg carries a distinct fill to prove _progress repointed (dog-agnostic).
	var main := instantiate_main()
	main._progress_by_trick[DogClips.TRICK_LIGG].value = 0.4
	main._open_trick_menu()
	main._on_trick_chosen(DogClips.TRICK_LIGG)
	assert_eq(main._current_trick, DogClips.TRICK_LIGG, "choosing Ligg makes it the active trick")
	assert_eq(main._progress.value, 0.4, "_progress now aliases Ligg's own learned model")
	assert_false(main._menu_open, "choosing a trick closes the menu and resumes offers")
	assert_false(_find_menu(main).visible, "the menu hides after a choice")
	main.queue_free()

func test_dismiss_keeps_the_current_trick() -> void:
	var main := instantiate_main()
	var before: String = main._current_trick
	main._open_trick_menu()
	main._on_menu_dismissed()
	assert_eq(main._current_trick, before, "dismissing keeps training the current trick (no switch)")
	assert_false(main._menu_open, "dismiss closes the menu")
	assert_false(_find_menu(main).visible, "the menu hides on dismiss")
	main.queue_free()

func test_locked_trick_is_never_selectable_or_performable() -> void:
	# The honesty gate: a genuinely-absent roadmap trick is never performable, never in the selectable
	# set, and choosing its id can never switch the active trick (it can never play a faked clip).
	var main := instantiate_main()
	var before: String = main._current_trick
	for locked in main.ROADMAP_LOCKED_TRICKS:
		assert_false(main._selectable_tricks().has(locked), "a locked trick is never selectable")
		assert_false(main._director != null and main._director.has_trick(locked),
			"the dog can never perform a locked (absent) trick")
		main._on_trick_chosen(locked)
		assert_eq(main._current_trick, before, "choosing a locked id never switches the active trick")
	main.queue_free()

func test_reopen_affordance_opens_the_menu() -> void:
	var main := instantiate_main()
	var btn := _find_by_name(main, "TricksButton") as BaseButton
	btn.pressed.emit()
	assert_true(main._menu_open, "pressing Tricks reopens the completion menu")
	main.queue_free()

# A SitLoop that counts tick() calls, to prove _advance_loop honours the _menu_open guard.
class _LoopSpy extends SitLoop:
	var ticks := 0
	func tick(_delta: float, _has_sit: bool, _session_elapsed: float, _sit_end: float) -> int:
		ticks += 1
		return SitLoop.Intent.NONE
