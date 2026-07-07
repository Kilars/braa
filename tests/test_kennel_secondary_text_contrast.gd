extends "res://tests/test_case.gd"
## Task 156 (PO father-pass-20, X-6): the kennel's grey secondary text — the breed subtitle
## under every grid cell, the modal «Raseegenskaper» section heading, and the «Unikt trekk»
## caption — was drawn in C_MUTED (#9aa6b0), which measures 2.1–2.5:1 on its light backgrounds,
## well under WCAG AA 4.5:1. The 149→154 sweep only ever checked blue-on-light text. The fix
## repoints those C_MUTED-as-text usages to the palette's AA-clear muted ink C_INK_SOFT.
## These assert the ink clears AA on every light surface those labels draw on, that C_MUTED was
## the failing baseline, and that the actual wired labels now carry the AA-clear ink.

func test_ink_soft_clears_aa_on_every_secondary_text_surface() -> void:
	# The three light backgrounds the secondary text draws on:
	#   C_CELL          #ffffff — grid cell footer (breed subtitle)
	#   C_MODAL_SURFACE #fbfbf7 — modal body (section heading)
	#   C_MODAL_CREAM   #f4efe6 — Unikt-trekk card (caption)
	var surfaces := [KennelScreen.C_CELL, KennelScreen.C_MODAL_SURFACE, KennelScreen.C_MODAL_CREAM]
	for bg in surfaces:
		var ratio := KennelScreen.wcag_contrast(KennelScreen.C_INK_SOFT, bg)
		assert_true(ratio >= 4.5, "C_INK_SOFT must clear AA 4.5:1 on secondary-text surface %s (got %.2f)" % [bg, ratio])

func test_muted_was_the_failing_baseline() -> void:
	# Document the defect: C_MUTED failed AA on all three surfaces (the 2.1–2.5:1 the PO measured).
	var surfaces := [KennelScreen.C_CELL, KennelScreen.C_MODAL_SURFACE, KennelScreen.C_MODAL_CREAM]
	for bg in surfaces:
		assert_true(KennelScreen.wcag_contrast(KennelScreen.C_MUTED, bg) < 3.0,
			"C_MUTED-as-text was the sub-3:1 baseline on %s" % bg)

func test_ink_soft_stays_muted_below_the_title_ink() -> void:
	# The fix must preserve the hierarchy — C_INK_SOFT stays quieter than the C_INK title.
	var soft_on_white := KennelScreen.wcag_contrast(KennelScreen.C_INK_SOFT, KennelScreen.C_CELL)
	var ink_on_white  := KennelScreen.wcag_contrast(KennelScreen.C_INK, KennelScreen.C_CELL)
	assert_true(soft_on_white < ink_on_white,
		"C_INK_SOFT secondary text stays lower-contrast than the C_INK title (soft %.2f < ink %.2f)" % [soft_on_white, ink_on_white])

func test_breed_subtitle_label_carries_aa_clear_ink() -> void:
	# Wiring assertion: the actual footer breed label must render with an AA-clear ink on C_CELL.
	var ks := KennelScreen.new()
	var row := {"name": "Bella", "breed": "Labrador retriever", "owned": true}
	var footer: PanelContainer = ks._make_footer(row)
	var col: VBoxContainer = footer.get_child(0)
	var breed_lbl: Label = col.get_child(1)   # child 0 = name (C_INK), child 1 = breed subtitle
	var col_used: Color = breed_lbl.get_theme_color("font_color")
	var ratio := KennelScreen.wcag_contrast(col_used, KennelScreen.C_CELL)
	assert_true(ratio >= 4.5,
		"breed subtitle label ink must clear AA on the white cell footer (got %.2f)" % ratio)
	footer.free()
	ks.free()
