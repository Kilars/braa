extends "res://tests/test_case.gd"

## X-6 (task 158): the kennel inspect-modal adopt button — the modal's primary CTA — must
## clear WCAG AA in ALL three states. The 149→156 sweep never measured it (it uses its own
## flat C_ADOPT_* fills, not the 153 GRAD_PILL_* gradient), so all three read below 4.5:1.
## These pin each state's (text, fill) pair over the bar and document the pre-158 baseline.

const AA := 4.5

func test_affordable_white_on_blue_clears_aa() -> void:
	# Affordable: white bold label on the adopt-blue fill.
	var ratio := KennelScreen.wcag_contrast(Color.WHITE, KennelScreen.C_ADOPT_BLUE)
	assert_true(ratio >= AA,
		"affordable adopt: white on C_ADOPT_BLUE must clear AA (got %.2f)" % ratio)

func test_unaffordable_ink_on_disabled_clears_aa() -> void:
	# Unaffordable: dark tag ink (not the old C_INK_SOFT) on the muted-grey disabled fill.
	var ratio := KennelScreen.wcag_contrast(KennelScreen.C_TAG_INK, KennelScreen.C_ADOPT_DISABLED)
	assert_true(ratio >= AA,
		"unaffordable adopt: C_TAG_INK on C_ADOPT_DISABLED must clear AA (got %.2f)" % ratio)

func test_free_adopt_ink_on_coral_clears_aa() -> void:
	# Free-adopt: dark tag ink (not white) on the coral fill — same pairing the «Påskeegg»
	# badge already uses on this exact coral.
	var ratio := KennelScreen.wcag_contrast(KennelScreen.C_TAG_INK, KennelScreen.C_ADOPT_FREE)
	assert_true(ratio >= AA,
		"free adopt: C_TAG_INK on C_ADOPT_FREE must clear AA (got %.2f)" % ratio)

func test_free_adopt_coral_identity_kept() -> void:
	# The coral fill is kept (identity with the «Påskeegg» tag) — only the label ink changed.
	assert_true(KennelScreen.C_ADOPT_FREE.is_equal_approx(KennelScreen.C_STATUS_EGG),
		"free-adopt fill stays the «Påskeegg» coral")

func test_old_pairings_were_below_aa() -> void:
	# Documents the pre-158 regression: every state's old (text, fill) failed AA.
	assert_true(KennelScreen.wcag_contrast(Color.WHITE, Color("4a90e2")) < AA,
		"old affordable white-on-#4a90e2 was below AA")
	assert_true(KennelScreen.wcag_contrast(KennelScreen.C_INK_SOFT, KennelScreen.C_ADOPT_DISABLED) < AA,
		"old unaffordable C_INK_SOFT-on-disabled was below AA")
	assert_true(KennelScreen.wcag_contrast(Color.WHITE, KennelScreen.C_ADOPT_FREE) < AA,
		"old free-adopt white-on-coral was below AA")
