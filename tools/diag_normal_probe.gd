extends SceneTree
## 032 probe: report the licensed dog material's normal map + roughness/metallic so we can tell
## whether the "ghost panel" arcs are normal-mapped fur-tuft shading vs albedo/geometry.
const DOG := "res://assets/models/dog_licensed.glb"
func _initialize() -> void:
	var dog := (load(DOG) as PackedScene).instantiate()
	_walk(dog)
	quit(0)
func _walk(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			var m := mi.get_active_material(i) as StandardMaterial3D
			if m:
				print("normal_enabled=%s normal_scale=%.2f normal_tex=%s rough=%.2f metal=%.2f rough_tex=%s" % [
					m.normal_enabled, m.normal_scale, str(m.normal_texture != null),
					m.roughness, m.metallic, str(m.roughness_texture != null)])
	for c in n.get_children(): _walk(c)
