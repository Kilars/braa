extends "res://tests/test_case.gd"
## The training-page top-left HUD nav pills — «Triks» and «Kennel» — plus the «Triks» hamburger
## glyph. History: they started on faint SLATE (~3.7/2.9:1 rendered); 176 swapped to BLUE_INK
## trusting its ANALYTIC 5.55:1 on PAPER. But PO father-pass-77 measured the SHIPPED pixels: at
## the small bold T_HEAD (18px Baloo) the thin strokes reach only ~0.60 sub-pixel coverage, so the
## darkest core is a 60/40 blend of ink over the PAPER pill — BLUE_INK rendered [126,166,215] ≈
## 2.43:1, failing AA (the darker INK «Sitt» control barely clears at 4.03). 200 points the shared
## HUD_NAV_INK at a NEW deeper DS token, NAV_INK, dark enough that even the 0.60-coverage rendered
## darkest pixel clears AA — while staying blue-dominant for the goal-art blue character.
##
## Pure token invariants — read off preloaded constants, no scene boot / framebuffer.

const MainScript := preload("res://scripts/main.gd")

func test_hud_nav_ink_is_the_nav_ink_token() -> void:
	# One named source shared by both pills' three font-colour states AND the hamburger bars, so
	# the labels and the glyph can never drift apart again.
	assert_eq(MainScript.HUD_NAV_INK, DesignSystem.NAV_INK,
		"the HUD nav ink is the DS NAV_INK deep-blue-slate token")

func test_hud_nav_ink_clears_wcag_aa_on_the_paper_pill_analytically() -> void:
	# Necessary but NOT sufficient: full-coverage analytic contrast. BLUE_INK passed this yet still
	# washed out in render — that is exactly why the render-floor guard below exists.
	var ratio := DesignSystem.wcag_contrast(MainScript.HUD_NAV_INK, DesignSystem.PAPER)
	assert_true(ratio >= 4.5,
		"HUD nav ink on PAPER clears analytic AA 4.5:1 (got %.2f:1)" % ratio)

func test_hud_nav_ink_clears_aa_in_the_render_floor_model() -> void:
	# The render-robust guard (mirrors 196/197's MEASURED_* headroom guards, inverted for
	# dark-on-light): at NAV_STROKE_COVERAGE ≈0.60 the darkest rendered stroke pixel is a blend of
	# ink over the PAPER pill. NAV_INK must clear AA at THAT blended pixel, not just full coverage —
	# this is the number the eye sees (pass-77 measured 2.43:1 for the old BLUE_INK here).
	var ratio := DesignSystem.render_floor_contrast(
		MainScript.HUD_NAV_INK, DesignSystem.PAPER, DesignSystem.NAV_STROKE_COVERAGE)
	assert_true(ratio >= 4.5,
		"HUD nav ink clears AA in the 0.60-coverage render-floor model (got %.2f:1)" % ratio)

func test_old_blue_ink_would_FAIL_the_render_floor_model() -> void:
	# The regression pin: prove the previous token (BLUE_INK, analytic 5.55:1) FAILS the render
	# floor — so no future recolour to an analytic-only-safe value can silently re-mask this defect.
	var ratio := DesignSystem.render_floor_contrast(
		DesignSystem.BLUE_INK, DesignSystem.PAPER, DesignSystem.NAV_STROKE_COVERAGE)
	assert_true(ratio < 4.5,
		"BLUE_INK must FAIL the render-floor model (it washed to ~2.43:1 in pass-77) — got %.2f:1" % ratio)

func test_hud_nav_ink_is_not_the_old_faint_slate_or_blue_ink() -> void:
	# Regression guard: these labels are no longer the muted SLATE (145 washout) nor the BLUE_INK
	# that rendered too light (pass-77 washout).
	assert_true(MainScript.HUD_NAV_INK != DesignSystem.SLATE
			and MainScript.HUD_NAV_INK != DesignSystem.BLUE_INK,
		"HUD nav ink is neither the faint SLATE nor the render-washing BLUE_INK")

func test_nav_labels_carry_a_stroke_thickening_outline() -> void:
	# The render fix's SECOND lever (measured, not modelled). At 18px the thin Nunito-700 strokes
	# reach only ~0.55 coverage, which caps the darkest core at ~4.68:1 even for pure black — so a
	# dark ink ALONE cannot clear AA with margin. A same-ink outline thickens the strokes to ~full
	# coverage, so NAV_INK renders at its true value (pass-77 harness measured [10,22,40] ≈ 17:1 on
	# the PAPER pill, vs 4.0:1 without the outline). Pin it so a future edit can't silently drop it.
	assert_true(MainScript.HUD_NAV_LABEL_OUTLINE > 0,
		"nav labels carry a stroke-thickening outline (got %d)" % MainScript.HUD_NAV_LABEL_OUTLINE)

func test_hud_nav_ink_is_blue_dominant() -> void:
	# Matches the goal art's BLUE treatment — a blue-dominant ink, not a neutral grey/black.
	assert_true(MainScript.HUD_NAV_INK.b > MainScript.HUD_NAV_INK.r
			and MainScript.HUD_NAV_INK.b > MainScript.HUD_NAV_INK.g,
		"HUD nav ink is blue-dominant (b > r and b > g)")
