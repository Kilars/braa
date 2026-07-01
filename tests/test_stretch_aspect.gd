extends "res://tests/test_case.gd"
## Regression guard for the garden letterbox (063, PO 2026-07-01). The project targets
## mobile portrait only (X-1), and every modern phone is TALLER than the 720×1280 (9:16 =
## 0.5625) design viewport — iPhone X+ ≈ 0.462, most Android ≈ 0.46. With
## `window/stretch/aspect="keep"` those devices get pure-black letterbox bands top and
## bottom (~16 % of a 390×844 screen), so the look-down garden ("a world to play in", P2-10)
## fails to fill the phone. A non-letterboxing mode — "expand" (match the window aspect) or
## "keep_width" (lock the 720 width, extend height) — makes the sky/grass reach every edge.
## The 3D fills safely (infinite ProceduralSky + grass over the sky's ground half) and the
## anchor-based UI re-anchors to the taller frame. This pins the setting so a flip back to a
## letterboxing mode fails the gate instead of shipping black bars again.

const NON_LETTERBOX := ["expand", "keep_width"]

func test_stretch_mode_is_canvas_items() -> void:
	# canvas_items keeps the 2D UI crisp at the base resolution while the world scales.
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items",
		"portrait UI expects canvas_items stretch")

func test_aspect_does_not_letterbox_tall_phones() -> void:
	var aspect: String = ProjectSettings.get_setting("display/window/stretch/aspect")
	assert_true(NON_LETTERBOX.has(aspect),
		"aspect=%s letterboxes phones taller than 9:16 (P2-10/X-1); use expand or keep_width" % aspect)
