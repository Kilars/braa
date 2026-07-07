extends "res://tests/test_case.gd"
## Task 154 (PO father-pass-18, X-6): every blue-on-light TEXT label in the completion/pause menu
## must clear WCAG AA (4.5:1) — the last corner the 149→151→153 AA sweep left behind. The «Gi
## tilbakemelding» secondary button label was BLUE-on-PAPER (~2.93:1) and the «Tilgjengelig» /
## learned / active row labels were BLUE-on-CREAM (~1.66-2.87:1). The fix repoints them to the
## deeper BLUE_INK token. These pin each token against the fill it actually sits on.

# Menu text tokens that sit on the CREAM row fill (TrickMenu.ROW_BG == DesignSystem.CREAM),
# paired with their name for a legible failure message.
func _cream_text_tokens() -> Array:
	return [
		["NAME_LEARNED", TrickMenu.NAME_LEARNED],
		["BADGE_LEARNED", TrickMenu.BADGE_LEARNED],
		["BADGE_AVAILABLE", TrickMenu.BADGE_AVAILABLE],
		["BREED_NAME_ACTIVE", TrickMenu.BREED_NAME_ACTIVE],
		["WORD_NAME_ACTIVE", TrickMenu.WORD_NAME_ACTIVE],
		["DIFF_NAME_ACTIVE", TrickMenu.DIFF_NAME_ACTIVE],
	]

func test_cream_row_blue_text_clears_aa() -> void:
	for pair in _cream_text_tokens():
		var ratio := DesignSystem.wcag_contrast(pair[1], TrickMenu.ROW_BG)
		assert_true(ratio >= 4.5,
			"%s must clear AA 4.5:1 on the CREAM row fill (got %.2f:1)" % [pair[0], ratio])

func test_secondary_button_label_clears_aa_on_paper() -> void:
	var ratio := DesignSystem.wcag_contrast(TrickMenu.SECONDARY_TEXT, TrickMenu.SECONDARY_BG)
	assert_true(ratio >= 4.5,
		"«Gi tilbakemelding» secondary label clears AA on its PAPER fill (got %.2f:1)" % ratio)

func test_blue_on_light_baseline_failed_before() -> void:
	# The BLUE accent (what these tokens used to be) fails AA on both menu fills — the bug 154 fixes.
	assert_true(DesignSystem.wcag_contrast(DesignSystem.BLUE, TrickMenu.ROW_BG) < 4.5,
		"plain BLUE on the CREAM row is the sub-AA baseline")
	assert_true(DesignSystem.wcag_contrast(DesignSystem.BLUE, TrickMenu.SECONDARY_BG) < 4.5,
		"plain BLUE on the PAPER secondary fill is the sub-AA baseline")

func test_active_row_ink_still_dark_on_pale_wash() -> void:
	# 152 must be left exactly as-is: the ACTIVE (currently-trained) row stays dark-ink on the
	# pale-blue wash, already AA-clear — 154 must not touch it.
	var ratio := DesignSystem.wcag_contrast(TrickMenu.ROW_ACTIVE_INK, TrickMenu.ROW_BG_ACTIVE)
	assert_true(ratio >= 4.5, "152 ACTIVE row ink still clears AA on its wash (got %.2f:1)" % ratio)
