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

func test_active_marker_dot_is_visible_on_both_backgrounds() -> void:
	## Task 165 (PO father-pass-30): the quiet "aktiv" dot must be visible whether its pip is the
	## bright spotlit pill (dark dot on paper) or a faint pill over the dark band (light dot on ink) —
	## a UI-graphic marker clears the ≥3:1 non-text bar on EITHER background, and the two colours differ.
	var on_light := DesignSystem.wcag_contrast(BreedShowcaseView.active_dot_color(true), DesignSystem.PAPER)
	assert_true(on_light >= 3.0,
		"active dot on the solid-paper spotlit pip clears the 3:1 graphic bar (got %.2f:1)" % on_light)
	var on_dark := DesignSystem.wcag_contrast(BreedShowcaseView.active_dot_color(false), DesignSystem.INK)
	assert_true(on_dark >= 3.0,
		"active dot on the dark band clears the 3:1 graphic bar (got %.2f:1)" % on_dark)
	assert_ne(BreedShowcaseView.active_dot_color(true), BreedShowcaseView.active_dot_color(false),
		"the dot adapts its colour to the pip background (dark on light, light on dark)")

func test_active_marker_dot_seats_fully_on_the_pill() -> void:
	## Task 166 (PO father-pass-31): the "aktiv" dot must sit fully on the pill fill, never bleeding
	## onto the dark band. The pip stylebox corner radius is 12; a dot at inset 8 (the 165 bug) has its
	## centre inside the corner CURVE, so half the disc spills into the transparent rounded corner. The
	## seated centre keeps the whole disc left of the right corner-curve start and below the flat top.
	var corner: float = BreedShowcaseView.ActiveDot.CORNER
	var r: float = BreedShowcaseView.ActiveDot.R
	# a representative pip: wide enough for a breed name, short pill height
	var size := Vector2(120, 34)
	var c := BreedShowcaseView.ActiveDot.center_for(size)
	assert_true(c.x + r <= size.x - corner + 0.01,
		"dot right edge must be at/left of the right corner-curve start, on the flat top (got x=%.1f)" % (c.x + r))
	assert_true(c.y - r >= -0.01,
		"dot top edge must be within the pill, on the flat top (got y=%.1f)" % (c.y - r))
	assert_true(c.x - r >= -0.01 and c.y + r <= size.y + 0.01,
		"the whole dot stays within the pill rect")
	assert_true(c.x > size.x * 0.5 and c.y < size.y * 0.5,
		"the dot still reads as a top-right badge")

## The father measured the composited stage band directly under the hint at (91,102,103) in-pixel at
## dsf3 over the default bright-grass showcase view — the band's translucent INK@.72 lets the lawn
## bleed through and lighten it. This is the real worst case the caption ink must stay legible on.
const MEASURED_WORST_BAND := Color8(91, 102, 103)

func test_hint_caption_clears_aa_over_bright_grass_band() -> void:
	## 169 (PO father-pass-34): «Bla med pilene …» read ~4.1–4.3:1 (sub-AA) because SUBTLE was only
	## 78%-opacity white over the lightened band. The EFFECTIVE (composited) hint ink must clear AA on
	## that measured worst-case band.
	var ink := BreedShowcaseView.hint_ink_over(MEASURED_WORST_BAND)
	var ratio := DesignSystem.wcag_contrast(ink, MEASURED_WORST_BAND)
	assert_true(ratio >= AA,
		"hint caption must clear AA on the worst-case bright-grass band (got %.2f:1)" % ratio)

func test_ghost_pill_chrome_clears_aa_over_bright_grass_band() -> void:
	## 171 (PO father-pass-36): the «Tilbake» label + ◀▶ chevron glyphs sit on white@0.14 GHOST pills
	## that LIFT the translucent band to a ~112–116-grey pill, so the white@0.92 chrome only read
	## ~3.9–4.0:1 (sub-AA) — the 169 hint fix only ever cleared the raw band, not these pills. The
	## EFFECTIVE (composited) chrome ink over its EFFECTIVE (composited) pill must clear AA on the same
	## measured worst-case bright-grass band the hint uses.
	var pill := BreedShowcaseView.chrome_pill_over(MEASURED_WORST_BAND)
	var ink := BreedShowcaseView.chrome_ink_over(MEASURED_WORST_BAND)
	var ratio := DesignSystem.wcag_contrast(ink, pill)
	assert_true(ratio >= AA,
		"«Tilbake»/chevron chrome must clear AA on its composited ghost pill (got %.2f:1)" % ratio)

func test_ghost_pill_is_a_darkening_fill() -> void:
	## The pill must be a DARKENING overlay (so the near-opaque white chrome clears AA on it), not the
	## old white@0.14 LIGHTENING fill that lifted the band above where white@0.92 could clear 4.5:1.
	var pill := BreedShowcaseView.chrome_pill_over(MEASURED_WORST_BAND)
	var band_lum := DesignSystem._rel_luminance(MEASURED_WORST_BAND)
	var pill_lum := DesignSystem._rel_luminance(pill)
	assert_true(pill_lum < band_lum,
		"ghost pill must darken the band (got pill %.3f vs band %.3f)" % [pill_lum, band_lum])

func test_caption_scrim_is_an_opaque_dark_ink() -> void:
	## PO father-pass-70 (X-6): the two captions — the «Labrador» breed subtitle (top band) and the
	## «Adopter flere …» hint (bottom band) — rendered ~2.0–2.4:1 in the shipped pixels because at a
	## subordinate 14–16px NO rendered pixel of their strokes reaches full white (measured peak ~0.48),
	## so over the translucent band (bright grass bleeds it to lum ~0.08–0.13) they land sub-AA. The
	## fix backs each caption with a LOCAL opaque-dark scrim chip that forces the band behind the strokes
	## to near-black INK, so even the ~0.48 peak clears AA — the scrim must be opaque + dark.
	assert_true(BreedShowcaseView.CAPTION_SCRIM.a >= 0.98,
		"caption scrim must be (near-)opaque so bright grass can't bleed behind the text (got a=%.2f)" % BreedShowcaseView.CAPTION_SCRIM.a)
	var scrim_lum := DesignSystem._rel_luminance(BreedShowcaseView.CAPTION_SCRIM)
	assert_true(scrim_lum < 0.05,
		"caption scrim must be a near-black ink (got luminance %.3f)" % scrim_lum)

func test_caption_render_peak_clears_aa_on_the_scrim() -> void:
	## The render-robust worst case: the caption's rendered peak white pixel reaches only ~0.46
	## LUMINANCE (measured in-pixel over the scrim, task 196 — thin subordinate strokes never fully
	## cover). Backed by the opaque near-black scrim, even that dim peak must clear AA — the guarantee
	## the translucent band couldn't give (there the peak sat on lum ~0.08–0.13 → ~2–4:1). Contrast is
	## computed from the measured peak LUMINANCE against the scrim's luminance (matching the in-pixel
	## sampler's units — the earlier bug treated 0.46 as an sRGB value, whose luminance is far lower).
	const MEASURED_PEAK_LUM := 0.46
	var scrim_lum := DesignSystem._rel_luminance(BreedShowcaseView.CAPTION_SCRIM)
	var ratio := (MEASURED_PEAK_LUM + 0.05) / (scrim_lum + 0.05)
	assert_true(ratio >= AA,
		"the measured ~0.46-luminance caption peak must clear AA on the opaque scrim (got %.2f:1)" % ratio)

func test_subtle_caption_is_full_opacity_white() -> void:
	## 169's SUBTLE was white@0.92 — the ~8% transparency compounded the thin-stroke under-coverage so
	## the brightest shipped pixel never reached the analytic target. Full-opaque white lands the glyph
	## body as bright as the render allows; subordination to the title now comes from the smaller size
	## + the scrim chip, not from a lowered alpha.
	assert_eq(BreedShowcaseView.SUBTLE.a, 1.0,
		"the SUBTLE caption colour must be full-opaque white so the brightest pixel reaches its peak")

func test_disabled_ink_is_a_dark_design_system_ink() -> void:
	## The disabled label ink is a real dark DS ink (not a washed light gold) — luminance well below the fill.
	var ink_lum := DesignSystem._rel_luminance(BreedShowcaseView.COMMIT_DISABLED_INK)
	var fill_lum := DesignSystem._rel_luminance(BreedShowcaseView.commit_disabled_fill())
	assert_true(ink_lum < fill_lum,
		"disabled ink must be darker than its fill (dark-ink-on-light-muted, not washed-on-gold)")
