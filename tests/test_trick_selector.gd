extends "res://tests/test_case.gd"
## The trick selector (066, P2-1 "Pick a trick"). TrickSelector is a dumb renderer + hit-map, the
## same pure/render-free split LearnedBar/TierReadout use: main decides the entries + which trick is
## current, this node draws one chip per trick and maps a tap x-position to a trick id, emitting
## `trick_selected`. These pin the id→name mapping, the x→chip hit-map, and the press-only signal
## render-free (public fields + a constructed InputEvent — no framebuffer). The routing INTO main
## (repointing _current_trick / _progress) is proven separately in test_trick_selector_wiring.gd.

func _entry(id: String, value := 0.0, mastered := false) -> Dictionary:
	return {"id": id, "value": value, "mastered": mastered}

func _selector(entries: Array, current: String, w := 600.0) -> TrickSelector:
	var s := TrickSelector.new()
	s.size = Vector2(w, TrickSelector.HEIGHT)  # headless: no layout pass, so pin the size the hit-map reads
	s.set_entries(entries, current)
	return s

func test_display_name_maps_the_wired_trick_ids() -> void:
	assert_eq(TrickSelector.display_name(DogClips.TRICK_SITT), "Sitt", "Sitt reads as Sitt")
	assert_eq(TrickSelector.display_name(DogClips.TRICK_LIGG), "Ligg", "Ligg reads as Ligg")
	assert_eq(TrickSelector.display_name(DogClips.TRICK_LEGG_DEG), "Legg deg", "Legg deg reads as two words")

func test_set_entries_records_current_and_count() -> void:
	var s := _selector([_entry("sitt"), _entry("ligg"), _entry("legg_deg")], "ligg")
	assert_eq(s.entry_count(), 3, "three chips for a three-trick roster")
	assert_eq(s.current_id(), "ligg", "the current trick is the one main selected")
	s.free()

func test_id_at_maps_x_to_the_chip_under_it() -> void:
	var s := _selector([_entry("sitt"), _entry("ligg"), _entry("legg_deg")], "sitt", 600.0)
	assert_eq(s.id_at(10.0), "sitt", "left third → first chip")
	assert_eq(s.id_at(310.0), "ligg", "middle third → second chip")
	assert_eq(s.id_at(590.0), "legg_deg", "right third → third chip")
	s.free()

func test_id_at_is_blank_with_no_entries() -> void:
	var s := _selector([], "", 600.0)
	assert_eq(s.id_at(100.0), "", "no chips → nothing to hit")
	s.free()

func test_left_click_emits_the_hit_trick() -> void:
	var s := _selector([_entry("sitt"), _entry("ligg"), _entry("legg_deg")], "sitt", 600.0)
	var got := {"id": ""}
	s.trick_selected.connect(func(id): got.id = id)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(310.0, 10.0)  # middle chip → ligg
	s._gui_input(ev)
	assert_eq(got.id, "ligg", "tapping a chip emits its trick id (the selection routes to main)")
	s.free()

func test_release_does_not_emit() -> void:
	# Fire on press once per tap — a release must not double-fire (mirrors the BRA button hygiene).
	var s := _selector([_entry("sitt"), _entry("ligg")], "sitt", 600.0)
	var got := {"n": 0}
	s.trick_selected.connect(func(_id): got.n += 1)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = Vector2(10.0, 10.0)
	s._gui_input(up)
	assert_eq(got.n, 0, "a release does not emit — press-only, one emit per tap")
	s.free()

func test_entry_for_reports_per_trick_learned_state() -> void:
	# P2-1: "each entry shows its own persisted learned/mastery state" — the selector carries a
	# per-trick value + mastered flag, not one shared bar.
	var s := _selector([_entry("sitt", 0.4, false), _entry("ligg", 1.0, true)], "sitt")
	assert_true(s.entry_for("ligg").mastered, "each chip carries its own mastery state")
	assert_eq(s.entry_for("sitt").value, 0.4, "and its own learned fraction")
	s.free()
