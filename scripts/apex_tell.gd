class_name ApexTell
extends RefCounted
## The apex tell envelope (specs2.md P1-4), task 024d.
##
## A soft pulse that builds to and peaks at the sit's apex — the honest "now" cue
## telling the player when a tap scores PERFECT. It is deliberately pure: given
## seconds-into-the-current-sit it returns an intensity in [0, damping], and the
## visual marker (apex_tell_marker.gd) just renders that number. Keeping the curve
## here, not in a node, is what makes the two acceptance criteria test-first:
##
##   - HONEST: the peak is at exactly `apex` — the same apex SitWindow scores
##     PERFECT at (024a/024b), one source of truth — so the glow can never drift
##     ahead of or behind the band. Build it via `from_window` and they share it.
##   - DORMANT AT REST: outside the markable [sit_start, sit_end] span the dog is
##     idle and there is nothing to mark, so the intensity is exactly 0 — the tell
##     never fires during idle. On the CC0 dog (no Sitt) no window ever opens, so
##     the marker simply stays dark until 025/ADR-0006 ships the sit-capable dog.
##
## The shape is a cosine bell over a `ramp` half-width (defaulting to the OK window,
## so the glow spans exactly the scorable window and is brightest at the PERFECT
## centre): 1.0 at the apex, smoothly to 0.0 at apex ± ramp. `damping` scales the
## whole curve for reduced motion (P1-8) — it dampens the peak but, being a positive
## factor that preserves the shape, never removes the cue (024g routes the real
## prefers-reduced-motion factor in here).

var apex: float       ## seconds: the fully-seated scoring peak (== SitWindow.apex)
var ramp: float       ## seconds: half-width the glow ramps over (0 at apex ± ramp)
var sit_start: float  ## seconds: when the sit becomes markable (clip start)
var sit_end: float    ## seconds: when the sit stops being markable (clip end)
var damping: float    ## reduced-motion scale in (0, 1]; 1.0 = full intensity

func _init(
		p_apex: float,
		p_ramp: float,
		p_sit_start: float,
		p_sit_end: float,
		p_damping := 1.0) -> void:
	apex = p_apex
	ramp = p_ramp
	sit_start = p_sit_start
	sit_end = p_sit_end
	damping = p_damping

## Build the tell from the sit's scoring window so the apex (and the markable span)
## are literally the same values the score uses — the single source of truth. The
## ramp tracks the OK window: the glow is visible across exactly the scorable window
## and dark where a tap would MISS or be DEAD.
static func from_window(window: SitWindow, damping := 1.0) -> ApexTell:
	return ApexTell.new(
		window.apex, window.ok_radius, window.sit_start, window.sit_end, damping)

## Intensity of the tell at `elapsed` seconds into the current sit, in [0, damping].
## 0 outside the active sit (idle — nothing to mark) and beyond apex ± ramp; a
## cosine bell peaking at exactly the apex in between.
func intensity(elapsed: float) -> float:
	if elapsed < sit_start or elapsed > sit_end:
		return 0.0
	var dist := absf(elapsed - apex)
	if dist >= ramp:
		return 0.0
	# Cosine bell: 1.0 at dist 0 (the apex), 0.5 at half-ramp, 0.0 at the ramp edge —
	# a soft build with no snap, monotonic in dist so the brightest instant is the apex.
	var bell := 0.5 * (1.0 + cos(PI * dist / ramp))
	return bell * damping
