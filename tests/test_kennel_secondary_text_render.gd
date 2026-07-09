extends "res://tests/test_case.gd"
## Task 203 (PO father-pass-80, X-6): the kennel's grey C_INK_SOFT secondary tier — grid breed
## subtitles, the header subtitle, and the modal stat labels / section headings / «Kan lære» — renders
## WASHED under WCAG AA in the shipped 390×844 SwiftShader pixels. SAME thin-stroke sub-pixel
## under-coverage tasks 200 (nav pills) / 201 (learned readout) / 202 (completion menu) fixed, never
## applied to kennel_screen.gd (the last high-traffic surface on the bare no-outline Label path). At
## 13px Nunito a Label with no outline_size reaches only ~NAV_STROKE_COVERAGE (0.60) coverage, so the
## analytically-AA C_INK_SOFT (~4.78:1, the token task 156 chose) renders a 0.60/0.40 ink-over-fill
## blend: the grid subtitles measured 1.65–1.78:1, «Kan lære» 1.38:1 — UNDER AA, though the analytic
## ratio (test_kennel_secondary_text_contrast) passes. 203 adds the proven same-colour outline
## (outline_size + font_outline_color via one _apply_soft_ink helper) so every C_INK_SOFT Label
## renders its true token.
##
## Pure token/coverage invariants — read off constants + one instantiated label, no framebuffer.

# The three light fills the C_INK_SOFT secondary text draws on (mirrors task 156's surface list).
func _secondary_fills() -> Array:
	return [
		["grid cell footer",  KennelScreen.C_CELL],
		["modal body",        KennelScreen.C_MODAL_SURFACE],
		["Unikt-trekk card",  KennelScreen.C_MODAL_CREAM],
	]

func test_ink_soft_hue_unchanged() -> void:
	# The fix is render (coverage), NOT a recolour: C_INK_SOFT stays the muted grey task 156 chose.
	# Guards a "just darken it" edit that would kill the title/subtitle hierarchy.
	assert_eq(KennelScreen.C_INK_SOFT, Color("5a6b7d"), "secondary text stays the 156 muted C_INK_SOFT")

func test_ink_soft_WASHES_without_the_outline() -> void:
	# The measured defect (regression pin, mirrors 202): at 0.60 stroke coverage C_INK_SOFT's core is a
	# 60/40 blend over its fill that renders under AA — the wash the analytic ratio hides. This is why
	# the stroke-thickening outline (not a recolour) is the required lever.
	for fill in _secondary_fills():
		var ratio := DesignSystem.render_floor_contrast(KennelScreen.C_INK_SOFT, fill[1], DesignSystem.NAV_STROKE_COVERAGE)
		assert_true(ratio < 4.5,
			"C_INK_SOFT on %s at 0.60 coverage WASHES under AA (pass-80 measured 1.4–2.9:1) — got %.2f:1" % [fill[0], ratio])

func test_secondary_text_carries_a_stroke_thickening_outline() -> void:
	# The decisive lever (same as 200/201/202): a same-colour outline raises effective coverage to ~full
	# so every C_INK_SOFT Label renders its true token. Pin it > 0 so a future edit can't silently drop it
	# and re-wash the kennel. Matches HUD_NAV_LABEL_OUTLINE / LearnedBar.LABEL_OUTLINE / ROW_LABEL_OUTLINE (4).
	assert_true(KennelScreen.SOFT_INK_OUTLINE > 0,
		"the kennel secondary text carries a stroke-thickening outline (got %d)" % KennelScreen.SOFT_INK_OUTLINE)

func test_ink_soft_clears_aa_at_restored_full_coverage() -> void:
	# With the outline restoring ~full coverage, C_INK_SOFT renders its true token, which clears AA on
	# every secondary-text surface (the ~4.78:1 the 156 token already guarantees analytically).
	for fill in _secondary_fills():
		var ratio := KennelScreen.wcag_contrast(KennelScreen.C_INK_SOFT, fill[1])
		assert_true(ratio >= 4.5,
			"outline-restored C_INK_SOFT clears AA on %s (got %.2f:1)" % [fill[0], ratio])

func test_wired_footer_breed_label_carries_the_outline() -> void:
	# Wiring assertion: the actual grid footer breed label must carry the same-colour outline so its
	# render is thickened to ~full coverage — a real in-tree guard that _apply_soft_ink reached this label.
	var ks := KennelScreen.new()
	var row := {"name": "Bella", "breed": "Labrador retriever", "owned": true}
	var footer: PanelContainer = ks._make_footer(row)
	var col: VBoxContainer = footer.get_child(0)
	var breed_lbl: Label = col.get_child(1)   # child 0 = name (C_INK), child 1 = breed subtitle
	assert_eq(breed_lbl.get_theme_constant("outline_size"), KennelScreen.SOFT_INK_OUTLINE,
		"footer breed subtitle carries the SOFT_INK_OUTLINE stroke-thickening outline")
	assert_eq(breed_lbl.get_theme_color("font_outline_color"), KennelScreen.C_INK_SOFT,
		"the outline is the same C_INK_SOFT hue (thickens the stroke, does not recolour)")
	footer.free()
	ks.free()
