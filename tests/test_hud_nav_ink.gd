extends "res://tests/test_case.gd"
## The training-page top-left HUD nav pills — «Triks» and «Kennel» — plus the «Triks» hamburger
## glyph (176, PO father-pass-41 X-6). They used to hard-set DesignSystem.SLATE for their font
## colour + baked glyph bars; at the small bold T_HEAD size SLATE's thin strokes anti-aliased
## toward the pale PAPER pill and read only ~3.7:1 / ~2.9:1 on screen — the faintest primary
## labels in the game, where the goal art shows a crisp saturated BLUE. Both pills + the glyph now
## share one named source, main.HUD_NAV_INK, pointed at the AA-safe BLUE_INK ink (154).
##
## Pure token invariants — read off preloaded constants, no scene boot / framebuffer.

const MainScript := preload("res://scripts/main.gd")

func test_hud_nav_ink_is_the_blue_ink_token() -> void:
	# One named source shared by both pills' three font-colour states AND the hamburger bars, so
	# the labels and the glyph can never drift apart again.
	assert_eq(MainScript.HUD_NAV_INK, DesignSystem.BLUE_INK,
		"the HUD nav ink is the DS BLUE_INK blue-on-light token")

func test_hud_nav_ink_clears_wcag_aa_on_the_paper_pill() -> void:
	# The pills sit on a near-opaque PAPER fill; the label must clear AA 4.5:1 against it with real
	# margin even after anti-aliasing (BLUE_INK ~5.5:1 on PAPER; SLATE nominally 5.2 but read <3.7).
	var ratio := DesignSystem.wcag_contrast(MainScript.HUD_NAV_INK, DesignSystem.PAPER)
	assert_true(ratio >= 4.5,
		"HUD nav ink on PAPER clears WCAG AA 4.5:1 (got %.2f:1)" % ratio)

func test_hud_nav_ink_is_not_the_old_faint_slate() -> void:
	# Regression guard: the whole point of 176 is that these labels are no longer the muted grey
	# that washed out against the bright sky.
	assert_true(MainScript.HUD_NAV_INK != DesignSystem.SLATE,
		"HUD nav ink is not the old faint SLATE grey")

func test_hud_nav_ink_is_blue_dominant() -> void:
	# Matches the goal art's crisp BLUE treatment — a blue-dominant ink, not a neutral grey.
	assert_true(MainScript.HUD_NAV_INK.b > MainScript.HUD_NAV_INK.r
			and MainScript.HUD_NAV_INK.b > MainScript.HUD_NAV_INK.g,
		"HUD nav ink is blue-dominant (b > r and b > g)")
