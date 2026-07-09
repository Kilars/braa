extends "res://tests/test_case.gd"
## Task 206 (PO father-pass-83, X-6): the kennel rarity/owned CORNER BADGE labels — «Din hund» green,
## «Episk» violet, «Sjelden» blue, «Vanlig» slate, «Påskeegg» coral — render WASHED under WCAG AA in
## the shipped 390×844 SwiftShader pixels. They are the LAST un-outlined dark-token text left by the
## whole 200→205 arc: `_make_tag` sets font_color = C_TAG_INK but never an outline, so at 10px bold
## Nunito the strokes reach only ~NAV_STROKE_COVERAGE (0.60) coverage and the analytically-AA dark ink
## (149: green ~6.9:1, violet ~5.1:1, blue ~5.2:1) renders a mid-tone blend the PO measured at 1.7–1.8:1.
## 206 routes both badge Labels through the same _apply_ink_outline(C_TAG_INK) lever the arc used
## everywhere else. Grid + modal share this one _make_tag, so both wash — and both — fix from one cause.
##
## Pure token/coverage invariants — read off constants + instantiated tags, no framebuffer.

# The three darker accents the PO measured well under AA (green owned, blue rare, violet epic).
func _dark_accents() -> Array:
	return [
		["owned green",  KennelScreen.C_STATUS_OWNED],
		["rare blue",    KennelScreen.C_RARITY_RARE],
		["epic violet",  KennelScreen.C_RARITY_EPIC],
	]

# Every accent a badge label draws on (adds the lighter slate/coral fills).
func _all_accents() -> Array:
	return _dark_accents() + [
		["common slate", KennelScreen.C_STATUS_NEUTRAL],
		["egg coral",    KennelScreen.C_STATUS_EGG],
	]

func test_badge_accents_hues_unchanged() -> void:
	# The fix is render (coverage), NOT a recolour: the accent identity stays exactly as 148/149 chose.
	assert_eq(KennelScreen.C_STATUS_OWNED, Color("57b85c"), "owned stays green")
	assert_eq(KennelScreen.C_RARITY_RARE,  Color("5b8fd0"), "rare stays blue")
	assert_eq(KennelScreen.C_RARITY_EPIC,  Color("9b7bd4"), "epic stays violet")
	assert_eq(KennelScreen.C_TAG_INK,      Color("141c26"), "badge ink stays the 149 dark C_TAG_INK")

func test_badge_ink_WASHES_without_the_outline() -> void:
	# The measured defect (regression pin, mirrors 203): at 0.60 stroke coverage C_TAG_INK's core is a
	# 60/40 blend over each accent that renders under AA — the wash the analytic ratio (149) hides.
	for a in _dark_accents():
		var ratio := DesignSystem.render_floor_contrast(KennelScreen.C_TAG_INK, a[1], DesignSystem.NAV_STROKE_COVERAGE)
		assert_true(ratio < 4.5,
			"C_TAG_INK on %s at 0.60 coverage WASHES under AA (pass-83 measured 1.7–1.8:1) — got %.2f:1" % [a[0], ratio])

func test_badge_outline_is_wired_positive() -> void:
	# The decisive lever (same as 200–205): a same-colour outline raises effective coverage to ~full.
	# Pin it > 0 so a future edit can't silently drop it and re-wash the badges.
	assert_true(KennelScreen.SOFT_INK_OUTLINE > 0,
		"the badge labels carry a stroke-thickening outline (got %d)" % KennelScreen.SOFT_INK_OUTLINE)

func test_badge_ink_clears_aa_at_restored_full_coverage() -> void:
	# With the outline restoring ~full coverage, C_TAG_INK renders its true token, which clears AA on
	# every badge accent (the 5–7:1 the 149 token already guarantees analytically).
	for a in _all_accents():
		var ratio := KennelScreen.wcag_contrast(KennelScreen.C_TAG_INK, a[1])
		assert_true(ratio >= 4.5,
			"outline-restored C_TAG_INK clears AA on %s (got %.2f:1)" % [a[0], ratio])

func _badge_label(row: Dictionary) -> Label:
	# Dig the badge Label out of the tag built by _make_tag: secret rows nest it in an HBox after the
	# star pip; every other row parents it directly on the PanelContainer.
	var ks := KennelScreen.new()
	var tag: PanelContainer = ks._make_tag(row)
	var lbl: Label
	if row.get("secret", false):
		var hbox: HBoxContainer = tag.get_child(0)
		lbl = hbox.get_child(1)   # child 0 = StarPip, child 1 = label
	else:
		lbl = tag.get_child(0)
	# Detach + free scaffolding; keep the label reference alive for the caller.
	lbl.get_parent().remove_child(lbl)
	tag.free()
	ks.free()
	return lbl

func test_buyable_badge_label_carries_the_outline() -> void:
	# Buyable/owned branch (line ~1016): rarity word must render its true dark token via the outline.
	var lbl := _badge_label({"name": "Nova", "owned": false, "secret": false,
		"rarity": KennelDog.Rarity.EPIC, "rarity_label": "Episk", "status_label": ""})
	assert_eq(lbl.get_theme_constant("outline_size"), KennelScreen.SOFT_INK_OUTLINE,
		"buyable rarity badge carries the SOFT_INK_OUTLINE stroke-thickening outline")
	assert_eq(lbl.get_theme_color("font_outline_color"), KennelScreen.C_TAG_INK,
		"the outline is the same C_TAG_INK hue (thickens the stroke, does not recolour)")
	lbl.free()

func test_owned_badge_label_carries_the_outline() -> void:
	var lbl := _badge_label({"name": "Bella", "owned": true, "secret": false,
		"rarity": KennelDog.Rarity.COMMON, "rarity_label": "Vanlig", "status_label": "Din hund"})
	assert_eq(lbl.get_theme_constant("outline_size"), KennelScreen.SOFT_INK_OUTLINE,
		"owned «Din hund» badge carries the outline")
	assert_eq(lbl.get_theme_color("font_outline_color"), KennelScreen.C_TAG_INK,
		"owned badge outline is C_TAG_INK")
	lbl.free()

func test_secret_star_pip_badge_label_carries_the_outline() -> void:
	# Secret branch (line ~1008): the «Påskeegg» label beside the star pip must ALSO carry the outline.
	var lbl := _badge_label({"name": "Trulte", "owned": false, "secret": true,
		"rarity": KennelDog.Rarity.SECRET, "rarity_label": "", "status_label": "Påskeegg"})
	assert_eq(lbl.get_theme_constant("outline_size"), KennelScreen.SOFT_INK_OUTLINE,
		"secret «Påskeegg» badge carries the outline")
	assert_eq(lbl.get_theme_color("font_outline_color"), KennelScreen.C_TAG_INK,
		"secret badge outline is C_TAG_INK")
	lbl.free()
