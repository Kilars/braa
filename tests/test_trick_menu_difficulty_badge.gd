extends "res://tests/test_case.gd"
## Task 194 (PO father-pass-68, X-6/X-4): «Vanskelighet» was the only one of the four
## completion-menu selection sections whose *selectable* alternate rows carried NO right-side
## action badge — Hard/Ekspert on a normal dog showed their trade hint but nothing signalling
## they were tappable, while the parallel «Markørord» (WordState.UNLOCKED → «Bytt») and «Raser»
## (BreedState.OWNED → «Bytt») switch rows both mark selectability with a blue «Bytt». These pin
## the fix: a selectable (non-active, non-locked) difficulty row now shows «Bytt» in the SAME
## action-blue, while «Valgt»/«Låst»/no-badge cases are untouched.

func _row(active: bool, locked: bool) -> Dictionary:
	return {"active": active, "locked": locked, "selectable": not locked}

func test_switch_word_matches_the_other_sections() -> void:
	# One shared switch word across sections so they read as one system.
	assert_true(TrickMenu.DIFF_BADGE_SWITCH == "Bytt",
		"the difficulty switch badge is «Bytt»")
	assert_true(TrickMenu.DIFF_BADGE_SWITCH == TrickMenu.WORD_BADGE[TrickMenu.WordState.UNLOCKED],
		"difficulty switch badge matches the marker-word «Bytt»")
	assert_true(TrickMenu.DIFF_BADGE_SWITCH == TrickMenu.BREED_BADGE[TrickMenu.BreedState.OWNED],
		"difficulty switch badge matches the breed «Bytt»")

func test_selectable_non_active_row_shows_switch_badge() -> void:
	# The whole point: Hard/Ekspert on a normal dog now signal they're tappable.
	assert_true(TrickMenu.difficulty_badge(_row(false, false)) == TrickMenu.DIFF_BADGE_SWITCH,
		"a selectable non-active difficulty row shows «Bytt»")

func test_active_row_keeps_valgt() -> void:
	assert_true(TrickMenu.difficulty_badge(_row(true, false)) == TrickMenu.DIFF_BADGE_ACTIVE,
		"the selected mode keeps its «Valgt» current-state badge")

func test_locked_active_keeps_last_and_locked_others_stay_bare() -> void:
	# Special dog: the fixed mode shows «Låst»; the other (non-tappable) locked rows stay bare.
	assert_true(TrickMenu.difficulty_badge(_row(true, true)) == TrickMenu.DIFF_BADGE_LOCKED,
		"the fixed mode on a special dog keeps «Låst»")
	assert_true(TrickMenu.difficulty_badge(_row(false, true)) == "",
		"a non-active LOCKED row is not tappable → still no badge")

func test_switch_badge_draws_in_the_blue_action_ink() -> void:
	# «Bytt» must read as an action, in the SAME blue the word/breed switch rows use — NOT the
	# dark current-state ink «Valgt» uses.
	assert_true(TrickMenu.difficulty_badge_ink(_row(false, false)) == TrickMenu.BADGE_AVAILABLE,
		"the selectable-row «Bytt» draws in the action-blue BADGE_AVAILABLE")
	assert_true(TrickMenu.difficulty_badge_ink(_row(false, false)) != TrickMenu.BADGE_ACTIVE,
		"the «Bytt» action ink is distinct from the dark current-state «Valgt» ink")

func test_switch_badge_clears_aa_on_the_cream_row() -> void:
	# A selectable row sits on the CREAM fill (not the active wash). The blue «Bytt» must clear AA
	# there — same bar the other blue action badges already meet (BLUE_INK was chosen for it).
	var ratio := DesignSystem.wcag_contrast(TrickMenu.BADGE_AVAILABLE, DesignSystem.CREAM)
	assert_true(ratio >= 4.5,
		"the «Bytt» action-blue clears AA on the cream selectable row (got %.2f:1)" % ratio)
