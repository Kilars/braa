extends "res://tests/test_case.gd"
## WCAG-AA + DS-conformance guard for the breed showcase chrome (163, PO father-pass-28, X-4).
##
## The showcase was the one live surface the 129→162 DS/AA arc skipped: hardcoded charcoal/gold,
## no DesignSystem, and an illegible ~1.03:1 disabled «Trener denne» CTA (washed gold-on-gold). This
## pins the two CTA states to the AA bar and pins gold OFF every non-coin chrome fill, exactly as the
## kennel status pills (151) and the menu price badge (162) already are.

const AA := 4.5

# The DS gold family the "gold = coin only" rule reserves — no showcase chrome fill may be one of these.
func _is_goldish(c: Color) -> bool:
	for g in [DesignSystem.GOLD, DesignSystem.GOLD_DARK, DesignSystem.GOLD_LIGHT]:
		if absf(c.r - g.r) < 0.06 and absf(c.g - g.g) < 0.06 and absf(c.b - g.b) < 0.06:
			return true
	return false

func test_disabled_commit_label_clears_aa() -> void:
	## The active-dog «Trener denne» is non-tappable (disabled); its dark ink over the muted fill must
	## clear AA — this is the ~1.03:1 washed-gold-on-gold defect the father caught.
	var ratio := DesignSystem.wcag_contrast(
		BreedShowcaseView.COMMIT_DISABLED_INK, BreedShowcaseView.commit_disabled_fill())
	assert_true(ratio >= AA,
		"disabled «Trener denne» ink must clear AA on its muted fill (got %.2f:1)" % ratio)

func test_enabled_commit_label_clears_aa() -> void:
	## The previewed-dog «Tren denne» is the DS blue gradient pill with a white label; white on the
	## LIGHTEST face colour it touches (GRAD_PILL_TOP) must clear AA (the 153 CTA contract).
	var ratio := DesignSystem.wcag_contrast(Color.WHITE, DesignSystem.GRAD_PILL_TOP)
	assert_true(ratio >= AA,
		"enabled «Tren denne» white label must clear AA on the blue gradient (got %.2f:1)" % ratio)

func test_no_non_coin_chrome_fill_is_gold() -> void:
	## Gold is reserved for the coin; the showcase shows no price, so NO chrome fill may be gold.
	for pair in [
		["NAME_ACTIVE", BreedShowcaseView.NAME_ACTIVE],
		["NAME_PREVIEW", BreedShowcaseView.NAME_PREVIEW],
		["PIP_ON", BreedShowcaseView.PIP_ON],
		["commit_disabled_fill", BreedShowcaseView.commit_disabled_fill()],
	]:
		assert_false(_is_goldish(pair[1] as Color),
			"showcase chrome fill %s must not be gold (gold = coin only)" % pair[0])

func test_disabled_ink_is_a_dark_design_system_ink() -> void:
	## The disabled label ink is a real dark DS ink (not a washed light gold) — luminance well below the fill.
	var ink_lum := DesignSystem._rel_luminance(BreedShowcaseView.COMMIT_DISABLED_INK)
	var fill_lum := DesignSystem._rel_luminance(BreedShowcaseView.commit_disabled_fill())
	assert_true(ink_lum < fill_lum,
		"disabled ink must be darker than its fill (dark-ink-on-light-muted, not washed-on-gold)")
