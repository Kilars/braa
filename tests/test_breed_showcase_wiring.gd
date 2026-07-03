extends "res://tests/test_case.gd"
## Scene-level wiring for the spotlit breed showcase (090, PO 2026-07-03 Bugfix 2). The pure model +
## view chrome are pinned by test_breed_showcase(.gd / _view.gd); this proves the RUNNING scene HIDES the
## training-HUD chrome while the showcase is open and RESTORES it on both close paths.
##
## Why: the showcase keeps its centre transparent so the spotlit dog shows through — the always-on BRA
## button (and the rest of the training chrome) must not ghost through that clear centre. The opaque
## trick-menu panel covers the chrome, so this concern is unique to the showcase surface.
##
## CC0-safe: the committed idle-only dog needs no trick to open/close the showcase. Hermetic: clear the
## shared save before/after so a leaked roster from another test can't change what is owned/shown.

const CHROME_NODES := ["_tell_marker", "_trainer_marker", "_readout", "_learned_bar", "_coin_readout", "_tricks_button"]

func _clear_save() -> void:
	if FileAccess.file_exists(TrickStore.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TrickStore.SAVE_PATH))

func test_open_hides_bra_and_dismiss_restores() -> void:
	_clear_save()
	var main := instantiate_main()
	assert_true(main._bra_button.visible, "the BRA button is visible during training")
	main._on_showcase_requested()
	assert_true(main._showcase.visible, "the showcase opened")
	assert_false(main._bra_button.visible, "BRA is hidden while the showcase is open (no ghost through the clear centre)")
	main._on_showcase_dismissed()
	assert_true(main._bra_button.visible, "BRA is restored after the showcase closes (dismiss)")
	main.queue_free()
	_clear_save()

func test_open_hides_the_full_training_chrome_and_close_restores() -> void:
	_clear_save()
	var main := instantiate_main()
	main._on_showcase_requested()
	for prop in CHROME_NODES:
		assert_false((main.get(prop) as CanvasItem).visible, "training chrome '%s' is hidden while the showcase is open" % prop)
	main._on_showcase_dismissed()
	for prop in CHROME_NODES:
		assert_true((main.get(prop) as CanvasItem).visible, "training chrome '%s' is restored after the showcase closes" % prop)
	main.queue_free()
	_clear_save()

func test_commit_close_path_also_restores_the_chrome() -> void:
	## "Tren denne" closes the showcase through the same _close_showcase path — chrome must restore even
	## when the commit then re-selects the (already active) breed.
	_clear_save()
	var main := instantiate_main()
	main._on_showcase_requested()
	assert_false(main._bra_button.visible, "BRA hidden while the showcase is open")
	main._on_showcase_commit()  # spotlit == active labrador → the switch is a no-op, but the showcase closes
	assert_true(main._bra_button.visible, "BRA is restored after commit closes the showcase")
	main.queue_free()
	_clear_save()
