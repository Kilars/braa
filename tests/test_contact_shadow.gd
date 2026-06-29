extends "res://tests/test_case.gd"
## TDD for the dog's blob contact shadow (031, P1-1, 2026-06-29). The PO play-test found
## the dog FLOATS — in every pose the paws meet flat blue with nothing beneath, breaking
## the grounded read. The fix is a cheap soft blob on the ground under the feet, placed and
## sized off the SAME DogBounds AABB the camera frames from, so it's model-agnostic (CC0 +
## licensed Labrador) and needs no per-model tuning.
##
## Two layers of guard: the pure placement math (ContactShadow — no scene needed, runs in
## public CI without the gitignored licensed glb) and a scene-mount wiring test that the
## blob is actually mounted under the dog at the foot plane (so it can't silently vanish).
## The binding proof is still the 390×844 pixel-verify in the task's acceptance criteria.

func _close(a: float, b: float, eps := 0.01) -> bool:
	return absf(a - b) <= eps

# --- pure placement math (ContactShadow) ---

func test_blob_sits_at_the_foot_plane_under_the_footprint_centre() -> void:
	# A footprint offset from the origin: min Y is the foot plane, x/z centre is the stance.
	var box := AABB(Vector3(1.0, 0.2, 2.0), Vector3(0.6, 1.0, 0.4))  # centre (1.3, 0.7, 2.2)
	var p := ContactShadow.position(box)
	assert_true(_close(p.y, 0.2),
		"blob sits at the foot plane (AABB min Y = 0.2), got %.3f" % p.y)
	assert_true(_close(p.x, 1.3) and _close(p.z, 2.2),
		"blob is centred under the dog's footprint (1.3, 2.2), got (%.3f, %.3f)" % [p.x, p.z])

func test_radius_spans_the_larger_horizontal_footprint_half_extent() -> void:
	# A long-but-narrow stance: the radius follows the LARGER horizontal extent (x here)
	# so a long dog still gets a shadow that spans it, never a coaster under the chest.
	var box := AABB(Vector3.ZERO, Vector3(0.6, 1.0, 0.4))
	var expected := 0.6 * 0.5 * ContactShadow.FOOTPRINT_SCALE
	assert_true(_close(ContactShadow.radius(box), expected),
		"radius is the larger half-extent scaled (%.3f), got %.3f" % [expected, ContactShadow.radius(box)])

func test_radius_is_a_little_wider_than_the_bare_footprint() -> void:
	# The soft edge must fall off OUTSIDE the paws (a tight disc reads as a coaster), so the
	# disc is scaled past the bare footprint half-width.
	var box := AABB(Vector3.ZERO, Vector3(1.0, 1.0, 1.0))
	assert_true(ContactShadow.radius(box) > 0.5,
		"the blob is wider than the bare footprint half-width (0.5), got %.3f" % ContactShadow.radius(box))

# --- scene-mount wiring (the blob is actually under the dog) ---

func test_contact_shadow_is_mounted_under_the_dog_at_the_foot_plane() -> void:
	var main := instantiate_main()
	var blob := main.get_node_or_null("ContactShadow")
	assert_ne(blob, null, "a contact-shadow node must exist so the dog reads grounded (031)")
	if blob != null:
		assert_true(blob is MeshInstance3D,
			"the contact shadow is a flat mesh blob, got %s" % blob)
		var dog := main.get_node_or_null("Dog")
		assert_ne(dog, null, "the dog must be mounted to anchor the shadow to")
		if dog != null:
			var box := DogBounds.measure(dog)
			assert_true(_close((blob as Node3D).position.y, box.position.y),
				"blob sits at the dog's foot plane y=%.3f, got %.3f"
					% [box.position.y, (blob as Node3D).position.y])
			var c := box.get_center()
			assert_true(_close((blob as Node3D).position.x, c.x) and _close((blob as Node3D).position.z, c.z),
				"blob is centred under the dog's footprint (%.3f, %.3f), got (%.3f, %.3f)"
					% [c.x, c.z, (blob as Node3D).position.x, (blob as Node3D).position.z])
	main.free()
