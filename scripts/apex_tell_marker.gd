class_name ApexTellMarker
extends Control
## The visual half of the apex tell (specs2.md P1-4), task 024d.
##
## A deliberately dumb renderer: ApexTell (the pure envelope) decides WHEN and HOW
## bright via `intensity` in [0,1]; this node just draws a soft warm pulse at that
## intensity, centred on its rect (placed over the BRA marker by main.gd). All the
## honesty — peak exactly at the apex, dark during idle — lives in ApexTell and is
## unit-tested there; this node only has to fade with `intensity` and never steal a
## tap from the button it overlays.
##
##   - `intensity` drives the whole node's opacity through `self_modulate.a`, so 0
##     is genuinely invisible (dormant at rest) and 1.0 is the full pulse. Tests
##     assert the fade without needing a framebuffer.
##   - `mouse_filter = IGNORE` so the marker, sitting on top of the BRA button,
##     passes every touch straight through to the button (P1-5).

## Warm pulse colour — reads as a friendly "now", not an alarm. A genuinely
## SATURATED gold (not a pale cream): it must still read as gold once alpha-blended
## over the dark BRA button, where a washed-out tint collapses toward grey. (030)
const GLOW := Color(1.0, 0.78, 0.20)
## Boldness of the pulse, fenced by test (030). The tell renders fine — the forced-
## intensity capture proved the composite — but as first authored it was a thin,
## ~half-alpha cream ring that desaturated over the dark button and was halved again
## under reduced motion (×ReducedMotion.DAMPED), so it read as "never renders" to both
## the eye and a saturated-gold detector (PO 2026-06-28, the #1 reopened defect). These
## are the per-element base alphas/width; the whole node also fades by
## `self_modulate.a == intensity`, so the effective on-screen alpha is `base * intensity`.
const HALO_ALPHA := 0.40   ## soft bloom disc (base alpha)
const RING_ALPHA := 1.0    ## the crisp "now" ring (base alpha) — opaque at peak
const RING_WIDTH := 10.0   ## ring line width in px at the pinned 720-wide viewport

var intensity: float = 0.0  ## current tell intensity in [0,1]; 0 = dormant

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # never eat a tap meant for BRA
	self_modulate.a = 0.0                       # start dark — nothing to mark yet

## Set the tell's intensity (from ApexTell each frame). Drives the node's opacity so
## the whole pulse fades as one, and redraws. Clamped so an out-of-range value can't
## over-brighten the cue.
func set_intensity(value: float) -> void:
	intensity = clampf(value, 0.0, 1.0)
	self_modulate.a = intensity
	queue_redraw()

## True while the tell is visible at all — the render-free predicate tests use to
## prove it stays dark during idle (and on the CC0 dog, which never opens a sit).
func is_showing() -> bool:
	return intensity > 0.0

## A soft halo plus a crisp ring that both grow slightly toward the apex, so the
## peak reads as a gentle bloom rather than a snap. Per-element alphas set the
## relative softness; the overall fade is `self_modulate.a` (== intensity), so the
## shape is drawn at full alpha here and faded globally.
func _draw() -> void:
	if intensity <= 0.0:
		return
	var center := size * 0.5
	var unit := minf(size.x, size.y) * 0.5
	# Soft halo: a translucent disc that blooms a touch as the apex nears.
	draw_circle(center, unit * (0.78 + 0.18 * intensity), Color(GLOW, HALO_ALPHA))
	# Crisp apex ring: brighter, blooming slightly — marks the "now".
	draw_arc(center, unit * (0.62 + 0.12 * intensity), 0.0, TAU, 64,
		Color(GLOW, RING_ALPHA), RING_WIDTH, true)
