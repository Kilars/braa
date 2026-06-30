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

## A dog whose pack has idle + a real Sitt (build + hold) so has_sit() is true. Fresh
## Animation.new() clips default to 1.0 s, so the apex (Sitting_start end) lands at 1.0 s
## and the OK ramp spans [0.8, 1.2]. In-tree so play() has a valid context.
func _sit_capable_ap() -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	for name in ["Idle", "Sitting_start", "Sitting_loop_1"]:
		lib.add_animation(name, Animation.new())
	ap.add_animation_library("", lib)
	(Engine.get_main_loop() as SceneTree).root.add_child(ap)
	return ap

func test_live_tell_lights_up_at_the_apex_on_a_sit_capable_dog() -> void:
	# The reopened P1-4 blocker (PO 2026-06-28 / 2026-06-29): the apex tell renders under
	# the ?bra_force_tell seam but was INVISIBLE in real play. The CC0-only wiring tests
	# above can't catch it — the placeholder never sits, so the live branch
	# (main.gd `_tell.intensity(_session.elapsed())`) is never exercised headless and a
	# live-path regression read as hollow green. This drives a REAL sit through _process
	# on a sit-capable dog and proves the marker actually pulses at the seated apex — the
	# headless guard for "the live tell renders," not just the forced seam.
	var main := instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "marker present")
	if marker == null:
		main.queue_free()
		return
	# Swap in a sit-capable director + a fresh loop so the production _process path runs a
	# real sit (the mounted CC0 dog is idle-only). The tell math is driven by the session
	# clock and clip lengths, both of which work headless even though the GPU/anim doesn't.
	main._director = DogDirector.new(_sit_capable_ap())
	main._director.play_idle()
	assert_true(main._director.has_sit(), "the injected dog can sit (live path is reachable)")
	assert_false(main._force_tell, "no capture seam — this is the genuine live path")
	# 048 made SitLoop's cadence VARIABLE and 35% of offers FEINTS (no markable window), so
	# relying on the random production loop to open a *real* sit inside the frame budget is flaky
	# (it sometimes only feints). Detach the loop and open the sit through the SAME production path
	# its START_SIT takes — _begin_sit opens the session + window and builds the tell — so the
	# genuine live branch (main.gd _process → _tell.intensity(_session.elapsed())) is still
	# exercised, deterministically, with only the RNG removed.
	main._loop = null
	var dt := 1.0 / 60.0
	# First, idle frames with NO sit open: the live tell must stay dark (P1-4 dormant-at-rest).
	var lit_during_idle := false
	for i in 30:
		main._process(dt)
		if marker.is_showing():
			lit_during_idle = true
	assert_false(lit_during_idle, "the tell stays dark whenever no sit is open (P1-4 dormant-at-rest)")
	# Now open a real sit and drive it: the marker must build to a clear peak at the seated apex.
	main._begin_sit()
	var max_i := 0.0
	var peak_elapsed := -1.0
	for i in 240:
		main._process(dt)
		if marker.intensity > max_i:
			max_i = marker.intensity
			peak_elapsed = main._session.elapsed()
	assert_true(max_i > 0.0,
		"the LIVE apex tell must light up during a real sit, not only under ?bra_force_tell (got max %.3f)" % max_i)
	assert_true(max_i >= 0.5,
		"the live tell must build to a clear peak at the apex, not a faint flicker (got %.3f)" % max_i)
	assert_true(absf(peak_elapsed - 1.0) <= 0.2,
		"the peak lands at the seated apex (~1.0 s into the sit), where a tap scores PERFECT (got %.3f s)" % peak_elapsed)
	main.queue_free()

func test_motion_scale_never_zeros_out_the_tell() -> void:
	# Regression for the live-play P1-4 blocker (PO 2026-06-29): on the Web export
	# ReducedMotion.query()'s bare-JS-boolean `JavaScriptBridge.eval` marshalled back as
	# null, so scale_for(null) collapsed to 0.0 and set_motion_scale(0.0) built EVERY apex
	# tell with damping 0 — a permanently invisible cue. Headless never caught it: off-web
	# query() short-circuits to false → scale 1.0. The contract is (0, 1] ("dampened, not
	# removed", P1-8) — a zero / negative / non-finite scale must NOT blank the cue. This
	# drives main.set_motion_scale directly so a future regression that lets the scale reach
	# 0 (the exact shape of this bug) reads red headless instead of only on the live site.
	var main := instantiate_main()
	main.set_motion_scale(0.0)
	assert_true(main.motion_scale() > 0.0,
		"a zero motion scale must not blank the apex tell — (0,1] contract (got %.3f)" % main.motion_scale())
	main.set_motion_scale(-1.0)
	assert_true(main.motion_scale() > 0.0, "a negative motion scale must not blank the cue")
	main.set_motion_scale(NAN)
	assert_true(main.motion_scale() > 0.0 and is_finite(main.motion_scale()),
		"a non-finite motion scale must not blank the cue")
	# Valid values still pass through untouched, so the fix doesn't break real damping.
	main.set_motion_scale(1.0)
	assert_true(is_equal_approx(main.motion_scale(), 1.0), "full motion passes through unchanged")
	main.set_motion_scale(ReducedMotion.DAMPED)
	assert_true(is_equal_approx(main.motion_scale(), ReducedMotion.DAMPED),
		"a real reduced-motion factor passes through unchanged (still pulses, just softer)")
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
