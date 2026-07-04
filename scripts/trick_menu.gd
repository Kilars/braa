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

## An OWNED, non-active breed row was tapped — main.select the active breed (switch which dog runs).
signal breed_chosen(id: String)
## A BUYABLE (affordable, unowned) breed row was tapped — main spends the coins + adopts it. An
## unaffordable (Locked) or already-active breed absorbs the tap and emits nothing (no debt, no switch).
signal breed_adopt(id: String)
## An UNLOCKED, non-active marker word was tapped — main.set_active + re-point the payoff clip.
## ACTIVE (already active) and LOCKED (not yet unlocked) rows absorb the tap and emit nothing.
signal word_chosen(id: String)
## The "Give feedback" row was tapped — main opens the FeedbackFormView modal over this menu.
## The menu itself stays dumb: it only emits; main holds the form and routes the submit through _telem.
signal feedback_requested

## The "Vis frem hundene" (show off my dogs) row was tapped — main opens the spotlit BreedShowcaseView
## over this menu (087, P3-4). Shown only when there are breeds; the menu stays dumb (only emits).
signal showcase_requested

## Each known trick's standing in the collection. LOCKED covers both the owner-gated absent tricks and
## anything the loaded dog simply can't perform (the honest CC0 read) — neither is ever trainable.
enum State { LEARNED, AVAILABLE, LOCKED }

## Each breed's standing in the roster (079, P3-D3/P3-4). ACTIVE = the running dog (absorbs a tap);
## OWNED = adopted but not active (tap → switch); BUYABLE = unowned + affordable (tap → adopt, spends
## coins); LOCKED = unowned + can't-afford (absorbs a tap — priced, no debt). Only OWNED/BUYABLE emit.
enum BreedState { ACTIVE, OWNED, BUYABLE, LOCKED }

## Each marker word's standing in the player's collection (092, P5-4). ACTIVE = the word that fires
## at the mark (absorbs a tap — already firing); UNLOCKED = unlocked by mastery, not yet active
## (tap → switch the active word); LOCKED = not yet earned (greyed, absorbs a tap — no faked clip).
## Only UNLOCKED rows emit word_chosen.
enum WordState { ACTIVE, UNLOCKED, LOCKED }

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
## The "Show off my dogs" row (087, P3-4) sits between the breeds section and the feedback row — it
## opens the spotlit showcase. Shown only when there are breeds (zero-height otherwise), so the
## trick-only menu (072) geometry is unchanged.
const SHOWCASE_GAP := 14.0      ## gutter above the showcase pill
const SHOWCASE_H := 48.0        ## the "Vis frem hundene" pill button height
## The "Give feedback" row sits just above the close button so it is always reachable (085, X-8).
const FEEDBACK_GAP := 10.0      ## gutter between the feedback row and the close button
const FEEDBACK_H := 48.0        ## the "Give feedback" pill button height
const RADIUS := 18.0            ## panel corner radius
## The breeds section (079): a small "Breeds" subheading + one row per shipped breed, seated between the
## trick rows and the close button. Zero-height when there are no breeds, so the trick-only geometry the
## 072 tests pin is unchanged.
const BREEDS_GAP := 18.0        ## gutter between the trick block and the breeds section
const BREED_HEADER_H := 30.0    ## the "Breeds" subheading band
const BREED_ROW_H := 54.0       ## one breed row (swatch + name + state/price)
const BREED_ROW_GAP := 8.0      ## gutter between breed rows
const SWATCH_R := 13.0          ## the honest coat-colour chip radius

## The marker words section (092, P5-4): a small "Marker words" subheading + one row per catalog word,
## seated between the breeds section and the showcase/footer pills. Zero-height when no words are fed.
const WORDS_GAP := 18.0        ## gutter between the breeds section (or trick rows if no breeds) and the words section
const WORD_HEADER_H := 30.0    ## the "Marker words" subheading band
const WORD_ROW_H := 54.0       ## one word row (display text + state badge)
const WORD_ROW_GAP := 8.0      ## gutter between word rows

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

## Breed-row palette + badges (079). ACTIVE reads gold like a learned trick; OWNED an available white;
## BUYABLE the calm coin-gold ("adopt"); LOCKED greyed with its price so the cost reads honestly.
const BREED_BADGE := {
	BreedState.ACTIVE: "Active",
	BreedState.OWNED: "Switch",
	BreedState.BUYABLE: "Adopt",
	BreedState.LOCKED: "Locked",
}
const BREED_NAME_ACTIVE := Color(1.0, 0.86, 0.30)     ## the running dog — gold
const BREED_NAME_OWNED := Color(1.0, 1.0, 1.0)        ## owned, tap to switch — white
const BREED_NAME_BUYABLE := Color(1.0, 1.0, 1.0)      ## affordable — white
const BREED_NAME_LOCKED := Color(1.0, 1.0, 1.0, 0.34) ## can't afford — greyed
const BREED_SUBHEAD := Color(1.0, 1.0, 1.0, 0.66)     ## the "Breeds" subheading
const SWATCH_RIM := Color(0.0, 0.0, 0.0, 0.5)         ## a thin dark rim so a pale coat chip reads on the panel

## Marker-word-row palette + badges (092). ACTIVE reads gold (the firing word); UNLOCKED white (tap
## to switch); LOCKED greyed (not yet earned — never tappable, never a faked clip).
const WORD_BADGE := {
	WordState.ACTIVE:   "Active",
	WordState.UNLOCKED: "Switch",
	WordState.LOCKED:   "Locked",
}
const WORD_NAME_ACTIVE  := Color(1.0, 0.86, 0.30)      ## the firing word — gold
const WORD_NAME_UNLOCKED := Color(1.0, 1.0, 1.0)       ## switchable — white
const WORD_NAME_LOCKED  := Color(1.0, 1.0, 1.0, 0.34)  ## not yet earned — greyed
const WORD_SUBHEAD := Color(1.0, 1.0, 1.0, 0.66)       ## the "Marker words" subheading

## The rows main fed in (each {id, state}) + the coin balance shown in the header.
var _rows: Array = []
var _balance := 0
## The breed rows main fed in (each {id, name, tint, state, price}) — empty until the roster wires them,
## so the trick-only menu (072) is byte-for-byte unchanged when there are no breeds.
var _breeds: Array = []
## The marker-word rows main fed in (each {id, display, state}) — empty until P5-4 wires them,
## so the trick-only + breeds-only menu geometry is unchanged when no words are fed.
var _words: Array = []

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

## Classify each shipped breed for the menu (pure — the adopt/switch split is unit-locked). `catalog` is
## the ordered breed list (each {id, name, tint}); `owned` the adopted ids; `active` the running breed;
## `balance` the coins on hand; `price` the fixed adopt cost. Each row carries the price so the Locked /
## Buyable badge can show the cost. Order follows the catalog so the roster reads the same every open.
static func classify_breeds(catalog: Array, owned: Array, active: String, balance: int, price: int) -> Array:
	var rows: Array = []
	for entry in catalog:
		var b: Dictionary = entry
		var id: String = b.id
		var st := BreedState.LOCKED
		if id == active:
			st = BreedState.ACTIVE
		elif owned.has(id):
			st = BreedState.OWNED
		elif balance >= price:
			st = BreedState.BUYABLE
		rows.append({"id": id, "name": b.get("name", id), "tint": b.get("tint", Color(1, 1, 1)),
			"state": st, "price": price})
	return rows

## Whether a breed row is tappable: OWNED switches to it, BUYABLE adopts it. ACTIVE (already running) and
## LOCKED (unaffordable) absorb the tap — no switch, no debt.
static func breed_is_selectable(state: int) -> bool:
	return state == BreedState.OWNED or state == BreedState.BUYABLE

## Classify each catalog word for the menu (pure — the active/unlocked/locked partition is unit-locked).
## `catalog` is the ordered word list (each {id, display, …}); `unlocked` the ids the player has earned;
## `active` the id currently firing at the mark. Each row: {id, display, state}. Order follows the catalog
## so the display reads the same every open. ACTIVE (the firing word) and LOCKED absorb a tap; only an
## UNLOCKED non-active word emits word_chosen (so the player can deliberately switch — P5-4, X-2 holds).
static func classify_words(catalog: Array, unlocked: Array, active: String) -> Array:
	var rows: Array = []
	for entry in catalog:
		var e: Dictionary = entry
		var id: String = e.get("id", "")
		var display: String = e.get("display", id)
		var st := WordState.LOCKED
		if id == active and unlocked.has(id):
			st = WordState.ACTIVE
		elif unlocked.has(id):
			st = WordState.UNLOCKED
		rows.append({"id": id, "display": display, "state": st})
	return rows

## The player-facing name for a trick id (pure). Unknown ids fall back to a capitalised id.
static func display_name(id: String) -> String:
	return LABELS.get(id, id.capitalize())

## Set the rows + the coin balance to show, and request a redraw. main rebuilds this each time it opens
## the menu (or after mastery), so the menu itself stays dumb.
func set_rows(rows: Array, balance: int) -> void:
	_rows = rows
	_balance = maxi(0, balance)
	queue_redraw()

## Set the breed rows to show (079) and request a redraw. Empty until the roster wires them; main rebuilds
## these (via classify_breeds) each time it opens the menu, so the menu itself stays dumb.
func set_breeds(breeds: Array) -> void:
	_breeds = breeds
	queue_redraw()

## Set the marker-word rows to show (092) and request a redraw. Empty until P5-4 wires them; main
## rebuilds these (via classify_words) each time it opens the menu, so the menu stays dumb.
func set_words(rows: Array) -> void:
	_words = rows
	queue_redraw()

func row_count() -> int:
	return _rows.size()

func breed_count() -> int:
	return _breeds.size()

## The i-th breed row's centre in this Control's local (viewport) coords, and its breed id (079). The
## live e2e/Visual-Review capture reads these to land a REAL canvas tap on a specific breed row (the same
## honest-tap proof the 072 menu capture uses for trick rows), rather than hard-coding fragile pixels.
func breed_row_center(i: int) -> Vector2:
	return _breed_row_rect(i).get_center()

func breed_id(i: int) -> String:
	return (_breeds[i] as Dictionary).id

## The i-th trick row's centre + its id (079) — same purpose as the breed accessors above. The breeds
## section makes the panel taller, so the 072-era hard-coded trick-row pixels no longer land; the capture
## reads these instead so a real tap on "Ligg" / "Legg deg" is robust to the layout growing.
func row_center(i: int) -> Vector2:
	return _row_rect(i).get_center()

func row_id(i: int) -> String:
	return (_rows[i] as Dictionary).id

## The i-th marker-word row's centre + its id (092/P5-4) — same capture purpose as the breed/trick
## accessors above, so the live e2e/Visual-Review capture can land a REAL tap on a specific word row.
func word_count() -> int:
	return _words.size()

func word_row_center(i: int) -> Vector2:
	return _word_row_rect(i).get_center()

func word_id(i: int) -> String:
	return (_words[i] as Dictionary).id

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

## The breeds block height (079): the gutter + "Breeds" subheading + one row per breed. Zero when there
## are no breeds, so the trick-only panel geometry (072) is unchanged.
func _breeds_block_h() -> float:
	var n := _breeds.size()
	if n == 0:
		return 0.0
	return BREEDS_GAP + BREED_HEADER_H + n * BREED_ROW_H + (n - 1) * BREED_ROW_GAP

## The marker words block height (092): the gutter + "Marker words" subheading + one row per word.
## Zero when no word rows are fed, so the trick-only panel geometry (072) and the breeds layout
## (079) are both unchanged when the section is absent.
func _words_block_h() -> float:
	var n := _words.size()
	if n == 0:
		return 0.0
	return WORDS_GAP + WORD_HEADER_H + n * WORD_ROW_H + (n - 1) * WORD_ROW_GAP

## The y where the words section (subheading) begins — just below breeds, or just below trick rows
## if there are no breeds.
func _words_top() -> float:
	var panel := _panel_rect()
	return panel.position.y + PANEL_PAD + HEADER_H + _rows_block_h() + _breeds_block_h() + WORDS_GAP

## The i-th word row rect inside the panel (below the "Marker words" subheading).
func _word_row_rect(i: int) -> Rect2:
	var panel := _panel_rect()
	var x := panel.position.x + PANEL_PAD
	var y := _words_top() + WORD_HEADER_H + i * (WORD_ROW_H + WORD_ROW_GAP)
	return Rect2(x, y, panel.size.x - 2.0 * PANEL_PAD, WORD_ROW_H)

## The word row index under a point, or -1 if none.
func _word_row_index_at(pos: Vector2) -> int:
	for i in _words.size():
		if _word_row_rect(i).has_point(pos):
			return i
	return -1

## The showcase pill's block height (087): the gutter + pill, only when there are breeds to show off.
## Zero-height with no breeds, so the trick-only panel geometry (072) is unchanged.
func _showcase_block_h() -> float:
	return (SHOWCASE_GAP + SHOWCASE_H) if not _breeds.is_empty() else 0.0

## The centred modal panel rect for the current size + row/breed/word counts.
## The showcase + feedback pills sit above the close button, so the panel grows to fit them.
func _panel_rect() -> Rect2:
	var pw := minf(size.x - 2.0 * PANEL_MARGIN_X, PANEL_MAX_W)
	var ph := PANEL_PAD + HEADER_H + _rows_block_h() + _breeds_block_h() + _words_block_h() + _showcase_block_h() + CLOSE_GAP + FEEDBACK_H + FEEDBACK_GAP + CLOSE_H + PANEL_PAD
	var px := (size.x - pw) * 0.5
	var py := (size.y - ph) * 0.5
	return Rect2(px, py, pw, ph)

## The y just below the trick + breeds + words blocks — the top of the footer (showcase/feedback/close pills).
func _foot_top() -> float:
	var panel := _panel_rect()
	return panel.position.y + PANEL_PAD + HEADER_H + _rows_block_h() + _breeds_block_h() + _words_block_h()

## The "Vis frem hundene" showcase pill rect (087) — between the breeds section and the feedback row.
## Zero-area (offscreen) when there are no breeds so it is never drawn or hit.
func _showcase_rect() -> Rect2:
	if _breeds.is_empty():
		return Rect2()
	var panel := _panel_rect()
	return Rect2(panel.position.x + PANEL_PAD, _foot_top() + SHOWCASE_GAP,
		panel.size.x - 2.0 * PANEL_PAD, SHOWCASE_H)

## The centre of the showcase row in local coords — the live e2e/capture harness taps this (087).
func showcase_row_center() -> Vector2:
	return _showcase_rect().get_center()

## The y where the breeds section (subheading) begins, just below the trick rows block.
func _breeds_top() -> float:
	var panel := _panel_rect()
	return panel.position.y + PANEL_PAD + HEADER_H + _rows_block_h() + BREEDS_GAP

## The i-th breed row rect inside the panel (below the "Breeds" subheading).
func _breed_row_rect(i: int) -> Rect2:
	var panel := _panel_rect()
	var x := panel.position.x + PANEL_PAD
	var y := _breeds_top() + BREED_HEADER_H + i * (BREED_ROW_H + BREED_ROW_GAP)
	return Rect2(x, y, panel.size.x - 2.0 * PANEL_PAD, BREED_ROW_H)

## The breed row index under a point, or -1 if none.
func _breed_row_index_at(pos: Vector2) -> int:
	for i in _breeds.size():
		if _breed_row_rect(i).has_point(pos):
			return i
	return -1

## The i-th trick row rect inside the panel.
func _row_rect(i: int) -> Rect2:
	var panel := _panel_rect()
	var x := panel.position.x + PANEL_PAD
	var y := panel.position.y + PANEL_PAD + HEADER_H + i * (ROW_H + ROW_GAP)
	return Rect2(x, y, panel.size.x - 2.0 * PANEL_PAD, ROW_H)

## The "Give feedback" pill rect, just above the close button (085, X-8). Placed at the same
## x/width as the close button so they read as a pair at the panel foot. The geometry is the
## single home for this rect — _draw and _gui_input both read it here, never hard-coded.
func _feedback_rect() -> Rect2:
	var panel := _panel_rect()
	var x := panel.position.x + PANEL_PAD
	var y := _foot_top() + _showcase_block_h() + CLOSE_GAP
	return Rect2(x, y, panel.size.x - 2.0 * PANEL_PAD, FEEDBACK_H)

## The centre of the "Give feedback" row in this Control's local coords — the live e2e/capture
## harness reads this to land a REAL canvas tap on the row (same honest-tap proof as row_center).
func feedback_row_center() -> Vector2:
	return _feedback_rect().get_center()

## The close ("Keep training") button rect at the panel foot, below the feedback row.
func _close_rect() -> Rect2:
	var panel := _panel_rect()
	var x := panel.position.x + PANEL_PAD
	var y := _foot_top() + _showcase_block_h() + CLOSE_GAP + FEEDBACK_H + FEEDBACK_GAP
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
## selectable row → trick_chosen; the feedback row → feedback_requested; the close button or a tap
## on the dimmed backdrop → dismissed; a Locked row is absorbed (no signal — never a faked switch).
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
	var bi := _breed_row_index_at(pos)
	if bi >= 0:
		var b: Dictionary = _breeds[bi]
		match b.state:
			BreedState.OWNED:   breed_chosen.emit(b.id)  # switch to an owned dog
			BreedState.BUYABLE: breed_adopt.emit(b.id)   # spend coins to adopt it
			# ACTIVE (already running) / LOCKED (can't afford) absorb the tap — no switch, no debt.
		return
	var wi := _word_row_index_at(pos)
	if wi >= 0:
		var w: Dictionary = _words[wi]
		if w.state == WordState.UNLOCKED:
			word_chosen.emit(w.id)  # switch the active marker word (non-active unlocked only)
		# ACTIVE (already firing) / LOCKED (not earned) absorb the tap — no switch, no faked clip.
		return
	if not _breeds.is_empty() and _showcase_rect().has_point(pos):
		showcase_requested.emit()
		accept_event()
		return
	if _feedback_rect().has_point(pos):
		feedback_requested.emit()
		accept_event()
		return
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
	# The breeds section (079): a subheading + one row per shipped breed (swatch, name, state/price).
	if not _breeds.is_empty():
		var sub_baseline := _breeds_top() + font.get_ascent(BADGE_SIZE)
		_draw_text_outlined(font, Vector2(panel.position.x + PANEL_PAD, sub_baseline), "Breeds",
			BADGE_SIZE, BREED_SUBHEAD)
		for i in _breeds.size():
			_draw_breed_row(font, i)
	# The marker words section (092): a subheading + one row per catalog word (Active/Unlocked/Locked).
	# Zero-height when no words are fed, so the trick-only + breeds-only geometry (072/079) is unchanged.
	if not _words.is_empty():
		var word_sub_baseline := _words_top() + font.get_ascent(BADGE_SIZE)
		_draw_text_outlined(font, Vector2(panel.position.x + PANEL_PAD, word_sub_baseline), "Marker words",
			BADGE_SIZE, WORD_SUBHEAD)
		for i in _words.size():
			_draw_word_row(font, i)
	# The "Vis frem hundene" showcase pill (087) — only when there are breeds. A gold-tinted pill so it
	# reads as the collection surface, distinct from the subtle secondary feedback/close pills below.
	if not _breeds.is_empty():
		var sr := _showcase_rect()
		draw_rect(sr, Color(1.0, 0.86, 0.30, 0.16), true)
		var sb := sr.position.y + sr.size.y * 0.5 + font.get_ascent(CLOSE_SIZE) * 0.5 - font.get_descent(CLOSE_SIZE) * 0.5
		_draw_text_outlined(font, Vector2(sr.position.x, sb), "Vis frem hundene", CLOSE_SIZE,
			Color(1.0, 0.90, 0.55, 0.95), HORIZONTAL_ALIGNMENT_CENTER, sr.size.x)
	# The "Give feedback" pill — subtle-but-present, distinct from trick/breed rows (085, X-8).
	# Same full-width pill shape and draw style as the close button, but at a slightly lower alpha
	# so it reads as secondary/optional (not competing with the trick/breed choices above it).
	var fr := _feedback_rect()
	draw_rect(fr, Color(1.0, 1.0, 1.0, 0.07), true)
	var fb := fr.position.y + fr.size.y * 0.5 + font.get_ascent(CLOSE_SIZE) * 0.5 - font.get_descent(CLOSE_SIZE) * 0.5
	_draw_text_outlined(font, Vector2(fr.position.x, fb), "Give feedback", CLOSE_SIZE, Color(1.0, 1.0, 1.0, 0.70),
		HORIZONTAL_ALIGNMENT_CENTER, fr.size.x)
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

## One breed row (079): the honest coat-colour swatch chip on the left, the breed name beside it, and the
## state badge on the right — with the adopt price appended for a Buyable/Locked row so the cost reads.
func _draw_breed_row(font: Font, i: int) -> void:
	var b: Dictionary = _breeds[i]
	var rect := _breed_row_rect(i)
	var st: int = b.state
	var locked := st == BreedState.LOCKED
	draw_rect(rect, ROW_BG_LOCKED if locked else ROW_BG, true)
	# The coat swatch chip — a filled disc of the real coat colour with a thin dark rim so a pale coat
	# still reads on the panel. An honest colour chip, never a faked breed image.
	var sc := Vector2(rect.position.x + 16.0 + SWATCH_R, rect.position.y + rect.size.y * 0.5)
	var chip: Color = b.get("tint", Color(1, 1, 1))
	if locked:
		chip.a = 0.4  # dim an unaffordable breed's chip so it reads clearly not-yet-yours
	draw_circle(sc, SWATCH_R + 1.0, SWATCH_RIM)
	draw_circle(sc, SWATCH_R, chip)
	# The breed name, to the right of the chip.
	var name_col := BREED_NAME_LOCKED
	if st == BreedState.ACTIVE:
		name_col = BREED_NAME_ACTIVE
	elif st == BreedState.OWNED:
		name_col = BREED_NAME_OWNED
	elif st == BreedState.BUYABLE:
		name_col = BREED_NAME_BUYABLE
	var name_x := sc.x + SWATCH_R + 12.0
	var name_baseline := rect.position.y + rect.size.y * 0.5 + font.get_ascent(NAME_SIZE) * 0.5 - font.get_descent(NAME_SIZE) * 0.5
	_draw_text_outlined(font, Vector2(name_x, name_baseline), str(b.get("name", b.id)), NAME_SIZE, name_col)
	# The state badge, right-aligned. Buyable/Locked append the coin price so the cost reads honestly.
	var badge: String = BREED_BADGE[st]
	if st == BreedState.BUYABLE or st == BreedState.LOCKED:
		badge = "%s %d" % [badge, int(b.get("price", 0))]
	var badge_col := BREED_NAME_LOCKED
	if st == BreedState.ACTIVE:
		badge_col = BADGE_LEARNED
	elif st == BreedState.OWNED:
		badge_col = BADGE_AVAILABLE
	elif st == BreedState.BUYABLE:
		badge_col = COIN_GOLD
	var badge_baseline := rect.position.y + rect.size.y * 0.5 + font.get_ascent(BADGE_SIZE) * 0.5 - font.get_descent(BADGE_SIZE) * 0.5
	_draw_text_outlined(font, Vector2(rect.position.x, badge_baseline), badge, BADGE_SIZE, badge_col,
		HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 14.0)

## One marker-word row (092): the display text on the left and the state badge on the right.
## ACTIVE row highlighted gold (the firing word); UNLOCKED white (tap to switch); LOCKED greyed
## (not yet earned — never tappable, never a faked clip). Mirrors _draw_breed_row.
func _draw_word_row(font: Font, i: int) -> void:
	var w: Dictionary = _words[i]
	var rect := _word_row_rect(i)
	var st: int = w.state
	var locked := st == WordState.LOCKED
	draw_rect(rect, ROW_BG_LOCKED if locked else ROW_BG, true)
	# The word display text (e.g. "Dyktig!"), left-aligned.
	var name_col := WORD_NAME_LOCKED
	if st == WordState.ACTIVE:
		name_col = WORD_NAME_ACTIVE
	elif st == WordState.UNLOCKED:
		name_col = WORD_NAME_UNLOCKED
	var name_baseline := rect.position.y + rect.size.y * 0.5 + font.get_ascent(NAME_SIZE) * 0.5 - font.get_descent(NAME_SIZE) * 0.5
	_draw_text_outlined(font, Vector2(rect.position.x + 14.0, name_baseline),
		str(w.get("display", w.id)), NAME_SIZE, name_col)
	# The state badge, right-aligned.
	var word_badge: String = WORD_BADGE[st]
	var word_badge_col := WORD_NAME_LOCKED
	if st == WordState.ACTIVE:
		word_badge_col = BADGE_LEARNED
	elif st == WordState.UNLOCKED:
		word_badge_col = BADGE_AVAILABLE
	var word_badge_baseline := rect.position.y + rect.size.y * 0.5 + font.get_ascent(BADGE_SIZE) * 0.5 - font.get_descent(BADGE_SIZE) * 0.5
	_draw_text_outlined(font, Vector2(rect.position.x, word_badge_baseline), word_badge, BADGE_SIZE, word_badge_col,
		HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 14.0)
