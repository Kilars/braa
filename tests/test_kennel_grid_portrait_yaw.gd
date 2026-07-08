extends "res://tests/test_case.gd"
## TDD for the kennel GRID per-cell portrait yaw band (155, PO father-pass-19, X-4).
## The grid renders each cell at PORTRAIT_THREE_QUARTER + PORTRAIT_YAW_SPREAD[i] off
## dead-on. The PO found the old spread ([...,-0.40,...,0.46,...]) swung cells from a
## ~1° dead-front mugshot to a ~50° side-profile, violating the code's own "face clearly
## to camera, never a rear/side profile" invariant. These pin the effective per-cell yaw
## inside a tight flattering front-¾ band, while proving the per-cell variety (131) survives.
## The render itself is Visual Review; the yaw arithmetic is pure logic and testable.

## Flattering front-¾ band, in radians off dead-on. Lower bound rules out a stiff
## dead-front mugshot (~14°). RE-TIGHTENED (177, PO father-pass-44): the old 0.68 (~39°)
## upper bound was PROVEN too generous in the web-export renderer — anything past ~0.50
## grazes to a full broadside flank in this fixed camera geometry. The old spread's +0.18
## offset (effective 0.60) sat "inside" the old band yet rendered broadside; the new bound
## rejects it. Verified in a fresh 390×844 capture: every cell reads front-¾ face-to-viewer.
const BAND_MIN := 0.24   ## ~13.7° — anything flatter reads as a dead-front mugshot
const BAND_MAX := 0.50   ## ~28.6° — anything wider grazes to a broadside side-profile

## The viewing geometry is ASYMMETRIC (177): the portrait camera sits front-RIGHT, so a
## POSITIVE per-cell delta turns the nose AWAY from it and hits broadside far faster than a
## negative one. The positive side must stay capped at the proven-good Bella cell (+0.06);
## the negative side is safe out to ~-0.14 (the proven-good Nova cell). This guard is what
## the old test lacked — it validated arithmetic but let +0.18 through, which the PO caught.
const POS_DELTA_CAP := 0.06   ## positive deltas graze to broadside fast — hold at/below Bella
const NEG_DELTA_FLOOR := -0.14 ## negative deltas turn the face back — safe to the Nova cell

func _effective_yaw(i: int) -> float:
	return KennelScreen.PORTRAIT_THREE_QUARTER + float(KennelScreen.PORTRAIT_YAW_SPREAD[i])

func test_every_cell_is_within_the_flattering_front_three_quarter_band() -> void:
	var spread: Array = KennelScreen.PORTRAIT_YAW_SPREAD
	for i in spread.size():
		var y := _effective_yaw(i)
		assert_true(y >= BAND_MIN,
			"cell %d effective yaw %.3f rad is not a dead-front mugshot (>= %.2f)" % [i, y, BAND_MIN])
		assert_true(y <= BAND_MAX,
			"cell %d effective yaw %.3f rad is not a side-profile (<= %.2f)" % [i, y, BAND_MAX])

func test_no_cell_is_dead_front_and_none_is_side_profile() -> void:
	## Explicit guard against the two exact failure modes the PO flagged: the min effective
	## yaw must clear the mugshot floor, the max must clear the side-profile ceiling.
	var lo := 999.0
	var hi := -999.0
	for i in KennelScreen.PORTRAIT_YAW_SPREAD.size():
		var y := _effective_yaw(i)
		lo = minf(lo, y)
		hi = maxf(hi, y)
	assert_true(lo >= BAND_MIN, "most face-on cell (%.3f) is not a dead-front mugshot" % lo)
	assert_true(hi <= BAND_MAX, "most-turned cell (%.3f) is not a side-profile" % hi)

func test_per_cell_variety_is_preserved() -> void:
	## 131's whole point: no two identical-model Labradors read the same. The narrowed spread
	## must still carry real, non-monotonic variety — both signs, a meaningful angular range,
	## and no two adjacent cells identical.
	var spread: Array = KennelScreen.PORTRAIT_YAW_SPREAD
	var has_pos := false
	var has_neg := false
	for v in spread:
		if v > 0.0:
			has_pos = true
		if v < 0.0:
			has_neg = true
	assert_true(has_pos and has_neg, "spread turns dogs both ways (variety, not one canned angle)")

	var lo := 999.0
	var hi := -999.0
	for i in spread.size():
		var y := _effective_yaw(i)
		lo = minf(lo, y)
		hi = maxf(hi, y)
	assert_true(hi - lo >= 0.12, "effective yaws span a visible range (%.3f rad), cells aren't clones" % (hi - lo))

	for i in range(1, spread.size()):
		assert_true(not is_equal_approx(spread[i], spread[i - 1]),
			"adjacent cells %d,%d have distinct yaw" % [i - 1, i])

func test_positive_deltas_are_capped_so_no_cell_grazes_to_broadside() -> void:
	## PO father-pass-44: the front-right portrait camera makes POSITIVE deltas graze to a
	## broadside flank far faster than negative ones — the old spread's +0.18/+0.14/+0.10
	## rendered full side-profiles even though they passed the arithmetic band. Every delta
	## must stay inside the proven-safe asymmetric window [NEG_DELTA_FLOOR, POS_DELTA_CAP].
	for i in KennelScreen.PORTRAIT_YAW_SPREAD.size():
		var d := float(KennelScreen.PORTRAIT_YAW_SPREAD[i])
		assert_true(d <= POS_DELTA_CAP + 0.0001,
			"cell %d delta %.3f exceeds the positive cap %.2f (grazes to broadside)" % [i, d, POS_DELTA_CAP])
		assert_true(d >= NEG_DELTA_FLOOR - 0.0001,
			"cell %d delta %.3f is below the negative floor %.2f" % [i, d, NEG_DELTA_FLOOR])
