class_name SitWindow
extends RefCounted
## The apex-band / scoring-window math for one sit (specs2.md P1-5), task 024a.
##
## Pure, deterministic value object — the heart of "mark the moment." A sit is
## markable over [sit_start, sit_end] (the AnimationPlayer clip's span). The apex
## is the fully-seated scoring peak. A tap is scored by closeness to the apex:
##
##   PERFECT  |tap - apex| <= perfect_radius   (the apex band, P1-4's "now")
##   OK       |tap - apex| <= ok_radius         (inside the window, off-peak)
##   MISS     active sit, but outside the window
##   DEAD     no sit active (Phase 1: does nothing — no penalty, P1-5)
##
## Radii are inclusive at their edges so the bands are exact and fair. The
## gameplay layer feeds in tap_time as seconds-into-the-current-sit; the visuals
## (button, tell, readout, payoff) all key off the Tier this returns. No engine
## state is touched here, which is what keeps it test-first (test_sit_window.gd).

enum Tier { DEAD, MISS, OK, PERFECT }

## Band edges are inclusive, but tap times come from float animation positions, so
## a tap "exactly" on an edge lands a hair off in IEEE-754. This tolerance keeps
## the bands exact and fair without flipping an edge tap to the wrong tier; it's
## ~0.01ms — far below 60fps frame granularity, so it can't cause real misscoring.
const EPSILON := 1e-5

## Canonical scoring bands (specs2.md P1-5) — the home of the apex-tolerance rule.
## They live on the scoring class (not the AnimationPlayer driver) so a designer
## tuning difficulty finds them next to the math that uses them. `from_sit_clips`
## still takes explicit radii so difficulty can override these later (029).
const DEFAULT_PERFECT_RADIUS := 0.08  ## the PERFECT band is apex ±80 ms
const DEFAULT_OK_RADIUS := 0.20       ## the OK window is apex ±200 ms

var apex: float           ## seconds: the fully-seated scoring peak
var perfect_radius: float ## half-width of the PERFECT band, inclusive
var ok_radius: float      ## half-width of the OK window, inclusive (>= perfect_radius)
var sit_start: float      ## seconds: when the sit becomes markable (clip start)
var sit_end: float        ## seconds: when the sit stops being markable (clip end)

func _init(
		p_apex: float,
		p_perfect_radius: float,
		p_ok_radius: float,
		p_sit_start: float,
		p_sit_end: float) -> void:
	apex = p_apex
	perfect_radius = p_perfect_radius
	ok_radius = p_ok_radius
	sit_start = p_sit_start
	sit_end = p_sit_end

## Build a window straight from an AnimationPlayer clip: the sit spans
## [0, length], with the apex keyframed at `apex` seconds into it.
static func from_clip(
		length: float,
		apex: float,
		perfect_radius: float,
		ok_radius: float) -> SitWindow:
	return SitWindow.new(apex, perfect_radius, ok_radius, 0.0, length)

## Build a window for a clip-driven sit (024b). The dog builds into the sit over
## `start_len` — the apex (fully seated) is the END of that build — then holds the
## seated loop for `loop_len`. The whole [0, start_len + loop_len] span is markable
## (the dog is "sitting"); outside it the dog is idle and a tap is DEAD. Tying the
## apex to the real `Sitting_start` clip length keeps it a single source of truth
## shared by the pose, the tell (024d), and the score.
static func from_sit_clips(
		start_len: float,
		loop_len: float,
		perfect_radius: float,
		ok_radius: float) -> SitWindow:
	return SitWindow.new(start_len, perfect_radius, ok_radius, 0.0, start_len + loop_len)

## Score a tap at `tap_time` seconds into the current sit. See the table above.
func score(tap_time: float) -> Tier:
	if tap_time < sit_start - EPSILON or tap_time > sit_end + EPSILON:
		return Tier.DEAD
	var dist := absf(tap_time - apex)
	if dist <= perfect_radius + EPSILON:
		return Tier.PERFECT
	if dist <= ok_radius + EPSILON:
		return Tier.OK
	return Tier.MISS

## True when a tier is a successful mark — the gate the payoff (voice + SFX +
## dog reaction, P1-6) keys off. MISS and DEAD are silent.
static func is_successful(tier: Tier) -> bool:
	return tier == Tier.PERFECT or tier == Tier.OK

## Human-readable label for on-screen feedback (P1-7) and logs.
static func tier_name(tier: Tier) -> String:
	match tier:
		Tier.PERFECT: return "PERFECT"
		Tier.OK: return "OK"
		Tier.MISS: return "MISS"
		_: return "DEAD"
