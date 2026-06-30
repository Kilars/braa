extends "res://tests/test_case.gd"
## Scene-level wiring for the P2-8 feint (048). The SitLoop tests prove the loop EMITS the
## feint intents; the director test proves play_feint() dips-and-aborts. This proves the
## running scene GLUE keeps a feint honest: _begin_feint() must NOT open the session, build a
## window, or build the apex tell — so the marker stays dark and a tap during the feint flows
## through the existing path as a wrong-moment DEAD → gentle erosion of the learned bar
## (P2-4), with no new downstream branches. A wiring regression (a feint that opens a window,
## or doesn't keep the tell dark) can then never read green.
##
## Hermetic: the DEAD-tap test drives the real _on_bra_pressed, which runs 049's _save_progress
## to the shared user:// store — so it clears that save before AND after (the same isolation
## test_trick_store_wiring uses) and never leaks a non-zero bar into another scene-boot test.

func _clear_save() -> void:
	if FileAccess.file_exists(TrickStore.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TrickStore.SAVE_PATH))

func test_a_feint_opens_no_session_window_or_tell() -> void:
	var main := instantiate_main()
	main._begin_feint()
	assert_false(main._session.is_open(), "a feint opens NO markable session")
	assert_eq(main._window, null, "a feint builds NO scoring window")
	assert_eq(main._tell, null, "the apex tell stays dark through a feint (P1-4 honest)")
	main.queue_free()

func test_a_tap_during_a_feint_is_dead_and_erodes_the_bar() -> void:
	_clear_save()
	var main := instantiate_main()
	# Pre-fill the learned bar above the floor so the gentle DEAD erosion is observable.
	main._progress.value = 0.5
	main._begin_feint()
	var scored := [99]
	main.marked.connect(func(tier): scored[0] = tier)
	var before: float = main._progress.value
	main._on_bra_pressed()
	assert_eq(scored[0], SitWindow.Tier.DEAD,
		"a tap during a feint scores DEAD — the session stayed closed (wrong-moment tap)")
	assert_true(main._progress.value < before,
		"the DEAD tap erodes the learned bar (P2-4 negative learning)")
	main.queue_free()
	_clear_save()
