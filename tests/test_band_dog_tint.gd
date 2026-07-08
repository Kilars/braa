extends "res://tests/test_case.gd"
## TDD for KennelScreen._band_dog_tint (147, X-6 cool-coat parity). The kennel renders every dog at
## a neutral grey coat, then MODULATES per breed toward its natural coat hue (portrait_tint). Dark
## coats must be lightened so they read on the band — but lightening must PRESERVE hue, or a cool
## coat (Nova) collapses to a near-neutral tint that framing/lighting flips to warm in the modal
## bust while the grid cell still reads it grey (the father's pass-11 "breed flip"). This pins the
## contract: dark cool stays cool, dark warm stays warm, both get readable, light is unchanged.

const NOVA   := Color(0.298, 0.322, 0.357)   ## Border collie — dark COOL (lum ~0.32)
const PONTUS := Color(0.529, 0.337, 0.212)   ## Gravhund — dark WARM (lum ~0.37)
const TRULTE := Color(0.902, 0.863, 0.796)   ## Malchi — LIGHT coat (lum high)
const BELLA  := Color(0.905, 0.760, 0.470)   ## STARTER_PORTRAIT_TINT — cream yellow Labrador (lum ~0.77)
const SOL    := Color(0.886, 0.741, 0.463)   ## Golden retriever — LIGHT warm coat (lum ~0.75)

static func _chroma(c: Color) -> float:
	return maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))

func test_dark_cool_coat_stays_cool() -> void:
	## Nova is a dark cool coat. After tinting it must remain visibly cool — blue clearly above red,
	## NOT collapsed to a near-neutral grey (the old lerp→white bug left b−r ≈ 0.02).
	var t := KennelScreen._band_dog_tint(NOVA)
	assert_true(t.b - t.r > 0.05, "Nova stays cool after tint: b(%.3f) clearly > r(%.3f)" % [t.b, t.r])

func test_dark_warm_coat_stays_warm() -> void:
	## Pontus is a dark warm coat — red must stay clearly above blue after tinting.
	var t := KennelScreen._band_dog_tint(PONTUS)
	assert_true(t.r - t.b > 0.05, "Pontus stays warm after tint: r(%.3f) clearly > b(%.3f)" % [t.r, t.b])

func test_dark_coats_are_lightened_to_readable_luminance() -> void:
	## Both dark coats must be lightened so the silhouette reads on the band (>= DARK_BAND_LUM).
	assert_true(KennelScreen._band_dog_tint(NOVA).get_luminance() >= KennelScreen.DARK_BAND_LUM,
		"Nova lightened to a readable luminance")
	assert_true(KennelScreen._band_dog_tint(PONTUS).get_luminance() >= KennelScreen.DARK_BAND_LUM,
		"Pontus lightened to a readable luminance")

func test_dark_cool_coat_is_not_near_neutral() -> void:
	## Regression guard on the actual bug: the tinted cool coat must carry real chroma, not the old
	## desaturated near-white the 0.7 lerp produced (which read cream under the modal's bright bust).
	var t := KennelScreen._band_dog_tint(NOVA)
	var chroma := maxf(t.r, maxf(t.g, t.b)) - minf(t.r, minf(t.g, t.b))
	assert_true(chroma > 0.06, "Nova keeps real chroma (%.3f), not collapsed to neutral" % chroma)

func test_light_coat_is_lightened() -> void:
	## 190 (PO father-pass-64 X-6): light coats (Bella cream, Sol golden) rendered brown in the kennel
	## because the neutral-grey base under the warm portrait rig, times a warm saturated tint, crushed
	## the pale coat down. The light branch must now LIGHTEN the modulate (luminance up) so the pale
	## coat reads pale — up toward Bella's cream training coat.
	assert_true(KennelScreen._band_dog_tint(BELLA).get_luminance() > BELLA.get_luminance(),
		"Bella (light) is lightened toward her pale training cream")
	assert_true(KennelScreen._band_dog_tint(SOL).get_luminance() > SOL.get_luminance(),
		"Sol (light golden) is lightened, not crushed to brown")

func test_light_coat_is_desaturated() -> void:
	## The over-brown was warm-biased (R clearly above B). The fix desaturates the warm bias, so the
	## tinted light coat carries LESS chroma than the raw portrait_tint — a pale cream, not a brown.
	assert_true(_chroma(KennelScreen._band_dog_tint(BELLA)) < _chroma(BELLA),
		"Bella tint is desaturated (chroma %.3f < raw %.3f)"
			% [_chroma(KennelScreen._band_dog_tint(BELLA)), _chroma(BELLA)])
	var t := KennelScreen._band_dog_tint(BELLA)
	assert_true(t.r - t.b < BELLA.r - BELLA.b,
		"Bella warm bias reduced: r-b %.3f < raw %.3f" % [t.r - t.b, BELLA.r - BELLA.b])

func test_light_coat_stays_above_dark_coats() -> void:
	## Sanity ordering: a lightened light coat still reads clearly brighter than a lightened dark coat,
	## so the roster keeps its light↔dark coat variety.
	assert_true(KennelScreen._band_dog_tint(BELLA).get_luminance()
		> KennelScreen._band_dog_tint(NOVA).get_luminance(),
		"Bella (light) stays brighter than Nova (dark) after tint")
