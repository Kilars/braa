class_name TrainerRing
extends RefCounted
## The approach-cue envelope (specs2.md P2-9), task 058.
##
## A ring that shrinks onto the BRA button and lands EXACTLY at the apex — the honest
## "tap when it lands" approach cue for a new trick. It is deliberately pure: given
## seconds-into-the-current-sit it returns a radius_scale and an opacity in [0, 1], and
## the visual marker (trainer_ring_marker.gd) just renders those numbers. Keeping the
## math here, not in a node, is what makes the two acceptance criteria test-first:
##
##   - HONEST: the ring lands at exactly `apex` — the same apex SitWindow scores PERFECT
##     at (single source of truth). Build it via `from_window` and they share it.
##   - FADES WITH LEARNING: the ring's opacity equals `teach`, derived from the learned-bar
##     value via `teach_strength()`. Gone at mastery (teach == 0); boldest on a brand-new
##     trick (teach == 1). The experienced player is weaned off the cue naturally.
##   - DARK OFF-WINDOW: outside [sit_start, apex] — idle, feints, after it lands — the
##     ring is dark. A feint never opens a SitWindow, so _trainer is never built, so the
##     ring never appears during a feint (the P2-9 honesty bullet).

## Guards against zero-length sits so division never produces NaN/Inf.
const EPSILON := 1e-5

var sit_start: float  ## seconds: when the approach begins (== SitWindow.sit_start)
var apex: float       ## seconds: when the ring lands / opacity falls to 0 (== SitWindow.apex)
var teach: float      ## approach prominence in [0, 1]; 0 = mastered (gone), 1 = brand-new

## The fade law: how prominently to show the cue given the current learned-bar state.
## 1.0 at a brand-new trick (value == 0) → monotonically decreasing → 0.0 at mastery.
## Simplest honest law that hits both endpoints: 1 - value, latched at mastery flag for
## the safe-checkpoint (mastered tricks never re-show the cue, even during re-practice).
static func teach_strength(value: float, mastered: bool) -> float:
	return 0.0 if mastered else clampf(1.0 - value, 0.0, 1.0)

## Build the ring from the sit's scoring window so sit_start and apex are literally the
## same values the score uses — the single source of truth. The ring can never drift off
## the scored apex.
static func from_window(window: SitWindow, teach: float) -> TrainerRing:
	var ring := TrainerRing.new()
	ring.sit_start = window.sit_start
	ring.apex = window.apex
	ring.teach = teach
	return ring

## Normalised ring radius at `elapsed` seconds into the current sit, in [0, 1].
## 1.0 (fully expanded, far from the button) at sit_start, shrinking monotonically to
## 0.0 (landed on the button) at the apex. 0.0 outside [sit_start, apex] — the ring
## only exists during the approach span.
func radius_scale(elapsed: float) -> float:
	if elapsed < sit_start or elapsed > apex:
		return 0.0
	var f := clampf((elapsed - sit_start) / maxf(apex - sit_start, EPSILON), 0.0, 1.0)
	return 1.0 - f  # 1.0 (far) at sit_start → 0.0 (landed) at apex

## Opacity of the approach ring at `elapsed` seconds into the current sit, in [0, 1].
## 0 outside [sit_start, apex] (dark during idle / feints / after landing); 0 whenever
## teach <= 0 (gone at mastery); otherwise equal to `teach` so the cue tracks the bar.
func opacity(elapsed: float) -> float:
	if teach <= 0.0 or elapsed < sit_start or elapsed > apex:
		return 0.0
	return teach
