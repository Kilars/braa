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

# Task 186 (PO father-pass-60, X-6): the three completion-menu SECTION SUBHEADINGS («Raser» /
# «Merkeord» / «Vanskelighet») are meaningful active labels on the PAPER card, not disabled
# chrome, so they must clear WCAG AA. They rendered at SLATE_SOFT #8a97a4 = 2.87:1 on PAPER — the
# same grey-on-light miss the kennel fixed (task 156). Fix = SLATE #5a6b7d (5.28:1 on PAPER).
func _paper_subhead_tokens() -> Array:
	return [
		["BREED_SUBHEAD", TrickMenu.BREED_SUBHEAD],
		["WORD_SUBHEAD", TrickMenu.WORD_SUBHEAD],
		["DIFF_SUBHEAD", TrickMenu.DIFF_SUBHEAD],
	]

func test_section_subheadings_clear_aa_on_paper() -> void:
	for pair in _paper_subhead_tokens():
		var ratio := DesignSystem.wcag_contrast(pair[1], TrickMenu.PANEL_BG)
		assert_true(ratio >= 4.5,
			"%s (section subheading) must clear AA 4.5:1 on the PAPER card (got %.2f:1)" % [pair[0], ratio])

func test_slate_soft_subhead_baseline_failed_before() -> void:
	# SLATE_SOFT (what the subheadings used to be) fails AA on PAPER — the bug 186 fixes.
	assert_true(DesignSystem.wcag_contrast(DesignSystem.SLATE_SOFT, TrickMenu.PANEL_BG) < 4.5,
		"SLATE_SOFT on the PAPER card is the sub-AA baseline")

func test_locked_row_labels_stay_soft() -> void:
	# The locked-row names/badges are intentional disabled styling (WCAG exempt) — 186 must not
	# touch them; they stay SLATE_SOFT.
	assert_eq(TrickMenu.NAME_LOCKED, DesignSystem.SLATE_SOFT,
		"locked-row name stays SLATE_SOFT (disabled styling)")
	assert_eq(TrickMenu.BADGE_LOCKED, DesignSystem.SLATE_SOFT,
		"locked-row badge stays SLATE_SOFT (disabled styling)")
