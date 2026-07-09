extends "res://tests/test_case.gd"
## The training-page LearnedBar «Sitt» name + «%» readout (045 / 097). History: 145 defeated the
## sky/sun BLEED onto this readout (opaque cream track + scrim), but PO father-pass-78 measured the
## SHIPPED pixels and caught a DIFFERENT wash the 145 fix never touched — the same thin-stroke
## sub-pixel under-coverage task 200 fixed on the nav pills. At T_HEAD (18px Baloo bold) the «Sitt»
## label (INK #1e2a3a) reaches only ~NAV_STROKE_COVERAGE (0.60) coverage, so its darkest core is a
## 0.60/0.40 blend of INK over the PAPER panel → rendered [119,127,135] ≈ 3.92:1, UNDER AA, the
## faintest primary text on the page once the nav pills jumped to 17:1. 201 adds task 200's proven
## stroke-thickening outline (via draw_string_outline) so the labels render their true tokens.
##
## Pure token/coverage invariants — read off preloaded constants, no scene boot / framebuffer.

const LabelColor := DesignSystem.INK        # «Sitt» name — kept, but the outline restores its coverage
const PctColor   := DesignSystem.BLUE_INK   # blue «%» readout (180) — kept, outline restores its coverage

func test_readout_tokens_unchanged() -> void:
	# The fix is render (coverage), NOT a recolour: the «Sitt» name stays INK and the «%» stays the
	# goal-art BLUE_INK (180). Guards against a future "just darken it" that would drop the blue «%».
	assert_eq(LearnedBar.LABEL_COLOR, DesignSystem.INK,
		"the «Sitt» name label stays the INK token")
	assert_eq(LearnedBar.PCT_COLOR, DesignSystem.BLUE_INK,
		"the «%» readout stays the goal-art BLUE_INK token (180)")

func test_name_label_WASHES_without_the_outline() -> void:
	# The measured defect (regression pin, mirrors nav's BLUE_INK-fails pin): at 0.60 stroke coverage
	# the INK «Sitt» core is a 60/40 blend over PAPER that renders ~3.92:1 — UNDER AA. This is why a
	# deeper ink alone can't fix it and the stroke-thickening outline is required.
	var ratio := DesignSystem.render_floor_contrast(
		LearnedBar.LABEL_COLOR, DesignSystem.PAPER, DesignSystem.NAV_STROKE_COVERAGE)
	assert_true(ratio < 4.5,
		"INK «Sitt» at 0.60 coverage WASHES under AA (pass-78 measured 3.92:1) — got %.2f:1" % ratio)

func test_readout_carries_a_stroke_thickening_outline() -> void:
	# The decisive lever (same as 200): a same-ink outline via draw_string_outline raises effective
	# stroke coverage to ~full, so both labels render their true tokens. Pin it so a future edit
	# can't silently drop it and re-wash the readout.
	assert_true(LearnedBar.LABEL_OUTLINE > 0,
		"the readout labels carry a stroke-thickening outline (got %d)" % LearnedBar.LABEL_OUTLINE)

func test_name_label_clears_aa_at_restored_full_coverage() -> void:
	# With the outline restoring ~full coverage, the «Sitt» name renders its true INK token — solid,
	# clearing AA with margin (as solid as the nav pills now do).
	var ratio := DesignSystem.wcag_contrast(LearnedBar.LABEL_COLOR, DesignSystem.PAPER)
	assert_true(ratio >= 4.5,
		"outline-restored INK «Sitt» clears AA on PAPER (got %.2f:1)" % ratio)

func test_pct_readout_clears_aa_at_restored_full_coverage() -> void:
	# The blue «%» (180) also washes at 0.60 coverage; the same outline restores it. At full coverage
	# BLUE_INK clears AA on PAPER (~4.84:1) while keeping the goal-art blue.
	var ratio := DesignSystem.wcag_contrast(LearnedBar.PCT_COLOR, DesignSystem.PAPER)
	assert_true(ratio >= 4.5,
		"outline-restored BLUE_INK «%» clears AA on PAPER (got %.2f:1)" % ratio)
