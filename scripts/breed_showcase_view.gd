class_name BreedShowcaseView
extends Control
## The spotlit breed-select / showcase screen (087, P3-4 "persistent, showcased roster" +
## PO-Improvement-2 "the dog is bright/spotlit, not buried in shadow"). A dumb renderer, twin of
## FeedbackFormView / TrickMenu: main owns the pure BreedShowcase model + the 3D stage (it brightens
## the lights and re-tints the LIVE rig to the previewed breed), and this node only draws the chrome
## and emits intents. Deliberately does NOT dim the whole screen — the CENTRE is transparent so the
## real spotlit dog behind it stays visible; only a top title band and a bottom control bar are drawn,
## so the roster reads as "here is my dog, shown off", not a cut-out on a dark veil.
##
## Intents (main maps them through the BreedShowcase model, re-tints the live rig, re-renders):
signal prev_requested        ## ◀ — spotlight the previous owned breed
signal next_requested        ## ▶ — spotlight the next owned breed
signal focus_requested(id: String)  ## a breed pip was tapped — spotlight that owned breed
signal commit_requested      ## "Tren denne" — make the spotlit breed active (persisted) + close
signal dismissed             ## "Tilbake" — close without switching (main restores the active dog)

## Layout + palette, homed here — all sourced from the design system (163, PO father-pass-28, X-4):
## the showcase was the one live surface built (087) BEFORE the 096+ DS arc, so it hardcoded charcoal
## + gold. The dark-STAGE spotlight concept stays (clear centre, lit dog visible) but every colour is
## now a DS token, gold is OFF every non-coin fill (gold = coin only), and the CTA states clear WCAG AA.
const BAND_BG := Color(DesignSystem.INK.r, DesignSystem.INK.g, DesignSystem.INK.b, 0.72)  ## dark stage band = DS INK @ .72
const TITLE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const NAME_ACTIVE := DesignSystem.PAPER            ## the spotlit breed's name (active) — bright paper-white, NOT gold
const NAME_PREVIEW := Color(1.0, 1.0, 1.0)         ## a previewed (not-yet-active) breed's name — white
const SUBTLE := Color(1.0, 1.0, 1.0, 0.78)         ## caption/hint on the dark band — legible white
const PIP_ON := DesignSystem.PAPER                 ## the SPOTLIT (selected) breed's pip — bright paper chip (dark INK text), NOT gold
const PIP_OFF := Color(1.0, 1.0, 1.0, 0.14)        ## a non-spotlit breed's pip — faint white chip
const PIP_ON_TEXT := DesignSystem.INK              ## dark ink on the bright spotlit pip (AA-clear)

## The active dog gets a quiet "aktiv" DOT (165, PO father-pass-30) so the SPOTLIT pip can own the
## dominant solid fill without the two states competing. The dot is DRAWN (never a font glyph — the
## coin/chevron lesson) and its colour ADAPTS to the pip background: dark BLUE_INK on the bright
## spotlit pill, light BLUE_LIGHT on a faint pill over the dark band. Blue echoes the trick-menu
## ACTIVE row + BRA primary, so all four selection surfaces read as one system.
const ACTIVE_DOT_ON_LIGHT := DesignSystem.BLUE_INK   ## dot on the solid-paper spotlit+active pip
const ACTIVE_DOT_ON_DARK := DesignSystem.BLUE_LIGHT  ## dot on the faint over-dark-band active pip
static func active_dot_color(on_bright_pip: bool) -> Color:
	return ACTIVE_DOT_ON_LIGHT if on_bright_pip else ACTIVE_DOT_ON_DARK
const BTN_SECONDARY := Color(1.0, 1.0, 1.0, 0.14)  ## «Tilbake» ghost pill over the dark band
const BTN_SECONDARY_TEXT := Color(1.0, 1.0, 1.0, 0.92)
const SWATCH_RIM := Color(0.0, 0.0, 0.0, 0.5)

## Primary CTA — the DS blue gradient pill (GRAD_PILL_*, the BRA / «Fortsett treningen» palette, 153),
## white label. Its DISABLED (active-dog «Trener denne») state is a muted light pill with a dark ink
## label — the kennel «Trener nå» non-tappable style (151) — never a washed label on gold (~1.03:1 defect).
const COMMIT_ENABLED_TEXT := Color(1.0, 1.0, 1.0)  ## white on the blue gradient (AA per 153)
const COMMIT_DISABLED_INK := DesignSystem.INK      ## dark DS ink on the muted disabled fill
const COMMIT_W := 280        ## commit-pill content width  (offset -140 .. +140)
const COMMIT_H := 42         ## commit-pill content height (offset -88 .. -46)

## The muted fill for the non-tappable active-dog «Trener denne» — a pale slate the dark INK clears AA on.
static func commit_disabled_fill() -> Color:
	return Color("cfd6dd")

## The ◀ ▶ chevrons cycle the OWNED roster, so they only do something with 2+ owned breeds (164,
## PO father-pass-29). With ≤1 owned dog they are verified no-ops → hidden, and the hint drops the
## "bla med pilene" instruction so no dead control looks live and no line instructs a no-op.
const HINT_MULTI := "Bla med pilene eller trykk en hund"   ## 2+ owned: arrows + tap both work
const HINT_SINGLE := "Adopter flere hunder for å bla"       ## ≤1 owned: no arrows — explains why
static func chevrons_active(owned_count: int) -> bool:
	return owned_count > 1
static func hint_text(owned_count: int) -> String:
	return HINT_MULTI if chevrons_active(owned_count) else HINT_SINGLE

const TITLE_H := 92.0        ## the top title band height
const CONTROL_H := 190.0     ## the bottom control-bar band height
const SWATCH_R := 16.0

## Cached DS blue-gradient stylebox for the commit pill (baked once — the per-pixel baker must never run per-frame).
var _commit_grad: StyleBoxTexture = null

## The rows main fed in: [{id, name, tint}] in roster order, plus the spotlit + active ids.
var _entries: Array = []
var _spotlit := ""
var _active := ""

## Live node refs (built once in _ready; updated per render).
var _title: Label
var _name_label: Label
var _hint: Label
var _pips: HBoxContainer
var _swatch: ColorRect
var _prev_btn: Button
var _next_btn: Button
var _commit_btn: Button
var _back_btn: Button

func _init() -> void:
	# Modal: eats every tap so a tap on the clear centre can't fall through to the BRA button / dog
	# behind it — but it does NOT paint a full backdrop, so the spotlit dog stays visible.
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_right = 1.0
	anchor_bottom = 1.0

func _ready() -> void:
	_build_ui()

## Feed the current model state and redraw (main calls this on open + after every prev/next/focus).
## entries = [{id, name, tint}] (roster order); spotlit = the previewed breed; active = the trained dog.
func render(entries: Array, spotlit: String, active: String) -> void:
	_entries = entries
	_spotlit = spotlit
	_active = active
	_refresh()
	_publish()

func _build_ui() -> void:
	# Top title band.
	var top := ColorRect.new()
	top.name = "TopBand"
	top.color = BAND_BG
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.anchor_right = 1.0
	top.offset_bottom = TITLE_H
	add_child(top)

	_title = Label.new()
	_title.text = "Mine hunder"
	_title.add_theme_color_override("font_color", TITLE_COLOR)
	_title.add_theme_font_override("font", DesignSystem.font_display())
	_title.add_theme_font_size_override("font_size", 30)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.anchor_right = 1.0
	_title.offset_top = 16.0
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)

	# The spotlit breed's big name (under the title, over the dog).
	_name_label = Label.new()
	_name_label.add_theme_font_override("font", DesignSystem.font_display())
	_name_label.add_theme_font_size_override("font_size", 26)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.anchor_right = 1.0
	_name_label.offset_top = 54.0
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	# Bottom control band.
	var bottom := ColorRect.new()
	bottom.name = "BottomBand"
	bottom.color = BAND_BG
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.anchor_right = 1.0
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_top = -CONTROL_H
	add_child(bottom)

	# The honest coat swatch of the spotlit breed, centred just above the pips.
	_swatch = ColorRect.new()
	_swatch.name = "Swatch"
	_swatch.custom_minimum_size = Vector2(SWATCH_R * 2.0, SWATCH_R * 2.0)
	_swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# The breed pips row (one per owned breed) — centred in the bottom band, top.
	_pips = HBoxContainer.new()
	_pips.name = "Pips"
	_pips.add_theme_constant_override("separation", 10)
	_pips.alignment = BoxContainer.ALIGNMENT_CENTER
	_pips.anchor_right = 1.0
	_pips.anchor_top = 1.0
	_pips.anchor_bottom = 1.0
	_pips.offset_top = -CONTROL_H + 14.0
	_pips.offset_bottom = -CONTROL_H + 58.0
	add_child(_pips)

	# ◀ / ▶ cycle buttons flank the pips — the arrow is a DRAWN chevron, not a font glyph (089).
	_prev_btn = _make_cycle_button(-1)
	_prev_btn.anchor_top = 1.0
	_prev_btn.anchor_bottom = 1.0
	_prev_btn.offset_left = 20.0
	_prev_btn.offset_top = -CONTROL_H + 12.0
	_prev_btn.offset_bottom = -CONTROL_H + 60.0
	_prev_btn.custom_minimum_size = Vector2(48, 48)
	_prev_btn.pressed.connect(func(): prev_requested.emit())
	add_child(_prev_btn)

	_next_btn = _make_cycle_button(1)
	_next_btn.anchor_left = 1.0
	_next_btn.anchor_right = 1.0
	_next_btn.anchor_top = 1.0
	_next_btn.anchor_bottom = 1.0
	_next_btn.offset_left = -68.0
	_next_btn.offset_right = -20.0
	_next_btn.offset_top = -CONTROL_H + 12.0
	_next_btn.offset_bottom = -CONTROL_H + 60.0
	_next_btn.custom_minimum_size = Vector2(48, 48)
	_next_btn.pressed.connect(func(): next_requested.emit())
	add_child(_next_btn)

	# "Tren denne" (train the spotlit dog — commit + persist) and "Tilbake" (back) at the band foot.
	_commit_btn = _make_commit_button()
	_commit_btn.anchor_left = 0.5
	_commit_btn.anchor_right = 0.5
	_commit_btn.anchor_top = 1.0
	_commit_btn.anchor_bottom = 1.0
	_commit_btn.offset_left = -140.0
	_commit_btn.offset_right = 140.0
	_commit_btn.offset_top = -88.0
	_commit_btn.offset_bottom = -46.0
	_commit_btn.pressed.connect(func(): commit_requested.emit())
	add_child(_commit_btn)

	_back_btn = _make_button("Tilbake", BTN_SECONDARY, BTN_SECONDARY_TEXT)
	_back_btn.anchor_left = 0.5
	_back_btn.anchor_right = 0.5
	_back_btn.anchor_top = 1.0
	_back_btn.anchor_bottom = 1.0
	_back_btn.offset_left = -140.0
	_back_btn.offset_right = 140.0
	_back_btn.offset_top = -40.0
	_back_btn.offset_bottom = -10.0
	_back_btn.pressed.connect(func(): dismissed.emit())
	add_child(_back_btn)

	_hint = Label.new()
	_hint.text = HINT_MULTI  # replaced per roster size in _refresh
	_hint.add_theme_color_override("font_color", SUBTLE)
	_hint.add_theme_font_override("font", DesignSystem.font_body())
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.anchor_right = 1.0
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.offset_top = -CONTROL_H + 62.0
	_hint.offset_bottom = -CONTROL_H + 84.0
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)

func _make_button(text: String, bg: Color, fg: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", DesignSystem.font_body_bold())   # DS font, not the fallback (163)
	b.add_theme_font_size_override("font_size", 17)
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(12)
	s.content_margin_left = 14.0
	s.content_margin_right = 14.0
	s.content_margin_top = 8.0
	s.content_margin_bottom = 8.0
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, s)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for fc in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(fc, fg)
	return b

## The primary «Tren denne» / «Trener denne» commit pill (163). Its normal/hover/pressed states are the DS
## blue gradient pill (baked once, cached) with a white label; its DISABLED state — the active dog, non-
## tappable — is a muted light pill with a dark INK label (the kennel «Trener nå» treatment, 151). Godot
## picks the disabled stylebox automatically when `.disabled` is set, so `_refresh` only toggles `.disabled`.
func _make_commit_button() -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", DesignSystem.font_display())     # Baloo 2 — the primary-CTA face
	b.add_theme_font_size_override("font_size", 19)
	if _commit_grad == null:
		_commit_grad = DesignSystem.gradient_pill(COMMIT_W, COMMIT_H, COMMIT_H * 0.5)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, _commit_grad)
	var muted := StyleBoxFlat.new()
	muted.bg_color = commit_disabled_fill()
	muted.set_corner_radius_all(int(COMMIT_H * 0.5))
	b.add_theme_stylebox_override("disabled", muted)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", COMMIT_ENABLED_TEXT)
	b.add_theme_color_override("font_hover_color", COMMIT_ENABLED_TEXT)
	b.add_theme_color_override("font_pressed_color", COMMIT_ENABLED_TEXT)
	b.add_theme_color_override("font_disabled_color", COMMIT_DISABLED_INK)  # was never set → the ~1.03:1 defect
	return b

## A ◀ / ▶ cycle button whose arrow is a DRAWN chevron, not a font glyph (089, PO 2026-07-03 Bugfix 1):
## U+25C0/U+25B6 are absent from the project font and drew as tofu boxes on the deployed GL build — the
## same missing-glyph class 069 fixed by *drawing* the coin. `dir` = -1 points the chevron left (prev),
## +1 right (next). The button keeps its styled pill + real hit target (its centre is published for the
## capture); the glyph text is empty and a mouse-ignoring `Chevron` child paints the arrow instead.
func _make_cycle_button(dir: int) -> Button:
	var b := _make_button("", BTN_SECONDARY, BTN_SECONDARY_TEXT)
	var chevron := Chevron.new(dir, BTN_SECONDARY_TEXT)
	chevron.name = "Chevron"
	b.add_child(chevron)
	return b

## A single filled-triangle chevron centred in its rect — the tofu-free cycle arrow (089). Fills its
## parent button and ignores mouse, so the button underneath still takes the tap.
class Chevron extends Control:
	var _dir := 1
	var _color := Color(1, 1, 1, 0.9)
	func _init(dir: int, color: Color) -> void:
		_dir = -1 if dir < 0 else 1
		_color = color
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
		resized.connect(queue_redraw)
	func _draw() -> void:
		var w := size.x * 0.24
		var h := size.y * 0.30
		var cx := size.x * 0.5
		var cy := size.y * 0.5
		var pts: PackedVector2Array
		if _dir < 0:  # ◀ point-left
			pts = PackedVector2Array([Vector2(cx - w, cy), Vector2(cx + w, cy - h), Vector2(cx + w, cy + h)])
		else:         # ▶ point-right
			pts = PackedVector2Array([Vector2(cx + w, cy), Vector2(cx - w, cy - h), Vector2(cx - w, cy + h)])
		draw_colored_polygon(pts, _color)

## A small filled "aktiv" dot in the pip's top-right corner (165, PO father-pass-30) — the quiet
## marker for the ACTIVE dog, drawn (not a font glyph) so it never renders as tofu. Fills its parent
## pip and ignores mouse, so the pip underneath still takes the tap.
class ActiveDot extends Control:
	const R := 4.0
	const INSET := 8.0
	var _color := Color(1, 1, 1)
	func _init(color: Color) -> void:
		_color = color
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
		resized.connect(queue_redraw)
	func _draw() -> void:
		draw_circle(Vector2(size.x - INSET, INSET), R, _color)

## Rebuild the pip row + the spotlit name/colour from the current model state.
func _refresh() -> void:
	if _name_label == null:
		return  # not built yet
	var is_active := _spotlit == _active
	_name_label.text = _name_of(_spotlit) + (" — aktiv" if is_active else "")
	_name_label.add_theme_color_override("font_color", NAME_ACTIVE if is_active else NAME_PREVIEW)
	# Rebuild pips: one per owned breed. The SPOTLIT (previewed) breed owns the solid dominant fill —
	# it is the current selection; the ACTIVE dog carries a quiet "aktiv" dot (165, PO father-pass-30).
	# (Was reversed: the fill keyed to active + an invisible `outline_size` on the spotlit pip, so
	# previewing a non-active dog left the eye pulled to the wrong pip.)
	for c in _pips.get_children():
		c.queue_free()
	for entry in _entries:
		var e: Dictionary = entry
		var id: String = e.id
		var is_spot := id == _spotlit
		var pip := _make_button(str(e.get("name", id)), PIP_ON if is_spot else PIP_OFF,
			PIP_ON_TEXT if is_spot else BTN_SECONDARY_TEXT)
		pip.add_theme_font_size_override("font_size", 15)
		if id == _active:
			var dot := ActiveDot.new(active_dot_color(is_spot))
			dot.name = "ActiveDot"
			pip.add_child(dot)
		var eid: String = id
		pip.pressed.connect(func(): focus_requested.emit(eid))
		_pips.add_child(pip)
	# The commit button reads differently when the spotlit dog is already the active one.
	_commit_btn.disabled = is_active
	_commit_btn.text = "Trener denne" if is_active else "Tren denne"
	# ◀ ▶ only cycle owned breeds — hide them (and drop the "bla med pilene" hint) when there's
	# nothing to cycle to, so a single-dog showcase shows no active-looking dead controls (164).
	var multi := chevrons_active(_entries.size())
	_prev_btn.visible = multi
	_next_btn.visible = multi
	_hint.text = hint_text(_entries.size())

func _name_of(id: String) -> String:
	for entry in _entries:
		var e: Dictionary = entry
		if e.id == id:
			return str(e.get("name", id))
	return id.capitalize()

## The spotlit breed id currently shown — the render-free predicate a test / capture reads.
func spotlit() -> String:
	return _spotlit

## Web-only e2e/capture hook (087): publish the ◀ ▶ / commit / back button centres (viewport px) so the
## Visual-Review capture lands REAL taps on them (they map through the live canvas rect like the menu
## rows). Published on each render + visibility change; a no-op off the web export, never read back.
func _publish() -> void:
	if not OS.has_feature("web") or _commit_btn == null:
		return
	var b := func(btn: Button) -> Dictionary:
		var c := btn.get_global_rect().get_center()
		return {"x": c.x, "y": c.y}
	var d := {"prev": b.call(_prev_btn), "next": b.call(_next_btn),
		"commit": b.call(_commit_btn), "back": b.call(_back_btn)}
	JavaScriptBridge.eval("window.__bra_showcase_buttons = %s;" % JSON.stringify(d), true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_publish()
