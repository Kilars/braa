extends "res://tests/test_case.gd"
## Scene-level wiring for the apex tell (024d, P1-4). The envelope's honesty is
## unit-proven in test_apex_tell (peak at the apex, dark during idle); these tests
## prove the running scene actually mounts the marker, holds it DARK on the CC0 dog
## (no Sitt → no sit ever opens → the tell never fires during idle), and never lets
## the marker steal a tap from the BRA button it overlays. So a wiring regression —
## marker missing, glowing at rest, or blocking the button — can't read green.

func _find_marker(n: Node) -> ApexTellMarker:
	if n is ApexTellMarker:
		return n
	for c in n.get_children():
		var f := _find_marker(c)
		if f != null:
			return f
	return null

func test_scene_mounts_the_tell_marker() -> void:
	var main := instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "the scene must mount the apex-tell marker (P1-4)")
	main.queue_free()

func test_marker_never_eats_a_bra_tap() -> void:
	# It sits on top of the BRA button — it must pass touches straight through, or it
	# would silently break the one verb (P1-5).
	var main := instantiate_main()
	var marker := _find_marker(main)
	if marker != null:
		assert_eq(marker.mouse_filter, Control.MOUSE_FILTER_IGNORE,
			"the marker ignores mouse so the BRA button still receives taps")
	main.queue_free()

func test_tell_is_dark_during_idle_on_the_cc0_dog() -> void:
	# The acceptance criterion observable on the deployed CC0 dog: with no Sitt clip
	# no sit ever opens, so the tell must stay dark through idle frames — it only ever
	# lights up once 025/ADR-0006 ships the sit-capable dog and a real sit opens.
	var main := instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "marker present")
	if marker != null:
		assert_false(marker.is_showing(), "dark at rest right after _ready")
		# Drive a second of frames — the CC0 session never opens, so the tell holds dark.
		for i in 30:
			main._process(1.0 / 30.0)
		assert_false(marker.is_showing(), "still dark after idle frames (no sit to mark)")
		assert_true(is_equal_approx(marker.self_modulate.a, 0.0),
			"fully transparent while dormant")
	main.queue_free()

func test_marker_opacity_tracks_intensity() -> void:
	# The marker is a dumb renderer: its whole opacity follows the intensity ApexTell
	# feeds it, so 0 is genuinely invisible and 1.0 is the full pulse — asserted
	# without a framebuffer via self_modulate.a.
	var marker := ApexTellMarker.new()
	marker.set_intensity(1.0)
	assert_true(marker.is_showing(), "showing at full intensity")
	assert_true(is_equal_approx(marker.self_modulate.a, 1.0), "opaque at intensity 1")
	marker.set_intensity(0.0)
	assert_false(marker.is_showing(), "dark at intensity 0")
	assert_true(is_equal_approx(marker.self_modulate.a, 0.0), "transparent at intensity 0")
	marker.set_intensity(1.7)
	assert_true(is_equal_approx(marker.self_modulate.a, 1.0), "intensity is clamped to 1")
	marker.free()

func test_tell_stays_a_bold_saturated_cue() -> void:
	# 030 regression fence. The tell RENDERS — a forced-intensity web capture proved the
	# ring composites on top of the BRA button — but as first authored it was a thin
	# (4px), ~half-alpha, pale-CREAM ring (GLOW.s ≈ 0.45) that desaturated over the dark
	# button and was halved AGAIN under reduced motion (×0.35), so the #1 reopened PO
	# defect was "the apex tell never renders." Lock the cue's boldness so it can't
	# silently slip back to faint. The pixel capture is the binding proof; this is the
	# fence that keeps a refactor from re-breaking it.
	#
	# The crisp ring is the cue's spine: it must stay clearly visible even at the
	# reduced-motion floor (effective alpha = base × DAMPED), be a thick line at the
	# pinned 720-wide viewport, and be a genuinely saturated gold, not a wash-out cream.
	var floor_alpha := ApexTellMarker.RING_ALPHA * ReducedMotion.DAMPED
	assert_true(floor_alpha >= 0.3,
		"apex ring must read even under reduced-motion damping (effective alpha %.2f)" % floor_alpha)
	assert_true(ApexTellMarker.RING_WIDTH >= 8.0,
		"apex ring must be a bold line at the pinned viewport (got %.1f px)" % ApexTellMarker.RING_WIDTH)
	assert_true(ApexTellMarker.HALO_ALPHA >= 0.3,
		"halo bloom must be present, not a ghost (got %.2f)" % ApexTellMarker.HALO_ALPHA)
	assert_true(ApexTellMarker.GLOW.s >= 0.6,
		"glow must be a saturated gold, not pale cream (got s=%.2f)" % ApexTellMarker.GLOW.s)

func test_marker_has_a_drawable_non_zero_rect() -> void:
	# 030 suspect-3 fence. A Control parented to a CanvasLayer (not another Control) can fail
	# to lay out its anchors and collapse to a zero rect; then _draw() derives center/unit
	# from `size` and paints nothing — tests-green / pixels-blank, exactly the reopened PO
	# defect's shape. The marker's size is offset-defined (200×200, anchors equal so it's
	# viewport-independent), so after the real _ready wiring it must be a genuine drawable
	# rect. The pixel capture is the binding proof; this catches a layout collapse headless.
	var main := instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "marker present")
	if marker != null:
		assert_true(marker.size.x > 0.0 and marker.size.y > 0.0,
			"the tell marker must have a non-zero rect to draw into (got %s)" % str(marker.size))
	main.queue_free()

func test_force_tell_seam_pins_the_cue_on() -> void:
	# 030 deterministic-capture seam. The live apex peaks for only ~0.2s per sit cycle — too
	# brief for a non-deterministic screenshot burst to reliably catch — so the web build
	# honours a `?bra_force_tell=1` query that pins the tell to full intensity for a single
	# deterministic gold-ring screenshot (the binding visual proof). Guard the seam's effect:
	# with it set, the marker shows at full opacity every frame even though the CC0 session
	# never opens a sit. (The query read itself is web-only; this tests the _process branch.)
	var main := instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "marker present")
	if marker != null:
		assert_false(main._force_tell, "force-tell is off by default (production play untouched)")
		main._force_tell = true
		main._process(1.0 / 60.0)
		assert_true(marker.is_showing(), "forced tell shows even with no sit open")
		assert_true(is_equal_approx(marker.self_modulate.a, 1.0), "forced tell is at full intensity")
	main.queue_free()

func test_tell_marker_draws_on_top_of_the_bra_button() -> void:
	# 030 z-order guard. The marker must stay a LATER sibling than the BRA button on the UI
	# layer so it composites ON TOP of the button's opaque themed stylebox — a reorder would
	# paint the ring and then bury it. (The forced-intensity capture proves it currently does;
	# this keeps it that way.)
	var main := instantiate_main()
	var ui := main.get_node_or_null("UI")
	assert_true(ui != null, "the UI CanvasLayer is mounted")
	if ui != null:
		var button := ui.get_node_or_null("BraButton")
		var marker := _find_marker(ui)
		assert_true(button != null and marker != null,
			"both the BRA button and the tell marker mount on the UI layer")
		if button != null and marker != null:
			assert_true(marker.get_index() > button.get_index(),
				"the tell marker draws after (on top of) the BRA button")
	main.queue_free()
