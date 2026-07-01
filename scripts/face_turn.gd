class_name FaceTurn
extends RefCounted
## The face-the-camera turn math (061, P2-11 "face me for the trick"). PURE: no Node, no Camera —
## main.gd feeds it the dog's current yaw + a target yaw and reads heading() each frame to yaw the
## dog ROOT (the same root the WanderField roam and the confused beat already rotate; the
## AnimationPlayer animates the skeleton, so this never fights the sit clip).
##
## It eases a heading toward a target at a BOUNDED angular speed (so the turn is smooth, never a
## snap) and always takes the SHORT way around the ±PI wrap (a dog never spins the long way to face
## you). It is RETARGETABLE so ONE turner serves the whole trick: main eases it IN to the
## camera-facing heading when a real sit begins, holds it through the seated apex, then retargets it
## OUT to the roam heading for a smooth release. is_facing() reports arrival.
##
## "Completes before the apex" is main's job, not a rule baked in here: main sizes `speed` =
## turn / (a fraction of the time-to-apex), so a turn of any size finishes before the seated apex.
## Reduced motion (X-5) is the same lever — main hands it a very high speed so the facing resolves
## near-instantly (a dampened/near-instant turn is fine; the trick is still read head-on).
## Determinism (no Node, no time source of its own) is why the contract is unit-tested headless
## while the node-driving glue is Visual-Review-gated (the same split as the WanderField in 050).

## Arrival tolerance (radians, ~1.1°): within this of the target the turn counts as facing and
## snaps exactly onto it, so it never oscillates or drifts around the last fraction of a degree.
const DONE_EPSILON := 0.02

var _heading: float
var _target: float
var _speed: float   ## radians/sec — the bounded turn rate main chooses per turn

## start/target: yaw radians (main uses the WanderField convention, heading = atan2(dir.x, dir.z),
## so the dog faces `dir`). speed: the bounded turn rate; negative is clamped to 0 (a still turner).
func _init(start: float, target: float, speed: float) -> void:
	_heading = start
	_target = target
	_speed = maxf(speed, 0.0)

## Aim at a new target yaw without changing the current heading — the same turner eases IN to the
## camera during the sit, then main retargets it OUT to the roam heading for the release.
func retarget(target: float) -> void:
	_target = target

## Change the bounded turn rate mid-life (main boosts it to beat the apex for the turn-in, then
## resets it to the natural roam rate for the release). Negative clamps to 0.
func set_speed(speed: float) -> void:
	_speed = maxf(speed, 0.0)

## Advance one frame: step the heading toward the target along the SHORTEST signed arc (wrapped to
## ±PI so it never sweeps the long way around), by at most speed*delta. On the step that would reach
## or pass the target, land EXACTLY on it (no overshoot, no drift).
func advance(delta: float) -> void:
	var diff := wrapf(_target - _heading, -PI, PI)
	var step := _speed * delta
	if step >= absf(diff):
		_heading = _target
	else:
		_heading += signf(diff) * step

## The current yaw (radians) — main yaws the dog root basis by this each frame.
func heading() -> float:
	return _heading

## The yaw currently aimed at.
func target() -> float:
	return _target

## True once the heading has reached the target (within DONE_EPSILON) — main uses this to know the
## turn-in finished (hold the camera facing) and, on release, when to hand the yaw back to the
## instant wander.
func is_facing(eps := DONE_EPSILON) -> bool:
	return absf(wrapf(_target - _heading, -PI, PI)) <= eps
