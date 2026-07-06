extends "res://tests/test_case.gd"
## Scene-level wiring for the kennel grid screen (105, Phase 8 K-1/K-3).
## The pure KennelDog model + KennelScreen renderer are pinned in their own unit tests;
## these prove the RUNNING scene:
##   • mounts the kennel screen hidden on the CanvasLayer,
##   • render(rows, balance) builds exactly 8 cells in the GridContainer,
##   • the shared CoinReadout pill reflects the supplied balance after render(),
##   • pressing a cell emits dog_selected(id) with the correct id,
##   • opening the kennel hides the training HUD (task-090 pattern),
##   • closing the kennel restores the training HUD.
##
## CC0-safe: no tricks or sits needed — the kennel screen operates independently of the
## training loop. Hermetic: clear the shared save before/after so a leaked roster can't
## change the tested balance.

func _clear_save() -> void:
	if FileAccess.file_exists(TrickStore.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TrickStore.SAVE_PATH))

## Walk the tree to find the KennelScreen instance (mounted on the UI CanvasLayer).
func _find_kennel(main: Node) -> KennelScreen:
	for child in main.get_children():
		var ui := child as CanvasLayer
		if ui == null:
			continue
		for ui_child in ui.get_children():
			if ui_child is KennelScreen:
				return ui_child as KennelScreen
	return null

## Walk the KennelScreen to find its GridContainer.
func _find_grid(ks: KennelScreen) -> GridContainer:
	return _find_by_class(ks, GridContainer) as GridContainer

## Walk the KennelScreen to find the shared CoinReadout pill in the header (129, X-4).
func _find_coin_readout(ks: KennelScreen) -> CoinReadout:
	return _find_by_class(ks, CoinReadout) as CoinReadout

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

## The training-chrome node names checked by the task-090 show/hide pattern. Covers all 8 non-BRA
## nodes _set_training_hud_visible() toggles (`_bra_button` is asserted separately below) — incl.
## `_word_pop` + `_kennel_button`, so a regression that left either visible over the kennel fails.
const CHROME_NODES := ["_tell_marker", "_trainer_marker", "_readout", "_word_pop", "_learned_bar",
	"_coin_readout", "_tricks_button", "_kennel_button"]

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_scene_mounts_the_kennel_screen_hidden() -> void:
	_clear_save()
	var main := instantiate_main()
	var ks := _find_kennel(main)
	assert_true(ks != null, "the scene must mount a KennelScreen on the UI CanvasLayer")
	assert_false(ks.visible, "the kennel screen starts hidden — shown only when the player opens it")
	main.queue_free()
	_clear_save()

func test_render_builds_8_cells() -> void:
	## render(rows, balance) with the full 8-dog classify array must produce exactly 8
	## cell children in the GridContainer.
	_clear_save()
	var main := instantiate_main()
	var ks := _find_kennel(main)
	assert_true(ks != null, "need a KennelScreen to test render()")
	var rows := KennelDog.classify_kennel_dogs([KennelDog.STARTER_ID], KennelDog.STARTER_ID, 0)
	ks.render(rows, 0)
	var grid := _find_grid(ks)
	assert_true(grid != null, "the grid container must exist after render()")
	assert_eq(grid.get_child_count(), 8, "render() with 8 rows must build exactly 8 cell children")
	main.queue_free()
	_clear_save()

func test_coin_chip_reflects_balance() -> void:
	## The shared CoinReadout pill must reflect the supplied balance after render() (129, X-4).
	_clear_save()
	var main := instantiate_main()
	var ks := _find_kennel(main)
	assert_true(ks != null, "need a KennelScreen to test coin readout")
	var rows := KennelDog.classify_kennel_dogs([KennelDog.STARTER_ID], KennelDog.STARTER_ID, 42)
	ks.render(rows, 42)
	var readout := _find_coin_readout(ks)
	assert_true(readout != null, "the shared CoinReadout pill must exist in the header after render()")
	assert_eq(readout.balance(), 42, "the CoinReadout must reflect the supplied balance (42)")
	main.queue_free()
	_clear_save()

func test_cell_press_emits_dog_selected_with_id() -> void:
	## Pressing the first cell (Bella) must emit dog_selected("bella").
	## GDScript 4 lambdas capture outer locals by VALUE, so we use an Array as a
	## mutable capture box (arrays are objects, passed by reference) — the same idiom
	## as test_trick_store / test_breed_showcase tests that need to observe emitted values.
	_clear_save()
	var main := instantiate_main()
	var ks := _find_kennel(main)
	assert_true(ks != null, "need a KennelScreen to test cell press")
	var rows := KennelDog.classify_kennel_dogs([KennelDog.STARTER_ID], KennelDog.STARTER_ID, 0)
	ks.render(rows, 0)
	var grid := _find_grid(ks)
	assert_true(grid != null and grid.get_child_count() == 8, "grid must have 8 cells")
	# Capture signal via array (mutable reference box — GDScript lambdas capture locals by value).
	var captured: Array = []
	ks.dog_selected.connect(func(id: String): captured.append(id))
	# Drive the press directly via the public method that the cell button's signal calls.
	ks._on_cell_pressed("bella")
	assert_true(captured.size() == 1 and captured[0] == "bella",
		"pressing the first cell (Bella) must emit dog_selected('bella')")
	main.queue_free()
	_clear_save()

func test_open_kennel_hides_training_hud() -> void:
	## Opening the kennel must hide the training-HUD chrome so it doesn't ghost through the
	## kennel screen (task-090 pattern: _set_training_hud_visible(false) on open).
	_clear_save()
	var main := instantiate_main()
	assert_true(main._bra_button.visible, "BRA button visible during training (pre-condition)")
	main._open_kennel()
	for prop in CHROME_NODES:
		assert_false((main.get(prop) as CanvasItem).visible,
			"training chrome '%s' must be hidden while the kennel is open" % prop)
	main.queue_free()
	_clear_save()

func test_close_kennel_restores_training_hud() -> void:
	## Closing the kennel (signal closed or _close_kennel) must restore the training HUD.
	_clear_save()
	var main := instantiate_main()
	main._open_kennel()
	assert_false(main._bra_button.visible, "BRA hidden while kennel open (pre-condition)")
	main._close_kennel()
	assert_true(main._bra_button.visible, "BRA restored after kennel closes")
	for prop in CHROME_NODES:
		assert_true((main.get(prop) as CanvasItem).visible,
			"training chrome '%s' must be restored after kennel closes" % prop)
	main.queue_free()
	_clear_save()

# ---------------------------------------------------------------------------
# _cell_surface mapping — pure color selection based on ownership/secret state
# ---------------------------------------------------------------------------

func test_cell_surface_neutral_row_returns_warm_sand() -> void:
	## A neutral row (neither owned nor secret) must return the Warm Sand base color
	## (#F4EFE6), the DS constant C_MODAL_CREAM already defined in KennelScreen.
	_clear_save()
	var main := instantiate_main()
	var ks := _find_kennel(main)
	assert_true(ks != null, "need a KennelScreen to test _cell_surface()")
	# Build a neutral row (not owned, not secret) for a common dog.
	var rows := KennelDog.classify_kennel_dogs([], KennelDog.STARTER_ID, 0)
	var neutral_row: Dictionary = rows[1]  # Nova, a common EPIC dog (not owned, not secret)
	assert_false(neutral_row.owned, "test precondition: row must not be owned")
	assert_false(neutral_row.secret, "test precondition: row must not be secret")
	var surface := ks._cell_surface(neutral_row)
	assert_eq(surface, Color("f4efe6"), "neutral row must return Warm Sand #F4EFE6")
	main.queue_free()
	_clear_save()

func test_cell_surface_owned_row_returns_distinct_owned_wash() -> void:
	## An owned row (owned == true) must return a distinct color that is NOT the plain
	## Warm Sand. The owned wash is a faint green-warm tint over the sand.
	_clear_save()
	var main := instantiate_main()
	var ks := _find_kennel(main)
	assert_true(ks != null, "need a KennelScreen to test _cell_surface()")
	# Build rows where Bella (the starter) is owned.
	var rows := KennelDog.classify_kennel_dogs([KennelDog.STARTER_ID], KennelDog.STARTER_ID, 0)
	var owned_row: Dictionary = rows[0]  # Bella, marked as owned
	assert_true(owned_row.owned, "test precondition: Bella must be marked owned")
	assert_false(owned_row.secret, "test precondition: Bella must not be secret")
	var surface := ks._cell_surface(owned_row)
	var neutral_sand := Color("f4efe6")
	assert_ne(surface, neutral_sand, "owned row must return a color distinct from Warm Sand")
	main.queue_free()
	_clear_save()

func test_cell_surface_secret_row_returns_distinct_egg_wash() -> void:
	## A secret/easter-egg row (secret == true) must return a distinct color that is
	## NOT the plain Warm Sand and NOT the owned wash. The egg wash is a faint coral tint.
	_clear_save()
	var main := instantiate_main()
	var ks := _find_kennel(main)
	assert_true(ks != null, "need a KennelScreen to test _cell_surface()")
	# Build rows with the full 8-dog catalog. Trulte (index 7) has Rarity.SECRET.
	var rows := KennelDog.classify_kennel_dogs([], KennelDog.STARTER_ID, 0)
	var secret_row: Dictionary = rows[7]  # Trulte, the SECRET easter egg
	assert_false(secret_row.owned, "test precondition: Trulte must not be owned (she is free secret)")
	assert_true(secret_row.secret, "test precondition: Trulte must be marked secret")
	var surface := ks._cell_surface(secret_row)
	var neutral_sand := Color("f4efe6")
	# Build the owned row to compare against (so we verify secret is distinct from owned too).
	var owned_rows := KennelDog.classify_kennel_dogs([KennelDog.STARTER_ID], KennelDog.STARTER_ID, 0)
	var owned_surface := ks._cell_surface(owned_rows[0] as Dictionary)
	assert_ne(surface, neutral_sand, "secret row must return a color distinct from Warm Sand")
	assert_ne(surface, owned_surface, "secret row must return a color distinct from owned wash")
	main.queue_free()
	_clear_save()
