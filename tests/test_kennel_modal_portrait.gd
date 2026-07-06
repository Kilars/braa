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
