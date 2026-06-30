class_name TrainerRingMarker
extends Control
## The visual half of the approach-cue trainer ring (specs2.md P2-9), task 058.
##
## A deliberately dumb renderer: TrainerRing (the pure envelope) decides WHEN and HOW
## bright/large via `radius_scale` and `opacity`; this node draws a bold contracting ring
## whose pixel radius shrinks from large (far from the button) to small (framing the verb)
## as it lands at the apex. All the honesty — lands exactly at the apex, dark during
## feints/idle, gone at mastery — lives in TrainerRing and is unit-tested there; this node
## only has to track the two driven values and never steal a tap from the button it overlays.
##
##   - `self_modulate.a` tracks `opacity` (set by set_opacity), so 0 is genuinely invisible
##     and the fade is observable in tests without a framebuffer.
##   - `mouse_filter = IGNORE` so the marker, sitting on top of the BRA button, passes every
##     touch straight through to the button (P1-5).
##   - Visually DISTINCT from the gold apex tell: a cool cyan/blue outlined ring with no halo,
##     thicker line, so the two cues read as two different things (approach vs. "now").

## Approach ring colour — cool blue/cyan so it reads as "coming in" vs the gold "now" tell.
const RING_COLOR := Color(0.25, 0.75, 1.0)
## Ring line width in px at the pinned 720-wide viewport. Thicker than the tell's 10px
## so it reads as "bold approach" even at small radius.
const RING_WIDTH := 14.0

## Marker square edge at the pinned 720-wide viewport. Matches ApexTellMarker.SIZE so
## main.gd can centre this marker identically to the tell with the same anchor math.
const SIZE := 320.0
## Half-width of the "BRA" glyph run — the landed ring must frame the word.
const WORD_HALF_WIDTH := 90.0

## Pixel radius when the ring has just landed (radius_scale == 0): a tight ring that
## frames the BRA word. Expressed as a fraction of the unit (SIZE*0.5 = 160 px):
## 0.62 * 160 ≈ 99 px — outside WORD_HALF_WIDTH so it frames rather than crosses the word.
## Matches the tell's RING_BASE so the two rings are concentric at the landing moment.
const APPROACH_LANDED := 0.62
## How far out the ring starts when fully expanded (radius_scale == 1.0):
## 0.62 + 1.0 = 1.62 * 160 ≈ 259 px — well outside the button, clearly "approaching".
const APPROACH_SPAN := 1.0

var _opacity: float = 0.0       ## current opacity in [0, 1]; 0 = dormant
var _radius_scale: float = 0.0  ## current radius scale in [0, 1] from TrainerRing

## Pure radius helper (render-free, so the framing geometry is unit-testable).
static func ring_radius(unit: float, radius_scale: float) -> float:
	return unit * (APPROACH_LANDED + APPROACH_SPAN * radius_scale)

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # never eat a tap meant for BRA
	self_modulate.a = 0.0                       # start dark — nothing to mark yet

## Set the ring's opacity (from TrainerRing.opacity each frame). Drives the node's overall
## alpha so the whole ring fades as one and redraws. Clamped so out-of-range values can't
## over-brighten the cue.
func set_opacity(value: float) -> void:
	_opacity = clampf(value, 0.0, 1.0)
	self_modulate.a = _opacity
	queue_redraw()

## Set the ring's radius scale (from TrainerRing.radius_scale each frame). Drives _draw.
func set_radius_scale(value: float) -> void:
	_radius_scale = clampf(value, 0.0, 1.0)
	queue_redraw()

## True while the ring is visible at all — the render-free predicate tests use to prove it
## stays dark during idle and feints.
func is_showing() -> bool:
	return _opacity > 0.0

## Draw one bold approach ring whose pixel radius shrinks as it lands. The ring starts
## large and outside the BRA word, contracting to frame the button at landing. Visually
## distinct from the gold apex tell: cool blue/cyan, outlined only (no halo), thicker line.
func _draw() -> void:
	if _opacity <= 0.0:
		return
	var center := size * 0.5
	var unit := minf(size.x, size.y) * 0.5
	draw_arc(center, ring_radius(unit, _radius_scale), 0.0, TAU, 64,
		Color(RING_COLOR, 1.0), RING_WIDTH, true)
