extends "res://tests/test_case.gd"
## Task 207 (PO father-pass-84, X-6): the secret «Gratis» coral PRICE-chip label (Trulte) is the LAST
## un-outlined dark-token text the whole 200→206 render-wash arc left. `_make_price_chip`'s status-word
## branch (else — coral «Gratis» / green «Din») sets font_color = C_TAG_INK but never an outline, so at
## 11px bold Nunito the strokes reach only ~NAV_STROKE_COVERAGE (0.60) coverage and the analytically-AA
## dark ink renders a mid-maroon the PO measured at 4.27:1 on the coral — under AA. 207 routes that Label
## through the same _apply_ink_outline(C_TAG_INK) lever every other surface in the arc uses.
##
## Pure token/coverage invariants — read off constants + the instantiated chip, no framebuffer.

func test_coral_fill_and_ink_unchanged() -> void:
	# The fix is render (coverage), NOT a recolour: coral fill + dark token stay exactly as chosen.
	assert_eq(KennelScreen.C_PRICE_FREE, Color("ff7a85"), "«Gratis» stays coral")
	assert_eq(KennelScreen.C_TAG_INK,    Color("141c26"), "price-chip ink stays the 149 dark C_TAG_INK")

func test_gratis_ink_WASHES_without_the_outline() -> void:
	# Regression pin (mirrors 203/206): at 0.60 stroke coverage C_TAG_INK's core is a 60/40 blend over
	# the coral that renders under AA — the wash the analytic ratio hides (PO-84 measured 4.27:1).
	var ratio := DesignSystem.render_floor_contrast(KennelScreen.C_TAG_INK, KennelScreen.C_PRICE_FREE, DesignSystem.NAV_STROKE_COVERAGE)
	assert_true(ratio < 4.5,
		"C_TAG_INK on coral at 0.60 coverage WASHES under AA (pass-84 measured 4.27:1) — got %.2f:1" % ratio)

func test_gratis_ink_clears_aa_at_restored_full_coverage() -> void:
	# With the outline restoring ~full coverage, C_TAG_INK renders its true token → clears AA on the coral.
	var ratio := KennelScreen.wcag_contrast(KennelScreen.C_TAG_INK, KennelScreen.C_PRICE_FREE)
	assert_true(ratio >= 4.5,
		"outline-restored C_TAG_INK clears AA on coral (PO-84: 6.84:1) — got %.2f:1" % ratio)

func _status_chip_label(row: Dictionary) -> Label:
	# Dig the status-word Label out of the price chip: the else-branch parents it directly on the panel.
	var ks := KennelScreen.new()
	var chip: PanelContainer = ks._make_price_chip(row)
	var lbl: Label = chip.get_child(0)
	lbl.get_parent().remove_child(lbl)
	chip.free()
	ks.free()
	return lbl

func test_gratis_chip_label_carries_the_outline() -> void:
	# Secret «Gratis» (Trulte): price_shows_coin is false → status-word branch → must carry the outline.
	var lbl := _status_chip_label({"owned": false, "secret": true, "price": 0, "price_label": "Gratis"})
	assert_eq(lbl.get_theme_constant("outline_size"), KennelScreen.SOFT_INK_OUTLINE,
		"«Gratis» chip label carries the SOFT_INK_OUTLINE stroke-thickening outline")
	assert_eq(lbl.get_theme_color("font_outline_color"), KennelScreen.C_TAG_INK,
		"the outline is the same C_TAG_INK hue (thickens the stroke, does not recolour)")
	lbl.free()

func test_owned_din_chip_label_also_carries_the_outline() -> void:
	# The «Din» owned half of the same branch (suppressed in practice by 149's if-not-owned) still
	# renders its dark token via the outline — cover the branch, not just the string.
	var lbl := _status_chip_label({"owned": true, "price": 0, "price_label": "Din"})
	assert_eq(lbl.get_theme_constant("outline_size"), KennelScreen.SOFT_INK_OUTLINE,
		"owned «Din» chip label carries the outline")
	assert_eq(lbl.get_theme_color("font_outline_color"), KennelScreen.C_TAG_INK,
		"owned chip outline is C_TAG_INK")
	lbl.free()
