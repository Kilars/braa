extends "res://tests/test_case.gd"
## Task 188 (PO father-pass-62, X-6): the kennel inspect-modal stat meters (Læreevne/Energi/
## Mot/Fokus) draw 5 segment pips each — filled = DS blue, empty = a track pip. The empty pip
## shipped at C_PIP_EMPTY = #dfe5ea, only ~1.22:1 against the C_MODAL_SURFACE card, so a 4/5
## read almost identically to a 5/5 (the empty slot disappeared). These assert the empty pip is a
## clearly-present-but-unfilled track (≥1.6:1 on the card, matching the learned-bar-rail intent
## from 145/179) while staying obviously lighter/greyer than the saturated DS-blue filled pip so
## the meter still reads its value at a glance.

const FLOOR := 1.6   ## the father's ≥~1.6:1 legibility target for the empty segment on the card

func test_empty_pip_clears_the_track_floor_on_the_card() -> void:
	var ratio := KennelScreen.wcag_contrast(KennelScreen.C_PIP_EMPTY, KennelScreen.C_MODAL_SURFACE)
	assert_true(ratio >= FLOOR,
		"empty stat pip must read as a present track ≥%.1f:1 on the card (got %.2f)" % [FLOOR, ratio])

func test_ghost_pip_is_the_failing_baseline() -> void:
	# The invisible #dfe5ea the directive flagged — under 1.3:1 against the card.
	var ghost := Color("dfe5ea")
	assert_true(KennelScreen.wcag_contrast(ghost, KennelScreen.C_MODAL_SURFACE) < 1.3,
		"the shipped ghost empty pip is the sub-1.3:1 baseline the fix must beat")

func test_empty_pip_stays_lighter_than_the_filled_blue() -> void:
	# The meter reads by value only if filled (saturated DS blue) is clearly darker/stronger than
	# the light empty track — never the reverse, or a 4/5 could read as brighter than a 5/5.
	var empty_lum := KennelScreen._rel_luminance(KennelScreen.C_PIP_EMPTY)
	var filled_lum := KennelScreen._rel_luminance(KennelScreen.C_PIP_FILLED)
	assert_true(empty_lum > filled_lum + 0.15,
		"empty track pip must stay clearly lighter than the filled blue pip (empty %.3f vs filled %.3f)"
			% [empty_lum, filled_lum])

func test_wcag_contrast_symmetric() -> void:
	var ab := KennelScreen.wcag_contrast(KennelScreen.C_PIP_EMPTY, KennelScreen.C_MODAL_SURFACE)
	var ba := KennelScreen.wcag_contrast(KennelScreen.C_MODAL_SURFACE, KennelScreen.C_PIP_EMPTY)
	assert_true(abs(ab - ba) < 0.001, "wcag_contrast is order-independent")
