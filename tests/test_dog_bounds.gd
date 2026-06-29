extends "res://tests/test_case.gd"
## TDD for DogBounds (024c framing regression, 2026-06-28). The camera frames the dog
## off this measured AABB. The CC0 dog's mesh get_aabb() happens to match its rig, so
## the old mesh-AABB measure framed it fine — but the licensed Labrador's skinned mesh
## get_aabb() is authored in a DIFFERENT frame than its skeleton: measured headless it
## reports a box centred ~0.07 BELOW the floor (y down to -0.638), so the camera aimed
## under the dog and the dog rendered too high with its head cut off (P1-1/P1-2 fail).
##
## The fix: measure the skeleton's REST-POSE BONE SPAN — the true posed extent, feet at
## the floor — which is correct for both rigs (CC0 bones y:[0,1.84], licensed y:[0,0.67]).
## Model-agnostic, no per-model tuning. These tests build synthetic rigs so they run in
## CI without the gitignored licensed glb, and pin the exact regression.

func _close(a: float, b: float, eps := 0.01) -> bool:
	return absf(a - b) <= eps

# A skinned dog whose mesh AABB is deliberately misplaced (centred below the floor,
# like the licensed Labrador), but whose bones stand on the floor. measure() must follow
# the BONES, not the mesh box.
func _skinned_dog() -> Node3D:
	var dog := Node3D.new()
	var skel := Skeleton3D.new()
	dog.add_child(skel)
	skel.add_bone("foot")  # bone 0 at the floor
	skel.add_bone("head")  # bone 1 up at y=0.7
	skel.set_bone_rest(0, Transform3D(Basis(), Vector3(0.0, 0.0, 0.0)))
	skel.set_bone_rest(1, Transform3D(Basis(), Vector3(0.0, 0.7, 0.0)))
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 1.2, 0.3)  # AABB y:[-0.6, 0.6] in mesh space
	mesh.mesh = box
	mesh.position = Vector3(0.0, -0.05, 0.0)  # shove it below the floor: y:[-0.65, 0.55]
	skel.add_child(mesh)
	return dog

func test_skinned_dog_is_measured_from_its_bones_not_the_mesh_box() -> void:
	var dog := _skinned_dog()
	var box := DogBounds.measure(dog)
	# Feet on the floor, not sunk below it (the licensed bug put position.y at -0.638).
	assert_true(box.position.y >= -0.01,
		"a skinned dog's feet must sit at/above the floor, got position.y=%.3f" % box.position.y)
	# Height + centre come from the bone span (0..0.7), not the mesh box (centre -0.05).
	assert_true(_close(box.size.y, 0.7),
		"height is the bone span (0.7), not the mesh box (1.2), got %.3f" % box.size.y)
	assert_true(_close(box.get_center().y, 0.35),
		"centre is the bone-span middle (0.35), not the sunk mesh centre (-0.05), got %.3f"
			% box.get_center().y)
	dog.free()

# No skeleton → fall back to the mesh-AABB accumulation (the pre-existing behaviour, for
# any non-skinned model). A plain box at the origin must measure as itself.
func _static_dog() -> Node3D:
	var dog := Node3D.new()
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 2.0, 1.0)
	mesh.mesh = box
	dog.add_child(mesh)
	return dog

func test_static_dog_falls_back_to_mesh_aabb() -> void:
	var dog := _static_dog()
	var box := DogBounds.measure(dog)
	assert_true(_close(box.size.y, 2.0), "static mesh height measured from its AABB, got %.3f" % box.size.y)
	assert_true(_close(box.get_center().y, 0.0) and _close(box.get_center().x, 0.0),
		"static mesh centres at the origin, got %s" % box.get_center())
	dog.free()
