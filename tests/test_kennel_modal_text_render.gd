extends "res://tests/test_case.gd"
## Task 204 (PO father-pass-81, X-6): the kennel inspect-modal's REMAINING text tier — the
## personality blurb, the «Unikt trekk» value, and the Raseegenskaper trait chips — is the last
## modal text still on the bare no-outline Label path after 203 lifted the C_INK_SOFT labels
## around it. At 0.60 stroke coverage even the dark C_INK (analytic ~11:1) render-floors to ~3.5:1,
## and the trait chip's C_TRAIT_INK is thin on C_TRAIT_BG. Fix mirrors 200/201/202/203: a same-colour
## outline restores ~full coverage so each renders its true token, PLUS one small token deepen on the
## chip ink for analytic margin. Pure token/coverage invariants — read off constants + instantiated
## nodes, no framebuffer.

# Dark-C_INK text elements (blurb, unique-trait value) and the fills they draw on.
func _dark_ink_fills() -> Array:
	return [
		["modal blurb",       KennelScreen.C_MODAL_SURFACE],
		["Unikt-trekk value", KennelScreen.C_MODAL_CREAM],
	]

func test_dark_ink_hue_unchanged() -> void:
	# The blurb / value fix is render coverage, NOT a recolour: C_INK stays the primary dark ink.
	assert_eq(KennelScreen.C_INK, Color("2b3742"), "modal body text stays the primary C_INK")

func test_trait_ink_deepened_stays_blue() -> void:
	# The chip ink is deepened toward BLUE_INK depth so it clears AA with margin (external sampler read
	# the old #3a6a9a at 3.71:1). It must stay the blue-family chip identity — blue channel dominant.
	var ink := KennelScreen.C_TRAIT_INK
	assert_true(ink.b8 > ink.r8 and ink.b8 > ink.g8, "trait chip ink stays blue-dominant (pale-blue identity)")
	var ratio := KennelScreen.wcag_contrast(ink, KennelScreen.C_TRAIT_BG)
	assert_true(ratio >= 5.5, "deepened C_TRAIT_INK clears AA with margin on C_TRAIT_BG (got %.2f:1)" % ratio)

func test_dark_ink_WASHES_without_the_outline() -> void:
	# Regression pin (mirrors 203): at 0.60 coverage the dark C_INK core is a 60/40 blend over its fill
	# that renders UNDER AA — the wash the analytic ratio hides — so the stroke-thickening outline (not
	# a recolour) is the required lever. Also holds for the deepened chip ink.
	for fill in _dark_ink_fills():
		var r := DesignSystem.render_floor_contrast(KennelScreen.C_INK, fill[1], DesignSystem.NAV_STROKE_COVERAGE)
		assert_true(r < 4.5, "C_INK on %s at 0.60 coverage WASHES under AA — got %.2f:1" % [fill[0], r])
	var rc := DesignSystem.render_floor_contrast(KennelScreen.C_TRAIT_INK, KennelScreen.C_TRAIT_BG, DesignSystem.NAV_STROKE_COVERAGE)
	assert_true(rc < 4.5, "trait chip ink at 0.60 coverage WASHES under AA — got %.2f:1" % rc)

func test_text_clears_aa_at_restored_full_coverage() -> void:
	# With the outline restoring ~full coverage each element renders its true token, which clears AA.
	for fill in _dark_ink_fills():
		var r := KennelScreen.wcag_contrast(KennelScreen.C_INK, fill[1])
		assert_true(r >= 4.5, "outline-restored C_INK clears AA on %s (got %.2f:1)" % [fill[0], r])
	var rc := KennelScreen.wcag_contrast(KennelScreen.C_TRAIT_INK, KennelScreen.C_TRAIT_BG)
	assert_true(rc >= 4.5, "outline-restored trait ink clears AA on C_TRAIT_BG (got %.2f:1)" % rc)

func test_wired_blurb_carries_the_outline() -> void:
	var ks := KennelScreen.new()
	var lbl: Label = ks._build_modal_blurb({"blurb": "En varm og tålmodig hund."})
	assert_eq(lbl.get_theme_constant("outline_size"), KennelScreen.SOFT_INK_OUTLINE,
		"modal blurb carries the stroke-thickening outline")
	assert_eq(lbl.get_theme_color("font_outline_color"), KennelScreen.C_INK,
		"blurb outline is the same C_INK hue (thickens the stroke, does not recolour)")
	lbl.free()
	ks.free()

func test_wired_unique_trait_value_carries_the_outline() -> void:
	var ks := KennelScreen.new()
	var card: PanelContainer = ks._build_modal_unique_trait({"unique_trait": "Godbit-radar"})
	var col: VBoxContainer = card.get_child(0)
	var value_lbl: Label = col.get_child(1)   # child 0 = «Unikt trekk» heading, child 1 = the value
	assert_eq(value_lbl.get_theme_constant("outline_size"), KennelScreen.SOFT_INK_OUTLINE,
		"unique-trait value carries the stroke-thickening outline")
	assert_eq(value_lbl.get_theme_color("font_outline_color"), KennelScreen.C_INK,
		"value outline is the same C_INK hue")
	card.free()
	ks.free()

func test_wired_trait_chip_carries_the_outline() -> void:
	var ks := KennelScreen.new()
	var col: VBoxContainer = ks._build_modal_traits({"traits": ["Snill", "Tålmodig"]})
	var chip_row: HBoxContainer = col.get_child(1)   # child 0 = «Raseegenskaper» heading, child 1 = chips
	var chip: PanelContainer = chip_row.get_child(0)
	var chip_lbl: Label = chip.get_child(0)
	assert_eq(chip_lbl.get_theme_constant("outline_size"), KennelScreen.SOFT_INK_OUTLINE,
		"trait chip carries the stroke-thickening outline")
	assert_eq(chip_lbl.get_theme_color("font_outline_color"), KennelScreen.C_TRAIT_INK,
		"chip outline is the same C_TRAIT_INK hue")
	assert_eq(chip_lbl.get_theme_color("font_color"), KennelScreen.C_TRAIT_INK,
		"chip text is the deepened C_TRAIT_INK token")
	col.free()
	ks.free()
