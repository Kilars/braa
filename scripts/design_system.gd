class_name DesignSystem
extends RefCounted
## Phase-6 design-token vault (task 096).
##
## Single source of truth for the Bra Design System: palette, radius scale,
## spacing scale, type scale, shadow tokens, real OFL fonts, StyleBox builders,
## and a Godot Theme. Every UI surface consumes tokens from here — no more
## ad-hoc Color(...) literals scattered across 7 scripts.
##
## Pure-data constants are unit-tested in tests/test_design_system.gd.
## Font accessors are lazy-loaded and cached statically.

# ---------------------------------------------------------------------------
# Palette (from the Bra Design System HTML spec)
# ---------------------------------------------------------------------------
const BLUE       := Color("4a90e2")   # primary — BRA button
const BLUE_DARK  := Color("2f6fbf")   # primary depth / pressed / button bottom-lip
const BLUE_LIGHT := Color("6fb6ff")
const GOLD       := Color("f5b841")   # accent — coins / mastery
const GOLD_DARK  := Color("d99a2b")
const GOLD_LIGHT := Color("ffdd8c")
const SLATE      := Color("5a6b7d")   # primary text on light
const SLATE_SOFT := Color("8a97a4")   # secondary text
const INK        := Color("1e2a3a")   # darkest ink  rgba(30,42,58,1)
const PAPER      := Color("fbfbf7")   # panel / card surface
const CREAM      := Color("f4efe6")   # page tint
const BORDER     := Color("e9e2d5")   # hairline border on paper
const DANGER     := Color("ff7a85")   # setback / miss

# ---------------------------------------------------------------------------
# Radius scale (px)
# ---------------------------------------------------------------------------
const R_SM   := 8
const R_MD   := 14
const R_LG   := 18    # primary
const R_XL   := 22
const R_PILL := 9999

# ---------------------------------------------------------------------------
# Spacing scale (px): s0..s4
# ---------------------------------------------------------------------------
const SPACE := [4, 8, 12, 16, 24]

## Return the spacing value at `step`, clamped to [0, len(SPACE)-1].
static func space(step: int) -> int:
	return SPACE[clamp(step, 0, SPACE.size() - 1)]

# ---------------------------------------------------------------------------
# Type scale (px)
# ---------------------------------------------------------------------------
const T_DISPLAY := 52   # Baloo 2 — hero (BRA)
const T_TITLE   := 26   # Baloo 2 — headings
const T_HEAD    := 18   # Baloo 2 — sub-heading / badge
const T_BODY    := 15   # Nunito — body
const T_SMALL   := 13   # Nunito / JetBrains Mono — caption / numeric

# ---------------------------------------------------------------------------
# Shadow tokens  (Godot StyleBoxFlat: shadow_size + shadow_offset + shadow_color)
# CSS equivalent: box-shadow: 0 6px 20px rgba(29,42,58,.08)
# ---------------------------------------------------------------------------
const SHADOW_CARD_COLOR  := Color(0.114, 0.165, 0.227, 0.08)
const SHADOW_CARD_SIZE   := 20
const SHADOW_CARD_OFFSET := Vector2(0, 6)

# ---------------------------------------------------------------------------
# Font source paths (OFL, committed under assets/fonts/)
# ---------------------------------------------------------------------------
const F_DISPLAY := "res://assets/fonts/Baloo2-Variable.ttf"
const F_BODY    := "res://assets/fonts/Nunito-Variable.ttf"
const F_MONO    := "res://assets/fonts/JetBrainsMono-Medium.ttf"

# Static cache: path → FontFile (loaded once)
static var _font_files: Dictionary = {}
# Static cache for the four named faces
static var _face_display: Font = null
static var _face_body:    Font = null
static var _face_bold:    Font = null
static var _face_mono:    Font = null

## Load and cache a FontFile by path. Returns null on missing resource (guard only —
## all three paths exist in the committed tree so this branch never fires in production).
static func _load_file(path: String) -> FontFile:
	if _font_files.has(path):
		return _font_files[path] as FontFile
	if not ResourceLoader.exists(path):
		return null
	var ff := load(path) as FontFile
	_font_files[path] = ff
	return ff

## Baloo 2 SemiBold (wght 600) — display / BRA hero text.
static func font_display() -> Font:
	if _face_display != null:
		return _face_display
	var ff := _load_file(F_DISPLAY)
	if ff == null:
		_face_display = ThemeDB.fallback_font
		return _face_display
	var fv := FontVariation.new()
	fv.base_font = ff
	fv.set_variation_opentype({&"wght": 600})
	_face_display = fv
	return _face_display

## Nunito Regular (wght 400) — body text.
static func font_body() -> Font:
	if _face_body != null:
		return _face_body
	var ff := _load_file(F_BODY)
	if ff == null:
		_face_body = ThemeDB.fallback_font
		return _face_body
	var fv := FontVariation.new()
	fv.base_font = ff
	fv.set_variation_opentype({&"wght": 400})
	_face_body = fv
	return _face_body

## Nunito Bold (wght 700) — bold body / emphasis.
static func font_body_bold() -> Font:
	if _face_bold != null:
		return _face_bold
	var ff := _load_file(F_BODY)
	if ff == null:
		_face_bold = ThemeDB.fallback_font
		return _face_bold
	var fv := FontVariation.new()
	fv.base_font = ff
	fv.set_variation_opentype({&"wght": 700})
	_face_bold = fv
	return _face_bold

## JetBrains Mono Medium — numeric / monospace.
static func font_mono() -> Font:
	if _face_mono != null:
		return _face_mono
	var ff := _load_file(F_MONO)
	if ff == null:
		_face_mono = ThemeDB.fallback_font
		return _face_mono
	_face_mono = ff
	return _face_mono

# ---------------------------------------------------------------------------
# StyleBox builders
# ---------------------------------------------------------------------------

## Soft card panel: bg fill, all-corners radius, hairline BORDER, card shadow.
static func panel(bg: Color = PAPER, radius: int = R_LG) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left     = radius
	sb.corner_radius_top_right    = radius
	sb.corner_radius_bottom_left  = radius
	sb.corner_radius_bottom_right = radius
	# Hairline border
	sb.border_width_top    = 1
	sb.border_width_right  = 1
	sb.border_width_bottom = 1
	sb.border_width_left   = 1
	sb.border_color = BORDER
	# Card shadow
	sb.shadow_color  = SHADOW_CARD_COLOR
	sb.shadow_size   = SHADOW_CARD_SIZE
	sb.shadow_offset = SHADOW_CARD_OFFSET
	return sb

## Pill / badge: bg fill, all-corners radius (default R_PILL = fully rounded).
static func pill(bg: Color, radius: int = R_PILL) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left     = radius
	sb.corner_radius_top_right    = radius
	sb.corner_radius_bottom_left  = radius
	sb.corner_radius_bottom_right = radius
	return sb

# ---------------------------------------------------------------------------
# Godot Theme — applied at the scene root so all Control text uses real fonts
# ---------------------------------------------------------------------------

## Build (once) the project Theme: Nunito body font + T_BODY default size,
## Button/Label font_color = SLATE. Consumed by main._ready() (task 096 §C).
static func theme() -> Theme:
	var t := Theme.new()
	t.default_font      = font_body()
	t.default_font_size = T_BODY
	# Button defaults
	t.set_color("font_color",          "Button", SLATE)
	t.set_color("font_pressed_color",  "Button", SLATE)
	t.set_color("font_hover_color",    "Button", SLATE)
	t.set_color("font_disabled_color", "Button", SLATE_SOFT)
	# Label defaults
	t.set_color("font_color", "Label", SLATE)
	return t
