extends "res://tests/test_case.gd"

# Task 193 (PO father-pass-67, X-6/X-4): the completion menu's three peer selection-section headings
# — «Raser» / «Markørord» / «Vanskelighet» — must render as ONE system, subordinate to the «Triks»
# panel title. Before 193, «Markørord» drew in f_display (Baloo-2) at TITLE_SIZE=26 with a unique
# divider rule — the exact font+size of the panel title — while its siblings drew in f_bold (Nunito)
# at BADGE_SIZE=18 with no divider. 193 demotes «Markørord» to the shared subheading treatment and
# routes all three through one _draw_subheading helper so they can't diverge again.

func test_word_subheading_band_matches_its_peers() -> void:
	# The «Markørord» band was 38px tall to seat the Baloo-2 display heading; demoted to the 30px
	# sibling band. All three peer section header bands must now be equal height.
	assert_eq(TrickMenu.WORD_HEADER_H, TrickMenu.BREED_HEADER_H,
		"«Markørord» band matches «Raser» band (no taller Baloo display band)")
	assert_eq(TrickMenu.WORD_HEADER_H, TrickMenu.DIFFICULTY_HEADER_H,
		"«Markørord» band matches «Vanskelighet» band")

func test_shared_subhead_size_is_demoted_below_the_panel_title() -> void:
	# The one shared subheading size all three sections draw at — the sub-heading scale (18), NOT the
	# panel-title scale (26). This is the crux of the mismatch the PO caught.
	assert_eq(TrickMenu.SUBHEAD_SIZE, TrickMenu.BADGE_SIZE,
		"the shared section-subheading size is the 18px sub-heading scale")
	assert_true(TrickMenu.SUBHEAD_SIZE != TrickMenu.TITLE_SIZE,
		"a mid-card subheading is never the 26px panel-title size")

func test_subhead_font_is_body_bold_not_the_display_face() -> void:
	# The shared subheading font is the Nunito body-bold face the siblings already used — NOT the
	# Baloo-2 display face «Markørord» wrongly borrowed from the panel title.
	assert_eq(TrickMenu.subhead_font(), DesignSystem.font_body_bold(),
		"section subheadings draw in the Nunito body-bold face")
	assert_true(TrickMenu.subhead_font() != DesignSystem.font_display(),
		"section subheadings do NOT draw in the Baloo-2 display face (the panel-title font)")

func test_section_subhead_colours_are_uniform_and_aa() -> void:
	# All three subheadings share one SLATE ink (186 AA on PAPER) — a regression guard so a future
	# change can't recolour one section out of the system.
	assert_eq(TrickMenu.WORD_SUBHEAD, TrickMenu.BREED_SUBHEAD,
		"«Markørord» ink matches «Raser» ink")
	assert_eq(TrickMenu.WORD_SUBHEAD, TrickMenu.DIFF_SUBHEAD,
		"«Markørord» ink matches «Vanskelighet» ink")
	assert_true(DesignSystem.wcag_contrast(TrickMenu.WORD_SUBHEAD, TrickMenu.PANEL_BG) >= 4.5,
		"the shared subheading ink stays AA-clean on the PAPER card (186)")
