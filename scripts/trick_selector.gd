class_name TrickSelector
extends Control
## The trick selector (066, P2-1 "Pick a trick"). A small, clear one-page chip row — one chip per
## trick the dog can perform — pinned in the top HUD band. Tapping a chip picks the trick to train;
## it is NOT a second gameplay verb during the round (the single scored verb stays BRA below). Each
## chip shows the trick's name and its OWN persisted learned/mastery state, so the roster reads as a
## repertoire at a glance (P2-1). The current trick's chip is highlighted.
##
## Same dumb-renderer split the rest of the HUD uses (LearnedBar / TierReadout): main decides the
## entries + the current trick and feeds them in via set_entries(); this node only draws them and
## maps a tap's x-position to a trick id, emitting `trick_selected`. So the mapping + signal are
## unit-testable render-free (id_at / a constructed InputEvent) with no framebuffer, and the routing
## INTO the game (repoint _current_trick / _progress) lives in main and is tested at the scene level.

## Emitted with the picked trick id when a chip is tapped. main.select_trick() consumes it.
signal trick_selected(id: String)

## The selector's preferred height (px, design space). main anchors the band; the tests pin it as
## the node's size so the hit-map has a real width/height without a layout pass.
const HEIGHT := 52.0

## Human-readable trick names (the labels the player reads). Keyed by the stable DogClips trick ids
## so a new trick is a one-line add here, mirroring how the clip bundles extend (065/067).
const LABELS := {
	DogClips.TRICK_SITT: "Sitt",
	DogClips.TRICK_LIGG: "Ligg",
	DogClips.TRICK_LEGG_DEG: "Legg deg",
}

## Chip padding + the mastery pip, homed here (no scattered literals — cf. 029). The label sits in
## the chip's upper zone and the pip hugs the bottom edge with a clear gap between, so the pip never
## strikes through a label's descenders ("Ligg" / "Legg deg").
const CHIP_GAP := 6.0          ## gutter between adjacent chips
const LABEL_SIZE := 26         ## px font for the trick name
const LABEL_TOP := 5.0         ## label baseline inset from the chip top
const PIP_H := 5.0             ## the per-trick learned-fraction pip height
const PIP_MARGIN_X := 12.0     ## the pip's horizontal inset from the chip edges
const PIP_BOTTOM := 6.0        ## the pip's gap up from the chip's bottom edge

## Palette — reads on the bright Pokémon-GO sky, and agrees with the rest of the HUD: the mastery
## gold matches PERFECT / the LearnedBar mastered gold; the fill green matches the LearnedBar fill.
const CHIP_BG := Color(0.0, 0.0, 0.0, 0.30)             ## an idle chip's panel
const CHIP_BG_CURRENT := Color(0.0, 0.0, 0.0, 0.52)     ## the selected chip: darker so its label pops
const CHIP_BORDER := Color(0.0, 0.0, 0.0, 0.35)         ## idle edge
const CHIP_BORDER_CURRENT := Color(1.0, 0.86, 0.30, 1.0)  ## selected edge: the triumphant gold
const LABEL_IDLE := Color(1.0, 1.0, 1.0, 0.82)          ## unselected name — legible but recessive
const LABEL_CURRENT := Color(1.0, 1.0, 1.0, 1.0)        ## selected name — full white
const PIP_TRACK := Color(0.0, 0.0, 0.0, 0.35)           ## the empty pip channel
const PIP_FILL := Color(0.35, 0.78, 0.48)               ## learning — the calm green (matches LearnedBar)
const PIP_MASTERED := Color(1.0, 0.86, 0.30)            ## mastered — the triumphant gold

## The roster: each entry is {id, label(optional), value, mastered}. main rebuilds it whenever the
## trick or its progress changes (_refresh_selector). `_current` is the highlighted trick's id.
var _entries: Array = []
var _current := ""

func _init() -> void:
	# The chips ARE tappable (the selector is meta-navigation, not the BRA verb) — STOP so a tap on
	# the top band picks a trick and never falls through. It sits well clear of the BRA button below,
	# so it never eats a scoring tap (P1-5).
	mouse_filter = Control.MOUSE_FILTER_STOP

## The player-facing name for a trick id (pure so the mapping is unit-locked). Unknown ids fall back
## to a capitalised id rather than crashing, so an unwired trick still reads honestly.
static func display_name(id: String) -> String:
	return LABELS.get(id, id.capitalize())

## Set the roster + which trick is current, and request a redraw. main is the single source of the
## per-trick learned state, so this just stores + draws it.
func set_entries(entries: Array, current_id: String) -> void:
	_entries = entries
	_current = current_id
	queue_redraw()

## The highlighted trick's id — the render-free predicate the wiring test reads.
func current_id() -> String:
	return _current

func entry_count() -> int:
	return _entries.size()

## The ids currently offered, in chip order — so a test can assert the roster is exactly the tricks
## the dog can perform (never a faked trick).
func entry_ids() -> Array:
	var ids: Array = []
	for e in _entries:
		ids.append(e.id)
	return ids

## The entry (id/value/mastered) for a trick, or {} if it isn't in the roster — lets a test read a
## chip's own learned/mastery state (P2-1) without a framebuffer.
func entry_for(id: String) -> Dictionary:
	for e in _entries:
		if e.id == id:
			return e
	return {}

## Map a local x-position to the trick id of the chip under it (equal-width chips across the band).
## "" when there is nothing to hit (no roster, or no measured width). The one home for the hit-map,
## so _gui_input and the tests agree on which chip a tap lands on.
func id_at(local_x: float) -> String:
	var n := _entries.size()
	if n == 0 or size.x <= 0.0:
		return ""
	var chip_w := size.x / float(n)
	var idx := clampi(int(local_x / chip_w), 0, n - 1)
	return _entries[idx].id

## Pick the trick under a left-press (press-only, once per tap — mirrors the BRA button's hygiene so
## a chip never double-fires on the release). main.select_trick() does the actual routing.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id := id_at((event as InputEventMouseButton).position.x)
		if id != "":
			trick_selected.emit(id)

func _draw() -> void:
	var n := _entries.size()
	if n == 0:
		return
	var chip_w := size.x / float(n)
	var font := ThemeDB.fallback_font
	for i in n:
		var e: Dictionary = _entries[i]
		var is_current: bool = e.id == _current
		var rect := Rect2(i * chip_w + CHIP_GAP, 0.0, chip_w - 2.0 * CHIP_GAP, size.y)
		# The chip panel — the current trick reads darker with a gold edge so the selection is obvious.
		draw_rect(rect, CHIP_BG_CURRENT if is_current else CHIP_BG, true)
		draw_rect(rect, CHIP_BORDER_CURRENT if is_current else CHIP_BORDER, false, 2.0)
		# The trick name, centred across the chip.
		var label := display_name(e.id)
		var col := LABEL_CURRENT if is_current else LABEL_IDLE
		var baseline := rect.position.y + LABEL_TOP + font.get_ascent(LABEL_SIZE)
		draw_string(font, Vector2(rect.position.x, baseline), label,
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, LABEL_SIZE, col)
		# Its OWN learned fraction as a thin pip hugging the chip's foot — gold once mastered (P2-1).
		var track := Rect2(rect.position.x + PIP_MARGIN_X, rect.position.y + rect.size.y - PIP_H - PIP_BOTTOM,
			rect.size.x - 2.0 * PIP_MARGIN_X, PIP_H)
		draw_rect(track, PIP_TRACK, true)
		var fill_w := maxf(0.0, track.size.x * clampf(float(e.value), 0.0, 1.0))
		if fill_w > 0.0:
			draw_rect(Rect2(track.position.x, track.position.y, fill_w, track.size.y),
				PIP_MASTERED if e.mastered else PIP_FILL, true)
