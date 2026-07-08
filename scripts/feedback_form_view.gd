class_name FeedbackFormView
extends Control
## The feedback form modal (085, X-8 / ADR-0007). A dumb renderer over FeedbackForm: the model
## holds all state and builds the payload; this node handles layout/input nodes and emits signals.
## TDD-exempt render glue — placement is Visual Review gated. Mirrors the TrickMenu discipline:
## main mounts it hidden, connects signals, and routes submitted through _telem (the one choke-point).
##
## Portrait-safe (X-1): centred panel, max ~340 wide, safe margins from all edges. Built with real
## input nodes (TextEdit + Buttons) so the player can actually type and tap chips.

## The feedback payload (text + tags + optional rating + screen_context) is ready to ship via
## Telemetry.capture("feedback_submitted", payload). main's _on_feedback_submitted routes it.
signal submitted(payload: Dictionary)
## Player cancelled without submitting — main just hides this view.
signal cancelled

## The pure form model. Holds all state; produces the payload. Re-created on configure().
var _form := FeedbackForm.new()
## The screen context passed in from main on each open (trick, menu_open, mastery state, …).
var _screen_context := {}
## Whether the rating row should be shown for this open (set by configure; true only on milestones).
var _show_rating := false

## Live references to input nodes so configure() can reset them cleanly without rebuilding the tree.
var _text_edit: TextEdit
var _chip_buttons := {}      ## tag id → Button
var _rating_buttons: Array   ## Array[Button] — only populated when _show_rating is true
var _send_btn: Button
var _rating_container: Control  ## the HFlowContainer holding the rating buttons, or null

## 181: light DS PAPER card, one system with the completion menu it pops from. All colours are
## DesignSystem tokens (INK on PAPER/CREAM, BORDER hairline), a BLUE primary CTA, and the 152/167
## active-row pale-blue wash on selected chips. GOLD appears nowhere here — it is the coin only.
const PANEL_MAX_W := 340.0
const PANEL_MARGIN := 24.0
const PANEL_BG := DesignSystem.PAPER
const PANEL_BORDER := DesignSystem.BORDER
const BACKDROP := Color(DesignSystem.INK.r, DesignSystem.INK.g, DesignSystem.INK.b, 0.55)  ## ink scrim
const RADIUS := 14.0
const TITLE_COLOR := DesignSystem.INK
const CHIP_BG_ON := TrickMenu.ROW_BG_ACTIVE        ## selected chip — the active-row pale-blue wash (152/167)
const CHIP_BG_OFF := DesignSystem.CREAM            ## unselected chip — calm cream, BORDER hairline
const CHIP_TEXT_ON := TrickMenu.ROW_ACTIVE_INK     ## dark shared active ink on the wash
const CHIP_TEXT_OFF := DesignSystem.SLATE          ## muted-but-AA slate on cream
const CHIP_BORDER_ON := DesignSystem.BLUE_INK      ## blue hairline on the selected chip
const CHIP_BORDER_OFF := DesignSystem.BORDER       ## neutral hairline on the resting chip
const SEND_BG := DesignSystem.GRAD_PILL_BOT        ## primary CTA — deep blue (white ≈7:1 AA), same family as the BRA/close pills
const SEND_TEXT := DesignSystem.PAPER
const CANCEL_BG := DesignSystem.PAPER              ## ghost secondary — paper + blue outline (mirrors the menu ghost pills)
const CANCEL_TEXT := DesignSystem.BLUE_INK
const CANCEL_BORDER := DesignSystem.BLUE_INK
const RATING_ON_BG := TrickMenu.ROW_BG_ACTIVE
const RATING_OFF_BG := DesignSystem.CREAM
const FIELD_BG := DesignSystem.CREAM               ## text-area inset — cream well on the paper card
const FIELD_TEXT := DesignSystem.INK
const FIELD_PLACEHOLDER := DesignSystem.SLATE_SOFT
const SECONDARY_LABEL := DesignSystem.SLATE        ## «Hurtigvalg:» / «Helhet:» / privacy — AA muted ink on paper

func _init() -> void:
	# Full-screen modal: eats all taps so nothing falls through to the trick menu behind it.
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0

func _ready() -> void:
	_build_ui()

## Reset and re-configure before each show. Call before show(); each open is a clean slate.
## screen_context is the game state at open time (trick, menu_open, etc.); show_rating controls
## whether the 1–5 row appears (only on milestones — sparse, avoids fatigue per ADR-0007).
func configure(screen_context: Dictionary, show_rating: bool) -> void:
	_form = FeedbackForm.new()
	_screen_context = screen_context
	_show_rating = show_rating
	# Reset all input nodes to their blank state.
	if _text_edit != null:
		_text_edit.text = ""
	for tag in _chip_buttons:
		var btn: Button = _chip_buttons[tag]
		btn.button_pressed = false
		_apply_chip_style(btn, false)
	# Rating row: show/hide and reset all rating buttons.
	if _rating_container != null:
		_rating_container.visible = show_rating
	for rb in _rating_buttons:
		(rb as Button).button_pressed = false
		_apply_rating_style(rb as Button, false)
	_refresh_send()

# ---- UI build (once, in _ready) ---------------------------------------------------------------

func _build_ui() -> void:
	# Full-rect dimmed backdrop drawn behind the panel (MOUSE_FILTER_STOP on self covers it).
	# We use a Panel node to draw the backdrop colour without blocking our own children.
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.color = BACKDROP
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE  # self already eats taps
	add_child(backdrop)

	# Centred panel: a MarginContainer capped to PANEL_MAX_W + centred via an HBoxContainer.
	var outer := HBoxContainer.new()
	outer.name = "Outer"
	outer.anchor_right = 1.0
	outer.anchor_bottom = 1.0
	outer.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(outer)

	# Left/right fill spacers to centre the panel horizontally.
	var fill_l := Control.new(); fill_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(fill_l)

	var panel_bg := PanelContainer.new()
	panel_bg.name = "PanelBG"
	panel_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel_bg.custom_minimum_size = Vector2(minf(PANEL_MAX_W, 340.0), 0)
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = PANEL_BG
	pstyle.set_corner_radius_all(int(RADIUS))
	pstyle.border_color = PANEL_BORDER
	pstyle.set_border_width_all(2)
	pstyle.content_margin_left = 20.0
	pstyle.content_margin_right = 20.0
	pstyle.content_margin_top = 20.0
	pstyle.content_margin_bottom = 20.0
	panel_bg.add_theme_stylebox_override("panel", pstyle)
	outer.add_child(panel_bg)

	var fill_r := Control.new(); fill_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(fill_r)

	# Vertical stack inside the panel.
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 14)
	panel_bg.add_child(vbox)

	# Title.
	var title := Label.new()
	title.text = "Fortell oss hva du synes"
	title.add_theme_color_override("font_color", TITLE_COLOR)
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Free-text area.
	var te := TextEdit.new()
	te.name = "TextEdit"
	te.placeholder_text = "Hva funker? Hva funker ikke?"
	te.custom_minimum_size = Vector2(0, 110)
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	var te_style := StyleBoxFlat.new()
	te_style.bg_color = FIELD_BG
	te_style.set_corner_radius_all(8)
	te_style.set_border_width_all(1)
	te_style.border_color = DesignSystem.BORDER
	te_style.content_margin_left = 10.0
	te_style.content_margin_right = 10.0
	te_style.content_margin_top = 8.0
	te_style.content_margin_bottom = 8.0
	te.add_theme_stylebox_override("normal", te_style)
	te.add_theme_stylebox_override("focus", te_style)
	te.add_theme_color_override("font_color", FIELD_TEXT)
	te.add_theme_color_override("font_placeholder_color", FIELD_PLACEHOLDER)
	te.add_theme_color_override("background_color", Color(0, 0, 0, 0))
	te.text_changed.connect(_on_text_changed)
	vbox.add_child(te)
	_text_edit = te

	# Quick-tag chip row (HFlowContainer wraps on small widths).
	var chip_label := Label.new()
	chip_label.text = "Hurtigvalg:"
	chip_label.add_theme_color_override("font_color", SECONDARY_LABEL)
	chip_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(chip_label)

	var chips := HFlowContainer.new()
	chips.name = "Chips"
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	vbox.add_child(chips)
	for tag in FeedbackForm.TAGS:
		var btn := Button.new()
		btn.text = FeedbackForm.TAG_LABELS[tag]
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 14)
		_apply_chip_style(btn, false)
		# Capture tag id by value for the closure (explicit type required for inference in closures).
		var tid: String = tag
		btn.toggled.connect(func(on: bool):
			_form.toggle_tag(tid)
			_apply_chip_style(btn, _form.is_tag_on(tid))
			_refresh_send()
		)
		chips.add_child(btn)
		_chip_buttons[tag] = btn

	# Optional 1–5 rating row (only added to the tree when show_rating is true on configure).
	var rating_cont := HBoxContainer.new()
	rating_cont.name = "RatingRow"
	rating_cont.add_theme_constant_override("separation", 8)
	rating_cont.visible = _show_rating
	vbox.add_child(rating_cont)
	_rating_container = rating_cont

	var star_label := Label.new()
	star_label.text = "Helhet:"
	star_label.add_theme_color_override("font_color", SECONDARY_LABEL)
	star_label.add_theme_font_size_override("font_size", 14)
	rating_cont.add_child(star_label)

	for star in range(1, 6):
		var rbtn := Button.new()
		rbtn.text = str(star)
		rbtn.toggle_mode = true
		rbtn.focus_mode = Control.FOCUS_NONE
		rbtn.add_theme_font_size_override("font_size", 16)
		rbtn.custom_minimum_size = Vector2(40, 36)
		_apply_rating_style(rbtn, false)
		var sv := star  # capture by value
		rbtn.toggled.connect(func(_on: bool):
			# Radio: selecting one deselects all others.
			_form.rating = sv
			_form.rating_shown = true
			for other in _rating_buttons:
				var o := other as Button
				var is_sel := _form.rating == int(o.text)
				o.button_pressed = is_sel
				_apply_rating_style(o, is_sel)
			_refresh_send()
		)
		rating_cont.add_child(rbtn)
		_rating_buttons.append(rbtn)

	# Privacy note — honest about data flow (ADR-0007 open items).
	var privacy := Label.new()
	privacy.name = "PrivacyNote"
	privacy.text = "Fritekst kan brukes til å forbedre spillet — ingenting lagres på enheten din."
	privacy.add_theme_color_override("font_color", SECONDARY_LABEL)
	privacy.add_theme_font_size_override("font_size", 12)
	privacy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(privacy)

	# Cancel + Send row.
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_row)

	var cancel := Button.new()
	cancel.name = "CancelBtn"
	cancel.text = "Avbryt"
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.add_theme_font_size_override("font_size", 17)
	_style_button(cancel, CANCEL_BG, CANCEL_TEXT, CANCEL_BORDER, 1)
	cancel.pressed.connect(_on_cancel)
	btn_row.add_child(cancel)

	var send := Button.new()
	send.name = "SendBtn"
	send.text = "Send"
	send.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	send.focus_mode = Control.FOCUS_NONE
	send.add_theme_font_size_override("font_size", 17)
	_style_button(send, SEND_BG, SEND_TEXT)
	send.pressed.connect(_on_send)
	btn_row.add_child(send)
	_send_btn = send

	_refresh_send()

# ---- helpers ----------------------------------------------------------------------------------

func _apply_chip_style(btn: Button, on: bool) -> void:
	var bg := CHIP_BG_ON if on else CHIP_BG_OFF
	var fg := CHIP_TEXT_ON if on else CHIP_TEXT_OFF
	var bc := CHIP_BORDER_ON if on else CHIP_BORDER_OFF
	_style_button(btn, bg, fg, bc, 1)

func _apply_rating_style(btn: Button, on: bool) -> void:
	var bg := RATING_ON_BG if on else RATING_OFF_BG
	var fg := CHIP_TEXT_ON if on else CHIP_TEXT_OFF
	var bc := CHIP_BORDER_ON if on else CHIP_BORDER_OFF
	_style_button(btn, bg, fg, bc, 1)

func _style_button(btn: Button, bg: Color, fg: Color, border_col := Color(0, 0, 0, 0), border_w := 0) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	if border_w > 0:
		s.set_border_width_all(border_w)
		s.border_color = border_col
	s.set_corner_radius_all(9999)
	s.content_margin_left = 14.0
	s.content_margin_right = 14.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	btn.add_theme_stylebox_override("normal",   s)
	btn.add_theme_stylebox_override("hover",    s)
	btn.add_theme_stylebox_override("pressed",  s)
	btn.add_theme_stylebox_override("disabled", s)
	btn.add_theme_stylebox_override("focus",    StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color",          fg)
	btn.add_theme_color_override("font_hover_color",    fg)
	btn.add_theme_color_override("font_pressed_color",  fg)
	btn.add_theme_color_override("font_disabled_color", Color(fg, 0.4))

## Send is enabled only when the form has something to say (text OR a tag).
func _refresh_send() -> void:
	if _send_btn == null:
		return
	_send_btn.disabled = not (_form.has_text() or not _form.selected_tags().is_empty())

# ---- input callbacks --------------------------------------------------------------------------

func _on_text_changed() -> void:
	if _text_edit != null:
		_form.text = _text_edit.text
	_refresh_send()

func _on_send() -> void:
	if not (_form.has_text() or not _form.selected_tags().is_empty()):
		return  # belt-and-suspenders: disabled state should prevent this
	submitted.emit(_form.build_payload(_screen_context))
	_hide_self()

func _on_cancel() -> void:
	cancelled.emit()
	_hide_self()

func _hide_self() -> void:
	hide()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__bra_feedback_open = false;", true)

## Use _notification to hook visibility changes and publish the web hook — overriding show() is
## blocked by Godot (warning-as-error). NOTIFICATION_VISIBILITY_CHANGED fires on both show and hide.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if OS.has_feature("web"):
			var open := "true" if visible else "false"
			JavaScriptBridge.eval("window.__bra_feedback_open = %s;" % open, true)
