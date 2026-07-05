class_name BackgroundGrace
extends RefCounted
## Post-resume tap grace (120, P4-5). On mobile, returning to the app from background/lock often
## delivers a stray touch on the first frame — which, in this timing game, would land as a false BRA
## mark (an undeserved erosion/penalty). After a resume-from-background, BRA taps within GRACE_S are
## ignored so a stray resume-touch (a notification, a lock) never causes a false mark.
##
## Pure + clock-injected (the caller passes elapsed seconds) so it is unit-testable with no real timer —
## the same discipline as SitWindow / Difficulty. main arms it on the resume notification and consults
## is_grace_active() in the BRA tap handler; a tap inside the window is swallowed (neither mark nor miss).

## The grace window after a resume, in seconds. Long enough to swallow the first stray resume-touch,
## short enough that it never blocks a legitimate tap once the player is back in control.
const GRACE_S := 0.35

## Seconds (monotonic) of the last resume, or -1.0 when never armed (so a game that never backgrounds
## is never in grace — the default no-ops).
var _armed_at := -1.0

## Arm the grace at `now` (the monotonic clock at a resume-from-background). Called from main's resume
## notification hook.
func arm(now: float) -> void:
	_armed_at = now

## True iff `now` falls inside the grace window that opened at the last arm(). Half-open [arm, arm+GRACE_S)
## so a tap exactly at GRACE_S already counts as normal play. Never true when unarmed (_armed_at < 0).
func is_grace_active(now: float) -> bool:
	return _armed_at >= 0.0 and (now - _armed_at) < GRACE_S
