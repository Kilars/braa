class_name DogFraming
extends RefCounted
## Model-agnostic camera framing: centre any dog in the portrait frame and fit the
## camera distance to its bounds, so the dog reads centred (P1-2 "centred"; D12 /
## PO-Change-3) on the CC0 placeholder and the licensed Labrador alike — no per-model
## tuning. Pure math, unit-tested headless (024c). main.gd feeds it the loaded dog's
## bounds and points a Camera3D (KEEP_HEIGHT) from eye() at target().

## Gentle 3/4 view: a touch above centre. look_at(target) keeps the dog centred.
const VIEW_DIR := Vector3(0.0, 0.18, 1.0)
## Stand off by a fraction of the dog's depth so the near face isn't undersized,
## without pushing a long dog so far back it shrinks.
const DEPTH_STANDOFF := 0.25

## The point the camera looks at: the dog's bounding-box centre.
static func target(aabb: AABB) -> Vector3:
	return aabb.position + aabb.size * 0.5

## Distance from the centre so the box fits a Camera3D (KEEP_HEIGHT) frustum with
## margin. fov_deg = vertical FOV; aspect = viewport width/height (portrait < 1);
## fill ∈ (0,1] = fraction of the tighter frame dimension the dog spans (smaller →
## more breathing room). Fits both width and height.
static func distance(aabb: AABB, fov_deg: float, aspect: float, fill: float) -> float:
	var v_half := deg_to_rad(fov_deg) * 0.5
	var h_half := atan(tan(v_half) * aspect)
	var dist_v := (aabb.size.y * 0.5) / tan(v_half) / fill
	var dist_w := (aabb.size.x * 0.5) / tan(h_half) / fill
	return maxf(dist_v, dist_w) + aabb.size.z * DEPTH_STANDOFF

## Full camera eye position for the given dog bounds.
static func eye(aabb: AABB, fov_deg: float, aspect: float, fill: float) -> Vector3:
	return target(aabb) + VIEW_DIR.normalized() * distance(aabb, fov_deg, aspect, fill)
