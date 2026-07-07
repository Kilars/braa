extends "res://tests/test_case.gd"
## Task 168 (PO father-pass-33, X-4): after 167 gave all four completion-menu selection sections
## (tricks·breeds·words·difficulty) the SAME pale-blue active-row wash, the active-row *badge ink*
## was the last cross-section inconsistency — the active TRICK badge «Trener nå» drew in the dark
## "current-state" ink (ROW_ACTIVE_INK #141c26, the kennel 151 / menu 152 treatment) while the
## active BREED «Aktiv», active WORD «Aktiv» and SELECTED difficulty «Valgt» badges still drew in
## the SAME action-blue (BLUE_INK) as the tappable «Tilgjengelig»/«Bytt» status badges — so on three
## of four sections the "you are here" state marker read identically to an "available/actionable" one.
## The fix routes every active-state badge through one shared BADGE_ACTIVE token = ROW_ACTIVE_INK, so
## «Aktiv»/«Aktiv»/«Valgt»/«Trener nå» all read as one calm dark current-state marker, distinct from
## the blue available/actionable badges. These pin that unification.

func test_active_badge_is_the_shared_dark_current_state_ink() -> void:
	# The one active-state badge token IS the dark current-state ink used everywhere (kennel 151 /
	# menu trick 152) — not the action-blue.
	assert_true(TrickMenu.BADGE_ACTIVE == TrickMenu.ROW_ACTIVE_INK,
		"BADGE_ACTIVE must be the shared dark current-state ink ROW_ACTIVE_INK")

func test_active_badge_distinct_from_the_available_action_badges() -> void:
	# The whole point: the active-state badge must NOT be the same colour as the tappable
	# available/actionable badges (BADGE_AVAILABLE / BADGE_LEARNED are the action-blue BLUE_INK).
	assert_true(TrickMenu.BADGE_ACTIVE != TrickMenu.BADGE_AVAILABLE,
		"active-state badge must be distinct from the available/actionable badge")
	assert_true(TrickMenu.BADGE_ACTIVE != TrickMenu.BADGE_LEARNED,
		"active-state badge must be distinct from the learned/available blue badge")

func test_active_badge_reads_darker_than_the_action_blue() -> void:
	# "You are here" should read stronger/darker than an available action. Compare relative
	# luminance via the DS contrast helper against a common light fill (the wash it sits on).
	var active_ratio := DesignSystem.wcag_contrast(TrickMenu.BADGE_ACTIVE, TrickMenu.ROW_BG_ACTIVE)
	var blue_ratio := DesignSystem.wcag_contrast(TrickMenu.BADGE_AVAILABLE, TrickMenu.ROW_BG_ACTIVE)
	assert_true(active_ratio > blue_ratio,
		"dark active-state badge reads stronger than the blue action badge on the wash (%.2f vs %.2f)"
			% [active_ratio, blue_ratio])

func test_active_badge_clears_aa_on_the_active_row_wash() -> void:
	# The active badge sits on the pale-blue active-row wash (167). It must clear WCAG AA there —
	# the dark ink pairing the trick row already ships (~14.7:1).
	var ratio := DesignSystem.wcag_contrast(TrickMenu.BADGE_ACTIVE, TrickMenu.ROW_BG_ACTIVE)
	assert_true(ratio >= 4.5,
		"active-state badge clears AA on the active-row wash (got %.2f:1)" % ratio)
