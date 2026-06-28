extends "res://tests/test_case.gd"
## TDD for DogFraming (024c): the camera must centre any dog and fit its bounds, so the
## dog reads centred (P1-2 "centred"; D12 / PO-Change-3) on the CC0 placeholder and the
## licensed Labrador alike — no per-model tuning. Pure math, no scene. The real-dog
## AABB below is measured headless from the committed glb (probe, 2026-06-28).

const FOV := 75.0
const PORTRAIT := 0.5625  # 720/1280 — the project's logical viewport (stretch=keep)

# Measured from assets/models/dog.glb: centre (0, 0.928, 0.279), size (0.95, 1.898,
# 2.098). pos = centre - size/2. get_aabb() is the static mesh AABB (pose-independent),
# so this is exactly what main.gd computes at load.
const DOG := AABB(Vector3(-0.475, -0.021, -0.770), Vector3(0.950, 1.898, 2.098))

func _close(a: float, b: float, eps := 0.001) -> bool:
	return absf(a - b) <= eps

func test_target_is_the_box_centre() -> void:
	var t := DogFraming.target(AABB(Vector3(-0.5, 0.0, -1.0), Vector3(1.0, 2.0, 2.0)))
	assert_true(_close(t.x, 0.0) and _close(t.y, 1.0) and _close(t.z, 0.0),
		"target is the AABB centre, got %s" % t)

func test_real_dog_target_is_its_centre() -> void:
	var t := DogFraming.target(DOG)
	assert_true(_close(t.x, 0.0) and _close(t.y, 0.928) and _close(t.z, 0.279, 0.002),
		"the committed dog centres at (0, 0.928, 0.279), got %s" % t)

func test_taller_dog_needs_more_distance() -> void:
	var short := AABB(Vector3.ZERO, Vector3(1, 1, 1))
	var tall := AABB(Vector3.ZERO, Vector3(1, 3, 1))
	assert_true(DogFraming.distance(tall, FOV, PORTRAIT, 0.8)
			> DogFraming.distance(short, FOV, PORTRAIT, 0.8),
		"a taller dog must be framed from farther back")

func test_wider_dog_needs_more_distance() -> void:
	var narrow := AABB(Vector3.ZERO, Vector3(1, 1, 1))
	var wide := AABB(Vector3.ZERO, Vector3(4, 1, 1))
	assert_true(DogFraming.distance(wide, FOV, PORTRAIT, 0.8)
			> DogFraming.distance(narrow, FOV, PORTRAIT, 0.8),
		"a wider dog must be framed from farther back")

func test_more_margin_means_more_distance() -> void:
	assert_true(DogFraming.distance(DOG, FOV, PORTRAIT, 0.6)
			> DogFraming.distance(DOG, FOV, PORTRAIT, 0.95),
		"a smaller fill (more margin) pushes the camera back")

func test_portrait_binds_on_width_more_than_landscape() -> void:
	# A wide, short box: a narrow portrait horizontal FOV forces a larger distance
	# than a landscape aspect would, to fit the same width.
	var wide := AABB(Vector3.ZERO, Vector3(3, 1, 1))
	assert_true(DogFraming.distance(wide, FOV, 0.5625, 0.8)
			> DogFraming.distance(wide, FOV, 1.6, 0.8),
		"a narrower (portrait) viewport needs more distance to fit the same width")

func test_real_dog_distance_is_sane() -> void:
	var d := DogFraming.distance(DOG, FOV, PORTRAIT, 0.72)
	assert_true(d > DOG.size.z * 0.5 and d < 100.0,
		"the committed dog frames at a sane distance, got %.3f" % d)

func test_eye_sits_in_front_and_above_centre() -> void:
	var e := DogFraming.eye(DOG, FOV, PORTRAIT, 0.72)
	var c := DogFraming.target(DOG)
	assert_true(e.z > c.z, "camera is in front of the dog (+z)")
	assert_true(e.y > c.y, "camera is slightly above centre (gentle 3/4 view)")
	assert_true(_close(e.x, 0.0), "camera stays horizontally centred on the dog")
