class_name LearnedBar
extends Control
## The on-screen learned bar (045, P2-4). A thin horizontal meter near the top of the
## portrait frame that fills as a trick is learned and visibly DROPS on a bad tap. It is a
## deliberately dumb renderer, the same split TierReadout uses: TrickProgress decides the
## value, this node just draws it.
##
## Reduced-motion-safe by construction (X-5 / P1-8): the learned amount reads off the FILL
## LENGTH, a static quantity — no motion is required to read it. The brief red setback flash
## on erosion is a secondary cue layered on top of the length drop, so the setback is still
## legible with motion reduced.
##
## The flash is stepped by main each frame via advance(delta) (like TierReadout.advance and
## the tell marker), so it is fully deterministic and render-free to test — value + flash
## state are read off public fields, no framebuffer needed.

## A brief red wash on a setback, fading over this long (no hold — the drop in length is the
## primary read; the wash just punctuates it).
const FLASH_FADE := 0.45

const TRACK_COLOR := Color(0.0, 0.0, 0.0, 0.35)        ## the empty channel
const FILL_COLOR := Color(0.35, 0.78, 0.48)            ## learning — a calm confident green
const MASTERED_COLOR := Color(1.0, 0.86, 0.30)         ## 100% — the triumphant gold (matches PERFECT)
const SETBACK_COLOR := Color(0.92, 0.26, 0.22)         ## the red setback wash
const BORDER_COLOR := Color(0.0, 0.0, 0.0, 0.5)        ## a dark edge so it reads on the bright sky
const CORNER_INSET := 2.0                              ## fill sits just inside the track edge

var value: float = 0.0      ## learned fraction in [0, 1] — the fill length
var mastered: bool = false  ## drawn as a full gold bar
var _flash := 0.0           ## current setback-wash intensity in [0, 1]

func _init() -> void:
	# Float over the stage; never eat a tap meant for the BRA button below.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Set the learned fraction (and mastered state) and request a redraw. Clamped defensively
## so a caller can pass the raw model value without pre-clamping.
func set_value(v: float, is_mastered := false) -> void:
	value = clampf(v, 0.0, 1.0)
	mastered = is_mastered
	queue_redraw()

## Punctuate a setback with a brief red wash (the bar already drops in length via set_value).
func pulse_setback() -> void:
	_flash = 1.0
	queue_redraw()

## Step the setback wash one frame's delta (driven from main._process). Linear fade to 0.
func advance(delta: float) -> void:
	if _flash <= 0.0:
		return
	_flash = maxf(0.0, _flash - delta / FLASH_FADE)
	queue_redraw()

## True while the setback wash is still showing — the render-free predicate the tests use.
func is_flashing() -> bool:
	return _flash > 0.0

func _draw() -> void:
	var w := size.x
	var h := size.y
	var track := Rect2(0.0, 0.0, w, h)
	draw_rect(track, TRACK_COLOR, true)
	draw_rect(track, BORDER_COLOR, false, 2.0)
	var fill_w := maxf(0.0, (w - 2.0 * CORNER_INSET) * value)
	if fill_w > 0.0:
		var fill := Rect2(CORNER_INSET, CORNER_INSET, fill_w, h - 2.0 * CORNER_INSET)
		draw_rect(fill, MASTERED_COLOR if mastered else FILL_COLOR, true)
	if _flash > 0.0:
		var wash := Color(SETBACK_COLOR.r, SETBACK_COLOR.g, SETBACK_COLOR.b, SETBACK_COLOR.a * _flash)
		draw_rect(track, wash, true)
