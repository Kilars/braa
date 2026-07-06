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

# ---- breeds section: adopt (spend coins) + select the active breed (079, P3-D3 / P3-4) -------------

const CAT := [
	{"id": "labrador", "name": "Labrador", "tint": Color(0.86, 0.72, 0.47)},
	{"id": "chocolate_labrador", "name": "Chocolate Labrador", "tint": Color(0.40, 0.28, 0.20)},
]

func test_classify_breeds_active_owned_buyable_locked() -> void:
	# The active breed reads Active; another owned breed reads Owned (tap → switch); an unowned breed the
	# player can afford reads Buyable (tap → adopt); an unowned breed they can't afford reads Locked.
	var owned_affordable := TrickMenu.classify_breeds(CAT, ["labrador"], "labrador", 30, 30)
	assert_eq(owned_affordable[0].state, TrickMenu.BreedState.ACTIVE, "the active breed reads Active")
	assert_eq(owned_affordable[1].state, TrickMenu.BreedState.BUYABLE, "an affordable unowned breed reads Buyable")
	var owned_broke := TrickMenu.classify_breeds(CAT, ["labrador"], "labrador", 10, 30)
	assert_eq(owned_broke[1].state, TrickMenu.BreedState.LOCKED, "an unaffordable unowned breed reads Locked")
	var both := TrickMenu.classify_breeds(CAT, ["labrador", "chocolate_labrador"], "chocolate_labrador", 0, 30)
	assert_eq(both[0].state, TrickMenu.BreedState.OWNED, "a non-active owned breed reads Owned (tap → switch)")
	assert_eq(both[1].state, TrickMenu.BreedState.ACTIVE, "the active owned breed reads Active")
	assert_eq(both[1].price, 30, "each row carries the adopt price for the locked/buyable badge")

func _breed_menu(breeds: Array) -> TrickMenu:
	var m := TrickMenu.new()
	m.size = Vector2(390.0, 844.0)
	m.set_rows([{"id": SITT, "state": TrickMenu.State.LEARNED}], 30)  # a trick row so the panel lays out normally
	m.set_breeds(breeds)
	return m

func test_press_on_owned_breed_emits_breed_chosen() -> void:
	var m := _breed_menu(TrickMenu.classify_breeds(CAT, ["labrador", "chocolate_labrador"], "labrador", 0, 30))
	var got := {"id": ""}
	m.breed_chosen.connect(func(id): got.id = id)
	m._gui_input(_press(m._breed_row_rect(1).get_center()))  # row 1 = chocolate, owned + not active
	assert_eq(got.id, "chocolate_labrador", "tapping an owned non-active breed switches to it")
	m.free()

func test_press_on_buyable_breed_emits_breed_adopt() -> void:
	var m := _breed_menu(TrickMenu.classify_breeds(CAT, ["labrador"], "labrador", 30, 30))
	var got := {"id": ""}
	m.breed_adopt.connect(func(id): got.id = id)
	m._gui_input(_press(m._breed_row_rect(1).get_center()))  # row 1 = chocolate, buyable
	assert_eq(got.id, "chocolate_labrador", "tapping an affordable unowned breed requests an adopt")
	m.free()

func test_press_on_active_or_locked_breed_emits_nothing() -> void:
	var m := _breed_menu(TrickMenu.classify_breeds(CAT, ["labrador"], "labrador", 10, 30))
	var got := {"chosen": 0, "adopt": 0, "dismissed": 0}
	m.breed_chosen.connect(func(_id): got.chosen += 1)
	m.breed_adopt.connect(func(_id): got.adopt += 1)
	m.dismissed.connect(func(): got.dismissed += 1)
	m._gui_input(_press(m._breed_row_rect(0).get_center()))  # row 0 = labrador, already Active
	m._gui_input(_press(m._breed_row_rect(1).get_center()))  # row 1 = chocolate, Locked (can't afford)
	assert_eq(got.chosen, 0, "the active breed absorbs a tap (already active, no switch)")
	assert_eq(got.adopt, 0, "an unaffordable breed absorbs a tap (no adopt, no debt)")
	assert_eq(got.dismissed, 0, "a breed row is absorbed, never a dismiss")
	m.free()

func _press(pos: Vector2) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = pos
	return ev

# ---- marker words section: load/swap the active word (092, P5-4) -----------------------------------

func test_classify_words_active_unlocked_locked() -> void:
	# The active word reads ACTIVE; another unlocked word reads UNLOCKED (tap → switch); a catalog word
	# not in `unlocked` reads LOCKED (greyed, never tappable). This mirrors the breed state partition.
	# Base "bra" + dyktig + flink unlocked, dyktig active → dyktig ACTIVE, bra + flink UNLOCKED, super + kjempebra LOCKED.
	var rows := TrickMenu.classify_words(MarkerWords.CATALOG, ["bra", "dyktig", "flink"], "dyktig")
	assert_eq(rows[0].state, TrickMenu.WordState.UNLOCKED, "base 'bra' unlocked but not active reads UNLOCKED")
	assert_eq(rows[1].state, TrickMenu.WordState.ACTIVE, "the active word 'dyktig' reads ACTIVE")
	assert_eq(rows[2].state, TrickMenu.WordState.UNLOCKED, "unlocked 'flink' reads UNLOCKED")
	assert_eq(rows[3].state, TrickMenu.WordState.LOCKED, "locked 'super' reads LOCKED")
	assert_eq(rows[4].state, TrickMenu.WordState.LOCKED, "locked 'kjempebra' reads LOCKED")

func test_classify_words_all_locked_when_only_base_active() -> void:
	# When only base "bra" is unlocked and active, it reads ACTIVE; all other catalog words read LOCKED.
	var rows := TrickMenu.classify_words(MarkerWords.CATALOG, ["bra"], "bra")
	assert_eq(rows[0].state, TrickMenu.WordState.ACTIVE, "base 'bra' alone unlocked + active reads ACTIVE")
	assert_eq(rows[1].state, TrickMenu.WordState.LOCKED, "'dyktig' not unlocked reads LOCKED")
	assert_eq(rows[2].state, TrickMenu.WordState.LOCKED, "'flink' not unlocked reads LOCKED")
	assert_eq(rows[3].state, TrickMenu.WordState.LOCKED, "'super' not unlocked reads LOCKED")
	assert_eq(rows[4].state, TrickMenu.WordState.LOCKED, "'kjempebra' not unlocked reads LOCKED")

func test_classify_words_order_follows_catalog() -> void:
	# Row order matches the catalog order (bra, dyktig, flink, super, kjempebra), not the order of
	# the `unlocked` array. This keeps the display consistent.
	var rows := TrickMenu.classify_words(MarkerWords.CATALOG, ["flink", "bra", "super"], "super")
	assert_eq(rows[0].id, "bra", "first row is 'bra' (first catalog entry)")
	assert_eq(rows[1].id, "dyktig", "second row is 'dyktig' (second catalog entry)")
	assert_eq(rows[2].id, "flink", "third row is 'flink' (third catalog entry)")
	assert_eq(rows[3].id, "super", "fourth row is 'super' (fourth catalog entry)")
	assert_eq(rows[4].id, "kjempebra", "fifth row is 'kjempebra' (fifth catalog entry)")

func test_classify_words_display_matches_catalog() -> void:
	# Each row's display field matches the catalog entry, e.g. "Dyktig!" not "dyktig".
	var rows := TrickMenu.classify_words(MarkerWords.CATALOG, ["bra", "dyktig", "flink"], "dyktig")
	assert_eq(rows[0].display, "Bra!", "display matches catalog for 'bra'")
	assert_eq(rows[1].display, "Dyktig!", "display matches catalog for 'dyktig'")
	assert_eq(rows[2].display, "Flink!", "display matches catalog for 'flink'")
	assert_eq(rows[3].display, "Super!", "display matches catalog for 'super'")
	assert_eq(rows[4].display, "Kjempebra!", "display matches catalog for 'kjempebra'")

func test_classify_words_all_unlocked() -> void:
	# When all words are unlocked, the active word is ACTIVE; the rest are UNLOCKED (switchable).
	var rows := TrickMenu.classify_words(MarkerWords.CATALOG,
		["bra", "dyktig", "flink", "super", "kjempebra"], "kjempebra")
	assert_eq(rows[0].state, TrickMenu.WordState.UNLOCKED, "unlocked 'bra' not active reads UNLOCKED")
	assert_eq(rows[1].state, TrickMenu.WordState.UNLOCKED, "unlocked 'dyktig' not active reads UNLOCKED")
	assert_eq(rows[2].state, TrickMenu.WordState.UNLOCKED, "unlocked 'flink' not active reads UNLOCKED")
	assert_eq(rows[3].state, TrickMenu.WordState.UNLOCKED, "unlocked 'super' not active reads UNLOCKED")
	assert_eq(rows[4].state, TrickMenu.WordState.ACTIVE, "active 'kjempebra' reads ACTIVE")

func test_classify_words_edge_active_not_in_unlocked() -> void:
	# Edge case: if the active word is NOT in the unlocked list, it should still appear in the
	# partition (treated as LOCKED, since it's not unlocked). The partition is deterministic
	# regardless of the active word's unlock status — no missing rows.
	var rows := TrickMenu.classify_words(MarkerWords.CATALOG, ["bra", "dyktig"], "super")
	assert_eq(rows.size(), 5, "all catalog entries are present (no rows dropped)")
	assert_eq(rows[0].id, "bra", "first row is 'bra'")
	assert_eq(rows[1].id, "dyktig", "second row is 'dyktig'")
	# 'super' is in the catalog but not in `unlocked`, so it should read LOCKED even though
	# the caller tried to set it active (a defensive edge case — in normal play, main ensures
	# the active word is always unlocked via MarkerWords.set_active() guards).
	assert_eq(rows[3].id, "super", "fourth row is 'super' (even though active was not in unlocked)")
	assert_eq(rows[3].state, TrickMenu.WordState.LOCKED, "an active word not in unlocked reads LOCKED (edge case)")

# ---- marker words trade-off cost: window_scale + cooldown in classify_words (095, P5-2) -----

func test_classify_words_rows_carry_window_scale_and_cooldown() -> void:
	# A stronger word's row must carry its catalog window_scale (> 1.0) and cooldown (> 0)
	# so the menu can display the trade-off before the player loads it.
	var rows := TrickMenu.classify_words(MarkerWords.CATALOG, ["bra", "dyktig"], "bra")
	# Find the dyktig row (second in catalog order)
	var dyktig_row: Dictionary = {}
	for row in rows:
		if row.id == "dyktig":
			dyktig_row = row
			break
	assert_true(dyktig_row.has("window_scale"), "dyktig row has window_scale key")
	assert_true(dyktig_row.has("cooldown"), "dyktig row has cooldown key")
	# Verify the values match the catalog
	var w := MarkerWords.new()
	assert_eq(dyktig_row.window_scale, w.window_scale("dyktig"), "window_scale value matches catalog")
	assert_true(dyktig_row.window_scale > 1.0, "dyktig window_scale > 1.0 (stronger word)")
	assert_eq(dyktig_row.cooldown, w.cooldown("dyktig"), "cooldown value matches catalog")
	assert_true(dyktig_row.cooldown > 0, "dyktig cooldown > 0 (has a cost)")

func test_classify_words_base_word_has_identity_cost() -> void:
	# Base "bra" carries window_scale == 1.0 and cooldown == 0 (no cost, always available).
	# This reinforces that "bra" is the plain always-available default with no downside.
	var rows := TrickMenu.classify_words(MarkerWords.CATALOG, ["bra"], "bra")
	# Find the bra row (always first in catalog order)
	var bra_row: Dictionary = rows[0]
	assert_eq(bra_row.id, "bra", "first row is 'bra'")
	assert_true(bra_row.has("window_scale"), "bra row has window_scale key")
	assert_true(bra_row.has("cooldown"), "bra row has cooldown key")
	assert_eq(bra_row.window_scale, 1.0, "base 'bra' has window_scale 1.0 (identity)")
	assert_eq(bra_row.cooldown, 0, "base 'bra' has cooldown 0 (never cools down)")

# ---- localization: the completion-menu chrome is Norwegian (138, PO father-pass-3) ----------------

func test_badge_labels_are_norwegian() -> void:
	# The «Triks» pill must open a Norwegian panel — the trick-row state badges read in Norwegian,
	# not the old English «Learned / Available / Locked».
	assert_eq(TrickMenu.BADGE[TrickMenu.State.LEARNED], "Lært", "LEARNED badge is «Lært»")
	assert_eq(TrickMenu.BADGE[TrickMenu.State.AVAILABLE], "Tilgjengelig", "AVAILABLE badge is «Tilgjengelig»")
	assert_eq(TrickMenu.BADGE[TrickMenu.State.LOCKED], "Låst", "LOCKED badge is «Låst»")

func test_breed_badge_labels_are_norwegian() -> void:
	assert_eq(TrickMenu.BREED_BADGE[TrickMenu.BreedState.ACTIVE], "Aktiv", "breed ACTIVE badge is «Aktiv»")
	assert_eq(TrickMenu.BREED_BADGE[TrickMenu.BreedState.OWNED], "Bytt", "breed OWNED badge is «Bytt»")
	assert_eq(TrickMenu.BREED_BADGE[TrickMenu.BreedState.BUYABLE], "Adopter", "breed BUYABLE badge is «Adopter»")
	assert_eq(TrickMenu.BREED_BADGE[TrickMenu.BreedState.LOCKED], "Låst", "breed LOCKED badge is «Låst»")

func test_word_badge_labels_are_norwegian() -> void:
	assert_eq(TrickMenu.WORD_BADGE[TrickMenu.WordState.ACTIVE], "Aktiv", "word ACTIVE badge is «Aktiv»")
	assert_eq(TrickMenu.WORD_BADGE[TrickMenu.WordState.UNLOCKED], "Bytt", "word UNLOCKED badge is «Bytt»")
	assert_eq(TrickMenu.WORD_BADGE[TrickMenu.WordState.LOCKED], "Låst", "word LOCKED badge is «Låst»")

func test_section_heading_labels_are_norwegian() -> void:
	# The three section headings are homed as named consts (no scattered literals) and read Norwegian.
	assert_eq(TrickMenu.LABEL_TITLE, "Triks", "panel title is «Triks»")
	assert_eq(TrickMenu.LABEL_BREEDS, "Raser", "breeds subheading is «Raser»")
	assert_eq(TrickMenu.LABEL_WORDS, "Markørord", "marker-words heading is «Markørord»")
