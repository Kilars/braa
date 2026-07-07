extends "res://tests/test_case.gd"
## Task 149 (PO father-pass-13, X-6): the kennel rarity/status corner badges + the status price
## pills must clear WCAG AA (4.5:1) for their small (~10-11px) label text. 148 shipped them with
## white text on calm mid-tone accents (2.48-3.40:1 — all failing). The fix keeps the accents and
## switches the label ink to a shared dark ink; these assert the ink clears AA on every accent and
## that the WCAG helper matches the known failing baseline.

func test_tag_ink_clears_aa_on_every_badge_accent() -> void:
	var accents := [
		KennelScreen.C_STATUS_NEUTRAL, KennelScreen.C_RARITY_RARE, KennelScreen.C_RARITY_EPIC,
		KennelScreen.C_STATUS_OWNED,   KennelScreen.C_STATUS_EGG,
		KennelScreen.C_PRICE_OWN,      KennelScreen.C_PRICE_FREE,
	]
	for a in accents:
		var ratio := KennelScreen.wcag_contrast(KennelScreen.C_TAG_INK, a)
		assert_true(ratio >= 4.5, "tag ink must clear AA 4.5:1 on accent %s (got %.2f)" % [a, ratio])

func test_white_on_slate_is_the_failing_baseline() -> void:
	assert_true(KennelScreen.wcag_contrast(Color.WHITE, KennelScreen.C_STATUS_NEUTRAL) < 3.0,
		"white-on-slate is the sub-3:1 baseline 148 shipped")
	assert_true(KennelScreen.wcag_contrast(KennelScreen.C_TAG_INK, KennelScreen.C_STATUS_NEUTRAL) >= 4.5,
		"ink-on-slate clears AA")

func test_wcag_contrast_is_symmetric() -> void:
	var ab := KennelScreen.wcag_contrast(KennelScreen.C_TAG_INK, KennelScreen.C_RARITY_EPIC)
	var ba := KennelScreen.wcag_contrast(KennelScreen.C_RARITY_EPIC, KennelScreen.C_TAG_INK)
	assert_true(abs(ab - ba) < 0.001, "wcag_contrast is order-independent")
