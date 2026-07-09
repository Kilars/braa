extends "res://tests/test_case.gd"
## TDD for task 199 (PO father-pass-74 X-6). The owned green ownership corner badge must read the
## SAME word on both surfaces — the grid cell drew «Din hund» while the inspect modal forced the
## rarity_label path and rendered «Din». Same class of drift the 198 «Trener nå» tint-unify closed.
## The badge word is a pure seam through _make_tag, so it is testable without a Visual Review.

func _find_named(n: Node, nm: String) -> Node:
	if n.name == nm:
		return n
	for c in n.get_children():
		var f := _find_named(c, nm)
		if f != null:
			return f
	return null

## The text of the first Label under the CURRENT modal's corner status badge, or "" if none.
## Searches the live _modal_overlay only (close_detail's queue_free is deferred → a stale prior
## overlay lingers a frame; searching from root could return its badge).
func _modal_badge_text(ks: KennelScreen) -> String:
	if ks._modal_overlay == null:
		return ""
	var tag := _find_named(ks._modal_overlay, "StatusTag")
	if tag == null:
		return ""
	var lbl := _find_first_label(tag)
	return lbl.text if lbl != null else ""

func _find_first_label(n: Node) -> Label:
	if n is Label:
		return n as Label
	for c in n.get_children():
		var f := _find_first_label(c)
		if f != null:
			return f
	return null

func test_owned_modal_badge_reads_din_hund_like_the_grid() -> void:
	## Bella is owned (cell 0). Her grid cell badge draws from status_label = «Din hund»; the modal
	## must read the IDENTICAL ownership word, not «Din». Pinned to the row's own status_label so
	## the two surfaces are sourced from one field and can never drift again (the DS-unify point).
	var ks := KennelScreen.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(ks)
	var rows: Array = KennelDog.classify_kennel_dogs(["bella"], "bella", 0)
	ks.render(rows, 0)

	ks.open_detail("bella")
	var modal_word := _modal_badge_text(ks)
	ks.close_detail()

	assert_eq(modal_word, "Din hund",
		"owned dog's modal corner badge reads «Din hund», the same ownership word as the grid cell")
	assert_eq(modal_word, str(rows[0]["status_label"]),
		"owned modal badge is sourced from the row's status_label (one source, grid ↔ modal can't drift)")

	ks.queue_free()

func test_status_label_helper_is_the_single_source() -> void:
	## The one function both the grid cell and the modal read the ownership/status word from.
	assert_eq(KennelDog.status_label(true, false), "Din hund", "owned → «Din hund»")
	assert_eq(KennelDog.status_label(false, true), "Påskeegg", "secret → «Påskeegg»")
	assert_eq(KennelDog.status_label(false, false), "", "buyable → \"\" (falls through to rarity word)")

func test_secret_and_buyable_modal_badges_are_unchanged() -> void:
	## Regression guard: the fix touches only the owned case. Secret keeps «Påskeegg» (its status
	## word, already on both surfaces) and a buyable keeps its rarity word «Episk» in the modal.
	var ks := KennelScreen.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(ks)
	var rows: Array = KennelDog.classify_kennel_dogs(["bella"], "bella", 0)
	ks.render(rows, 0)

	ks.open_detail("trulte")     # SECRET
	assert_eq(_modal_badge_text(ks), "Påskeegg",
		"secret dog's modal badge still reads «Påskeegg» (unchanged)")

	ks.open_detail("nova")       # EPIC buyable
	assert_eq(_modal_badge_text(ks), "Episk",
		"a buyable dog's modal badge still reads its rarity word «Episk» (unchanged)")

	ks.close_detail()
	ks.queue_free()
