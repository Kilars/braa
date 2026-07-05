class_name KennelScreen
extends Control
## Phase-8 kennel grid screen (105, K-1/K-3 — the anchor visual slice). A dumb renderer —
## main owns the economy state (CoinPurse/KennelDog.classify_kennel_dogs) and this node
## only draws the 8-cell 2-column grid plus the header, emitting intents via signals.
##
## Browse only: no adopt, no modal, no economy/roster mutation this slice (K-2/K-4/K-5
## land in follow-up tasks). Cell tap emits dog_selected(id); closed emits from the back
## button and triggers main._close_kennel().
##
## Dog band render (116, K-1): each cell shows the game's ACTUAL dog behind the steel bars —
## the stylized-realism licensed Labrador on deploy, the CC0 dog locally, framed face-on. ONE live
## SubViewport renders that dog to a single ViewportTexture, shared across all 8 cells + the modal
## header and `modulate`-tinted toward each dog's band_tint (X-7: render once, reuse 8×). The dog is
## rendered at a neutral desaturated coat so the per-breed modulate reads cleanly, exactly as the old
## baked mid-grey portrait did. Distinct per-breed MODELS stay owner-gated (BUST-068) — the shared
## tinted Labrador is the honest stand-in the flag already names, not a stub. The SubViewport route
## keeps the licensed dog's rendered pixels OUT of public git (no baked PNG) — the earlier baked-CC0
## portrait (107) is retired. Headless-safe: the SubViewport is attached lazily (never in _init),
## and if it can't render (missing model) the band degrades cleanly to tint-only, never a primitive.

signal dog_selected(id: String)    ## cell was tapped → the detail modal task will consume this
signal closed                       ## back/✕ was tapped → main restores the training HUD
signal detail_closed                ## the inspect modal was dismissed (optional hook for main)
signal adopt_requested(id: String)  ## the adopt button was pressed → main._on_kennel_adopt (109, K-4)
signal train_with_requested(id: String)  ## «Tren med [navn]» pressed → main._on_kennel_train_with (110, K-5)

# ---------------------------------------------------------------------------
# Palette — cool/clinical kennel colours (phase8.md:114-118). Named constants,
# not scattered literals (cf. task 029 / CLAUDE.md checklist).
# ---------------------------------------------------------------------------
const C_PANEL_TOP    := Color("f4f6f8")   ## panel gradient top
const C_PANEL_BTM    := Color("e5eaee")   ## panel gradient bottom
const C_CELL         := Color("ffffff")   ## individual cell background
const C_HAIRLINE     := Color("dde3e8")   ## 1.5 px inset hairline on cells
const C_STEEL        := Color("788794")   ## steel-bar tint (used at ~40% alpha in shader)
const C_INK          := Color("2b3742")   ## primary text ink
const C_MUTED        := Color("9aa6b0")   ## muted / secondary text (breed, subtitle)
const C_STATUS_OWNED := Color("57b85c")   ## «Din hund» green
const C_STATUS_EGG   := Color("ff7a85")   ## «Påskeegg» coral (star drawn as geometry — no U+2605 font glyph, 106)
const C_STATUS_NEUTRAL := Color("9aa6b0") ## neutral «Ny» tag
const C_PRICE_OWN    := Color("57b85c")   ## «Din» owned price chip
const C_PRICE_GOLD   := Color("f5b841")   ## buyable price chip (gold)
const C_PRICE_FREE   := Color("ff7a85")   ## «Gratis» coral
const C_CLOSE_BG     := Color("2b3742", 0.12)  ## subtle close button bg
const C_HEADER_BG    := Color("f4f6f8")   ## flat header bg (no gradient needed in code)
const C_COIN_BG      := Color("f5b841")   ## gold coin chip bg
const C_COIN_TEXT    := Color("1e2a3a")   ## ink on gold

# Modal-specific palette (108, K-2 inspect modal). Named constants — no scattered literals.
const C_MODAL_BACKDROP := Color(0.078, 0.11, 0.149, 0.5)  ## rgba(20,28,38,.5) dim overlay
const C_MODAL_SURFACE  := Color("fbfbf7")                  ## warm off-white card surface
const C_MODAL_CREAM    := Color("f4efe6")                  ## warm cream for Unikt trekk card
const C_PIP_FILLED     := Color("4a90e2")                  ## filled stat pip (blue)
const C_PIP_EMPTY      := Color("dfe5ea")                  ## empty stat pip (light grey)
const C_TRAIT_BG       := Color("e8f0f8")                  ## raseegenskaper chip background
const C_TRAIT_INK      := Color("3a6a9a")                  ## raseegenskaper chip text

# ---------------------------------------------------------------------------
# Layout constants
# ---------------------------------------------------------------------------
const HEADER_H       := 72.0
const GRID_PAD       := 12.0    ## scroll container margin from screen edges
const CELL_GAP       := 12.0    ## gap between cells in the GridContainer
const CELL_RADIUS    := 16.0
const BAND_H         := 112.0   ## the tinted portrait band — the MINIMUM band height (short screens)
const FOOTER_BLOCK_H := 72.0    ## the name+breed footer block below the band (cell_h − band_h)
const GRID_COLS      := 2       ## the roster grid is 2-wide; rows = ceil(dogs / cols)
const DESIGN_VP_H    := 1280.0  ## fallback logical viewport height (project.godot) when none is live
const DARK_BAND_LUM  := 0.42    ## below this band luminance, lighten the dog so it reads on a dark band

# Live portrait SubViewport (116, K-1) — renders the game's actual dog once, shared 8× (X-7).
const DOG_SCENE_PATH   := "res://assets/models/dog.glb"           ## CC0 dog (verify/local)
const LICENSED_DOG_PATH := "res://assets/models/dog_licensed.glb" ## licensed Labrador (deploy) — same pick as main._dog_path()
const PORTRAIT_VP_SIZE := Vector2i(384, 340)   ## portrait-ish render target, matches the old bake aspect
## Neutral desaturated coat the dog is rendered at so the per-breed `modulate` reads cleanly. A mid
## grey < 1.0 (like the old baked portrait's base) — the coat atlas is MULTIPLIED by this, killing the
## CC0 brown / licensed yellow so each cell's band_tint modulate lands as a clean tinted silhouette.
const NEUTRAL_COAT     := Color(0.62, 0.62, 0.62)
## Front-quarter face-on view + fill, mirroring the retired bake so head/body/legs all read.
const PORTRAIT_VIEW_DIR := Vector3(0.66, 0.24, 1.0)
const PORTRAIT_FILL     := 0.78
## The idle dog's rest pose faces its own default heading (side-on to the camera), so — unlike the
## training scene, which turns the dog to face the camera for a trick (061, P2-11) — the kennel must
## apply the SAME camera-facing yaw here, or the portrait reads as a broadside profile (PO 2026-07-05
## "framed facing the viewer, not rear/side-slumped"). We rotate the dog to face the camera eye, then
## add a small ¾ offset so the face reads toward the viewer without a foreshortened dead-on stance.
const PORTRAIT_THREE_QUARTER := 0.42  ## radians (~24°) — front-¾, flattering, face clearly to camera
const TAG_RADIUS     := 8.0
const CHIP_RADIUS    := 8.0
const FOOTER_PAD     := 10.0
const CLOSE_SIZE     := 36.0

# Modal layout constants (108, K-2).
const MODAL_CARD_RADIUS    := 24.0   ## card corner radius
const MODAL_CARD_MAX_W     := 330.0  ## max card width (portrait: 390 - 2*30 margin)
const MODAL_BAND_H         := 100.0  ## tinted header band on the modal card
const MODAL_BODY_PAD       := 16.0   ## inner horizontal padding for card body
const MODAL_PIP_W          := 28.0   ## width of one stat pip
const MODAL_PIP_H          := 10.0   ## height of one stat pip
const MODAL_PIP_GAP        := 4.0    ## gap between pips
const MODAL_PIP_RADIUS     := 5.0    ## corner radius on each pip
const MODAL_SECTION_SEP    := 10.0   ## vertical gap between modal sections

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _rows: Array = []          ## last rows passed to render()
var _balance: int = 0          ## last balance passed to render()

## The ONE live portrait SubViewport (116) — renders the game's actual dog to a single
## ViewportTexture shared (modulate-tinted) across all 8 cells + the modal header (X-7).
## Built lazily the first time a portrait is needed (NEVER in _init — headless harness gotcha).
## _portrait_built guards a repeated build attempt; _portrait_tex is null until the viewport is
## in-tree and has rendered a frame, so consumers fall back to tint-only cleanly meanwhile.
var _portrait_vp: SubViewport = null
var _portrait_tex: Texture2D = null
var _portrait_built: bool = false

## Live node refs (built once in _ready, updated per render())
var _coin_label: Label
var _grid: GridContainer

## The currently open modal overlay (null when closed). Freed (not hidden) on close so the
## grid's ScrollContainer position is preserved — we never touch the scroll container on close.
var _modal_overlay: Control = null

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_right  = 1.0
	anchor_bottom = 1.0

func _ready() -> void:
	if _grid == null:
		_build_ui()
	# Re-fit the grid when the logical viewport resolves after the first render, or on an
	# orientation/window change — cell heights are derived from the live viewport (115).
	resized.connect(_on_resized)

## Root resized: the derived cell height may have changed → rebuild the grid to re-fill the
## portrait. Cheap (8 cells) and safe: _refresh never mutates the root size, so no resize loop.
func _on_resized() -> void:
	if _grid != null and not _rows.is_empty():
		_refresh()

# ---------------------------------------------------------------------------
# Public API — main calls render(rows, balance) on open; nothing else mutates state.
# ---------------------------------------------------------------------------

## Feed new rows (from KennelDog.classify_kennel_dogs) and redraw.
## Lazy-builds the UI if _ready() hasn't fired yet (headless test harness: _ready
## is deferred; render() forces the build so the test can assert on the grid).
func render(rows: Array, balance: int) -> void:
	if _grid == null:
		_build_ui()
	_rows   = rows
	_balance = balance
	_refresh()

## Live coin balance for the header chip (updated without a full re-render when only
## the balance changes — kept simple: just call render() again).
func balance() -> int:
	return _balance

## Open the K-2 inspect modal for the dog with the given id. Builds an overlay on top of the
## grid without touching the ScrollContainer — scroll position is therefore preserved across
## open+close. Calling open_detail while a modal is already open replaces it cleanly.
## Headless-safe: builds the overlay node tree without requiring is_inside_tree(); tweens are
## guarded by is_inside_tree() so the headless test harness never crashes.
func open_detail(id: String) -> void:
	if _grid == null:
		_build_ui()
	close_detail()  # replace any existing modal cleanly
	var detail := KennelDog.detail_for(id)
	# Augment detail with economy state so _build_adopt_button can gate on affordability
	# and render the correct label. These keys are NOT in KennelDog.detail_for (it stays
	# economy-unaware) — we compute them here from the last rendered balance (_balance)
	# and the classify rows if available, so the modal always reflects the live state.
	var is_owned := false
	var is_active := false
	for row in _rows:
		if row.get("id") == id:
			is_owned = row.get("owned", false)
			is_active = row.get("active", false)
			break
	detail["owned"] = is_owned
	detail["active"] = is_active
	detail["affordable"] = is_owned or detail["price"] == 0 or _balance >= detail["price"]
	_modal_overlay = _build_modal_overlay(detail)
	add_child(_modal_overlay)
	# Publish the modal's action-button centre for the Visual-Review capture (110) — after the layout
	# has settled (containers resolve child rects over a couple of frames) so get_global_rect() is
	# valid. Web-only, no-op elsewhere.
	if OS.has_feature("web"):
		_publish_modal_action()
	# Animate if inside the scene tree and not reduced-motion (X-5).
	if _modal_overlay.is_inside_tree() and not ReducedMotion.query():
		_modal_overlay.modulate.a = 0.0
		var card := _modal_overlay.find_child("ModalCard", true, false)
		if card != null:
			(card as Control).scale = Vector2(0.96, 0.96)
			(card as Control).pivot_offset = Vector2(MODAL_CARD_MAX_W * 0.5, 400.0)
		var tw := _modal_overlay.create_tween()
		tw.set_parallel(true)
		tw.tween_property(_modal_overlay, "modulate:a", 1.0, 0.2)
		if card != null:
			tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Close the inspect modal. Frees the overlay so the ScrollContainer scroll position is
## preserved (we never rebuild the grid). Emits detail_closed.
func close_detail() -> void:
	if _modal_overlay != null:
		_modal_overlay.queue_free()
		_modal_overlay = null
		detail_closed.emit()

# ---------------------------------------------------------------------------
# UI construction (called once from _ready)
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Full-screen cool-grey panel background (drawn via a ColorRect; no gradient node
	# needed — two rects stacked give a convincing top-bottom tint for GL Compatibility).
	var bg_top := ColorRect.new()
	bg_top.name = "BgTop"
	bg_top.color = C_PANEL_TOP
	bg_top.anchor_right  = 1.0
	bg_top.anchor_bottom = 1.0
	bg_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_top)

	# Slightly darker bottom half to suggest the gradient.
	var bg_btm := ColorRect.new()
	bg_btm.name = "BgBtm"
	bg_btm.color = C_PANEL_BTM
	bg_btm.color.a = 0.5
	bg_btm.anchor_right  = 1.0
	bg_btm.anchor_top    = 0.5
	bg_btm.anchor_bottom = 1.0
	bg_btm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_btm)

	_build_header()
	_build_scroll_grid()

func _build_header() -> void:
	# Fixed header band: white bg, hairline bottom border.
	var hdr := PanelContainer.new()
	hdr.name = "Header"
	hdr.anchor_right  = 1.0
	hdr.offset_bottom = HEADER_H
	var hdr_style := StyleBoxFlat.new()
	hdr_style.bg_color = C_CELL
	hdr_style.border_width_bottom = 1
	hdr_style.border_color = C_HAIRLINE
	hdr_style.content_margin_left   = 16.0
	hdr_style.content_margin_right  = 12.0
	hdr_style.content_margin_top    = 0.0
	hdr_style.content_margin_bottom = 0.0
	hdr.add_theme_stylebox_override("panel", hdr_style)
	add_child(hdr)

	var row := HBoxContainer.new()
	row.name = "HeaderRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	hdr.add_child(row)

	# Close / back button (✕) — top-left.
	var close_btn := Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "x"   ## ASCII x — safe in all fonts (no tofu risk, 089/CLAUDE.md)
	close_btn.add_theme_font_override("font", DesignSystem.font_body_bold())
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color",         C_INK)
	close_btn.add_theme_color_override("font_hover_color",   C_INK)
	close_btn.add_theme_color_override("font_pressed_color", C_MUTED)
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(CLOSE_SIZE, CLOSE_SIZE)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = C_CLOSE_BG
	close_style.set_corner_radius_all(int(CLOSE_SIZE * 0.5))
	close_style.content_margin_left  = 6.0
	close_style.content_margin_right = 6.0
	for st in ["normal", "hover", "pressed", "disabled"]:
		close_btn.add_theme_stylebox_override(st, close_style)
	close_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	close_btn.pressed.connect(func(): closed.emit())
	row.add_child(close_btn)

	# Title + subtitle, centred — let it flex.
	var title_col := VBoxContainer.new()
	title_col.name = "TitleCol"
	title_col.alignment = BoxContainer.ALIGNMENT_CENTER
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_col.add_theme_constant_override("separation", 0)
	row.add_child(title_col)

	var title := Label.new()
	title.name = "Title"
	title.text = "Kennelen"
	title.add_theme_font_override("font", DesignSystem.font_display())
	title.add_theme_font_size_override("font_size", DesignSystem.T_TITLE)
	title.add_theme_color_override("font_color", C_INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_col.add_child(title)

	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = "Profesjonell fasilitet · 8 plasser"
	sub.add_theme_font_override("font", DesignSystem.font_body())
	sub.add_theme_font_size_override("font_size", DesignSystem.T_SMALL)
	sub.add_theme_color_override("font_color", C_MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_col.add_child(sub)

	# Live coin chip — right side.
	var coin_pill := PanelContainer.new()
	coin_pill.name = "CoinPill"
	coin_pill.custom_minimum_size = Vector2(80, 32)
	var coin_style := StyleBoxFlat.new()
	coin_style.bg_color = C_COIN_BG
	coin_style.set_corner_radius_all(DesignSystem.R_PILL)
	coin_style.content_margin_left  = 10.0
	coin_style.content_margin_right = 10.0
	coin_style.content_margin_top   = 4.0
	coin_style.content_margin_bottom = 4.0
	coin_pill.add_theme_stylebox_override("panel", coin_style)
	row.add_child(coin_pill)

	_coin_label = Label.new()
	_coin_label.name = "CoinLabel"
	_coin_label.text = "0 🪙"
	_coin_label.add_theme_font_override("font", DesignSystem.font_body_bold())
	_coin_label.add_theme_font_size_override("font_size", DesignSystem.T_SMALL)
	_coin_label.add_theme_color_override("font_color", C_COIN_TEXT)
	_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coin_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_coin_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_pill.add_child(_coin_label)

func _build_scroll_grid() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.anchor_right  = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_top    = HEADER_H
	scroll.offset_left   = GRID_PAD
	scroll.offset_right  = -GRID_PAD
	scroll.offset_bottom = -GRID_PAD
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", int(CELL_GAP))
	grid.add_theme_constant_override("v_separation", int(CELL_GAP))
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	_grid = grid

# ---------------------------------------------------------------------------
# Refresh — rebuild the grid from current _rows / _balance.
# ---------------------------------------------------------------------------

func _refresh() -> void:
	if _grid == null or _coin_label == null:
		return  # not ready yet

	# Update coin chip text.
	_coin_label.text = "%d mynter" % _balance

	# Clear and repopulate the grid.
	for c in _grid.get_children():
		c.queue_free()

	var reduced := ReducedMotion.query()
	for i in _rows.size():
		var row: Dictionary = _rows[i]
		var cell := _make_cell(row)
		_grid.add_child(cell)
		# Pop-in animation: small scale-up + fade, lightly staggered (X-5: skip stagger when reduced).
		# Guard on cell.is_inside_tree() — headless harness may not have a running SceneTree.
		if cell.is_inside_tree():
			cell.modulate.a = 0.0
			cell.scale = Vector2(0.92, 0.92)
			cell.pivot_offset = Vector2(cell.custom_minimum_size.x * 0.5, cell.custom_minimum_size.y * 0.5)
			var delay := 0.0 if reduced else i * 0.045
			var tw := cell.create_tween()
			tw.tween_interval(delay)
			tw.tween_property(cell, "modulate:a", 1.0, 0.15)
			tw.parallel().tween_property(cell, "scale", Vector2(1.0, 1.0), 0.18)

# ---------------------------------------------------------------------------
# Cell construction — one reusable Button per classify row.
# ---------------------------------------------------------------------------

# Logical (stretch-space) viewport height. The root is anchored full-rect and the project
# stretches canvas_items with aspect "expand", so on a tall phone the logical height grows past
# the 1280 design (e.g. ~1558 at 390×844) — cells must be sized against the LIVE height, not a
# constant, or 4 rows fill only the top ~55% and the lower portrait reads as unfinished (115).
func _viewport_h() -> float:
	if is_inside_tree():
		var vp := get_viewport()
		if vp != null:
			var h := vp.get_visible_rect().size.y
			if h > 0.0:
				return h
	if size.y > 0.0:
		return size.y
	return DESIGN_VP_H  # headless / pre-layout fallback

# Cell height that makes the whole roster FILL the portrait below the header: the available
# height (viewport − header − bottom pad − inter-row gaps) split evenly across the rows. Never
# smaller than the natural band+footer, so short screens still scroll instead of squashing.
func _target_cell_h() -> float:
	var rows := int(ceil(float(_rows.size()) / float(GRID_COLS)))
	if rows < 1:
		rows = 1
	var avail := _viewport_h() - HEADER_H - GRID_PAD - float(rows - 1) * CELL_GAP
	return max(avail / float(rows), BAND_H + FOOTER_BLOCK_H)

func _make_cell(row: Dictionary) -> Button:
	var btn := Button.new()
	btn.name = "Cell_" + str(row.id)
	# White StyleBoxFlat, radius 16, soft shadow + hairline (phase8.md:119).
	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = C_CELL
	normal_sb.set_corner_radius_all(int(CELL_RADIUS))
	normal_sb.border_width_top    = 1
	normal_sb.border_width_right  = 1
	normal_sb.border_width_bottom = 1
	normal_sb.border_width_left   = 1
	normal_sb.border_color = C_HAIRLINE
	normal_sb.shadow_color  = Color(0.114, 0.165, 0.227, 0.10)
	normal_sb.shadow_size   = 12
	normal_sb.shadow_offset = Vector2(0, 4)
	# Zero content margins so the VBoxContainer inside fills the entire cell area.
	normal_sb.content_margin_left   = 0.0
	normal_sb.content_margin_right  = 0.0
	normal_sb.content_margin_top    = 0.0
	normal_sb.content_margin_bottom = 0.0
	# Pressed: gentle scale-down is handled via scale tween below; use a slightly-darker bg.
	var pressed_sb := normal_sb.duplicate() as StyleBoxFlat
	pressed_sb.bg_color = Color("f4f6f8")
	for st in ["normal", "hover", "pressed", "disabled"]:
		btn.add_theme_stylebox_override(st, normal_sb if st != "pressed" else pressed_sb)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.focus_mode = Control.FOCUS_NONE
	# Width: the GridContainer expands cells to fill the row. Height is derived so the 8-dog
	# roster fills the portrait (115) rather than stopping at ~55% with a dead grey lower half.
	var cell_h := _target_cell_h()
	btn.custom_minimum_size = Vector2(160.0, cell_h)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Emit dog_selected on press. Scale-down affordance skipped in headless (no running tween).
	var dog_id: String = row.id
	btn.pressed.connect(_on_cell_pressed.bind(dog_id))

	# Build the cell contents as a VBoxContainer anchored to fill the Button.
	# Button is not a container (no propagation to children), so anchor manually.
	var vbox := VBoxContainer.new()
	vbox.name = "CellContent"
	vbox.add_theme_constant_override("separation", 0)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.anchor_right  = 1.0
	vbox.anchor_bottom = 1.0
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_child(vbox)

	# 1. Portrait band with steel bars overlay and status/price tags. The band takes all the
	#    cell height above the fixed footer block, so a taller cell shows a bigger dog.
	vbox.add_child(_make_band(row, cell_h - FOOTER_BLOCK_H))

	# 2. Footer: name + breed (PanelContainer with white bg).
	vbox.add_child(_make_footer(row))

	return btn

## The top portrait band: tinted background + the shared live-SubViewport dog (116) behind the steel
## bars + status tag (top-left) + price chip (bottom-right). Distinct per-breed models stay owner-
## gated (BUST-068) — every cell shares the one stylized-realism Labrador, modulate-tinted per breed.
func _make_band(row: Dictionary, band_h: float = BAND_H) -> Control:
	var band := Control.new()
	band.name = "Band"
	band.custom_minimum_size = Vector2(0, max(band_h, BAND_H))
	band.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Tinted background.
	var bg := ColorRect.new()
	bg.name = "BandBg"
	bg.color = row.band_tint
	bg.anchor_right  = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(bg)

	# Dog portrait (116, K-1): the shared live-SubViewport dog, behind the bars, modulate-tinted
	# toward this dog's NATURAL COAT hue (portrait_tint, 117) — decoupled from the rarity band bg so
	# Bella-the-Labrador reads warm cream, not her blue owned-band. All 8 read as tinted Labradors.
	# Skipped cleanly when the SubViewport isn't renderable yet (tint-only fallback) — never a primitive.
	var tex := _get_portrait_texture()
	if tex != null:
		var dog := TextureRect.new()
		dog.name = "DogPortrait"
		dog.texture = tex
		dog.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dog.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dog.modulate = _band_dog_tint(row.portrait_tint)
		dog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Bottom-anchored, slightly inset from the band edges so the feet sit just above the
		# bars' base frame and the silhouette doesn't touch the sides.
		dog.anchor_left   = 0.0
		dog.anchor_right  = 1.0
		dog.anchor_top    = 0.0
		dog.anchor_bottom = 1.0
		dog.offset_left   = 8.0
		dog.offset_right  = -8.0
		dog.offset_top    = 8.0
		dog.offset_bottom = -3.0
		band.add_child(dog)

	# Steel-bar overlay drawn in code (GL Compatibility — no shader needed for simple stripes).
	# Repeating vertical stripes ~2px on ~29px pitch, #788794 @ 40%, + 2px inset frame.
	# Rendered as a mouse-transparent Control using _draw.
	var bars := _SteelBars.new()
	bars.name = "SteelBars"
	bars.anchor_right  = 1.0
	bars.anchor_bottom = 1.0
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(bars)

	# Status tag — top-left (owned / easter-egg / neutral).
	if row.status_label != "":
		var tag := _make_tag(row)
		tag.anchor_left   = 0.0
		tag.anchor_right  = 0.0
		tag.anchor_top    = 0.0
		tag.anchor_bottom = 0.0
		tag.offset_left   = 6.0
		tag.offset_top    = 6.0
		# Width auto-sizes; cap it.
		tag.offset_right  = 6.0 + 90.0
		tag.offset_bottom = 6.0 + 22.0
		band.add_child(tag)

	# Price chip — bottom-right.
	var chip := _make_price_chip(row)
	chip.anchor_left   = 1.0
	chip.anchor_right  = 1.0
	chip.anchor_top    = 1.0
	chip.anchor_bottom = 1.0
	chip.offset_left   = -84.0
	chip.offset_right  = -6.0
	chip.offset_top    = -28.0
	chip.offset_bottom = -6.0
	band.add_child(chip)

	return band

## The ONE live portrait texture (116, X-7): the game's actual dog rendered face-on by a shared
## SubViewport, fed to every cell + the modal header and modulate-tinted per breed. Lazily builds
## the SubViewport on first call (never in _init — headless harness gotcha). Returns the
## ViewportTexture, or null if the viewport can't be built yet / the model failed to load, so the
## band degrades cleanly to tint-only rather than erroring. Cheap after the first build (cached).
func _get_portrait_texture() -> Texture2D:
	if not _portrait_built:
		_portrait_built = true
		_build_portrait_viewport()
	return _portrait_tex

## Build the shared portrait SubViewport: instance the game's dog (licensed on deploy, CC0 locally —
## same pick as main._dog_path()), flatten + neutral-tint the coat, frame it face-on with a Camera3D
## via DogBounds/DogFraming, and light it. The ViewportTexture is cached in _portrait_tex. Attached
## as a child of this Control (headless-safe: SubViewports render off-screen; guarded .play()).
func _build_portrait_viewport() -> void:
	var path := _portrait_dog_path()
	if not ResourceLoader.exists(path):
		return  # no dog asset → tint-only fallback (never a primitive)
	var packed := load(path) as PackedScene
	if packed == null:
		return
	var vp := SubViewport.new()
	vp.name = "KennelPortraitViewport"
	vp.size = PORTRAIT_VP_SIZE
	vp.transparent_bg = true
	vp.own_world_3d = true                        # isolated world — no bleed to/from the main scene
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS  # live idle → breathing portrait
	add_child(vp)
	_portrait_vp = vp

	var dog: Node = packed.instantiate()
	dog.name = "KennelPortraitDog"
	vp.add_child(dog)
	CoatOpaque.flatten(dog)                       # kill the translucent fur-mask panels (P1-1/P1-9)
	CoatTint.apply(dog, NEUTRAL_COAT)             # neutral grey so the per-cell modulate reads cleanly

	# The CC0 glb ships its OWN Camera3D (CLAUDE.md gotcha) — inside this isolated world it would stay
	# `current` and frame the dog itself, overriding ours. Strip every bundled camera (main.gd:457).
	for bundled in _find_all_cameras(dog):
		(bundled as Camera3D).current = false
		bundled.queue_free()

	# Settle the idle to a natural standing frame (skinned pose snaps from rest on frame 0).
	# Guard .play() on is_inside_tree() — the SubViewport child is in-tree here, but headless-safe.
	var ap := DogClips.find_animation_player(dog)
	if ap != null and ap.is_inside_tree():
		var clips := DogClips.resolve(ap.get_animation_list())
		if clips.idle != "":
			ap.play(clips.idle)
			ap.seek(0.6, true)

	# Key + gentle fill so the coat reads as a rounded animal, not a flat cut-out.
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-34.0, -38.0, 0.0)
	key.light_energy = 1.2
	vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-8.0, 145.0, 0.0)
	fill.light_energy = 0.35
	vp.add_child(fill)
	# Ambient via the isolated world's own environment so the shadowed side isn't black.
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.74, 0.78)
	env.ambient_light_energy = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)

	# Frame the dog face-on: measure its honest standing bounds, place a 3/4-front telephoto camera
	# far enough that the whole bounding SPHERE fits at any angle (no clip). DogFraming.VIEW_DIR already
	# faces the dog's front; we use the wider PORTRAIT_VIEW_DIR (more side/lift) for a flattering head-
	# visible portrait, reusing the retired bake's proven framing math.
	var box := DogBounds.measure(dog)
	var cam := Camera3D.new()
	cam.name = "KennelPortraitCam"
	cam.fov = 30.0                                # telephoto: flattens perspective, clean silhouette
	vp.add_child(cam)                             # in-tree before look_at (026 — no Transform3D error)
	var aspect := float(PORTRAIT_VP_SIZE.x) / float(PORTRAIT_VP_SIZE.y)
	var radius := maxf(maxf(box.size.x, box.size.y), box.size.z) * 0.5
	var v_half := deg_to_rad(cam.fov) * 0.5
	var h_half := atan(tan(v_half) * aspect)
	var half_angle := minf(v_half, h_half)
	var dist := radius / tan(half_angle) / PORTRAIT_FILL
	var target := DogFraming.target(box)
	var eye := target + PORTRAIT_VIEW_DIR.normalized() * dist
	cam.look_at_from_position(eye, target, Vector3.UP)
	cam.make_current()                            # scoped to this SubViewport's own world

	# Turn the dog to FACE the camera (the raw idle rest pose is side-on). Same convention main.gd
	# uses for the trick face-turn: heading = atan2(camX - dogX, camZ - dogZ) applied to the root
	# basis about UP. A small ¾ offset keeps it a flattering front-¾, not a dead-on foreshortened
	# stance. Done AFTER the sphere-fit distance (rotation about UP keeps the fit radius) so no clip.
	if dog is Node3D:
		var d3 := dog as Node3D
		var to_cam := eye - d3.transform.origin
		var heading := atan2(to_cam.x, to_cam.z) + PORTRAIT_THREE_QUARTER
		d3.transform.basis = d3.transform.basis.rotated(Vector3.UP, heading)

	_portrait_tex = vp.get_texture()

## The dog to render in the kennel portrait: the licensed Labrador on deploy, the CC0 dog locally —
## the SAME pick as main._dog_path() so the kennel shows the game's actual dog. (No debug override:
## the kennel always mirrors whatever the running build renders in training.)
func _portrait_dog_path() -> String:
	if ResourceLoader.exists(LICENSED_DOG_PATH):
		return LICENSED_DOG_PATH
	return DOG_SCENE_PATH

## Collect every Camera3D in a subtree (strip the CC0 dog's bundled camera — CLAUDE.md gotcha).
func _find_all_cameras(n: Node) -> Array:
	var out: Array = []
	if n is Camera3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_all_cameras(c))
	return out

## The modulate for the dog portrait, given the dog's NATURAL COAT hue (portrait_tint, 117 — a
## warm cream for Bella, each other dog its plausible band hue; DECOUPLED from the rarity band bg).
## The dog renders at NEUTRAL_COAT (a mid-grey base < 1.0), so a LIGHT/mid coat renders the dog as a
## warm tinted silhouette. A DARK coat (luminance < DARK_BAND_LUM) would leave a near-black dog, so
## we lighten it toward white — a light silhouette that still reads. Either way the dog carries a
## natural coat colour, never the raw band background.
func _band_dog_tint(coat_hue: Color) -> Color:
	if coat_hue.get_luminance() < DARK_BAND_LUM:
		return coat_hue.lerp(Color.WHITE, 0.7)
	return coat_hue

## Status tag (PanelContainer pill): owned green, easter coral, neutral muted.
## For the secret/easter row a drawn _StarPip is prepended before the word label —
## no font glyph (U+2605 is absent in Baloo 2 / Nunito; task 106 / 089 precedent).
func _make_tag(row: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "StatusTag"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_color: Color
	if row.owned:
		bg_color = C_STATUS_OWNED
	elif row.secret:
		bg_color = C_STATUS_EGG
	else:
		bg_color = C_STATUS_NEUTRAL
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(int(TAG_RADIUS))
	sb.content_margin_left   = 6.0
	sb.content_margin_right  = 6.0
	sb.content_margin_top    = 2.0
	sb.content_margin_bottom = 2.0
	panel.add_theme_stylebox_override("panel", sb)

	if row.secret:
		# Easter tag: [star pip][label] in an HBoxContainer — no U+2605 glyph anywhere.
		var hbox := HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 3)
		panel.add_child(hbox)
		var pip := _StarPip.new()
		pip.name = "StarPip"
		pip.custom_minimum_size = Vector2(11.0, 11.0)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(pip)
		var lbl := Label.new()
		lbl.text = row.status_label
		lbl.add_theme_font_override("font", DesignSystem.font_body_bold())
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(lbl)
	else:
		var lbl := Label.new()
		lbl.text = row.status_label
		lbl.add_theme_font_override("font", DesignSystem.font_body_bold())
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(lbl)

	return panel

## Price chip (Label in a PanelContainer pill): colour from rarity / ownership.
func _make_price_chip(row: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "PriceChip"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chip_color: Color
	if row.owned:
		chip_color = C_PRICE_OWN
	elif row.secret:
		chip_color = C_PRICE_FREE
	else:
		chip_color = C_PRICE_GOLD
	var sb := StyleBoxFlat.new()
	sb.bg_color = chip_color
	sb.set_corner_radius_all(int(CHIP_RADIUS))
	sb.content_margin_left   = 7.0
	sb.content_margin_right  = 7.0
	sb.content_margin_top    = 3.0
	sb.content_margin_bottom = 3.0
	panel.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = row.price_label
	lbl.add_theme_font_override("font", DesignSystem.font_body_bold())
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color.WHITE if row.owned or row.secret else C_COIN_TEXT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)
	return panel

## Cell footer: name (Baloo 2 700) + breed (Nunito muted) in a PanelContainer for bg fill.
func _make_footer(row: Dictionary) -> PanelContainer:
	var footer := PanelContainer.new()
	footer.name = "Footer"
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fp := StyleBoxFlat.new()
	fp.bg_color = C_CELL
	fp.content_margin_left   = FOOTER_PAD
	fp.content_margin_right  = FOOTER_PAD
	fp.content_margin_top    = 7.0
	fp.content_margin_bottom = 8.0
	fp.corner_radius_bottom_left  = int(CELL_RADIUS)
	fp.corner_radius_bottom_right = int(CELL_RADIUS)
	footer.add_theme_stylebox_override("panel", fp)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 1)
	footer.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = row.name
	name_lbl.add_theme_font_override("font", DesignSystem.font_display())
	name_lbl.add_theme_font_size_override("font_size", DesignSystem.T_HEAD)
	name_lbl.add_theme_color_override("font_color", C_INK)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.clip_text = true
	col.add_child(name_lbl)

	var breed_lbl := Label.new()
	breed_lbl.text = row.breed
	breed_lbl.add_theme_font_override("font", DesignSystem.font_body_bold())
	breed_lbl.add_theme_font_size_override("font_size", DesignSystem.T_SMALL)
	breed_lbl.add_theme_color_override("font_color", C_MUTED)
	breed_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	breed_lbl.clip_text = true
	col.add_child(breed_lbl)

	return footer

## Handle a cell press: emit dog_selected with the dog's id.
## Uses a named method so the signal bind is GDScript-safe in all harnesses.
## Scale-down affordance is omitted here; a future refinement can wire per-cell tweens
## via a separate signal or by finding the button from the emitted id.
func _on_cell_pressed(dog_id: String) -> void:
	dog_selected.emit(dog_id)

# ---------------------------------------------------------------------------
# Modal overlay builder (108, K-2 — inspect modal).
# Builds the full-rect overlay with backdrop + centered card. Never touches the
# ScrollContainer so grid scroll position is preserved across open+close.
# ---------------------------------------------------------------------------

## Build the full-rect overlay: backdrop ColorRect + centered card PanelContainer.
## Returns a Control sized to fill the parent (this KennelScreen) anchored full-rect.
func _build_modal_overlay(detail: Dictionary) -> Control:
	var overlay := Control.new()
	overlay.name = "ModalOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Dim backdrop — a full-rect ColorRect. Tapping it closes the modal.
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = C_MODAL_BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	# Tap the backdrop → close the modal.
	backdrop.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			close_detail())
	overlay.add_child(backdrop)

	# Centered card — a PanelContainer with radius-24 surface.
	var card := PanelContainer.new()
	card.name = "ModalCard"
	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = C_MODAL_SURFACE
	card_sb.set_corner_radius_all(int(MODAL_CARD_RADIUS))
	card_sb.shadow_color = Color(0.114, 0.165, 0.227, 0.18)
	card_sb.shadow_size  = 20
	card_sb.shadow_offset = Vector2(0, 6)
	card_sb.content_margin_left   = 0.0
	card_sb.content_margin_right  = 0.0
	card_sb.content_margin_top    = 0.0
	card_sb.content_margin_bottom = 0.0
	card.add_theme_stylebox_override("panel", card_sb)
	# Center the card: anchor to center and offset by half the card width/height.
	# Use a fixed max width; height is auto (content-driven via VBoxContainer).
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(MODAL_CARD_MAX_W, 0.0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Position the card vertically centred but slightly above centre (golden ratio feel).
	card.anchor_top    = 0.5
	card.anchor_bottom = 0.5
	card.anchor_left   = 0.5
	card.anchor_right  = 0.5
	# Let the card grow downward from its vertical centre offset.
	# We can't know height at build time, so we use a Container parent for centering.
	overlay.remove_child(backdrop)
	# Rebuild with a CenterContainer so the card is properly centred.
	var center := CenterContainer.new()
	center.name = "CardCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(backdrop)
	overlay.add_child(center)

	# The card's inner VBox holds all sections stacked vertically.
	var vbox := VBoxContainer.new()
	vbox.name = "CardVBox"
	vbox.add_theme_constant_override("separation", 0)
	card.add_child(vbox)

	# 1. Header band: per-dog tint + steel bars + ✕ close button.
	vbox.add_child(_build_modal_band(detail))

	# 2. Body content in a VBoxContainer with padding.
	var body := VBoxContainer.new()
	body.name = "ModalBody"
	body.add_theme_constant_override("separation", int(MODAL_SECTION_SEP))
	var body_m := MarginContainer.new()
	body_m.name = "BodyMargin"
	body_m.add_theme_constant_override("margin_left",   int(MODAL_BODY_PAD))
	body_m.add_theme_constant_override("margin_right",  int(MODAL_BODY_PAD))
	body_m.add_theme_constant_override("margin_top",    int(MODAL_SECTION_SEP))
	body_m.add_theme_constant_override("margin_bottom", int(MODAL_BODY_PAD))
	body_m.add_child(body)
	vbox.add_child(body_m)

	# 2a. Blurb (warm line, Nunito body).
	body.add_child(_build_modal_blurb(detail))

	# 2a★. K-6 (task 111): the secret dog gets a coral «★ Påskeegg» ribbon above the stats — the
	# star is drawn geometry (_StarPip), no U+2605 font glyph (tofu-safe, 106 precedent).
	if detail.get("secret", false):
		body.add_child(_build_egg_ribbon())

	# 2b. 4 stat rows.
	body.add_child(_build_modal_stats(detail))

	# 2c. Raseegenskaper chip row.
	body.add_child(_build_modal_traits(detail))

	# 2d. Unikt trekk — warm cream card.
	body.add_child(_build_modal_unique_trait(detail))

	# 2e. Trick list (K-8): "Kan lære: Sitt · Ligg · Legg deg".
	body.add_child(_build_modal_trick_list(detail))

	# Full-width action button (109 adopt + 110 switch): unowned → blue «Adopter · N mynt»;
	# owned & not active → green «Tren med [navn]»; owned & active → a non-tappable «Trener nå»
	# state (no dead button). Dispatched by _build_action_button.
	var action_node := _build_action_button(detail)
	if action_node != null:
		body.add_child(action_node)

	center.add_child(card)
	return overlay

## Modal header band: per-dog tint + steel bars + ✕ close button (top-right).
## Reuses the same _SteelBars inner class as the grid cells for visual consistency.
func _build_modal_band(detail: Dictionary) -> Control:
	var band := Control.new()
	band.name = "ModalBand"
	band.custom_minimum_size = Vector2(0, MODAL_BAND_H)
	band.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Tinted background.
	var bg := ColorRect.new()
	bg.name = "ModalBandBg"
	bg.color = detail["band_tint"]
	bg.anchor_right  = 1.0
	bg.anchor_bottom = 1.0
	# Round only the top corners to match the card's radius-24 top edge.
	# ColorRect doesn't support per-corner radius — use a StyleBoxFlat on a Panel instead.
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(bg)

	# Shared dog portrait (116): the same live SubViewport texture as the grid cells, modulate-tinted
	# toward this dog's NATURAL COAT hue (portrait_tint, 117) — so the modal header shows the same
	# stylized-realism Labrador (Bella warm cream, not blue) behind the bars.
	# Skipped cleanly when the viewport isn't renderable yet (tint-only) — never a primitive.
	var mtex := _get_portrait_texture()
	if mtex != null:
		var mdog := TextureRect.new()
		mdog.name = "ModalDogPortrait"
		mdog.texture = mtex
		mdog.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mdog.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mdog.modulate = _band_dog_tint(detail["portrait_tint"])
		mdog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mdog.set_anchors_preset(Control.PRESET_FULL_RECT)
		mdog.offset_left   = 8.0
		mdog.offset_right  = -8.0
		mdog.offset_top    = 6.0
		mdog.offset_bottom = -3.0
		band.add_child(mdog)

	# Steel-bar overlay (reuse _SteelBars for GL-Compat–safe rendering).
	var bars := _SteelBars.new()
	bars.name = "ModalSteelBars"
	bars.anchor_right  = 1.0
	bars.anchor_bottom = 1.0
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(bars)

	# Dog name along the band BOTTOM edge (white, Baloo 2 display) — clear of the portrait's
	# face, which the live render turns toward the viewer in the upper band (117, PO 2026-07-05:
	# the centred title previously overlapped the dog render). Bottom-aligned reads as a nameplate.
	var name_lbl := Label.new()
	name_lbl.name = "ModalDogName"
	name_lbl.text = detail["name"]
	name_lbl.add_theme_font_override("font", DesignSystem.font_display())
	name_lbl.add_theme_font_size_override("font_size", DesignSystem.T_TITLE)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_BOTTOM
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	name_lbl.offset_bottom = -6.0
	band.add_child(name_lbl)

	# ✕ close button — top-right of the band. ASCII "x", no tofu.
	var close_btn := Button.new()
	close_btn.name = "ModalClose"
	close_btn.text = "x"
	close_btn.add_theme_font_override("font", DesignSystem.font_body_bold())
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_color_override("font_color",         Color.WHITE)
	close_btn.add_theme_color_override("font_hover_color",   Color.WHITE)
	close_btn.add_theme_color_override("font_pressed_color", Color(1,1,1,0.6))
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(CLOSE_SIZE, CLOSE_SIZE)
	var close_sb := StyleBoxFlat.new()
	close_sb.bg_color = Color(0.0, 0.0, 0.0, 0.20)
	close_sb.set_corner_radius_all(int(CLOSE_SIZE * 0.5))
	close_sb.content_margin_left  = 6.0
	close_sb.content_margin_right = 6.0
	for st in ["normal", "hover", "pressed", "disabled"]:
		close_btn.add_theme_stylebox_override(st, close_sb)
	close_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# Position top-right with a small margin.
	close_btn.anchor_left   = 1.0
	close_btn.anchor_right  = 1.0
	close_btn.anchor_top    = 0.0
	close_btn.anchor_bottom = 0.0
	close_btn.offset_left   = -(CLOSE_SIZE + 8.0)
	close_btn.offset_right  = -8.0
	close_btn.offset_top    = 8.0
	close_btn.offset_bottom = 8.0 + CLOSE_SIZE
	close_btn.pressed.connect(close_detail)
	band.add_child(close_btn)

	return band

## Blurb — one warm Norwegian line (Nunito body font, muted ink).
func _build_modal_blurb(detail: Dictionary) -> Label:
	var lbl := Label.new()
	lbl.name = "ModalBlurb"
	lbl.text = detail["blurb"]
	lbl.add_theme_font_override("font", DesignSystem.font_body())
	lbl.add_theme_font_size_override("font_size", DesignSystem.T_BODY)
	lbl.add_theme_color_override("font_color", C_INK)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

## 4 stat rows: Læreevne · Energi · Mot · Fokus, each with 5 pips.
## Pips are drawn as small rounded ColorRects (no font glyphs, no tofu).
func _build_modal_stats(detail: Dictionary) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.name = "ModalStats"
	col.add_theme_constant_override("separation", 7)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var stat_labels := ["Læreevne", "Energi", "Mot", "Fokus"]
	var stats: Array = detail["stats"]
	for i in stat_labels.size():
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 8)
		col.add_child(row)

		var lbl := Label.new()
		lbl.text = stat_labels[i]
		lbl.add_theme_font_override("font", DesignSystem.font_body())
		lbl.add_theme_font_size_override("font_size", DesignSystem.T_SMALL)
		lbl.add_theme_color_override("font_color", C_MUTED)
		lbl.custom_minimum_size = Vector2(76.0, 0.0)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl)

		var pip_row := HBoxContainer.new()
		pip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip_row.add_theme_constant_override("separation", int(MODAL_PIP_GAP))
		row.add_child(pip_row)

		var filled_count: int = stats[i] if i < stats.size() else 0
		for p in 5:
			var pip := _StatPip.new()
			pip.filled = p < filled_count
			pip.custom_minimum_size = Vector2(MODAL_PIP_W, MODAL_PIP_H)
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pip_row.add_child(pip)

	return col

## Raseegenskaper chip row — the traits Array as small pill chips.
## Plain text words in a HFlowContainer — no glyphs, no tofu.
func _build_modal_traits(detail: Dictionary) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.name = "ModalTraits"
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var section_lbl := Label.new()
	section_lbl.text = "Raseegenskaper"
	section_lbl.add_theme_font_override("font", DesignSystem.font_body_bold())
	section_lbl.add_theme_font_size_override("font_size", DesignSystem.T_SMALL)
	section_lbl.add_theme_color_override("font_color", C_MUTED)
	section_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(section_lbl)

	var chip_row := HBoxContainer.new()
	chip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_row.add_theme_constant_override("separation", 6)
	col.add_child(chip_row)

	var traits: Array = detail["traits"]
	for trait_word in traits:
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var chip_sb := StyleBoxFlat.new()
		chip_sb.bg_color = C_TRAIT_BG
		chip_sb.set_corner_radius_all(int(CHIP_RADIUS))
		chip_sb.content_margin_left   = 8.0
		chip_sb.content_margin_right  = 8.0
		chip_sb.content_margin_top    = 4.0
		chip_sb.content_margin_bottom = 4.0
		chip.add_theme_stylebox_override("panel", chip_sb)
		var chip_lbl := Label.new()
		chip_lbl.text = str(trait_word)
		chip_lbl.add_theme_font_override("font", DesignSystem.font_body_bold())
		chip_lbl.add_theme_font_size_override("font_size", DesignSystem.T_SMALL)
		chip_lbl.add_theme_color_override("font_color", C_TRAIT_INK)
		chip_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(chip_lbl)
		chip_row.add_child(chip)

	return col

## Unikt trekk — a warm-cream card showing the dog's one unique trait.
func _build_modal_unique_trait(detail: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "ModalUniqueTrait"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_MODAL_CREAM
	sb.set_corner_radius_all(int(CHIP_RADIUS))
	sb.content_margin_left   = MODAL_BODY_PAD
	sb.content_margin_right  = MODAL_BODY_PAD
	sb.content_margin_top    = 10.0
	sb.content_margin_bottom = 10.0
	card.add_theme_stylebox_override("panel", sb)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 3)
	card.add_child(col)

	var heading := Label.new()
	heading.text = "Unikt trekk"
	heading.add_theme_font_override("font", DesignSystem.font_body_bold())
	heading.add_theme_font_size_override("font_size", DesignSystem.T_SMALL)
	heading.add_theme_color_override("font_color", C_MUTED)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(heading)

	var trait_lbl := Label.new()
	trait_lbl.name = "UniqueTraitLabel"
	trait_lbl.text = detail["unique_trait"]
	trait_lbl.add_theme_font_override("font", DesignSystem.font_body_bold())
	trait_lbl.add_theme_font_size_override("font_size", DesignSystem.T_BODY)
	trait_lbl.add_theme_color_override("font_color", C_INK)
	trait_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(trait_lbl)

	return card

## Trick list (K-8) — "Kan lære: Sitt · Ligg · Legg deg" as plain text.
## Maps trick ids to display names (DogClips constants). No raw ids printed, no glyphs.
func _build_modal_trick_list(detail: Dictionary) -> Label:
	var id_to_label := {
		DogClips.TRICK_SITT:    "Sitt",
		DogClips.TRICK_LIGG:    "Ligg",
		DogClips.TRICK_LEGG_DEG: "Legg deg",
	}
	var trick_ids: Array = detail["trick_ids"]
	var parts: Array = []
	for tid in trick_ids:
		parts.append(id_to_label.get(str(tid), str(tid)))
	var lbl := Label.new()
	lbl.name = "ModalTrickList"
	lbl.text = "Kan laere: " + " · ".join(parts)
	lbl.add_theme_font_override("font", DesignSystem.font_body())
	lbl.add_theme_font_size_override("font_size", DesignSystem.T_SMALL)
	lbl.add_theme_color_override("font_color", C_MUTED)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

## K-6 coral «★ Påskeegg» ribbon (task 111): a full-width coral band that flags the secret dog above
## her stats. The star is the same drawn _StarPip geometry as the grid tag (no U+2605 glyph → no tofu).
func _build_egg_ribbon() -> Control:
	var panel := PanelContainer.new()
	panel.name = "EggRibbon"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_STATUS_EGG
	sb.set_corner_radius_all(int(CHIP_RADIUS))
	sb.content_margin_left   = 10.0
	sb.content_margin_right  = 10.0
	sb.content_margin_top    = 7.0
	sb.content_margin_bottom = 7.0
	panel.add_theme_stylebox_override("panel", sb)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(center)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(hbox)
	var pip := _StarPip.new()
	pip.name = "RibbonStarPip"
	pip.custom_minimum_size = Vector2(13.0, 13.0)
	hbox.add_child(pip)
	var lbl := Label.new()
	lbl.text = "Påskeegg — en hemmelig venn"
	lbl.add_theme_font_override("font", DesignSystem.font_body_bold())
	lbl.add_theme_font_size_override("font_size", DesignSystem.T_SMALL)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(lbl)
	return panel

## Full-width action button dispatcher (109 adopt + 110 switch). Three states:
##   - unowned            → the blue «Adopter · N mynt» adopt button (_build_adopt_button, K-4).
##   - owned & NOT active  → the green «Tren med [navn]» switch button (_build_train_with_button, K-5).
##   - owned & active      → a non-tappable «Trener nå» state (_build_active_state, no dead button, K-5).
func _build_action_button(detail: Dictionary) -> Control:
	if not detail.get("owned", false):
		# K-6 (task 111): the secret free dog (Trulte) gets the coral «Adopter gratis ♥» button
		# instead of the priced blue path — price 0, always affordable, drawn heart (no tofu).
		if detail.get("secret", false):
			return _build_free_adopt_button(detail)
		return _build_adopt_button(detail)
	if detail.get("active", false):
		return _build_active_state(detail)
	return _build_train_with_button(detail)

## K-5 switch button (110): a full-width GREEN «Tren med [navn]» button on an owned, non-active dog.
## Pressing it emits train_with_requested(id) — main._on_kennel_train_with sets the dog active, re-tints
## + re-levers the training scene to it, persists, and closes the kennel. The green owned treatment
## (C_STATUS_OWNED) reads distinctly from the blue adopt button so «adopt» vs «train» never blur.
func _build_train_with_button(detail: Dictionary) -> Control:
	var dog_id: String = detail.get("id", "")
	var dog_name: String = detail.get("name", "")
	var btn := Button.new()
	btn.name = "TrainWithButton"
	btn.text = "Tren med %s" % dog_name
	btn.add_theme_font_override("font", DesignSystem.font_body_bold())
	btn.add_theme_font_size_override("font_size", DesignSystem.T_BODY)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.75))
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_STATUS_OWNED
	sb.set_corner_radius_all(int(CHIP_RADIUS))
	sb.content_margin_top    = 14.0
	sb.content_margin_bottom = 14.0
	var sb_pressed := sb.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = C_STATUS_OWNED.darkened(0.12)
	for st in ["normal", "hover", "disabled"]:
		btn.add_theme_stylebox_override(st, sb)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.pressed.connect(func(): train_with_requested.emit(dog_id))
	return btn

## K-5 active state (110): the dog the player already trains shows a non-tappable «Trener nå» pill —
## a muted, disabled surface (no dead green button that looks pressable but does nothing). Communicates
## "this is your current dog" without offering a redundant switch.
func _build_active_state(_detail: Dictionary) -> Control:
	var btn := Button.new()
	btn.name = "ActiveState"
	btn.text = "Trener nå"
	btn.disabled = true
	btn.add_theme_font_override("font", DesignSystem.font_body_bold())
	btn.add_theme_font_size_override("font_size", DesignSystem.T_BODY)
	btn.add_theme_color_override("font_disabled_color", C_STATUS_OWNED)
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(C_STATUS_OWNED.r, C_STATUS_OWNED.g, C_STATUS_OWNED.b, 0.14)
	sb.set_corner_radius_all(int(CHIP_RADIUS))
	sb.content_margin_top    = 14.0
	sb.content_margin_bottom = 14.0
	for st in ["normal", "hover", "pressed", "disabled"]:
		btn.add_theme_stylebox_override(st, sb)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn

## K-4 adopt button (109). For an unowned dog: a full-width blue button reading «Adopter · N mynt»
## (Baloo 2, #4a90e2). When the dog is unaffordable the button is visually dimmed and disabled
## (non-tappable) — no error state (K-3). On press emits adopt_requested(id) which
## main._on_kennel_adopt wires into the real spend+roster mutation. Trulte's free-adopt coral
## treatment is K-6 (task 111) — this task ships the priced blue path only.
const C_ADOPT_BLUE := Color("4a90e2")    ## blue adopt button bg
const C_ADOPT_DIM  := Color("b0c8e8")    ## dimmed blue when unaffordable

func _build_adopt_button(detail: Dictionary) -> Control:
	var price: int = detail.get("price", 0)
	var affordable: bool = detail.get("affordable", true)
	var dog_id: String = detail.get("id", "")

	# Button label: «Adopter · N mynt» (price in numerals — no emoji, no non-theme glyph).
	var label_text := "Adopter  %d mynt" % price if price > 0 else "Adopter"

	var btn := Button.new()
	btn.name = "AdoptButton"
	btn.text = label_text
	btn.add_theme_font_override("font", DesignSystem.font_body_bold())
	btn.add_theme_font_size_override("font_size", DesignSystem.T_BODY)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.75))
	btn.add_theme_color_override("font_disabled_color", Color.WHITE)
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bg_color := C_ADOPT_BLUE if affordable else C_ADOPT_DIM
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.set_corner_radius_all(int(CHIP_RADIUS))
	sb.content_margin_left   = 0.0
	sb.content_margin_right  = 0.0
	sb.content_margin_top    = 14.0
	sb.content_margin_bottom = 14.0
	var sb_pressed := sb.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = bg_color.darkened(0.12)
	for st in ["normal", "hover", "disabled"]:
		btn.add_theme_stylebox_override(st, sb)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# K-3: unaffordable → dim + non-tappable.
	btn.disabled = not affordable
	if not affordable:
		btn.modulate = Color(1.0, 1.0, 1.0, 0.55)

	# On press emit the new adopt_requested signal — main wires to _on_kennel_adopt.
	if affordable:
		btn.pressed.connect(func(): adopt_requested.emit(dog_id))

	return btn

## K-6 free-adopt button (task 111): the secret dog's coral «Adopter gratis ♥» affordance. Costs
## nothing (price 0 → main._on_kennel_adopt spends 0 and marks her owned via the same adopt_requested
## signal). The heart is DRAWN geometry (_HeartPip) — U+2665 has no entry in Baloo 2 / Nunito, so a
## font glyph would tofu (106 / 089 precedent). The button provides the press + stylebox; a full-rect
## CenterContainer child renders [label ♥] so the drawn heart sits beside the word.
const C_ADOPT_FREE := Color("ff7a85")    ## coral free-adopt fill (matches the «Påskeegg» tag, C_STATUS_EGG)

func _build_free_adopt_button(detail: Dictionary) -> Control:
	var dog_id: String = detail.get("id", "")

	var btn := Button.new()
	btn.name = "FreeAdoptButton"
	btn.text = ""   # visual content is the CenterContainer child (label + drawn heart)
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var sb := StyleBoxFlat.new()
	sb.bg_color = C_ADOPT_FREE
	sb.set_corner_radius_all(int(CHIP_RADIUS))
	sb.content_margin_top    = 14.0
	sb.content_margin_bottom = 14.0
	var sb_pressed := sb.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = C_ADOPT_FREE.darkened(0.12)
	for st in ["normal", "hover", "disabled"]:
		btn.add_theme_stylebox_override(st, sb)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	# Content overlay: centred [«Adopter gratis»][drawn heart pip], non-interactive so the Button
	# underneath receives the press.
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 7)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(hbox)
	var lbl := Label.new()
	lbl.text = "Adopter gratis"
	lbl.add_theme_font_override("font", DesignSystem.font_body_bold())
	lbl.add_theme_font_size_override("font_size", DesignSystem.T_BODY)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(lbl)
	var heart := _HeartPip.new()
	heart.name = "HeartPip"
	heart.custom_minimum_size = Vector2(17.0, 17.0)
	hbox.add_child(heart)
	btn.add_child(center)

	btn.pressed.connect(func(): adopt_requested.emit(dog_id))
	return btn

# ---------------------------------------------------------------------------
# Web capture hook — publish cell centres for real-tap automation.
# ---------------------------------------------------------------------------
func _publish_cells() -> void:
	if not OS.has_feature("web"):
		return
	# The grid + ScrollContainer resolve child rects over a couple of frames after render()/show();
	# publishing immediately on the visibility notification would read every cell at the container
	# origin (all-same coords). Await the layout pass so each cell's global rect is real (110 fix —
	# 108's scroll-preservation test never tapped a *specific* cell so it didn't surface this).
	if is_inside_tree():
		await get_tree().process_frame
		await get_tree().process_frame
	if _grid == null:
		return
	var cells: Array = []
	for child in _grid.get_children():
		var c := child as Button
		if c == null:
			continue
		var id := c.name.trim_prefix("Cell_")
		var centre := c.get_global_rect().get_center()
		cells.append({"id": id, "x": centre.x, "y": centre.y})
	JavaScriptBridge.eval("window.__bra_kennel_cells = %s;" % JSON.stringify(cells), true)
	JavaScriptBridge.eval("window.__bra_kennel_open = true;", true)

## Publish the currently-open modal's action button (Adopt / TrainWith) centre in viewport px so the
## Visual-Review capture can land a REAL tap on it (110). Only the tappable buttons are published (the
## disabled «Trener nå» active state is skipped — nothing to tap). Web-only; no-op when no modal is open.
func _publish_modal_action() -> void:
	if not OS.has_feature("web"):
		return
	# The modal opens with a 0.28s scale/fade tween (pivot-offset scaling shifts every child's global
	# rect mid-flight), and the CenterContainer centres a content-sized card over several passes. Wait
	# past the tween so the button's global rect is its final, tappable position before publishing.
	if is_inside_tree():
		await get_tree().create_timer(0.4).timeout
	if _modal_overlay == null:
		return
	var payload := "null"
	var found: Array = []
	_collect_buttons(_modal_overlay, found)
	for node in found:
		var nm := (node as Control).name
		if nm == "TrainWithButton" or nm == "AdoptButton" or nm == "FreeAdoptButton":
			var c := (node as Control).get_global_rect().get_center()
			payload = "{id: '%s', x: %s, y: %s}" % [nm, c.x, c.y]
			break
	JavaScriptBridge.eval("window.__bra_kennel_action = %s;" % payload, true)

## Recursively collect every Button under `n` into `out` (owner-independent — modal nodes are built by
## code, so their `owner` is unset and find_child(owned=false) is the only reliable walk).
func _collect_buttons(n: Node, out: Array) -> void:
	if n is Button:
		out.append(n)
	for c in n.get_children():
		_collect_buttons(c, out)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			_publish_cells()
		elif OS.has_feature("web"):
			JavaScriptBridge.eval("window.__bra_kennel_open = false;", true)


# ---------------------------------------------------------------------------
# Inner class: drawn stat pip — a small rounded rect, filled or empty (108, K-2).
# Drawn via _draw() with draw_rect — no font glyph, no tofu, GL Compatibility-safe.
# ---------------------------------------------------------------------------
class _StatPip extends Control:
	var filled: bool = false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var color := C_PIP_FILLED if filled else C_PIP_EMPTY
		# Draw a rounded rect by using draw_rect for the body + four corner circles.
		# Godot 4's draw_rect with rounded corners requires the Canvas2D draw_rect overload
		# which accepts a corner-radius parameter.
		draw_rect(r, color, true, -1.0)

# ---------------------------------------------------------------------------
# Inner class: drawn steel bars overlay — GL Compatibility-safe, no shader needed.
# Repeating ~2px vertical stripes on ~29px pitch, C_STEEL @ 40% alpha, + 2px inset frame.
# ---------------------------------------------------------------------------
class _SteelBars extends Control:
	const STRIPE_W  := 3.0    ## stripe width (px) — wider so the thin bars actually read (116)
	const PITCH     := 26.0   ## stripe centre-to-centre pitch (px) — tighter for a denser cage
	const BAR_ALPHA := 0.38   ## bar opacity over the tint — spec #788794 @ 32-40% (116)
	const FRAME_W   := 2.0    ## inset frame width (px)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var bar_color := Color(C_STEEL.r, C_STEEL.g, C_STEEL.b, BAR_ALPHA)
		var frame_color := Color(C_STEEL.r, C_STEEL.g, C_STEEL.b, 0.55)
		# Repeating vertical stripes.
		var x := fmod(0.0, PITCH)
		while x < w:
			draw_rect(Rect2(x, 0.0, STRIPE_W, h), bar_color)
			x += PITCH
		# 2px inset frame on all four edges.
		draw_rect(Rect2(0.0, 0.0, w,     FRAME_W), frame_color)   # top
		draw_rect(Rect2(0.0, h - FRAME_W, w, FRAME_W), frame_color) # bottom
		draw_rect(Rect2(0.0, 0.0, FRAME_W, h), frame_color)        # left
		draw_rect(Rect2(w - FRAME_W, 0.0, FRAME_W, h), frame_color) # right


# ---------------------------------------------------------------------------
# Inner class: drawn 5-point star pip for the easter/secret tag (task 106).
# Replaces the U+2605 BLACK STAR glyph which has no entry in Baloo 2 / Nunito.
# Drawn as a filled polygon (draw_colored_polygon) — zero font dependency,
# guaranteed to render on GL Compatibility (089 precedent / Chevron).
# ---------------------------------------------------------------------------
class _StarPip extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	## Compute the 10 points of a 5-point star (alternating outer/inner vertices, 36° apart,
	## starting at the top). Returns a PackedVector2Array ready for draw_colored_polygon.
	static func _star_points(cx: float, cy: float, outer_r: float, inner_r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 10:
			var angle := deg_to_rad(-90.0 + i * 36.0)
			var r := outer_r if i % 2 == 0 else inner_r
			pts.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r))
		return pts

	func _draw() -> void:
		var cx := size.x * 0.5
		var cy := size.y * 0.5
		var outer_r := minf(cx, cy) * 0.95
		var inner_r := outer_r * 0.44   ## ~0.44 gives a classic 5-point star silhouette
		draw_colored_polygon(_star_points(cx, cy, outer_r, inner_r), Color.WHITE)

# ---------------------------------------------------------------------------
# Inner class: drawn heart pip for the K-6 free-adopt button (task 111).
# Replaces the U+2665 BLACK HEART SUIT glyph which has no entry in Baloo 2 /
# Nunito. Built from two top lobes (circles) + a bottom triangle, filled white
# via draw_colored_polygon / draw_circle — zero font dependency, GL-Compat safe.
# ---------------------------------------------------------------------------
class _HeartPip extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var r := w * 0.26            ## lobe radius
		var lobe_y := h * 0.34       ## vertical centre of the two lobes
		var lx := w * 0.30           ## left lobe centre x
		var rx := w * 0.70           ## right lobe centre x
		var col := Color.WHITE
		# Two top lobes.
		draw_circle(Vector2(lx, lobe_y), r, col)
		draw_circle(Vector2(rx, lobe_y), r, col)
		# Bottom point: a triangle from the outer edges of the lobes down to the tip.
		var tip := Vector2(w * 0.5, h * 0.92)
		var pts := PackedVector2Array([
			Vector2(lx - r, lobe_y),
			Vector2(rx + r, lobe_y),
			tip,
		])
		draw_colored_polygon(pts, col)
