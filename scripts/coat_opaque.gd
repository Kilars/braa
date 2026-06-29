class_name CoatOpaque
extends RefCounted
## Kills the translucent "ghost panels" on the dog's coat (032, PO 2026-06-28). The licensed
## Labrador is a SINGLE opaque-intended body surface (its glTF declares no alphaMode → OPAQUE),
## but its albedo atlas carries a baked FUR/HAIR-STRAND alpha mask — ≈18% sub-255 pixels,
## streaky hair cards over the chest and flanks. Sampled by the GL Compatibility (WebGL2)
## renderer that ships, that stray alpha renders as see-through panels (a vertical strip down
## the chest, curved arcs across both flanks) in every pose — breaking P1-1's clean silhouette
## and P1-9's "no bugs". A coat/fur-card alpha workflow that this opaque, single-mesh game
## doesn't use.
##
## The fix runs at load (model-agnostic, ships in the encrypted pck — no per-file .import tweak
## that wouldn't travel): every MeshInstance3D surface whose albedo texture carries an alpha
## channel is forced fully opaque — transparency DISABLED, backface CULL_BACK, and the texture's
## stray alpha STRIPPED to RGB. Stripping the DATA (not just flipping the transparency mode)
## makes it robust to whatever transparency state the export actually lands on, and to every
## renderer path that could punch a hole (blend, alpha-scissor, alpha-hash).
##
## Targeted, not blanket: only alpha-TEXTURED surfaces are touched. A deliberately-transparent
## surface with no alpha-mask texture (an albedo_color fade — a legit eye/glass) is left alone
## (criterion #6). A no-op on the CC0 placeholder, whose body is already clean opaque RGB.

## Walk the dog subtree and flatten every alpha-textured surface to opaque. Returns the number
## of surfaces fixed (0 on an already-clean model). Call once, right after the dog instantiates.
static func flatten(root: Node) -> int:
	var fixed := 0
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			if _flatten_surface(mi, i):
				fixed += 1
	for child in root.get_children():
		fixed += flatten(child)
	return fixed

## Flatten one surface if it's the fur-mask bug: a StandardMaterial3D whose albedo texture
## carries an alpha channel. Clones the material (never mutates a shared resource), forces it
## opaque + backface-culled, strips the texture alpha, and assigns it back as a surface
## override. Returns true iff it fixed this surface.
static func _flatten_surface(mi: MeshInstance3D, i: int) -> bool:
	var mat := mi.get_active_material(i)
	if not (mat is StandardMaterial3D):
		return false
	var sm := mat as StandardMaterial3D
	var tex := sm.albedo_texture
	if tex == null or not _has_alpha(tex):
		return false  # no alpha-mask texture → not the bug → leave it (incl. legit fades)
	var fixed := sm.duplicate() as StandardMaterial3D
	fixed.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	fixed.cull_mode = BaseMaterial3D.CULL_BACK
	var opaque_tex := _strip_alpha(tex)
	if opaque_tex != null:
		fixed.albedo_texture = opaque_tex  # keep the real coat texture, minus its stray alpha
	mi.set_surface_override_material(i, fixed)
	return true

## True when the texture's CPU image has any sub-opaque pixel (a stray fur-mask alpha).
static func _has_alpha(tex: Texture2D) -> bool:
	var img := tex.get_image()
	if img == null:
		return false
	if img.is_compressed():
		img = img.duplicate()
		img.decompress()
	return img.detect_alpha() != Image.ALPHA_NONE

## An opaque RGB copy of the texture — same colour, alpha channel dropped entirely so no
## renderer path can sample it. Returns null if the image can't be read (then the caller
## still has transparency DISABLED as the fallback lever).
static func _strip_alpha(tex: Texture2D) -> Texture2D:
	var img := tex.get_image()
	if img == null:
		return null
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGB8)  # drops the alpha channel; converts mipmap-free
	return ImageTexture.create_from_image(img)
