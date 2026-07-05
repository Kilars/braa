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
## Dog band render: the band is filled with the per-dog band_tint from KennelDog. All 8
## dogs share the one licensed Labrador rig (owner-gated on distinct breed models,
## BUST-068), so there is no per-dog portrait render here — the tinted band IS the honest
## visual differentiation for this slice. A baked per-breed portrait is a later refinement
## once the owner supplies distinct models; this is not a stub of a claimed feature.

signal dog_selected(id: String)   ## cell was tapped → the detail modal task will consume this
signal closed                      ## back/✕ was tapped → main restores the training HUD
signal detail_closed               ## the inspect modal was dismissed (optional hook for main)

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
const BAND_H         := 112.0   ## the tinted portrait band at the top of each cell
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
	_modal_overlay = _build_modal_overlay(detail)
	add_child(_modal_overlay)
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
	# The cell width: (viewport_width - 2*GRID_PAD - CELL_GAP) / 2 ≈ (390-24-12)/2 = 177 px.
	# We can't query final size at build time, so set a reasonable minimum.
	btn.custom_minimum_size = Vector2(160.0, BAND_H + 72.0)
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

	# 1. Portrait band with steel bars overlay and status/price tags.
	vbox.add_child(_make_band(row))

	# 2. Footer: name + breed (PanelContainer with white bg).
	vbox.add_child(_make_footer(row))

	return btn

## The top portrait band: tinted background + steel-bar shader overlay + status tag (top-left)
## + price chip (bottom-right). No dog silhouette this slice — the tint IS the visual identity
## until the owner supplies distinct breed models (BUST-068 — already flagged, not a stub).
func _make_band(row: Dictionary) -> Control:
	var band := Control.new()
	band.name = "Band"
	band.custom_minimum_size = Vector2(0, BAND_H)
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

	# 2b. 4 stat rows.
	body.add_child(_build_modal_stats(detail))

	# 2c. Raseegenskaper chip row.
	body.add_child(_build_modal_traits(detail))

	# 2d. Unikt trekk — warm cream card.
	body.add_child(_build_modal_unique_trait(detail))

	# 2e. Trick list (K-8): "Kan lære: Sitt · Ligg · Legg deg".
	body.add_child(_build_modal_trick_list(detail))

	# K-4 adopt button mounts here (next task).
	# The _build_adopt_button() stub is defined below; it returns null in this slice
	# so nothing is added — the modal is a complete inspect card with no dead button.
	var adopt_node := _build_adopt_button(detail)
	if adopt_node != null:
		body.add_child(adopt_node)

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

	# Steel-bar overlay (reuse _SteelBars for GL-Compat–safe rendering).
	var bars := _SteelBars.new()
	bars.name = "ModalSteelBars"
	bars.anchor_right  = 1.0
	bars.anchor_bottom = 1.0
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(bars)

	# Dog name centred in the band (white, Baloo 2 display).
	var name_lbl := Label.new()
	name_lbl.name = "ModalDogName"
	name_lbl.text = detail["name"]
	name_lbl.add_theme_font_override("font", DesignSystem.font_display())
	name_lbl.add_theme_font_size_override("font_size", DesignSystem.T_TITLE)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
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

## K-4 adopt button mount seam (next task). Returns null in this K-2 inspect slice —
## no visible, dead or no-op button is rendered. The K-4 task replaces this stub with
## the real adopt wiring (spend coins, roster mutation, close modal, persist save).
## Allowlisted as "a stand-in an open task names" per CLAUDE.md placeholder rules.
func _build_adopt_button(_detail: Dictionary) -> Control:
	# K-4 adopt button mounts here (next task — wires economy/roster/save).
	return null

# ---------------------------------------------------------------------------
# Web capture hook — publish cell centres for real-tap automation.
# ---------------------------------------------------------------------------
func _publish_cells() -> void:
	if not OS.has_feature("web") or _grid == null:
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
	const STRIPE_W  := 2.0    ## stripe width (px)
	const PITCH     := 29.0   ## stripe centre-to-centre pitch (px)
	const BAR_ALPHA := 0.40   ## bar opacity over the tint
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
