extends "res://tests/test_case.gd"
## Task 202 (PO father-pass-79, X-6): the completion-menu ROW text tier (trick names, breed names,
## the «Labrador» breed subtitle) renders WASHED under WCAG AA in the shipped 390×844 SwiftShader
## pixels — the SAME thin-stroke sub-pixel under-coverage tasks 200 (nav pills) / 201 (learned
## readout) fixed, never applied to trick_menu.gd (the last high-traffic surface on the bare
## draw_string path). At the row sizes (13–26px Nunito) draw_string reaches only ~NAV_STROKE_COVERAGE
## (0.60) coverage, so an analytically-AA token renders a 0.60/0.40 ink-over-fill blend: the «Labrador»
## subtitle (SLATE) measured 1.58:1, the active «Sitt» name (ROW_ACTIVE_INK) 3.64:1 — UNDER AA,
## though the analytic ratio (test_trick_menu_contrast) passes. 202 adds the proven stroke-thickening
## outline (draw_string_outline inside _draw_text) so every row renders its true token.
##
## Pure token/coverage invariants — read off preloaded constants, no scene boot / framebuffer.

# Row-name/subtitle-tier tokens paired with the fill they actually sit on.
func _row_tokens_on_fill() -> Array:
	return [
		["ROW_ACTIVE_INK (active «Sitt» name)", TrickMenu.ROW_ACTIVE_INK, TrickMenu.ROW_BG_ACTIVE],
		["NAME_LEARNED",        TrickMenu.NAME_LEARNED,        TrickMenu.ROW_BG],
		["NAME_AVAILABLE",      TrickMenu.NAME_AVAILABLE,      TrickMenu.ROW_BG],
		["BREED_NAME_OWNED",    TrickMenu.BREED_NAME_OWNED,    TrickMenu.ROW_BG],
		["BREED_NAME_BUYABLE",  TrickMenu.BREED_NAME_BUYABLE,  TrickMenu.ROW_BG],
		["WORD_COST_HINT («Labrador» subtitle)", TrickMenu.WORD_COST_HINT, TrickMenu.ROW_BG_ACTIVE],
	]

func test_row_tokens_unchanged() -> void:
	# The fix is render (coverage), NOT a recolour: the active name stays the 170 ROW_ACTIVE_INK, the
	# learned name the 154 BLUE_INK, available/owned/buyable stay SLATE. Guards a "just darken it" edit.
	assert_eq(TrickMenu.ROW_ACTIVE_INK, Color("141c26"), "active row name stays the dark ROW_ACTIVE_INK")
	assert_eq(TrickMenu.NAME_LEARNED, DesignSystem.BLUE_INK, "learned name stays the 154 BLUE_INK")
	assert_eq(TrickMenu.NAME_AVAILABLE, DesignSystem.SLATE, "available name stays SLATE")
	assert_eq(TrickMenu.BREED_NAME_BUYABLE, DesignSystem.SLATE, "buyable breed name stays SLATE")

func test_row_text_WASHES_without_the_outline() -> void:
	# The measured defect (regression pin, mirrors 201): at 0.60 stroke coverage each row token's core
	# is a 60/40 blend over its fill that renders under AA — the wash the analytic ratio hides. This is
	# why the stroke-thickening outline (not a recolour) is the required lever.
	for row in _row_tokens_on_fill():
		var ratio := DesignSystem.render_floor_contrast(row[1], row[2], DesignSystem.NAV_STROKE_COVERAGE)
		assert_true(ratio < 4.5,
			"%s at 0.60 coverage WASHES under AA (pass-79 measured 1.6–3.6:1) — got %.2f:1" % [row[0], ratio])

func test_rows_carry_a_stroke_thickening_outline() -> void:
	# The decisive lever (same as 200/201): a same-colour outline via draw_string_outline inside
	# _draw_text raises effective coverage to ~full so every row renders its true token. Pin it > 0 so a
	# future edit can't silently drop it and re-wash the menu. Matches HUD_NAV_LABEL_OUTLINE / LABEL_OUTLINE.
	assert_true(TrickMenu.ROW_LABEL_OUTLINE > 0,
		"the menu rows carry a stroke-thickening outline (got %d)" % TrickMenu.ROW_LABEL_OUTLINE)

func test_active_and_learned_names_clear_aa_at_restored_full_coverage() -> void:
	# With the outline restoring ~full coverage, the dark active name + blue learned name render their
	# true tokens, clearing AA with margin on their fills.
	var active := DesignSystem.wcag_contrast(TrickMenu.ROW_ACTIVE_INK, TrickMenu.ROW_BG_ACTIVE)
	assert_true(active >= 4.5, "outline-restored active «Sitt» name clears AA on its wash (got %.2f:1)" % active)
	var learned := DesignSystem.wcag_contrast(TrickMenu.NAME_LEARNED, TrickMenu.ROW_BG)
	assert_true(learned >= 4.5, "outline-restored learned name clears AA on CREAM (got %.2f:1)" % learned)

func test_slate_row_text_clears_aa_at_restored_full_coverage() -> void:
	# The SLATE available/owned/buyable names + the «Labrador» subtitle also wash at 0.60 coverage; the
	# same outline restores them to their true SLATE token, which clears AA on both menu fills.
	assert_true(DesignSystem.wcag_contrast(DesignSystem.SLATE, TrickMenu.ROW_BG) >= 4.5,
		"outline-restored SLATE row name clears AA on CREAM")
	assert_true(DesignSystem.wcag_contrast(DesignSystem.SLATE, TrickMenu.ROW_BG_ACTIVE) >= 4.5,
		"outline-restored SLATE «Labrador» subtitle clears AA on the active wash")

func test_locked_rows_stay_intentionally_soft() -> void:
	# The locked-row names stay the intentionally-greyed SLATE_SOFT (disabled styling, WCAG-exempt) —
	# the outline restores their true render but must not recolour them into looking selectable.
	assert_eq(TrickMenu.NAME_LOCKED, DesignSystem.SLATE_SOFT, "locked trick name stays SLATE_SOFT")
	assert_eq(TrickMenu.BREED_NAME_LOCKED, DesignSystem.SLATE_SOFT, "locked breed name stays SLATE_SOFT")
