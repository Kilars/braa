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

func test_cycle_buttons_draw_a_chevron_not_a_glyph() -> void:
	## The prev/next cycle buttons carry NO glyph text — the affordance is a drawn chevron child instead.
	var view := _build_view()
	assert_eq(view._prev_btn.text, "", "the prev cycle button carries no glyph text (chevron is drawn)")
	assert_eq(view._next_btn.text, "", "the next cycle button carries no glyph text (chevron is drawn)")
	assert_ne(view._prev_btn.get_node_or_null("Chevron"), null, "the prev button mounts a drawn Chevron")
	assert_ne(view._next_btn.get_node_or_null("Chevron"), null, "the next button mounts a drawn Chevron")
	view.queue_free()
