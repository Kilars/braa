extends "res://tests/test_case.gd"
## Task 170 (PO father-pass-35, X-4): the last un-unified piece of the 167/168 active-row arc.
## 167 gave all four completion-menu selection sections (tricks·breeds·words·difficulty) the SAME
## pale-blue active-row wash; 168 gave the trailing active-state *badge* the SAME dark current-state
## ink (ROW_ACTIVE_INK #141c26). But the active-row *primary NAME* was still styled two ways: the
## active TRICK «Sitt» drew in ROW_ACTIVE_INK while the active BREED/WORD/difficulty names drew in the
## action-blue (BLUE_INK) — so on the same card the active trick titled itself dark and the active
## breed titled itself blue. The fix repoints BREED_NAME_ACTIVE / WORD_NAME_ACTIVE / DIFF_NAME_ACTIVE
## onto ROW_ACTIVE_INK so all four active rows render dark name + dark badge identically. These pin it.

func test_active_names_are_the_shared_dark_current_state_ink() -> void:
	# All three active-row NAME tokens are the dark current-state ink — the exact ink the active
	# trick name already draws in (see _draw_row: State.ACTIVE → ROW_ACTIVE_INK).
	assert_true(TrickMenu.BREED_NAME_ACTIVE == TrickMenu.ROW_ACTIVE_INK,
		"BREED_NAME_ACTIVE must be the shared dark current-state ink ROW_ACTIVE_INK")
	assert_true(TrickMenu.WORD_NAME_ACTIVE == TrickMenu.ROW_ACTIVE_INK,
		"WORD_NAME_ACTIVE must be the shared dark current-state ink ROW_ACTIVE_INK")
	assert_true(TrickMenu.DIFF_NAME_ACTIVE == TrickMenu.ROW_ACTIVE_INK,
		"DIFF_NAME_ACTIVE must be the shared dark current-state ink ROW_ACTIVE_INK")

func test_active_name_matches_the_active_badge_ink() -> void:
	# Name + badge on an active row now read as one calm dark current-state marker (168 badge + 170 name).
	assert_true(TrickMenu.BREED_NAME_ACTIVE == TrickMenu.BADGE_ACTIVE,
		"active breed name and active badge must share the one dark current-state ink")
	assert_true(TrickMenu.WORD_NAME_ACTIVE == TrickMenu.BADGE_ACTIVE,
		"active word name and active badge must share the one dark current-state ink")
	assert_true(TrickMenu.DIFF_NAME_ACTIVE == TrickMenu.BADGE_ACTIVE,
		"active difficulty name and active badge must share the one dark current-state ink")

func test_active_names_distinct_from_the_non_active_blue() -> void:
	# The whole point: the active-row name must no longer read as the action-blue the tappable
	# non-active names use (BREED_NAME_OWNED/BUYABLE etc. stay SLATE, learned rows stay BLUE_INK).
	assert_true(TrickMenu.BREED_NAME_ACTIVE != DesignSystem.BLUE_INK,
		"active breed name must not be the action-blue anymore")
	assert_true(TrickMenu.WORD_NAME_ACTIVE != DesignSystem.BLUE_INK,
		"active word name must not be the action-blue anymore")
	assert_true(TrickMenu.DIFF_NAME_ACTIVE != DesignSystem.BLUE_INK,
		"active difficulty name must not be the action-blue anymore")

func test_active_names_clear_aa_on_the_active_row_wash() -> void:
	# The active name sits on the pale-blue active-row wash (167). Dark ink there reads ~14:1.
	for tok in [TrickMenu.BREED_NAME_ACTIVE, TrickMenu.WORD_NAME_ACTIVE, TrickMenu.DIFF_NAME_ACTIVE]:
		var ratio := DesignSystem.wcag_contrast(tok, TrickMenu.ROW_BG_ACTIVE)
		assert_true(ratio >= 4.5,
			"active-row name clears AA on the active-row wash (got %.2f:1)" % ratio)
