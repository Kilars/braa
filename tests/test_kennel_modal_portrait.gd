extends "res://tests/test_case.gd"
## TDD for the modal-header portrait framing yaw (140, PO father-pass-5). The inspect
## modal must open on a CONSISTENT front-¾ hero bust for every dog, independent of the
## grid cell's per-cell variety yaw (PORTRAIT_YAW_SPREAD, 131). These assert the contract
## that the modal framing is decoupled from the cell spread — the actual render is Visual
## Review, but the yaw-selection seam is pure logic and testable.

func test_modal_portrait_yaw_is_index_independent() -> void:
	## The modal uses ONE fixed framing yaw for every dog — tapping any cell opens the same
	## hero-bust angle. So the offset must not vary with the dog's grid index.
	var y0: float = KennelScreen.modal_portrait_yaw_offset(0)
	for i in range(1, 8):
		assert_eq(KennelScreen.modal_portrait_yaw_offset(i), y0,
			"modal portrait yaw offset is the same for every dog index (index %d)" % i)

func test_modal_portrait_yaw_is_pure_front_three_quarter() -> void:
	## The modal offset is 0.0 — pure PORTRAIT_THREE_QUARTER, the most face-on framing, with
	## NO per-cell variety delta added. This is what makes every modal a Nova/Sol-quality bust.
	assert_eq(KennelScreen.modal_portrait_yaw_offset(3), 0.0,
		"modal portrait yaw offset is 0.0 (pure front-¾, no variety delta)")

func test_modal_yaw_differs_from_side_facing_cells() -> void:
	## Proof the fix actually decouples: the modal offset must differ from the most side-facing
	## cell in the spread (the ones the PO flagged as side-profile modals — e.g. -0.40, 0.46).
	var modal_y: float = KennelScreen.modal_portrait_yaw_offset(1)
	var spread: Array = KennelScreen.PORTRAIT_YAW_SPREAD
	var most_side := 0.0
	for v in spread:
		if absf(v) > absf(most_side):
			most_side = v
	assert_true(absf(modal_y - most_side) > 0.3,
		"modal framing yaw clearly differs from the most side-facing cell yaw (%f)" % most_side)

## Find the modal header's live dog portrait TextureRect texture, or null (tint-only fallback).
func _modal_portrait_texture(ks: KennelScreen) -> Texture2D:
	var node := _find_named(ks, "ModalDogPortrait")
	return (node as TextureRect).texture if node is TextureRect else null

func _find_named(n: Node, nm: String) -> Node:
	if n.name == nm:
		return n
	for c in n.get_children():
		var f := _find_named(c, nm)
		if f != null:
			return f
	return null

func test_owned_active_dog_shares_the_same_modal_portrait_texture() -> void:
	## Pass-6 regression guard. The owned + ACTIVE dog (Bella, cell 0) must open its inspect
	## modal on the SAME dedicated front-¾ portrait as every unowned dog — coat differs only by
	## modulate. So the ModalDogPortrait TextureRect must reference the IDENTICAL shared modal
	## ViewportTexture for an owned+active dog and an unowned dog. If anyone ever re-couples the
	## owned dog to its per-cell grid texture (the pass-5/pass-6 symptom), this fails.
	var ks := KennelScreen.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(ks)
	var rows: Array = KennelDog.classify_kennel_dogs(["bella"], "bella", 0)
	ks.render(rows, 0)

	ks.open_detail("bella")     # cell 0 — owned + active (the marquee «Din hund»)
	var t_owned := _modal_portrait_texture(ks)
	ks.open_detail("nova")      # an unowned dog
	var t_unowned := _modal_portrait_texture(ks)
	ks.close_detail()

	assert_true(t_owned != null,
		"owned/active dog's modal header has a live portrait texture (not a tint-only fallback)")
	assert_true(t_owned == t_unowned,
		"owned/active dog and unowned dog share the identical dedicated modal portrait texture")

	ks.queue_free()

## Find the CURRENT modal's header band background ColorRect, or null. Searches within the
## live _modal_overlay (not the whole tree) — close_detail()'s queue_free() is deferred, so a
## prior overlay lingers in the tree for a frame; searching from the root would return its stale band.
func _modal_band_bg(ks: KennelScreen) -> ColorRect:
	if ks._modal_overlay == null:
		return null
	var node := _find_named(ks._modal_overlay, "ModalBandBg")
	return node as ColorRect

func test_modal_band_bg_uses_calm_cell_surface_not_loud_band_tint() -> void:
	## 150, PO father-pass-14 (X-4). The inspect modal's header band must paint the SAME calm
	## DS neutral surface the grid cell uses (_cell_surface, task 133) — NOT the raw saturated
	## per-dog band_tint. Otherwise a dog reads calm-neutral in the grid but garish in the modal,
	## re-introducing the "eight clashing fills" the PO removed. This guards that the band bg is
	## driven by ownership state, not the loud rarity tint.
	var ks := KennelScreen.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(ks)
	var rows: Array = KennelDog.classify_kennel_dogs(["bella"], "bella", 0)
	ks.render(rows, 0)

	# Neutral (unowned, not secret) — must be the plain Warm Sand base, NOT Nova's saturated violet.
	ks.open_detail("nova")
	var nova_bg := _modal_band_bg(ks)
	assert_true(nova_bg != null, "modal header has a ModalBandBg ColorRect")
	assert_true(nova_bg.color.is_equal_approx(ks.C_SURFACE_SAND),
		"neutral dog's modal band bg is the calm Warm Sand surface")
	assert_false(nova_bg.color.is_equal_approx(KennelDog.by_id("nova").band_tint),
		"neutral dog's modal band bg is NOT the loud per-dog band_tint")

	# Owned (Bella) — the faint green-warm owned wash, matching her grid cell.
	ks.open_detail("bella")
	assert_true(_modal_band_bg(ks).color.is_equal_approx(ks.C_SURFACE_OWNED),
		"owned dog's modal band bg is the faint owned wash (matches the grid cell)")

	# Secret (Trulte) — the faint coral egg wash, matching its grid cell.
	ks.open_detail("trulte")
	assert_true(_modal_band_bg(ks).color.is_equal_approx(ks.C_SURFACE_EGG),
		"secret dog's modal band bg is the faint egg wash (matches the grid cell)")

	ks.close_detail()
	ks.queue_free()
