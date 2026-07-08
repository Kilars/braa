extends "res://tests/test_case.gd"
## The training-page top-left «Kennel» HUD nav pill (185, PO father-pass-58 X-6). It used to be
## pinned to a bare hard-coded 96 px, too narrow for the 6-char «Kennel» label at T_HEAD (Baloo 2
## bold 18) once the pill's internal side padding is subtracted — so Godot trimmed it to «Kennel.»
## with an overrun ellipsis (reads as a stray trailing dot on a primary nav control). Its sibling
## «Triks» pill had already been widened to 128 px for exactly this reason. The width is now a named
## KENNEL_BTN_WIDTH const, wide enough to hold «Kennel» with balanced side padding.
##
## Font-accurate width guard (like test_breed_personality's un-elided name check) — the real
## acceptance is "the label renders without an ellipsis", asserted against the measured glyph run
## rather than a char count, so it would have caught the original 96 px elision.

const MainScript := preload("res://scripts/main.gd")

## Side padding the pill must keep on each side of the label so «Kennel» reads centred, not edge-to-
## edge (which is what triggers the ellipsis). 15 px/side ≈ the balanced padding the PO asked for.
const SIDE_PADDING := 15.0

func _kennel_label_width() -> float:
	var f := DesignSystem.font_body_bold()
	return f.get_string_size("Kennel", HORIZONTAL_ALIGNMENT_LEFT, -1, DesignSystem.T_HEAD).x

func test_kennel_pill_holds_the_label_without_eliding() -> void:
	var label_w := _kennel_label_width()
	assert_true(MainScript.KENNEL_BTN_WIDTH >= label_w + 2.0 * SIDE_PADDING,
		"the «Kennel» pill (%.0f px) holds «Kennel» (%.0f px) plus balanced side padding — no ellipsis"
			% [MainScript.KENNEL_BTN_WIDTH, label_w])

func test_kennel_pill_is_wider_than_the_old_eliding_96px() -> void:
	# Regression guard: the whole point of 185 is that the pill is no longer the bare 96 px that
	# truncated «Kennel» to «Kennel.».
	assert_true(MainScript.KENNEL_BTN_WIDTH > 96.0,
		"the «Kennel» pill is wider than the old truncating 96 px (got %.0f)" % MainScript.KENNEL_BTN_WIDTH)

func test_kennel_pill_needs_no_glyph_room_so_narrower_than_triks() -> void:
	# «Kennel» has no leading hamburger glyph (that lives on the «Triks» pill), so it needs less width
	# than TRICKS_BTN_WIDTH — a named constant, not a copy of the Triks value.
	assert_true(MainScript.KENNEL_BTN_WIDTH < MainScript.TRICKS_BTN_WIDTH,
		"the glyph-less «Kennel» pill (%.0f) is narrower than the glyph-bearing «Triks» pill (%.0f)"
			% [MainScript.KENNEL_BTN_WIDTH, MainScript.TRICKS_BTN_WIDTH])
