extends "res://tests/test_case.gd"
## TDD for the design system (task 096, Phase 6 foundation). DesignSystem is a pure-data
## token vault holding the Bra Design System's palette, spacing, radius, type scale, real fonts,
## and StyleBox builders. Every test covers a behavior from §B of the task spec.

func test_palette_blue_constant_equals_spec_hex() -> void:
	assert_eq(DesignSystem.BLUE, Color("4a90e2"), "BLUE == spec hex #4a90e2")

func test_palette_blue_dark_constant_equals_spec_hex() -> void:
	assert_eq(DesignSystem.BLUE_DARK, Color("2f6fbf"), "BLUE_DARK == spec hex #2f6fbf")

func test_palette_blue_light_constant_equals_spec_hex() -> void:
	assert_eq(DesignSystem.BLUE_LIGHT, Color("6fb6ff"), "BLUE_LIGHT == spec hex #6fb6ff")

func test_palette_gold_constant_equals_spec_hex() -> void:
	assert_eq(DesignSystem.GOLD, Color("f5b841"), "GOLD == spec hex #f5b841")

func test_palette_gold_dark_constant_equals_spec_hex() -> void:
	assert_eq(DesignSystem.GOLD_DARK, Color("d99a2b"), "GOLD_DARK == spec hex #d99a2b")

func test_palette_gold_light_constant_equals_spec_hex() -> void:
	assert_eq(DesignSystem.GOLD_LIGHT, Color("ffdd8c"), "GOLD_LIGHT == spec hex #ffdd8c")

func test_palette_slate_constant_equals_spec_hex() -> void:
	assert_eq(DesignSystem.SLATE, Color("5a6b7d"), "SLATE == spec hex #5a6b7d")

func test_palette_slate_soft_constant_equals_spec_hex() -> void:
	assert_eq(DesignSystem.SLATE_SOFT, Color("8a97a4"), "SLATE_SOFT == spec hex #8a97a4")

func test_palette_ink_constant_equals_spec_hex() -> void:
	assert_eq(DesignSystem.INK, Color("1e2a3a"), "INK == spec hex #1e2a3a")

func test_palette_paper_constant_equals_spec_hex() -> void:
	assert_eq(DesignSystem.PAPER, Color("fbfbf7"), "PAPER == spec hex #fbfbf7")

func test_palette_cream_constant_equals_spec_hex() -> void:
	assert_eq(DesignSystem.CREAM, Color("f4efe6"), "CREAM == spec hex #f4efe6")

func test_palette_border_constant_equals_spec_hex() -> void:
	assert_eq(DesignSystem.BORDER, Color("e9e2d5"), "BORDER == spec hex #e9e2d5")

func test_palette_danger_constant_equals_spec_hex() -> void:
	assert_eq(DesignSystem.DANGER, Color("ff7a85"), "DANGER == spec hex #ff7a85")

func test_space_zero_returns_four() -> void:
	assert_eq(DesignSystem.space(0), 4, "space(0) == 4")

func test_space_one_returns_eight() -> void:
	assert_eq(DesignSystem.space(1), 8, "space(1) == 8")

func test_space_two_returns_twelve() -> void:
	assert_eq(DesignSystem.space(2), 12, "space(2) == 12")

func test_space_three_returns_sixteen() -> void:
	assert_eq(DesignSystem.space(3), 16, "space(3) == 16")

func test_space_four_returns_twenty_four() -> void:
	assert_eq(DesignSystem.space(4), 24, "space(4) == 24")

func test_space_ninety_nine_clamps_to_last_step() -> void:
	assert_eq(DesignSystem.space(99), 24, "space(99) clamps to last step == 24")

func test_space_negative_one_clamps_to_first_step() -> void:
	assert_eq(DesignSystem.space(-1), 4, "space(-1) clamps to first step == 4")

func test_space_negative_ninety_nine_clamps_to_first_step() -> void:
	assert_eq(DesignSystem.space(-99), 4, "space(-99) clamps to first step == 4")

func test_radius_sm_constant_equals_eight() -> void:
	assert_eq(DesignSystem.R_SM, 8, "R_SM == 8")

func test_radius_md_constant_equals_fourteen() -> void:
	assert_eq(DesignSystem.R_MD, 14, "R_MD == 14")

func test_radius_lg_constant_equals_eighteen() -> void:
	assert_eq(DesignSystem.R_LG, 18, "R_LG == 18")

func test_radius_xl_constant_equals_twenty_two() -> void:
	assert_eq(DesignSystem.R_XL, 22, "R_XL == 22")

func test_radius_pill_constant_equals_nine_thousand_nine_hundred_ninety_nine() -> void:
	assert_eq(DesignSystem.R_PILL, 9999, "R_PILL == 9999")

func test_type_display_constant_equals_fifty_two() -> void:
	assert_eq(DesignSystem.T_DISPLAY, 52, "T_DISPLAY == 52")

func test_type_title_constant_equals_twenty_six() -> void:
	assert_eq(DesignSystem.T_TITLE, 26, "T_TITLE == 26")

func test_type_head_constant_equals_eighteen() -> void:
	assert_eq(DesignSystem.T_HEAD, 18, "T_HEAD == 18")

func test_type_body_constant_equals_fifteen() -> void:
	assert_eq(DesignSystem.T_BODY, 15, "T_BODY == 15")

func test_type_small_constant_equals_thirteen() -> void:
	assert_eq(DesignSystem.T_SMALL, 13, "T_SMALL == 13")

func test_shadow_card_color_is_correct() -> void:
	assert_eq(DesignSystem.SHADOW_CARD_COLOR, Color(0.114, 0.165, 0.227, 0.08), "SHADOW_CARD_COLOR == rgba(29,42,58,.08)")

func test_shadow_card_size_is_twenty() -> void:
	assert_eq(DesignSystem.SHADOW_CARD_SIZE, 20, "SHADOW_CARD_SIZE == 20")

func test_shadow_card_offset_is_zero_six() -> void:
	assert_eq(DesignSystem.SHADOW_CARD_OFFSET, Vector2(0, 6), "SHADOW_CARD_OFFSET == Vector2(0, 6)")

func test_font_display_path_exists() -> void:
	assert_true(ResourceLoader.exists(DesignSystem.F_DISPLAY), "F_DISPLAY path exists (Baloo2-Variable.ttf)")

func test_font_body_path_exists() -> void:
	assert_true(ResourceLoader.exists(DesignSystem.F_BODY), "F_BODY path exists (Nunito-Variable.ttf)")

func test_font_mono_path_exists() -> void:
	assert_true(ResourceLoader.exists(DesignSystem.F_MONO), "F_MONO path exists (JetBrainsMono-Medium.ttf)")

func test_font_display_returns_non_null_font() -> void:
	var f = DesignSystem.font_display()
	assert_true(f != null, "font_display() returns non-null")
	assert_true(f is Font, "font_display() returns a Font")

func test_font_body_returns_non_null_font() -> void:
	var f = DesignSystem.font_body()
	assert_true(f != null, "font_body() returns non-null")
	assert_true(f is Font, "font_body() returns a Font")

func test_font_body_bold_returns_non_null_font() -> void:
	var f = DesignSystem.font_body_bold()
	assert_true(f != null, "font_body_bold() returns non-null")
	assert_true(f is Font, "font_body_bold() returns a Font")

func test_font_mono_returns_non_null_font() -> void:
	var f = DesignSystem.font_mono()
	assert_true(f != null, "font_mono() returns non-null")
	assert_true(f is Font, "font_mono() returns a Font")

func test_theme_returns_non_null_theme() -> void:
	var t = DesignSystem.theme()
	assert_true(t != null, "theme() returns non-null")
	assert_true(t is Theme, "theme() returns a Theme")

func test_theme_default_font_size_equals_body_size() -> void:
	var t = DesignSystem.theme()
	assert_eq(t.default_font_size, DesignSystem.T_BODY, "theme default font size == T_BODY (15)")

func test_theme_default_font_is_not_null() -> void:
	var t = DesignSystem.theme()
	assert_true(t.default_font != null, "theme default font is not null")

func test_panel_returns_stylebox_flat() -> void:
	var sb = DesignSystem.panel()
	assert_true(sb != null, "panel() returns non-null")
	assert_true(sb is StyleBoxFlat, "panel() returns a StyleBoxFlat")

func test_panel_has_correct_corner_radius_lg() -> void:
	var sb = DesignSystem.panel()
	assert_eq(sb.corner_radius_top_left, DesignSystem.R_LG, "panel() corner_radius_top_left == R_LG (18)")
	assert_eq(sb.corner_radius_top_right, DesignSystem.R_LG, "panel() corner_radius_top_right == R_LG (18)")
	assert_eq(sb.corner_radius_bottom_left, DesignSystem.R_LG, "panel() corner_radius_bottom_left == R_LG (18)")
	assert_eq(sb.corner_radius_bottom_right, DesignSystem.R_LG, "panel() corner_radius_bottom_right == R_LG (18)")

func test_panel_default_bg_color_is_paper() -> void:
	var sb = DesignSystem.panel()
	assert_eq(sb.bg_color, DesignSystem.PAPER, "panel() default bg_color == PAPER")

func test_pill_returns_stylebox_flat() -> void:
	var sb = DesignSystem.pill(DesignSystem.BLUE, DesignSystem.R_XL)
	assert_true(sb != null, "pill() returns non-null")
	assert_true(sb is StyleBoxFlat, "pill() returns a StyleBoxFlat")

func test_pill_sets_bg_color_to_argument() -> void:
	var sb = DesignSystem.pill(DesignSystem.BLUE, DesignSystem.R_XL)
	assert_eq(sb.bg_color, DesignSystem.BLUE, "pill(BLUE, ...) bg_color == BLUE")

func test_pill_sets_corner_radius_to_argument() -> void:
	var sb = DesignSystem.pill(DesignSystem.BLUE, DesignSystem.R_XL)
	assert_eq(sb.corner_radius_top_left, DesignSystem.R_XL, "pill(BLUE, R_XL) corner_radius_top_left == R_XL (22)")
	assert_eq(sb.corner_radius_top_right, DesignSystem.R_XL, "pill(BLUE, R_XL) corner_radius_top_right == R_XL (22)")
	assert_eq(sb.corner_radius_bottom_left, DesignSystem.R_XL, "pill(BLUE, R_XL) corner_radius_bottom_left == R_XL (22)")
	assert_eq(sb.corner_radius_bottom_right, DesignSystem.R_XL, "pill(BLUE, R_XL) corner_radius_bottom_right == R_XL (22)")

func test_pill_with_different_color_and_radius() -> void:
	var sb = DesignSystem.pill(DesignSystem.GOLD, DesignSystem.R_SM)
	assert_eq(sb.bg_color, DesignSystem.GOLD, "pill(GOLD, R_SM) bg_color == GOLD")
	assert_eq(sb.corner_radius_top_left, DesignSystem.R_SM, "pill(GOLD, R_SM) corner_radius == R_SM (8)")

func test_pill_default_radius_is_pill() -> void:
	var sb = DesignSystem.pill(DesignSystem.DANGER)
	assert_eq(sb.corner_radius_top_left, DesignSystem.R_PILL, "pill(DANGER) default radius == R_PILL (9999)")

# Primary-CTA gradient WCAG-AA contrast (153, X-6). The BRA button + the completion-menu
# «Fortsett treningen» primary both bake through gradient_pill with the GRAD_PILL_* palette
# and draw a WHITE label. The label was ~2.7:1 on the old too-light gradient (top ran
# lighter than BLUE itself). Pin: the LIGHTEST face colour the white label can touch
# (GRAD_PILL_TOP) still clears AA (4.5:1), so the label is AA-legible everywhere on the face.

func test_wcag_contrast_white_on_black_is_max() -> void:
	assert_true(is_equal_approx(DesignSystem.wcag_contrast(Color.WHITE, Color.BLACK), 21.0),
		"wcag_contrast(white, black) == 21:1 (the canonical AA helper is correct)")

func test_primary_cta_gradient_top_clears_wcag_aa_for_white_label() -> void:
	var ratio := DesignSystem.wcag_contrast(Color.WHITE, DesignSystem.GRAD_PILL_TOP)
	assert_true(ratio >= 4.5,
		"white CTA label on the LIGHTEST gradient face (GRAD_PILL_TOP) clears WCAG AA 4.5:1 (got %.2f:1)" % ratio)

func test_primary_cta_gradient_bottom_clears_wcag_aa_for_white_label() -> void:
	var ratio := DesignSystem.wcag_contrast(Color.WHITE, DesignSystem.GRAD_PILL_BOT)
	assert_true(ratio >= 4.5,
		"white CTA label on the gradient bottom (GRAD_PILL_BOT) clears WCAG AA 4.5:1 (got %.2f:1)" % ratio)

func test_primary_cta_gradient_still_darkens_top_to_bottom() -> void:
	# Identity/depth kept: the face is still a bright-top → deep-bottom gradient, not flat.
	var lum_top := DesignSystem._rel_luminance(DesignSystem.GRAD_PILL_TOP)
	var lum_bot := DesignSystem._rel_luminance(DesignSystem.GRAD_PILL_BOT)
	assert_true(lum_bot < lum_top, "the CTA gradient still darkens top→bottom (3D depth preserved)")

func test_bra_button_shares_the_design_system_cta_palette() -> void:
	# The BRA button and the menu CTA are ONE component — main.gd's BRA_PILL_* must be the
	# SAME palette as DesignSystem.GRAD_PILL_*, so the AA fix can never drift between them.
	var main_script := load("res://scripts/main.gd")
	assert_eq(main_script.BRA_PILL_TOP, DesignSystem.GRAD_PILL_TOP, "BRA_PILL_TOP == DesignSystem.GRAD_PILL_TOP")
	assert_eq(main_script.BRA_PILL_BOT, DesignSystem.GRAD_PILL_BOT, "BRA_PILL_BOT == DesignSystem.GRAD_PILL_BOT")
	assert_eq(main_script.BRA_PILL_LIP, DesignSystem.GRAD_PILL_LIP, "BRA_PILL_LIP == DesignSystem.GRAD_PILL_LIP")

# BLUE_INK — AA-legible blue text on light surfaces (154, X-6). The DS BLUE token (#4a90e2) is a
# fill/identity accent; on the CREAM/PAPER menu surfaces it is only ~2.9-3.3:1, failing AA for the
# menu's blue-on-light TEXT. BLUE_INK is the deeper blue that clears 4.5:1 on both CREAM and PAPER,
# so every blue text label in the completion menu is legible while staying clearly blue.
# NOTE: BLUE_DARK (#2f6fbf) is only 4.42:1 on CREAM — UNDER the bar — so it cannot serve this role.

func test_blue_ink_clears_wcag_aa_on_cream() -> void:
	var ratio := DesignSystem.wcag_contrast(DesignSystem.BLUE_INK, DesignSystem.CREAM)
	assert_true(ratio >= 4.5, "BLUE_INK on CREAM clears WCAG AA 4.5:1 (got %.2f:1)" % ratio)

func test_blue_ink_clears_wcag_aa_on_paper() -> void:
	var ratio := DesignSystem.wcag_contrast(DesignSystem.BLUE_INK, DesignSystem.PAPER)
	assert_true(ratio >= 4.5, "BLUE_INK on PAPER clears WCAG AA 4.5:1 (got %.2f:1)" % ratio)

func test_blue_token_on_cream_is_the_failing_baseline() -> void:
	# The bug 154 fixes: the plain BLUE accent on the menu's CREAM/PAPER fills fails AA.
	assert_true(DesignSystem.wcag_contrast(DesignSystem.BLUE, DesignSystem.CREAM) < 4.5,
		"BLUE-on-CREAM is the sub-AA baseline the menu shipped")
	assert_true(DesignSystem.wcag_contrast(DesignSystem.BLUE_DARK, DesignSystem.CREAM) < 4.5,
		"even BLUE_DARK on CREAM is under the bar (4.42:1) — why BLUE_INK is needed")

func test_blue_ink_is_still_recognisably_blue() -> void:
	# Identity kept: BLUE_INK's blue channel dominates and it stays in the BLUE family.
	assert_true(DesignSystem.BLUE_INK.b > DesignSystem.BLUE_INK.r, "BLUE_INK is blue-dominant (b > r)")
	assert_true(DesignSystem.BLUE_INK.b > DesignSystem.BLUE_INK.g, "BLUE_INK is blue-dominant (b > g)")
