extends "res://tests/test_case.gd"
## Task 162 (PO father-pass-27, X-6): the completion menu's «Raser» buyable breed-price badge
## «Adopter 30» drew its whole string in COIN_GOLD (== DesignSystem.GOLD #f5b841) over the CREAM
## row fill — gold-on-cream ~1.55:1, far under the 4.5:1 AA bar. It is the ONE price badge the
## 149→156 AA sweep never measured. The fix mirrors the kennel _make_price_chip: dark AA-legible
## ink for the text + a small gold coin pip to keep the "gold = coin" signal on an actual coin
## glyph (never as text). These pin the price-badge ink against the CREAM fill it sits on, and
## keep the pip gold.

func test_price_badge_ink_clears_aa_on_cream_row() -> void:
	# The buyable «Adopter 30» text ink must clear WCAG AA on the CREAM row fill.
	var ratio := DesignSystem.wcag_contrast(TrickMenu.BADGE_PRICE_INK, TrickMenu.ROW_BG)
	assert_true(ratio >= 4.5,
		"BADGE_PRICE_INK «Adopter 30» must clear AA 4.5:1 on the CREAM row (got %.2f:1)" % ratio)

func test_old_gold_price_text_was_sub_aa_baseline() -> void:
	# The bug 162 fixes: GOLD text on CREAM is intrinsically two light warm tones → far sub-AA.
	var ratio := DesignSystem.wcag_contrast(DesignSystem.GOLD, TrickMenu.ROW_BG)
	assert_true(ratio < 2.0,
		"GOLD-on-CREAM is the sub-AA baseline the price text used to be (got %.2f:1)" % ratio)

func test_coin_pip_stays_gold_to_preserve_the_coin_signal() -> void:
	# Gold is not gone — it is reserved to a real coin glyph (the DS rule). The price-badge pip
	# fill stays GOLD so the "gold = coin" signal survives the text going dark.
	assert_eq(TrickMenu.COIN_GOLD, DesignSystem.GOLD,
		"the price-badge coin pip keeps the GOLD coin signal")
