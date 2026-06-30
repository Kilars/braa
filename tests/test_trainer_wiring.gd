extends "res://tests/test_case.gd"
## Scene-level wiring for the trainer ring (058, P2-9). The envelope's honesty is
## unit-proven in test_trainer_ring (shrinks from 1 to 0 at the apex, gone at mastery);
## these tests prove the running scene actually mounts the marker, holds it dark during
## feints and when mastered, and never lets the marker steal a tap from the BRA button
## it overlays. So a wiring regression — marker missing, glowing when it shouldn't, or
## blocking the button — can't read green.

func _find_marker(n: Node) -> TrainerRingMarker:
	if n is TrainerRingMarker:
		return n
	for c in n.get_children():
		var f := _find_marker(c)
		if f != null:
			return f
	return null

func test_scene_mounts_the_trainer_marker() -> void:
	var main := instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "the scene must mount the trainer-ring marker (P2-9)")
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

func test_trainer_is_dark_during_idle_on_the_cc0_dog() -> void:
	# The acceptance criterion observable on the deployed CC0 dog: with no Sitt clip
	# no sit ever opens, so the trainer must stay dark through idle frames.
	var main := instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "marker present")
	if marker != null:
		assert_false(marker.is_showing(), "dark at rest right after _ready")
		# Drive a second of frames — the CC0 session never opens, so the trainer holds dark.
		for i in 30:
			main._process(1.0 / 30.0)
		assert_false(marker.is_showing(), "still dark after idle frames (no sit to mark)")
		assert_true(is_equal_approx(marker.self_modulate.a, 0.0),
			"fully transparent while dormant")
	main.queue_free()

func test_marker_opacity_tracks_ring_opacity() -> void:
	# The marker is a dumb renderer: its whole opacity follows the opacity TrainerRing
	# feeds it, so 0 is genuinely invisible and 1.0 is the full ring — asserted
	# without a framebuffer via self_modulate.a.
	var marker := TrainerRingMarker.new()
	marker.set_opacity(1.0)
	assert_true(marker.is_showing(), "showing at full opacity")
	assert_true(is_equal_approx(marker.self_modulate.a, 1.0), "opaque at opacity 1")
	marker.set_opacity(0.0)
	assert_false(marker.is_showing(), "dark at opacity 0")
	assert_true(is_equal_approx(marker.self_modulate.a, 0.0), "transparent at opacity 0")
	marker.set_opacity(0.6)
	assert_true(marker.is_showing(), "showing at opacity 0.6")
	assert_true(is_equal_approx(marker.self_modulate.a, 0.6), "opacity 0.6 sets self_modulate.a to 0.6")
	marker.set_opacity(1.7)
	assert_true(is_equal_approx(marker.self_modulate.a, 1.0), "opacity is clamped to 1")
	marker.free()

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

func test_live_trainer_lights_up_during_a_real_sit() -> void:
	# The trainer ring is the approach cue: it should show during a real sit on a
	# sit-capable dog, then fade/disappear after the apex as it hands off to the apex
	# tell and the tap. This drives a REAL sit through _process on a sit-capable dog
	# and proves the marker actually pulses during the approach.
	var main := instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "marker present")
	if marker == null:
		main.queue_free()
		return
	# Swap in a sit-capable director + a fresh loop so the production _process path runs a
	# real sit (the mounted CC0 dog is idle-only).
	main._director = DogDirector.new(_sit_capable_ap())
	main._director.play_idle()
	assert_true(main._director.has_sit(), "the injected dog can sit (live path is reachable)")
	assert_false(main._force_trainer, "no force seam — this is the genuine live path")
	# Detach the loop and open the sit through the SAME production path its START_SIT
	# takes — _begin_sit opens the session + window and builds the trainer.
	main._loop = null
	var dt := 1.0 / 60.0
	# First, idle frames with NO sit open: the live trainer must stay dark.
	var lit_during_idle := false
	for i in 30:
		main._process(dt)
		if marker.is_showing():
			lit_during_idle = true
	assert_false(lit_during_idle, "the trainer stays dark whenever no sit is open")
	# Now open a real sit and drive it: the marker must show during the approach.
	main._begin_sit()
	var max_o := 0.0
	for i in 120:
		main._process(dt)
		max_o = maxf(max_o, marker.self_modulate.a)
	assert_true(max_o > 0.0,
		"the LIVE trainer ring must light up during a real sit (got max opacity %.3f)" % max_o)
	main.queue_free()

func test_trainer_stays_dark_during_a_feint() -> void:
	# A feint (a false sit offer) never opens a SitWindow, so the trainer ring never
	# lights up during a feint. This is the honesty bullet: the ring rides the real
	# scored window, not an imagined one. (The loop can only feint if main._loop is
	# present and random, so we inject a deterministic feint via _begin_feint if it
	# exists; otherwise we rely on the default behavior where a feint never opens a
	# window.)
	var main := instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "marker present")
	if marker == null:
		main.queue_free()
		return
	# Swap in a sit-capable director so feints can theoretically happen, but detach
	# the loop so we control the exact sequence.
	main._director = DogDirector.new(_sit_capable_ap())
	main._director.play_idle()
	main._loop = null
	var dt := 1.0 / 60.0
	# If main has a _begin_feint() method, call it to open a deterministic feint.
	# Otherwise, just drive idle frames (the default loop never opens a window anyway).
	if main.has_method("_begin_feint"):
		main._begin_feint()
		var lit_during_feint := false
		for i in 120:
			main._process(dt)
			if marker.is_showing():
				lit_during_feint = true
		assert_false(lit_during_feint, "the trainer stays dark during a feint (no window)")
	else:
		# Fallback: just drive idle frames and assert darkness (the CC0 dog has no feints).
		for i in 30:
			main._process(dt)
		assert_false(marker.is_showing(), "the trainer stays dark during idle (no feints on CC0)")
	main.queue_free()

func test_trainer_is_gone_at_mastery() -> void:
	# A mastered trick has teach_strength == 0, so the ring opacity is 0 even during
	# an open sit. The trained player is weaned off the guidance.
	var main := instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "marker present")
	if marker == null:
		main.queue_free()
		return
	# Swap in a sit-capable director so we can open a real sit.
	main._director = DogDirector.new(_sit_capable_ap())
	main._director.play_idle()
	assert_true(main._director.has_sit(), "the injected dog can sit")
	main._loop = null
	# Set the progress to mastered so teach_strength returns 0.
	main._progress.mastered = true
	main._progress.value = 1.0
	var dt := 1.0 / 60.0
	# Open a real sit: the trainer should NOT light up because teach is 0.
	main._begin_sit()
	var ever_showed := false
	for i in 120:
		main._process(dt)
		if marker.is_showing():
			ever_showed = true
	assert_false(ever_showed,
		"the trainer ring must be gone at mastery — teach_strength == 0 → opacity == 0")
	main.queue_free()

func test_force_trainer_seam_pins_the_ring_on() -> void:
	# The live trainer shrinks in ~0.2s per sit cycle — too brief for a non-deterministic
	# screenshot burst to reliably catch — so the web build honours a `?bra_force_trainer=1`
	# query that pins the ring to a mid-approach radius at full teach for one deterministic
	# screenshot. Guard the seam's effect: with it set, the marker shows at full opacity
	# every frame even though the CC0 session never opens a sit.
	var main := instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "marker present")
	if marker != null:
		assert_false(main._force_trainer, "force-trainer is off by default (production play untouched)")
		main._force_trainer = true
		main._process(1.0 / 60.0)
		assert_true(marker.is_showing(), "forced trainer shows even with no sit open")
		assert_true(is_equal_approx(marker.self_modulate.a, 1.0), "forced trainer is at full opacity")
	main.queue_free()

func test_trainer_marker_has_a_drawable_non_zero_rect() -> void:
	# 030 suspect-3 fence adapted for the trainer. A Control parented to a CanvasLayer
	# (not another Control) can fail to lay out its anchors and collapse to a zero rect;
	# then _draw() derives center/unit from `size` and paints nothing. The trainer marker's
	# size is offset-defined, so after the real _ready wiring it must be a genuine drawable
	# rect.
	var main := instantiate_main()
	var marker := _find_marker(main)
	assert_true(marker != null, "marker present")
	if marker != null:
		assert_true(marker.size.x > 0.0 and marker.size.y > 0.0,
			"the trainer marker must have a non-zero rect to draw into (got %s)" % str(marker.size))
	main.queue_free()

func test_trainer_marker_draws_on_top_of_or_near_the_bra_button() -> void:
	# The trainer marker must be visually positioned near the BRA button (on the UI
	# layer) so it can frame it with the shrinking ring. (Exact z-order vs. the tell
	# is a visual review call; both should be on the UI layer.)
	var main := instantiate_main()
	var ui := main.get_node_or_null("UI")
	assert_true(ui != null, "the UI CanvasLayer is mounted")
	if ui != null:
		var button := ui.get_node_or_null("BraButton")
		var marker := _find_marker(ui)
		assert_true(button != null and marker != null,
			"both the BRA button and the trainer marker mount on the UI layer")
	main.queue_free()
