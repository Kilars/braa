extends "res://tests/test_case.gd"
## The completion menu (072, Phase-3 PO note 1 "one active trick + a completion menu"). TrickMenu is
## a dumb renderer + hit-map, the same pure/render-free split TrickSelector/CoinReadout/LearnedBar
## use: main decides the rows (learned / available / locked) + the coin balance and feeds them in;
## this node draws the modal and maps a tap to a trick id, emitting `trick_chosen` (a selectable row)
## or `dismissed` (the close affordance / a tap on the dimmed backdrop). These pin the classify split,
## the row hit-map, and the press-only signals render-free (public fields + a constructed InputEvent —
## no framebuffer). The routing INTO main (open on mastery, pause offers, switch trick) is proven in
## test_trick_menu_wiring.gd.

const SITT := DogClips.TRICK_SITT
const LIGG := DogClips.TRICK_LIGG
const LEGG := DogClips.TRICK_LEGG_DEG
const LOCKED := ["gi_labb", "rull", "snurr"]  # BUST-064 residual: absent from the asset → roadmap-locked

func _menu(rows: Array, balance := 0) -> TrickMenu:
	var m := TrickMenu.new()
	m.size = Vector2(390.0, 844.0)  # headless: no layout pass, pin the phone-portrait size the hit-map reads
	m.set_rows(rows, balance)
	return m

# ---- classify: the learned / available / locked split (the honesty gate) --------------------------

func test_classify_splits_learned_available_locked() -> void:
	# Sitt performable + mastered → LEARNED; Ligg performable + unmastered → AVAILABLE; an absent
	# roadmap trick → LOCKED. This is the exact split the PO's completion menu shows.
	var rows := TrickMenu.classify(
		[SITT, LIGG, "gi_labb"],
		[SITT, LIGG],                 # performable
		{SITT: true, LIGG: false},    # mastered
		LOCKED)
	assert_eq(rows[0].state, TrickMenu.State.LEARNED, "a mastered performable trick reads Learned")
	assert_eq(rows[1].state, TrickMenu.State.AVAILABLE, "an unmastered performable trick reads Available")
	assert_eq(rows[2].state, TrickMenu.State.LOCKED, "a genuinely-absent trick reads Locked")

func test_classify_order_follows_all_ids() -> void:
	var rows := TrickMenu.classify([LEGG, SITT, LIGG], [SITT, LIGG, LEGG], {}, LOCKED)
	assert_eq(rows[0].id, LEGG, "row order follows all_ids, not the performable order")
	assert_eq(rows[1].id, SITT, "second row is the second listed id")
	assert_eq(rows[2].id, LIGG, "third row is the third listed id")

func test_classify_roadmap_id_is_always_locked_even_if_performable() -> void:
	# The never-fake gate: an id named in `locked` (the owner-gated residual) can never read as
	# trainable, even if some future dog reported it performable — it stays LOCKED.
	var rows := TrickMenu.classify(["gi_labb"], ["gi_labb"], {"gi_labb": true}, LOCKED)
	assert_eq(rows[0].state, TrickMenu.State.LOCKED, "a roadmap-locked id is never Learned/Available")

func test_classify_cc0_all_locked_when_nothing_performable() -> void:
	# On the idle-only CC0 dog nothing is performable → every trick reads Locked (the honest read
	# that the placeholder can train nothing), never a faked Available row.
	var rows := TrickMenu.classify([SITT, LIGG, LEGG], [], {}, LOCKED)
	for r in rows:
		assert_eq(r.state, TrickMenu.State.LOCKED, "no performable trick → all Locked")

# ---- selectability: only Learned/Available rows may be chosen --------------------------------------

func test_is_selectable_only_for_learned_and_available() -> void:
	assert_true(TrickMenu.is_selectable(TrickMenu.State.LEARNED), "a learned trick can be re-picked")
	assert_true(TrickMenu.is_selectable(TrickMenu.State.AVAILABLE), "an available trick can be picked")
	assert_false(TrickMenu.is_selectable(TrickMenu.State.LOCKED), "a locked trick can never be picked")

# ---- hit-map: a tap → the trick id under it (selectable only) --------------------------------------

func test_id_at_maps_a_tap_to_a_selectable_row() -> void:
	var m := _menu([
		{"id": SITT, "state": TrickMenu.State.LEARNED},
		{"id": LIGG, "state": TrickMenu.State.AVAILABLE},
		{"id": "gi_labb", "state": TrickMenu.State.LOCKED},
	], 30)
	assert_eq(m.id_at(m._row_rect(0).get_center()), SITT, "a tap on the Learned row maps to its id")
	assert_eq(m.id_at(m._row_rect(1).get_center()), LIGG, "a tap on the Available row maps to its id")
	m.free()

func test_id_at_is_blank_on_a_locked_row() -> void:
	var m := _menu([
		{"id": SITT, "state": TrickMenu.State.AVAILABLE},
		{"id": "gi_labb", "state": TrickMenu.State.LOCKED},
	], 0)
	assert_eq(m.id_at(m._row_rect(1).get_center()), "", "a Locked row is never a hit (never trainable)")
	m.free()

func test_id_at_is_blank_outside_the_rows() -> void:
	var m := _menu([{"id": SITT, "state": TrickMenu.State.AVAILABLE}], 0)
	assert_eq(m.id_at(Vector2(2.0, 2.0)), "", "a tap on the dimmed backdrop hits no row")
	m.free()

# ---- signals: press-only, one emit per tap --------------------------------------------------------

func test_press_on_available_row_emits_trick_chosen() -> void:
	var m := _menu([
		{"id": SITT, "state": TrickMenu.State.LEARNED},
		{"id": LIGG, "state": TrickMenu.State.AVAILABLE},
	], 10)
	var got := {"id": ""}
	m.trick_chosen.connect(func(id): got.id = id)
	m._gui_input(_press(m._row_rect(1).get_center()))
	assert_eq(got.id, LIGG, "tapping an Available row emits its trick id (routes to select_trick)")
	m.free()

func test_press_on_locked_row_emits_nothing() -> void:
	var m := _menu([{"id": "gi_labb", "state": TrickMenu.State.LOCKED}], 0)
	var got := {"chosen": 0, "dismissed": 0}
	m.trick_chosen.connect(func(_id): got.chosen += 1)
	m.dismissed.connect(func(): got.dismissed += 1)
	m._gui_input(_press(m._row_rect(0).get_center()))
	assert_eq(got.chosen, 0, "a Locked row never chooses a trick (never plays a faked clip)")
	assert_eq(got.dismissed, 0, "a Locked row is absorbed, not a dismiss")
	m.free()

func test_press_on_close_emits_dismissed() -> void:
	var m := _menu([{"id": SITT, "state": TrickMenu.State.AVAILABLE}], 0)
	var got := {"dismissed": 0}
	m.dismissed.connect(func(): got.dismissed += 1)
	m._gui_input(_press(m._close_rect().get_center()))
	assert_eq(got.dismissed, 1, "the close affordance dismisses the menu (keep training the current trick)")
	m.free()

func test_press_on_backdrop_dismisses() -> void:
	var m := _menu([{"id": SITT, "state": TrickMenu.State.AVAILABLE}], 0)
	var got := {"dismissed": 0}
	m.dismissed.connect(func(): got.dismissed += 1)
	m._gui_input(_press(Vector2(2.0, 2.0)))  # far outside the centred panel
	assert_eq(got.dismissed, 1, "a tap on the dimmed backdrop dismisses the modal")
	m.free()

func test_release_does_not_emit() -> void:
	var m := _menu([{"id": SITT, "state": TrickMenu.State.AVAILABLE}], 0)
	var got := {"n": 0}
	m.trick_chosen.connect(func(_id): got.n += 1)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = m._row_rect(0).get_center()
	m._gui_input(up)
	assert_eq(got.n, 0, "a release does not emit — press-only, one emit per tap")
	m.free()

func _press(pos: Vector2) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = pos
	return ev
