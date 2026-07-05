extends "res://tests/test_case.gd"
## The difficulty selector section of the completion menu (118, P4-1 "for normal dogs I want to be
## able to select difficulty"). TrickMenu.classify_difficulty is the pure, render-free classify the
## same dumb-renderer split the Breeds / Marker-words sections use: main feeds the catalog + the active
## mode id, this returns one row per mode with the active one flagged. These pin the classify order +
## the active flag render-free (no framebuffer). The routing INTO main (tap → _on_difficulty_chosen →
## re-apply levers → persist) is proven in test_difficulty_wiring.gd.

func test_classify_difficulty_one_row_per_mode_in_catalog_order() -> void:
	var rows := TrickMenu.classify_difficulty(Difficulty.catalog(), "normal")
	assert_eq(rows.size(), 3, "one row per shipped mode (Normal/Hard/Expert)")
	assert_eq(rows[0].id, "normal", "row order follows the catalog: Normal first")
	assert_eq(rows[1].id, "hard", "Hard second")
	assert_eq(rows[2].id, "expert", "Expert third")
	assert_eq(rows[0].name, "Normal", "the row carries the display name")

func test_classify_difficulty_flags_exactly_the_active_mode() -> void:
	var rows := TrickMenu.classify_difficulty(Difficulty.catalog(), "hard")
	assert_false(rows[0].active, "Normal is not the active mode")
	assert_true(rows[1].active, "Hard is flagged active")
	assert_false(rows[2].active, "Expert is not the active mode")

func test_classify_difficulty_unknown_active_flags_no_row() -> void:
	# A corrupt / legacy active id flags nothing active — a safe fallback, never a wrong highlight.
	var rows := TrickMenu.classify_difficulty(Difficulty.catalog(), "ghost")
	for r in rows:
		assert_false(r.active, "an unknown active id flags no row active (safe fallback)")

func test_classify_difficulty_rows_selectable_when_unlocked() -> void:
	# 118: for a normal dog the selector is free — every mode row is selectable (the player can switch).
	var rows := TrickMenu.classify_difficulty(Difficulty.catalog(), "normal")
	for r in rows:
		assert_true(TrickMenu.is_difficulty_selectable(r),
			"an unlocked difficulty row is selectable (the player can pick it)")

# ---- 119 (P4-1): the locked variant — special dogs fix the mode, every row non-selectable ----

func test_classify_difficulty_locked_flags_the_locked_mode_active() -> void:
	# On a special dog the fixed mode is flagged active (not the free active_id), and every row is
	# non-selectable — the section stays visible so the player sees WHY difficulty is fixed.
	var rows := TrickMenu.classify_difficulty(Difficulty.catalog(), "normal", true, "hard")
	assert_false(rows[0].active, "Normal is not the fixed mode")
	assert_true(rows[1].active, "Hard (the locked mode) is flagged active regardless of active_id")
	assert_false(rows[2].active, "Expert is not the fixed mode")

func test_classify_difficulty_locked_rows_are_all_non_selectable() -> void:
	var rows := TrickMenu.classify_difficulty(Difficulty.catalog(), "normal", true, "hard")
	for r in rows:
		assert_false(TrickMenu.is_difficulty_selectable(r),
			"every difficulty row is non-selectable while a special dog locks the mode")
		assert_true(r.locked, "each row carries the locked flag so the renderer shows the Låst read")
