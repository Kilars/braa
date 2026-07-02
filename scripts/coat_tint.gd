class_name CoatTint
extends RefCounted
## Per-breed coat recolor (076, P3-1/P3-2, BUST-074). The licensed Labrador is a SINGLE coat surface
## whose colour is ENTIRELY the baked albedo atlas (its glTF baseColorFactor is white [1,1,1,1]), so a
## second, breed-distinct dog is a runtime albedo_color MULTIPLY over that atlas — a genuine new breed
## (the chocolate Labrador) with NO new owner model, same rig + same Sitt/Ligg/Legg deg roster.
##
## Runs right AFTER CoatOpaque.flatten(): it targets the same coat surface (the albedo-TEXTURED body that
## CoatOpaque forced opaque) and tints only that. Textureless surfaces — a legit eye/glass albedo_color
## fade, which CoatOpaque also leaves alone — are untouched, so tinting never bleeds onto the eyes/nose
## geometry. Like CoatOpaque it works on a private duplicate assigned back as a surface override, so it
## NEVER mutates a shared/imported resource (tinting one dog instance can't bleed into another).
##
## The yellow Labrador passes the identity tint Color(1,1,1) — a harmless no-op multiply that leaves the
## PO-signed coat exactly as-is. A no-op too on the CC0 placeholder (no albedo-textured coat surface).

## Walk the dog subtree and tint every albedo-textured coat surface by `tint`. Returns the number of
## surfaces tinted (0 on a coatless/CC0 model). Call once at load, right after CoatOpaque.flatten().
static func apply(root: Node, tint: Color) -> int:
	var tinted := 0
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			if _tint_surface(mi, i, tint):
				tinted += 1
	for child in root.get_children():
		tinted += apply(child, tint)
	return tinted

## Tint one surface iff it's the coat: a StandardMaterial3D carrying an albedo texture (the baked coat
## atlas — the exact surface CoatOpaque targets). Duplicates the material (never mutates a shared
## resource), multiplies its albedo_color by the breed tint — keeping the atlas texture so fur detail /
## dark nose+pads survive the recolor — and assigns it back as the surface override. Returns true iff it
## tinted this surface.
static func _tint_surface(mi: MeshInstance3D, i: int, tint: Color) -> bool:
	var mat := mi.get_active_material(i)
	if not (mat is StandardMaterial3D):
		return false
	var sm := mat as StandardMaterial3D
	if sm.albedo_texture == null:
		return false  # no coat atlas → not the coat (a textureless eye/glass fade) → leave it
	var tinted := sm.duplicate() as StandardMaterial3D
	tinted.albedo_color = tint  # multiplies the atlas; keeps the texture so fur/nose detail survives
	mi.set_surface_override_material(i, tinted)
	return true
