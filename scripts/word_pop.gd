class_name WordPop
extends Label
## The juicy marker-word burst (P5-3, task 094). A dumb renderer, twin of TierReadout: main
## decides the fired word, this shows it, floats it up from the BRA button, and fades it out.
## The fade is stepped by main each frame via advance(delta), so it's fully deterministic and
## render-free to test — visibility, opacity, and rise offset are read off pure predicates
## (text, self_modulate.a, rise_offset()), no framebuffer needed.
##
## Reduced motion (X-5): set_motion_scale() dampens the float, never removes the word.
## The word text and alpha are always unaffected by motion scale.

const HOLD := 0.45          ## fully opaque + readable this long, then fade over FADE
const FADE := 0.55          ## linear fade from opaque to fully transparent
const RISE_PX := 64.0       ## how far the word floats UP over its life at full motion
const COLOR_WORD := DesignSystem.GOLD                 ## the ONE reserved gold — agrees with PERFECT + coin + mastery bar (183, X-6)
const OUTLINE_COLOR := Color(0.07, 0.07, 0.10, 1.0)   ## near-black stroke, reads against any sky
const OUTLINE_SIZE := 13                               ## firmer stroke to match PERFECT's legibility ratio
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.55)      ## solid drop-shadow, reads over bright grass

var _age := 0.0
var _active := false
var _motion := 1.0      ## X-5 factor; 1.0 = full, ReducedMotion.DAMPED = calmer, never 0
var _base_y := 0.0      ## set in _ready() from the node's laid-out position.y (float is relative)

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # never eats a BRA tap
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 64)
	add_theme_color_override("font_color", COLOR_WORD)
	add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	add_theme_constant_override("outline_size", OUTLINE_SIZE)
	# Solid drop-shadow on top of the outline for high contrast over bright grass
	add_theme_color_override("font_shadow_color", SHADOW_COLOR)
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 3)
	add_theme_constant_override("shadow_outline_size", 1)
	self_modulate.a = 0.0  # start blank — nothing fired yet

func _ready() -> void:
	_base_y = position.y   # capture the anchored offset so the float is relative to mount point

## Set the X-5 motion factor (guarded against zero / non-finite, same as the tell).
## Motion scale ONLY affects rise_offset() — never text, alpha, or visibility.
func set_motion_scale(scale: float) -> void:
	if not is_finite(scale) or scale <= 0.0:
		_motion = 1.0
	else:
		_motion = scale

## Pop the given already-display-formatted word (e.g. "Dyktig!"). Resets the fade clock so the
## word shows at full opacity immediately. Empty string clears (defensive — a mark always fires
## SOME word, so main only calls this on a successful mark with a real word).
func pop(word: String) -> void:
	text = word
	if word == "":
		_active = false
		_age = 0.0
		self_modulate.a = 0.0
		return
	self_modulate = Color(COLOR_WORD.r, COLOR_WORD.g, COLOR_WORD.b, 1.0)
	_active = true
	_age = 0.0

## The upward float offset in px (negative = up) for the current age. Pure function of _age
## and _motion — unit-testable even without a scene tree (_base_y stays 0.0 in headless tests).
## 0.0 at age 0; grows more negative (upward) over HOLD + FADE; capped at -RISE_PX * _motion.
func rise_offset() -> float:
	return -RISE_PX * _motion * clampf(_age / (HOLD + FADE), 0.0, 1.0)

## Step the fade by one frame's delta (driven from main._process). Full opacity through HOLD,
## then a linear fade to 0 over FADE, then inert until the next pop().
func advance(delta: float) -> void:
	if not _active:
		return
	_age += delta
	position.y = _base_y + rise_offset()
	if _age <= HOLD:
		self_modulate.a = 1.0
		return
	var t := (_age - HOLD) / FADE
	if t >= 1.0:
		self_modulate.a = 0.0
		_active = false
		return
	self_modulate.a = 1.0 - t

## True while the word is actually visible — non-empty text and some opacity.
## The render-free predicate the tests use.
func is_visible_now() -> bool:
	return text != "" and self_modulate.a > 0.0
