class_name WanderField
extends RefCounted
## The bounded-patch ambient wander math (050, P2-8 locomotion). PURE: no Node, no
## AnimationPlayer — main.gd reads position()/heading() each frame to glide the dog ROOT across
## the grass while idle, and the dog's real walk clip (DogDirector.play_walk) moves the legs. The
## camera stays FIXED; only the dog translates (the PO's P2-8 "the dog wanders … camera fixed").
##
## The roam is an amble→pause→amble rhythm inside a disc of `radius` centred on the dog's rest
## spot: pick a target inside the disc, walk to it (facing it, so it reads as roaming not
## sliding), pause a beat (idle clip reads), pick another. Targets are always inside the patch and
## the position is clamped to it, so the dog turns back at the edges and NEVER walks out of frame
## or off the grass. Determinism comes from an INJECTED, seeded RandomNumberGenerator (the same
## idiom as SitLoop), so "target in range / edge turn-back / never leaves the patch" are
## unit-tested headless; production constructs one with a random seed.

enum Phase { MOVING, PAUSING }

## Patch radius (m). The dog fills ~70% of the frame width centred (FRAME_FILL), so the lateral
## budget before its broadside silhouette clips an edge is small: a Visual-Review capture at 0.55
## walked the dog's head off the right edge. 0.32 keeps it fully framed at its widest (facing
## across the frame) while a ±0.32 m roam on a ~1 m dog still reads clearly as roaming.
const DEFAULT_RADIUS := 0.32
const DEFAULT_SPEED := 0.45   ## metres/sec — a calm amble, not a dart
const DEFAULT_PAUSE := 1.0    ## seconds paused at each target before ambling on
const ARRIVE_EPSILON := 0.04  ## metres: within this of the target, count it reached

var radius: float
var speed: float
var pause_time: float
var _rng: RandomNumberGenerator
var _pos: Vector2 = Vector2.ZERO   ## XZ offset from the dog's rest spot (x = world X, y = world Z)
var _target: Vector2
var _heading: float = 0.0          ## yaw radians the dog faces — its current travel heading
var _phase: int = Phase.MOVING
var _pause_elapsed: float = 0.0

## rng: inject a seeded RandomNumberGenerator for deterministic tests; null (production) builds
## one with a random seed. The patch radius / amble speed / pause beat are tunable for Visual
## Review without touching the math.
func _init(rng: RandomNumberGenerator = null, p_radius := DEFAULT_RADIUS,
		p_speed := DEFAULT_SPEED, p_pause := DEFAULT_PAUSE) -> void:
	_rng = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		_rng.randomize()
	radius = p_radius
	speed = p_speed
	pause_time = p_pause
	_target = pick_target()

## A fresh target uniformly inside the patch disc — guaranteed within `radius` (sqrt on the
## radial draw spreads the points by area instead of clumping them at the centre).
func pick_target() -> Vector2:
	var ang := _rng.randf() * TAU
	var r := sqrt(_rng.randf()) * radius
	return Vector2(cos(ang), sin(ang)) * r

## Advance one frame. While MOVING, step toward the current target (facing it) and clamp to the
## patch; on arrival, begin the pause. While PAUSING, wait out the beat then draw a fresh target
## and amble on. Read position()/heading()/is_moving() after.
func advance(delta: float) -> void:
	if _phase == Phase.PAUSING:
		_pause_elapsed += delta
		if _pause_elapsed >= pause_time:
			_pause_elapsed = 0.0
			_phase = Phase.MOVING
			_target = pick_target()
		return
	var to := _target - _pos
	var dist := to.length()
	if dist <= ARRIVE_EPSILON:
		_phase = Phase.PAUSING
		_pause_elapsed = 0.0
		return
	_heading = atan2(to.x, to.y)  # face the travel direction so it reads as roaming
	var step := minf(speed * delta, dist)
	_pos = clamp_to_patch(_pos + to / dist * step)

## Pull a point back onto the patch boundary if it strays past it (same bearing) — the turn-back
## mechanism, and a belt-and-suspenders guard that the dog can never leave the patch.
func clamp_to_patch(p: Vector2) -> Vector2:
	if p.length() > radius:
		return p.normalized() * radius
	return p

## The dog's current XZ offset from its rest spot (within the patch).
func position() -> Vector2:
	return _pos

## The target the dog is currently ambling toward (or paused at).
func target() -> Vector2:
	return _target

## The yaw (radians) the dog faces — its travel heading, so main can turn the root to match.
func heading() -> float:
	return _heading

## True while ambling toward a target (drive the walk clip); false while paused (drive idle).
func is_moving() -> bool:
	return _phase == Phase.MOVING
