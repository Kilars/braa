extends "res://tests/test_case.gd"
## 181 (PO father-pass-54): the feedback modal must read as one system with the rest of the game —
## a light DS PAPER card, INK text, BLUE primary CTA, and GOLD reserved strictly for the coin.
## These pin the view's style constants against DesignSystem tokens render-free (the layout itself
## stays Visual-Review gated). Guards against a regression back to the dark-navy / gold-chrome card.

func test_panel_is_ds_paper_card() -> void:
	assert_eq(FeedbackFormView.PANEL_BG, DesignSystem.PAPER, "panel is the DS PAPER card surface")
	assert_eq(FeedbackFormView.PANEL_BORDER, DesignSystem.BORDER, "panel border is the DS hairline BORDER")
	assert_eq(FeedbackFormView.TITLE_COLOR, DesignSystem.INK, "title is DS INK on paper")

func test_primary_send_is_blue() -> void:
	# The primary «Send» CTA mirrors «Fortsett treningen»/«Adopter» — a deep-blue GRAD_PILL fill
	# with an AA-safe white label (never the light BLUE token that failed 153).
	assert_eq(FeedbackFormView.SEND_BG, DesignSystem.GRAD_PILL_BOT, "Send fill is the deep GRAD_PILL blue")
	assert_true(DesignSystem.wcag_contrast(FeedbackFormView.SEND_BG, FeedbackFormView.SEND_TEXT) >= 4.5,
		"white Send label clears WCAG AA on the blue fill")

func test_selected_chip_mirrors_active_wash() -> void:
	# Selected chips reuse the 152/167 active-row pale-blue wash + dark ink, not gold.
	assert_eq(FeedbackFormView.CHIP_BG_ON, TrickMenu.ROW_BG_ACTIVE, "selected chip uses the active-row blue wash")
	assert_eq(FeedbackFormView.CHIP_TEXT_ON, TrickMenu.ROW_ACTIVE_INK, "selected chip text is the shared dark active ink")

func test_no_gold_in_ui_chrome() -> void:
	# GOLD is the coin, nowhere else. None of the view's colour constants may be the GOLD token.
	var chrome := [
		FeedbackFormView.PANEL_BG, FeedbackFormView.PANEL_BORDER, FeedbackFormView.TITLE_COLOR,
		FeedbackFormView.CHIP_BG_ON, FeedbackFormView.CHIP_BG_OFF,
		FeedbackFormView.CHIP_TEXT_ON, FeedbackFormView.CHIP_TEXT_OFF,
		FeedbackFormView.SEND_BG, FeedbackFormView.SEND_TEXT,
		FeedbackFormView.CANCEL_BG, FeedbackFormView.CANCEL_TEXT,
		FeedbackFormView.RATING_ON_BG, FeedbackFormView.RATING_OFF_BG,
	]
	for c in chrome:
		assert_true((c as Color) != DesignSystem.GOLD, "no chrome constant is the GOLD coin token")
		assert_true((c as Color) != DesignSystem.GOLD_DARK, "no chrome constant is GOLD_DARK")
