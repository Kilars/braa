extends "res://tests/test_case.gd"
## TDD for the kennel portrait render quality (160, PO father-pass-24, X-4/X-7).
## The PO found the grid cells + modal hero bust render dark speckle noise around every dog's
## muzzle — thin whisker geometry aliasing into dirt-like dots (some floating in the empty cell
## air past the snout) — because the shared portrait SubViewport rasterises at a low 384×340 with
## NO anti-aliasing (no msaa_3d), then upscales into the cell (~195px) and ~2× in the modal.
##
## The 3D render itself is Visual Review; the render-config constants are pure values and testable.
## These pin: (1) a real MSAA level is configured (anti-aliases the whisker geometry that specks),
## and (2) the render target is large enough not to be upscaled from 384 in the ~2× modal.

## Below MSAA_2X (i.e. MSAA_DISABLED) the thin whisker geometry aliases to the specks the PO saw.
func test_portrait_msaa_is_enabled() -> void:
	assert_true("PORTRAIT_MSAA" in KennelScreen,
		"KennelScreen exposes a PORTRAIT_MSAA render-quality constant")
	var msaa: int = KennelScreen.PORTRAIT_MSAA
	assert_true(msaa >= Viewport.MSAA_2X,
		"portrait MSAA (%d) is a real multisample level, not MSAA_DISABLED (%d)" % [msaa, Viewport.MSAA_DISABLED])

## The modal upscales the portrait ~2×; a 384-wide target was magnified there. Require the render
## target to be at least 512 wide so the modal is no longer upscaled from the old low resolution.
func test_portrait_render_target_is_high_res_enough_for_the_modal() -> void:
	var sz: Vector2i = KennelScreen.PORTRAIT_VP_SIZE
	assert_true(sz.x >= 512,
		"portrait render target width (%d) is high-res enough not to upscale in the ~2× modal (>= 512)" % sz.x)
	assert_true(sz.y >= 452,
		"portrait render target height (%d) scaled up in proportion (>= 452)" % sz.y)

## Raising the resolution must not warp the framing: the framing math derives its camera aspect
## from PORTRAIT_VP_SIZE, so the aspect must stay the same portrait-ish ratio as the tuned bake.
func test_portrait_aspect_ratio_is_preserved() -> void:
	var sz: Vector2i = KennelScreen.PORTRAIT_VP_SIZE
	var aspect := float(sz.x) / float(sz.y)
	## Old tuned aspect was 384/340 = 1.1294; keep it within a hair so framing (140/155) is unchanged.
	assert_true(absf(aspect - (384.0 / 340.0)) < 0.02,
		"portrait aspect (%.4f) stays the tuned ~1.129 so framing is unchanged" % aspect)
