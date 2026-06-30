class_name TapGate
extends RefCounted
## Anti-mash freeze for the BRA button (046, phase2.md P2-7). After an ACCEPTED tap the gate
## locks for a FIXED LOCK_S (~350 ms), swallowing taps until it re-arms on its own. Pure +
## tickable (no engine state) so it unit-tests like SitSession (024e): main advances it from
## _process and gates _on_bra_pressed on is_armed().
##
## The window is FIXED, not a hold-open debounce: only an ACCEPTED tap calls lock(), and a
## swallowed tap touches nothing — so a masher tapping during the lock can neither extend the
## freeze nor keep it alive. That is what makes "one tap, then a beat" honest (P2-7) and gives
## P2-6 (mashing should lose) for free: spam taps simply never register.

const LOCK_S := 0.35  ## the fixed re-arm window (~350 ms)

var _remaining := 0.0  ## seconds left in the current lock; <= 0 means armed

## True only when a tap should be accepted (the gate is armed). Pure query — never mutates,
## so it can be polled freely (every press, every frame for the button's locked state).
func is_armed() -> bool:
	return _remaining <= 0.0

## Call when a tap is ACCEPTED — starts a fresh fixed lock. Swallowed taps must NOT call this:
## that omission is precisely what keeps the window fixed rather than masher-extendable.
func lock() -> void:
	_remaining = LOCK_S

## Advance the lock clock by one frame's delta. Re-arms automatically once the window elapses;
## a no-op (clamped at 0) while already armed, so time passing can't drive it negative.
func tick(delta: float) -> void:
	if _remaining > 0.0:
		_remaining = maxf(0.0, _remaining - delta)

## 0..1 for the locked-button UI: 1.0 the instant it locks, easing to 0.0 as it re-arms (and
## 0.0 while armed). Lets the button dim/restore off a single static quantity.
func lock_fraction() -> float:
	return _remaining / LOCK_S
