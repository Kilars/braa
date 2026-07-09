extends "res://tests/test_case.gd"
## Task 151 (PO father-pass-15, X-6): the owned-dog status controls must clear WCAG AA (4.5:1).
## The «Trener nå» active pill shipped green-on-green (label C_STATUS_OWNED over the same green at
## 14% = 1.39:1) and the «Tren med [navn]» switch button shipped white-on-full-green (~2.49:1) —
## both failing. The fix keeps the surfaces and switches the label ink to the shared dark
## C_TAG_INK; these assert the ink clears AA on both and pin the failing baselines.

func test_tag_ink_clears_aa_on_active_pill_fill() -> void:
	var fill := KennelScreen.active_state_fill()
	var ratio := KennelScreen.wcag_contrast(KennelScreen.C_TAG_INK, fill)
	assert_true(ratio >= 4.5,
		"active-pill ink must clear AA 4.5:1 on the owned wash (got %.2f)" % ratio)

func test_tag_ink_clears_aa_on_switch_button_green() -> void:
	var ratio := KennelScreen.wcag_contrast(KennelScreen.C_TAG_INK, KennelScreen.C_STATUS_OWNED)
	assert_true(ratio >= 4.5,
		"switch-button ink must clear AA 4.5:1 on the owned green (got %.2f)" % ratio)

func test_green_on_green_is_the_failing_baseline() -> void:
	var fill := KennelScreen.active_state_fill()
	assert_true(KennelScreen.wcag_contrast(KennelScreen.C_STATUS_OWNED, fill) < 3.0,
		"green-label-on-green-wash is the sub-3:1 baseline the pill shipped")
	assert_true(KennelScreen.wcag_contrast(Color.WHITE, KennelScreen.C_STATUS_OWNED) < 3.0,
		"white-on-full-green is the sub-3:1 switch-button baseline")

func test_active_state_fill_matches_po_sampled_composite() -> void:
	# PO father-pass-15 sampled the rendered pill fill at (228,242,225): C_STATUS_OWNED at 14%
	# over the C_MODAL_SURFACE card. The opaque helper must reproduce it (±1/255).
	var fill := KennelScreen.active_state_fill()
	assert_true(abs(fill.r * 255.0 - 228.0) <= 1.5, "fill R ~228 (got %.1f)" % (fill.r * 255.0))
	assert_true(abs(fill.g * 255.0 - 241.0) <= 1.5, "fill G ~241 (got %.1f)" % (fill.g * 255.0))
	assert_true(abs(fill.b * 255.0 - 225.0) <= 1.5, "fill B ~225 (got %.1f)" % (fill.b * 255.0))

## Task 205 (PO father-pass-82, X-6): task 151 set the dark C_TAG_INK token (analytic ~14.8:1) but
## never added an outline_size override to the disabled Button, so it hit the same thin-stroke
## render-wash the 200→204 arc closed — the PO sampled 2.70:1 in shipped pixels. The lever is the same
## same-colour outline, applied Button-typed. These pin the wash and the wired outline.

func test_active_pill_ink_WASHES_without_the_outline() -> void:
	# Regression pin: at 0.60 stroke coverage the dark C_TAG_INK core is a 60/40 blend over the mint
	# fill that renders UNDER AA — the wash the ~14.8:1 analytic ratio hid until the PO measured pixels.
	var r := DesignSystem.render_floor_contrast(
		KennelScreen.C_TAG_INK, KennelScreen.active_state_fill(), DesignSystem.NAV_STROKE_COVERAGE)
	assert_true(r < 4.5,
		"C_TAG_INK on the mint pill at 0.60 coverage WASHES under AA — got %.2f:1" % r)

func test_active_state_button_carries_the_outline() -> void:
	var ks := KennelScreen.new()
	var btn: Button = ks._build_active_state({})
	assert_eq(btn.get_theme_constant("outline_size"), KennelScreen.SOFT_INK_OUTLINE,
		"«Trener nå» pill carries the stroke-thickening outline")
	assert_eq(btn.get_theme_color("font_outline_color"), KennelScreen.C_TAG_INK,
		"pill outline is the same C_TAG_INK hue (thickens the stroke, does not recolour)")
	btn.free()
	ks.free()

func test_showcase_commit_button_disabled_carries_the_outline() -> void:
	# The shared sibling pill (198) sources its disabled fill from active_state_fill() — keep it unified.
	# The outline is scoped to the DISABLED «Trener nå» state so the enabled blue-gradient CTA keeps its
	# clean white label; assert both branches.
	var sv := BreedShowcaseView.new()
	var btn: Button = sv._make_commit_button()
	assert_eq(btn.get_theme_color("font_outline_color"), BreedShowcaseView.COMMIT_DISABLED_INK,
		"showcase pill outline hue is COMMIT_DISABLED_INK")
	sv._apply_commit_outline(btn, true)
	assert_eq(btn.get_theme_constant("outline_size"), KennelScreen.SOFT_INK_OUTLINE,
		"disabled «Trener nå» commit pill carries the stroke-thickening outline")
	sv._apply_commit_outline(btn, false)
	assert_eq(btn.get_theme_constant("outline_size"), 0,
		"enabled blue-gradient CTA keeps its clean no-outline white label")
	btn.free()
	sv.free()
