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
