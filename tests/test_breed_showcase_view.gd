extends "res://tests/test_case.gd"
## Chrome-level guard for the spotlit breed showcase view (089, PO 2026-07-03 Bugfix 1). The pure model
## is pinned by test_breed_showcase.gd; this pins that the DUMB VIEW renders NO missing-glyph "tofu" box.
##
## `◀`/`▶` (U+25C0/U+25B6) are not in the project font, so the 087 cycle buttons + the hint line drew
## broken boxes on the deployed GL build — the same tofu class 069 fixed by DRAWING the coin. The fix
## draws the chevron instead and rewords the hint, so no showcase chrome text may carry either glyph.

const TOFU := ["◀", "▶"]  # ◀ ▶ — absent from the project font (render as tofu)

func _build_view() -> BreedShowcaseView:
	var view := BreedShowcaseView.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(view)
	if not view.is_node_ready():
		view._ready()
	view.render([{"id": "labrador", "name": "Labrador", "tint": Color(1, 1, 1)}], "labrador", "labrador")
	return view

func _collect_text(node: Node, out: Array) -> void:
	if node is Label:
		out.append((node as Label).text)
	elif node is Button:
		out.append((node as Button).text)
	for c in node.get_children():
		_collect_text(c, out)

func test_no_tofu_glyph_in_any_showcase_text() -> void:
	## No Label/Button text anywhere in the built chrome carries U+25C0/U+25B6 — the missing-glyph boxes.
	var view := _build_view()
	var texts: Array = []
	_collect_text(view, texts)
	assert_true(texts.size() > 0, "the built showcase renders some chrome text (title/hint at least)")
	for t in texts:
		for glyph in TOFU:
			assert_false(String(t).contains(glyph),
				"showcase chrome must not render the tofu glyph '%s' (found in '%s')" % [glyph, t])
	view.queue_free()

func test_shows_individual_name_with_breed_subtitle() -> void:
	# 173 (PO father-pass-38 X-4): the spotlit entry surfaces its individual kennel name (Bella) with
	# the breed (Labrador) rendered beneath as a subtitle — so the "show off MY dog" surface names her
	# like the kennel does, not by her breed.
	var view := BreedShowcaseView.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(view)
	if not view.is_node_ready():
		view._ready()
	view.render([{"id": "labrador", "name": "Bella", "subtitle": "Labrador", "tint": Color(1, 1, 1)}],
		"labrador", "labrador")
	var texts: Array = []
	_collect_text(view, texts)
	var joined := " | ".join(PackedStringArray(texts))
	assert_true(joined.contains("Bella"), "the individual name «Bella» is rendered (name/pip)")
	assert_true(joined.contains("Labrador"), "the breed «Labrador» is rendered as the subtitle")
	view.queue_free()

func test_no_subtitle_when_name_is_the_breed() -> void:
	# A breed with no kennel individual feeds subtitle "" — the subtitle line stays empty (no phantom
	# second line duplicating the name).
	var view := BreedShowcaseView.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(view)
	if not view.is_node_ready():
		view._ready()
	view.render([{"id": "chocolate_labrador", "name": "Brun lab", "subtitle": "", "tint": Color(1, 1, 1)}],
		"chocolate_labrador", "chocolate_labrador")
	assert_eq(view._subtitle_of("chocolate_labrador"), "",
		"a breed with no individual name renders an empty subtitle")
	view.queue_free()

func test_cycle_buttons_draw_a_chevron_not_a_glyph() -> void:
	## The prev/next cycle buttons carry NO glyph text — the affordance is a drawn chevron child instead.
	var view := _build_view()
	assert_eq(view._prev_btn.text, "", "the prev cycle button carries no glyph text (chevron is drawn)")
	assert_eq(view._next_btn.text, "", "the next cycle button carries no glyph text (chevron is drawn)")
	assert_ne(view._prev_btn.get_node_or_null("Chevron"), null, "the prev button mounts a drawn Chevron")
	assert_ne(view._next_btn.get_node_or_null("Chevron"), null, "the next button mounts a drawn Chevron")
	view.queue_free()

## --- 164 (PO father-pass-29): a single-dog roster must not show active-looking dead chevrons ---
## nor a hint that instructs their (no-op) use. The ◀ ▶ chevrons only cycle OWNED breeds, so with
## one owned dog they are verified no-ops; make the state honest below ≤1 breed, active at 2+.

func test_chevrons_active_only_with_more_than_one_breed() -> void:
	## Pure predicate: chevrons cycle only when there is more than one owned breed to cycle between.
	assert_false(BreedShowcaseView.chevrons_active(0), "no owned breeds → no live chevrons")
	assert_false(BreedShowcaseView.chevrons_active(1), "one owned breed → nothing to cycle → no live chevrons")
	assert_true(BreedShowcaseView.chevrons_active(2), "two owned breeds → chevrons cycle")
	assert_true(BreedShowcaseView.chevrons_active(5), "several owned breeds → chevrons cycle")

func test_single_dog_hint_does_not_instruct_arrow_use() -> void:
	## The single-dog hint must NOT tell the player to "bla med pilene" (use the arrows) — the arrows are gone.
	var single := BreedShowcaseView.hint_text(1)
	assert_false(single.to_lower().contains("pilene"),
		"single-dog hint must not instruct arrow use (was '%s')" % single)
	assert_true(single.length() > 0, "single-dog hint is still a real line")
	var multi := BreedShowcaseView.hint_text(2)
	assert_true(multi.to_lower().contains("pilene"), "multi-dog hint still invites the arrows (was '%s')" % multi)

func test_single_dog_view_hides_cycle_chevrons() -> void:
	## A rendered one-owned-dog showcase draws no active chevrons.
	var view := _build_view()  # _build_view renders exactly one owned breed (labrador)
	assert_false(view._prev_btn.visible, "single-dog showcase hides the ◀ prev chevron")
	assert_false(view._next_btn.visible, "single-dog showcase hides the ▶ next chevron")
	view.queue_free()

func test_multi_dog_view_shows_cycle_chevrons() -> void:
	## A rendered two-owned-dog showcase keeps both chevrons live.
	var view := _build_two_dog_view("labrador", "labrador")
	assert_true(view._prev_btn.visible, "two-dog showcase shows the ◀ prev chevron")
	assert_true(view._next_btn.visible, "two-dog showcase shows the ▶ next chevron")
	view.queue_free()

## --- Task 165 (PO father-pass-30): the SPOTLIT (previewed) pip is the dominant selection; the
## ACTIVE dog gets a quieter marker — not the reverse. The pip fill was keyed to `active` and the
## spotlit cue was an invisible outline, so previewing a non-active dog pulled the eye to the wrong
## (active) pip. Below pins the fill to spotlit + a quiet drawn "aktiv" dot on the active pip.

func _build_two_dog_view(spotlit: String, active: String) -> BreedShowcaseView:
	var view := BreedShowcaseView.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(view)
	if not view.is_node_ready():
		view._ready()
	view.render([
		{"id": "labrador", "name": "Labrador", "tint": Color(1, 1, 1)},
		{"id": "chocolate_labrador", "name": "Brun lab", "tint": Color(0.7, 0.5, 0.3)},
	], spotlit, active)
	return view

func _pip_named(view: BreedShowcaseView, name: String) -> Button:
	for c in view._pips.get_children():
		if c is Button and (c as Button).text == name:
			return c as Button
	return null

func test_spotlit_pip_is_the_solid_dominant_fill() -> void:
	## Previewing the non-active «Brun lab»: ITS pip carries the solid bright fill (the selection),
	## while the active «Labrador» pip is the faint one — not the reverse (the pass-30 defect).
	var view := _build_two_dog_view("chocolate_labrador", "labrador")
	var spot := _pip_named(view, "Brun lab")
	var act := _pip_named(view, "Labrador")
	assert_ne(spot, null, "the spotlit pip exists")
	assert_ne(act, null, "the active pip exists")
	assert_eq(spot.get_theme_stylebox("normal").bg_color, BreedShowcaseView.PIP_ON,
		"the SPOTLIT pip carries the solid dominant fill")
	assert_eq(act.get_theme_stylebox("normal").bg_color, BreedShowcaseView.PIP_OFF,
		"the non-spotlit ACTIVE pip is the faint one (not the dominant fill)")
	view.queue_free()

func test_active_pip_carries_a_quiet_active_marker() -> void:
	## The active dog is still flagged — a small drawn dot — but quietly, so it never competes with
	## the spotlit selection. The spotlit-but-not-active pip carries NO such marker.
	var view := _build_two_dog_view("chocolate_labrador", "labrador")
	var act := _pip_named(view, "Labrador")
	var spot := _pip_named(view, "Brun lab")
	assert_ne(act.get_node_or_null("ActiveDot"), null, "the active dog's pip mounts a quiet active marker")
	assert_eq(spot.get_node_or_null("ActiveDot"), null, "the non-active spotlit pip carries no active marker")
	view.queue_free()

## --- Task 184 (PO father-pass-57 X-6): the active-dog commit label unifies onto the kennel
## «Trener nå» status word — «Trener denne» diverged from the kennel modal (151) / trick-menu
## ACTIVE (152) for the identical "currently training this dog" state. Copy unification only. ---

func test_active_commit_label_is_trener_na() -> void:
	## The active dog's non-tappable commit label reads the SAME status word the kennel modal +
	## trick-menu ACTIVE row use — «Trener nå» — not the old divergent «Trener denne».
	assert_eq(BreedShowcaseView.commit_label(true), "Trener nå",
		"active-dog label unifies onto «Trener nå» (matches TrickMenu.BADGE[ACTIVE] + kennel modal)")
	assert_eq(BreedShowcaseView.commit_label(true), TrickMenu.BADGE[TrickMenu.State.ACTIVE],
		"showcase active label is literally the same status word as the trick-menu ACTIVE badge")

func test_inactive_commit_label_is_the_switch_action() -> void:
	## The enabled (non-active) label stays the «Tren denne» switch ACTION — unchanged.
	assert_eq(BreedShowcaseView.commit_label(false), "Tren denne",
		"non-active dog keeps the «Tren denne» switch action label")

func test_rendered_active_commit_button_reads_trener_na() -> void:
	## End-to-end: a rendered showcase on the active dog shows «Trener nå» on the disabled commit button.
	var view := _build_view()  # renders one owned breed, spotlit == active
	assert_true(view._commit_btn.disabled, "spotlit==active → commit button is the non-tappable status")
	assert_eq(view._commit_btn.text, "Trener nå", "the rendered active commit button reads «Trener nå»")
	view.queue_free()

func test_spotlit_equals_active_pip_reads_as_both() -> void:
	## Default single-active view (spotlit == active): the pip is BOTH the solid dominant fill AND
	## carries the active marker — it reads cleanly as the selected AND active dog at once.
	var view := _build_two_dog_view("labrador", "labrador")
	var pip := _pip_named(view, "Labrador")
	assert_eq(pip.get_theme_stylebox("normal").bg_color, BreedShowcaseView.PIP_ON,
		"the spotlit==active pip is the solid dominant fill")
	assert_ne(pip.get_node_or_null("ActiveDot"), null, "and still carries the active marker")
	view.queue_free()
