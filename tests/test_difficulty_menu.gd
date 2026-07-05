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

# ---- 121 (P4-1/P4-3): difficulty rows show the reward/challenge trade inline ----

func test_difficulty_trade_label_normal_is_empty() -> void:
	# Normal mode (reward 1.0, window 1.0) is the baseline with no subtitle.
	var label := TrickMenu.difficulty_trade_label(1.0, 1.0)
	assert_eq(label, "", "Normal (1.0 reward, 1.0 window) returns an empty label (no subtitle)")

func test_difficulty_trade_label_hard_shows_reward_and_window() -> void:
	# Hard mode (reward 1.4, window 0.72) shows the trade: ×1.4 coins and a tightened window.
	var label := TrickMenu.difficulty_trade_label(1.4, 0.72)
	assert_false(label.is_empty(), "Hard mode has a non-empty label")
	assert_true(label.contains("×1.4"), "label contains the reward multiplier ×1.4")
	assert_true(label.contains("mynt"), "label contains 'mynt' (coins)")
	assert_true(label.contains("smalere"), "label contains a window-tightening phrase with 'smalere'")

func test_difficulty_trade_label_expert_shows_reward_without_trailing_zero() -> void:
	# Expert mode (reward 2.0, window 0.5) shows the trade with ×2 (not ×2.0) and a stronger window phrase.
	var label := TrickMenu.difficulty_trade_label(2.0, 0.5)
	assert_false(label.is_empty(), "Expert mode has a non-empty label")
	assert_true(label.contains("×2"), "label contains the reward multiplier ×2 (no trailing .0)")
	assert_false(label.contains("×2.0"), "label does NOT contain ×2.0 (trailing .0 is dropped)")
	assert_true(label.contains("mynt"), "label contains 'mynt' (coins)")
	assert_true(label.contains("smalere"), "label contains a window-tightening phrase with 'smalere'")

func test_classify_difficulty_rows_carry_scales() -> void:
	# The rows carry reward_scale and window_scale so the renderer can build the trade label.
	var rows := TrickMenu.classify_difficulty(Difficulty.catalog(), "normal")
	assert_eq(rows.size(), 3, "three difficulty rows (Normal/Hard/Expert)")
	# Normal row: reward_scale 1.0, window_scale 1.0
	var normal_row := rows[0] as Dictionary
	assert_eq(normal_row.reward_scale, 1.0, "Normal row has reward_scale 1.0")
	assert_eq(normal_row.window_scale, 1.0, "Normal row has window_scale 1.0")
	# Hard row: reward_scale 1.4, window_scale 0.72
	var hard_row := rows[1] as Dictionary
	assert_eq(hard_row.reward_scale, 1.4, "Hard row has reward_scale 1.4")
	assert_eq(hard_row.window_scale, 0.72, "Hard row has window_scale 0.72")
	# Expert row: reward_scale 2.0, window_scale 0.5
	var expert_row := rows[2] as Dictionary
	assert_eq(expert_row.reward_scale, 2.0, "Expert row has reward_scale 2.0")
	assert_eq(expert_row.window_scale, 0.5, "Expert row has window_scale 0.5")

func test_classify_difficulty_rows_retain_existing_keys() -> void:
	# The rows still carry id, name, active, selectable, locked (no regression).
	var rows := TrickMenu.classify_difficulty(Difficulty.catalog(), "hard")
	for r in rows:
		var row := r as Dictionary
		assert_true(row.has("id"), "each row has 'id'")
		assert_true(row.has("name"), "each row has 'name'")
		assert_true(row.has("active"), "each row has 'active'")
		assert_true(row.has("selectable"), "each row has 'selectable'")
		assert_true(row.has("locked"), "each row has 'locked'")
