class_name DogBounds
extends RefCounted
## Model-agnostic measurement of a loaded dog's extent, in dog-local space, for the
## camera framing (DogFraming). Pure + unit-tested, no scene needed (024c framing fix).
##
## Why not just the mesh AABB? A skinned glTF dog's MeshInstance3D.get_aabb() is the raw
## mesh in the mesh's OWN authoring frame, which need not line up with the skeleton. The
## CC0 dog happens to match (mesh box ≈ bone span), so framing it off the mesh AABB read
## fine. The licensed Labrador does NOT: its mesh box is centred ~0.07 below the floor
## (measured y down to -0.638), so framing aimed under the dog and the dog rendered too
## high, head cut off (the 024c regression). The rig is the honest source of where the
## posed dog actually stands, so we measure the REST-POSE BONE SPAN when a skeleton is
## present (CC0 bones y:[0,1.84]; licensed y:[0,0.67] — feet on the floor for both), and
## fall back to the mesh-AABB accumulation only for a non-skinned model.

## The dog's bounds in dog-local space. Prefers the skeleton rest-pose bone span (correct
## for skinned rigs); falls back to the merged mesh AABBs when there's no skeleton.
static func measure(dog: Node) -> AABB:
	var skel := _skeleton(dog)
	if skel != null and skel.get_bone_count() > 0:
		return _bone_rest_span(skel, _local_xform(skel, dog))
	return _mesh_aabb(dog)

## Rest-pose bone joint positions, mapped into dog-local space — the standing extent.
static func _bone_rest_span(skel: Skeleton3D, to_dog: Transform3D) -> AABB:
	var have := false
	var box := AABB()
	for i in skel.get_bone_count():
		var p: Vector3 = (to_dog * skel.get_bone_global_rest(i)).origin
		if not have:
			box = AABB(p, Vector3.ZERO)
			have = true
		else:
			box = box.expand(p)
	return box

## Merge every VisualInstance3D's mesh AABB, each carried into dog-local space.
static func _mesh_aabb(dog: Node) -> AABB:
	var have := false
	var box := AABB()
	for vi in _visual_instances(dog):
		var ab: AABB = _local_xform(vi, dog) * vi.get_aabb()
		if not have:
			box = ab
			have = true
		else:
			box = box.merge(ab)
	return box

## Accumulate node-LOCAL transforms from `node` up to (and including) the dog root, but
## not its parent. Local — not global_transform — because a skinned glTF's global
## transforms only propagate after the first frame; locals carry the real placement
## synchronously at _ready, so framing is correct on the very first rendered frame.
static func _local_xform(node: Node, dog: Node) -> Transform3D:
	var x := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != dog.get_parent():
		if n is Node3D:
			x = (n as Node3D).transform * x
		n = n.get_parent()
	return x

static func _skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var f := _skeleton(c)
		if f != null:
			return f
	return null

static func _visual_instances(n: Node) -> Array:
	var out := []
	if n is VisualInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_visual_instances(c))
	return out
