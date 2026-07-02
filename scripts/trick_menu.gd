class_name TrickMenu
extends Control
## The completion menu (072, Phase-3 PO note 1). The game trains ONE active trick at a time; when that
## trick is mastered this modal pops up showing the whole collection — the just-learned trick as
## Learned, the other performable tricks as Available (tap one to train it next), the earned COIN
## balance, and the genuinely-absent tricks as Locked/unavailable (greyed, never tappable, never a
## faked clip — the never-fake honesty gate, BUST-064 residual). It supersedes the always-on 066 chip
## row: picking a trick is now this between-rounds surface, not a permanent second in-round verb.
##
## Same dumb-renderer split the rest of the HUD uses (TrickSelector / CoinReadout / LearnedBar): main
## decides the rows + the balance and feeds them in via set_rows(); this node only draws the modal and
## maps a tap to a trick id. So the classify split + the row hit-map + the signals are unit-testable
## render-free (static classify / id_at / a constructed InputEvent — no framebuffer), and the routing
## INTO the game (open on mastery, pause offers, select_trick) lives in main and is scene-tested.

## A performable trick was tapped — main.select_trick() consumes it. Only Learned/Available rows emit.
signal trick_chosen(id: String)
## The menu was dismissed without switching (the close affordance or a tap on the dimmed backdrop) —
## main hides it and resumes training the CURRENT trick.
signal dismissed

## Each known trick's standing in the collection. LOCKED covers both the owner-gated absent tricks and
## anything the loaded dog simply can't perform (the honest CC0 read) — neither is ever trainable.
enum State { LEARNED, AVAILABLE, LOCKED }

## Player-facing names, keyed by the stable trick ids (the three wired tricks + the BUST-064 roadmap
## residual so the Locked rows read honestly). A new trick is a one-line add, mirroring TrickSelector.
const LABELS := {
	DogClips.TRICK_SITT: "Sitt",
	DogClips.TRICK_LIGG: "Ligg",
	DogClips.TRICK_LEGG_DEG: "Legg deg",
	"gi_labb": "Gi labb",
	"rull": "Rull",
	"snurr": "Snurr",
}

## The state badge each row shows to its right.
const BADGE := {
	State.LEARNED: "Learned",
	State.AVAILABLE: "Available",
	State.LOCKED: "Locked",
}

## Layout, homed here (no scattered literals — cf. 029). Design space; the panel centres in whatever
## size main anchors (full-screen). Row/close geometry is derived from these so the hit-map and _draw
## agree on exactly one layout.
const PANEL_MARGIN_X := 28.0    ## min gutter from the screen edges to the panel
const PANEL_MAX_W := 340.0      ## the panel never grows wider than this (reads centred on a phone)
const PANEL_PAD := 20.0         ## inner padding inside the panel
const HEADER_H := 76.0          ## the coins + "Tricks" title band
const ROW_H := 58.0             ## one trick row
const ROW_GAP := 8.0            ## gutter between rows
const CLOSE_GAP := 16.0         ## gap above the close button
const CLOSE_H := 54.0           ## the "Keep training" close button
const RADIUS := 18.0            ## panel corner radius

## Type sizes.
const TITLE_SIZE := 30
const NUMBER_SIZE := 26
const NAME_SIZE := 26
const BADGE_SIZE := 18
const CLOSE_SIZE := 22
const COIN_R := 11.0
const OUTLINE := 1.5

## Palette — agrees with the rest of the HUD (mastery gold matches PERFECT / the coin gold; the fill
## green matches LearnedBar).
const BACKDROP := Color(0.0, 0.0, 0.0, 0.55)          ## the dimmed veil over the game
const PANEL_BG := Color(0.10, 0.13, 0.18, 0.98)       ## the modal panel
const PANEL_BORDER := Color(1.0, 0.86, 0.30, 0.85)    ## the triumphant gold edge
const TITLE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const ROW_BG := Color(1.0, 1.0, 1.0, 0.06)            ## an available/learned row panel
const ROW_BG_LOCKED := Color(1.0, 1.0, 1.0, 0.02)     ## a locked row — barely there
const NAME_LEARNED := Color(1.0, 0.86, 0.30)          ## learned name — gold
const NAME_AVAILABLE := Color(1.0, 1.0, 1.0)          ## available name — full white
const NAME_LOCKED := Color(1.0, 1.0, 1.0, 0.32)       ## locked name — greyed, clearly not tappable
const BADGE_LEARNED := Color(1.0, 0.86, 0.30)
const BADGE_AVAILABLE := Color(0.55, 0.86, 0.62)      ## the calm learning green
const BADGE_LOCKED := Color(1.0, 1.0, 1.0, 0.30)
const COIN_GOLD := Color(1.0, 0.84, 0.29)
const COIN_RIM := Color(0.72, 0.53, 0.10)
const NUMBER_COLOR := Color(1.0, 0.92, 0.45)
const CLOSE_BG := Color(1.0, 1.0, 1.0, 0.10)
const CLOSE_TEXT := Color(1.0, 1.0, 1.0, 0.92)
const SHADOW := Color(0.0, 0.0, 0.0, 0.9)

## The rows main fed in (each {id, state}) + the coin balance shown in the header.
var _rows: Array = []
var _balance := 0

func _init() -> void:
	# Modal: the menu eats every tap while it is up (STOP), so a tap can never fall through to the BRA
	# button or a chip behind it. main also hides/shows it; it starts hidden (main mounts it hidden).
	mouse_filter = Control.MOUSE_FILTER_STOP

## Classify each known trick for the menu (pure — the honesty split is unit-locked). `performable` are
## the ids the loaded dog can actually do; `mastered` maps id→bool; `locked` are the genuinely-absent
## roadmap ids that must ALWAYS read Locked (never trainable) regardless of anything else.
static func classify(all_ids: Array, performable: Array, mastered: Dictionary, locked: Array) -> Array:
	var rows: Array = []
	for id in all_ids:
		var st := State.LOCKED
		if not locked.has(id) and performable.has(id):
			st = State.LEARNED if mastered.get(id, false) else State.AVAILABLE
		rows.append({"id": id, "state": st})
	return rows

## Whether a state is choosable (a Locked trick never is — the never-fake gate).
static func is_selectable(state: int) -> bool:
	return state == State.LEARNED or state == State.AVAILABLE

## The player-facing name for a trick id (pure). Unknown ids fall back to a capitalised id.
static func display_name(id: String) -> String:
	return LABELS.get(id, id.capitalize())

## Set the rows + the coin balance to show, and request a redraw. main rebuilds this each time it opens
## the menu (or after mastery), so the menu itself stays dumb.
func set_rows(rows: Array, balance: int) -> void:
	_rows = rows
	_balance = maxi(0, balance)
	queue_redraw()

func row_count() -> int:
	return _rows.size()

## The coin balance currently shown — the render-free predicate a test reads.
func balance() -> int:
	return _balance

## The State for a trick id in the current rows, or LOCKED if it isn't present (defensive default —
## an unknown id is never trainable).
func state_of(id: String) -> int:
	for r in _rows:
		if r.id == id:
			return r.state
	return State.LOCKED

# ---- geometry (one home so _draw and the hit-map agree) -------------------------------------------

## The rows block height for the current row count.
func _rows_block_h() -> float:
	var n := _rows.size()
	if n == 0:
		return 0.0
	return n * ROW_H + (n - 1) * ROW_GAP

## The centred modal panel rect for the current size + row count.
func _panel_rect() -> Rect2:
	var pw := minf(size.x - 2.0 * PANEL_MARGIN_X, PANEL_MAX_W)
	var ph := PANEL_PAD + HEADER_H + _rows_block_h() + CLOSE_GAP + CLOSE_H + PANEL_PAD
	var px := (size.x - pw) * 0.5
	var py := (size.y - ph) * 0.5
	return Rect2(px, py, pw, ph)

## The i-th trick row rect inside the panel.
func _row_rect(i: int) -> Rect2:
	var panel := _panel_rect()
	var x := panel.position.x + PANEL_PAD
	var y := panel.position.y + PANEL_PAD + HEADER_H + i * (ROW_H + ROW_GAP)
	return Rect2(x, y, panel.size.x - 2.0 * PANEL_PAD, ROW_H)

## The close ("Keep training") button rect at the panel foot.
func _close_rect() -> Rect2:
	var panel := _panel_rect()
	var x := panel.position.x + PANEL_PAD
	var y := panel.position.y + PANEL_PAD + HEADER_H + _rows_block_h() + CLOSE_GAP
	return Rect2(x, y, panel.size.x - 2.0 * PANEL_PAD, CLOSE_H)

## The row index under a point, or -1 if none.
func row_index_at(pos: Vector2) -> int:
	for i in _rows.size():
		if _row_rect(i).has_point(pos):
			return i
	return -1

## Map a point to the trick id of the SELECTABLE row under it, or "" (a Locked row or empty space —
## never a hit, so a Locked trick can never be chosen). The one home for the hit-map.
func id_at(pos: Vector2) -> String:
	var i := row_index_at(pos)
	if i < 0:
		return ""
	var r: Dictionary = _rows[i]
	return r.id if is_selectable(r.state) else ""

## Pick on a left-press (press-only, once per tap — mirrors the BRA button + selector hygiene). A
## selectable row → trick_chosen; the close button or a tap on the dimmed backdrop → dismissed; a tap
## on a Locked row is absorbed (no signal — it stays put, never a faked switch).
func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pos := (event as InputEventMouseButton).position
	var i := row_index_at(pos)
	if i >= 0:
		var r: Dictionary = _rows[i]
		if is_selectable(r.state):
			trick_chosen.emit(r.id)
		return  # a Locked row is absorbed — never a dismiss, never a switch
	if _close_rect().has_point(pos) or not _panel_rect().has_point(pos):
		dismissed.emit()

# ---- rendering ------------------------------------------------------------------------------------

func _draw_text_outlined(font: Font, pos: Vector2, text: String, fsize: int, color: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	for o in [Vector2(-OUTLINE, 0), Vector2(OUTLINE, 0), Vector2(0, -OUTLINE), Vector2(0, OUTLINE)]:
		draw_string(font, pos + o, text, align, width, fsize, SHADOW)
	draw_string(font, pos, text, align, width, fsize, color)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	# The dimmed veil over the whole game, then the centred panel.
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP, true)
	var panel := _panel_rect()
	draw_style_box(_panel_box(), panel)
	# Header: the "Tricks" title on the left, the drawn coin + balance on the right.
	var hx := panel.position.x + PANEL_PAD
	var hy := panel.position.y + PANEL_PAD
	var title_baseline := hy + font.get_ascent(TITLE_SIZE)
	_draw_text_outlined(font, Vector2(hx, title_baseline), "Tricks", TITLE_SIZE, TITLE_COLOR)
	_draw_coins(font, panel, hy)
	# The trick rows.
	for i in _rows.size():
		_draw_row(font, i)
	# The close ("Keep training") button.
	var cr := _close_rect()
	draw_rect(cr, CLOSE_BG, true)
	var cb := cr.position.y + cr.size.y * 0.5 + font.get_ascent(CLOSE_SIZE) * 0.5 - font.get_descent(CLOSE_SIZE) * 0.5
	_draw_text_outlined(font, Vector2(cr.position.x, cb), "Keep training", CLOSE_SIZE, CLOSE_TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, cr.size.x)

func _panel_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_BG
	box.set_corner_radius_all(int(RADIUS))
	box.border_color = PANEL_BORDER
	box.set_border_width_all(2)
	return box

## The drawn coin disc + balance, right-aligned in the header band (reuses the CoinReadout motif so no
## font-glyph tofu — bug 1 can never come back through this seam either).
func _draw_coins(font: Font, panel: Rect2, top: float) -> void:
	var num := "%d" % _balance
	var num_w := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE).x
	var cy := top + COIN_R + 3.0
	var right := panel.position.x + panel.size.x - PANEL_PAD
	# number sits to the right of the coin; lay the group out from the right edge leftward.
	var num_x := right - num_w
	var cc := Vector2(num_x - 8.0 - COIN_R, cy)
	draw_circle(cc, COIN_R, COIN_RIM)
	draw_circle(cc, COIN_R - 2.0, COIN_GOLD)
	draw_arc(cc, COIN_R * 0.55, 0.0, TAU, 20, COIN_RIM, 1.5)
	var nb := cy + font.get_ascent(NUMBER_SIZE) * 0.5 - font.get_descent(NUMBER_SIZE) * 0.5
	_draw_text_outlined(font, Vector2(num_x, nb), num, NUMBER_SIZE, NUMBER_COLOR)

func _draw_row(font: Font, i: int) -> void:
	var r: Dictionary = _rows[i]
	var rect := _row_rect(i)
	var st: int = r.state
	var locked := st == State.LOCKED
	draw_rect(rect, ROW_BG_LOCKED if locked else ROW_BG, true)
	# Trick name, left; state badge, right.
	var name_col := NAME_LOCKED
	if st == State.LEARNED:
		name_col = NAME_LEARNED
	elif st == State.AVAILABLE:
		name_col = NAME_AVAILABLE
	var name_baseline := rect.position.y + rect.size.y * 0.5 + font.get_ascent(NAME_SIZE) * 0.5 - font.get_descent(NAME_SIZE) * 0.5
	_draw_text_outlined(font, Vector2(rect.position.x + 14.0, name_baseline),
		display_name(r.id), NAME_SIZE, name_col)
	var badge: String = BADGE[st]
	var badge_col := BADGE_LOCKED
	if st == State.LEARNED:
		badge_col = BADGE_LEARNED
	elif st == State.AVAILABLE:
		badge_col = BADGE_AVAILABLE
	var badge_baseline := rect.position.y + rect.size.y * 0.5 + font.get_ascent(BADGE_SIZE) * 0.5 - font.get_descent(BADGE_SIZE) * 0.5
	_draw_text_outlined(font, Vector2(rect.position.x, badge_baseline), badge, BADGE_SIZE, badge_col,
		HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 14.0)
