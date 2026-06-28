class_name SitSession
extends RefCounted
## The BRA-tap session (024e, specs2.md P1-5). SitWindow (024a) is the pure per-sit
## math — given a tap_time it returns a Tier. SitSession is the thin state layer the
## button taps into: it owns whether a sit is OPEN right now and how many seconds we
## are INTO it, so the gameplay layer never has to track "is this tap markable, and
## at what t". It is the testable seam between the running scene and the scoring
## math (no engine state here — driven by open/close from the director and advance()
## from the frame loop).
##
##   - With no sit open, every tap is DEAD: it does nothing, no penalty (P1-5). On
##     the CC0 placeholder (no Sitt clip) that is every tap — the button still works.
##   - While a sit is open, a tap scores against the window at the elapsed time, so
##     a tap at the apex is PERFECT. When 025/ADR-0006 ships the sit-capable
##     Labrador, the same taps light up with zero gameplay change.

var _window: SitWindow = null  ## the open sit, or null when the dog is not sitting
var _elapsed: float = 0.0      ## seconds into the current sit (only runs while open)

## True while a sit is markable (a window is open).
func is_open() -> bool:
	return _window != null

## Seconds elapsed into the current sit — the tap_time a tap is scored at.
func elapsed() -> float:
	return _elapsed

## Open a sit: taps now score against this window, timed from t=0. Re-opening
## restarts the clock so each new sit's apex aligns with its own build-in.
func open(window: SitWindow) -> void:
	_window = window
	_elapsed = 0.0

## Close the sit (the dog stood up / the sequence ended): taps are DEAD again.
func close() -> void:
	_window = null

## Advance the sit clock by one frame's delta. A no-op while closed, so a session's
## clock only runs during an actual sit — the next open() starts honestly at t=0.
func advance(delta: float) -> void:
	if _window != null:
		_elapsed += delta

## Score a tap at the current elapsed time. DEAD when no sit is open — a dead tap
## does nothing in Phase 1 (no penalty, P1-5).
func tap() -> SitWindow.Tier:
	if _window == null:
		return SitWindow.Tier.DEAD
	return _window.score(_elapsed)
