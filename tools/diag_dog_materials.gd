extends SceneTree
## One-shot diagnostic (task 032): load the licensed dog and log, per MeshInstance3D
## surface, the resolved material's transparency + cull_mode + albedo alpha AND its
## next_pass chain (a coat/fur shell is usually a next_pass overlay), so we can name the
## exact translucent "shell" surfaces the PO saw before forcing anything opaque.
## Run: godot --headless --script res://tools/diag_dog_materials.gd

const DOG := "res://assets/models/dog_licensed.glb"

func _initialize() -> void:
	if not ResourceLoader.exists(DOG):
		print("[diag] licensed dog not present: %s" % DOG)
		quit(0)
		return
	var packed := load(DOG) as PackedScene
	var dog := packed.instantiate()
	print("\n── dog material diagnostic ─────────────────")
	_walk(dog, "")
	print("────────────────────────────────────────────\n")
	quit(0)

func _walk(n: Node, indent: String) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var mesh := mi.mesh
		var surf_count := 0 if mesh == null else mesh.get_surface_count()
		print("%sMeshInstance3D '%s' — %d surface(s), override_count=%d" % [
			indent, n.name, surf_count, mi.get_surface_override_material_count()])
		for i in surf_count:
			print("%s  [surf %d] active:" % [indent, i])
			_describe(mi.get_active_material(i), indent + "    ", 0)
	for child in n.get_children():
		_walk(child, indent + "  ")

func _describe(mat: Material, indent: String, depth: int) -> void:
	if mat == null:
		print("%s<null material>" % indent)
		return
	if mat is StandardMaterial3D:
		var sm := mat as StandardMaterial3D
		var a := sm.albedo_color
		var tex := sm.albedo_texture
		var has_alpha_tex := false
		if tex != null:
			var img := tex.get_image()
			has_alpha_tex = img != null and img.detect_alpha() != Image.ALPHA_NONE
		print("%spass%d Standard '%s'" % [indent, depth, sm.resource_name])
		print("%s  transparency=%d cull=%d blend=%d alpha=%.3f alpha_scissor=%.3f" % [
			indent, sm.transparency, sm.cull_mode, sm.blend_mode, a.a, sm.alpha_scissor_threshold])
		print("%s  albedo_tex=%s tex_has_alpha=%s grow=%s shaded=%s" % [
			indent, "yes" if tex != null else "no", str(has_alpha_tex),
			str(sm.grow), str(not sm.flags_unshaded if "flags_unshaded" in sm else "n/a")])
	else:
		print("%spass%d %s '%s'" % [indent, depth, mat.get_class(), mat.resource_name])
	if mat.next_pass != null:
		print("%s  next_pass ->" % indent)
		_describe(mat.next_pass, indent + "    ", depth + 1)
