extends "res://tests/test_case.gd"
## The honest timing readout (specs2.md P1-7), task 024g. TierReadout is the dumb
## on-screen label: given the scored Tier it shows PERFECT / OK / MISS immediately,
## and a DEAD tap (no sit) shows NOTHING — so the readout never contradicts the audio
## (which is also silent on MISS/DEAD) and a dead tap stays "does nothing" (P1-5).
## The mapping and the fade are pure/deterministic here; scene wiring is in
## test_readout_wiring. No framebuffer needed — visibility is read off the label text
## and self_modulate.a, the same render-free trick the tell marker uses.

func test_text_names_the_scored_tier() -> void:
	assert_eq(TierReadout.text_for(SitWindow.Tier.PERFECT), "PERFECT", "PERFECT label")
	assert_eq(TierReadout.text_for(SitWindow.Tier.OK), "OK", "OK label")
	assert_eq(TierReadout.text_for(SitWindow.Tier.MISS), "MISS", "MISS label")

func test_a_dead_tap_shows_no_text() -> void:
	# A DEAD tap (no sit open) does nothing in Phase 1 — no penalty, no readout. Empty
	# string so the label renders blank and stays consistent with the silent audio.
	assert_eq(TierReadout.text_for(SitWindow.Tier.DEAD), "",
		"a DEAD tap shows nothing on screen (P1-5 — does nothing)")

func test_perfect_reads_brighter_than_ok() -> void:
	# Mirrors the payoff gate (PERFECT brighter than OK) so the readout's emphasis
	# agrees with the reward — a PERFECT should feel more triumphant than an OK.
	var perfect := TierReadout.color_for(SitWindow.Tier.PERFECT)
	var ok := TierReadout.color_for(SitWindow.Tier.OK)
	assert_true(perfect.v >= ok.v, "PERFECT is at least as bright as OK")
	assert_ne(perfect, ok, "PERFECT and OK are visually distinct colours")

func test_display_shows_the_tier_then_clears_on_dead() -> void:
	var r := TierReadout.new()
	r.display(SitWindow.Tier.PERFECT)
	assert_eq(r.text, "PERFECT", "displaying PERFECT sets the label text")
	assert_true(r.is_visible_now(), "a scored tier is visible immediately (P1-7)")
	r.display(SitWindow.Tier.DEAD)
	assert_false(r.is_visible_now(), "a DEAD tap clears the readout (shows nothing)")
	r.free()

func test_readout_fades_out_so_it_never_goes_stale() -> void:
	# Immediate on the tap, but it must not linger forever — drive enough frames and the
	# readout fades fully out, so the next sit starts with a clean slate (no stale tier).
	var r := TierReadout.new()
	r.display(SitWindow.Tier.OK)
	assert_true(r.is_visible_now(), "visible right after the tap")
	# Step past hold + fade.
	for i in 60:
		r.advance(1.0 / 30.0)  # 2.0s — comfortably beyond HOLD + FADE
	assert_false(r.is_visible_now(), "the readout fades fully out (never stale)")
	assert_true(is_equal_approx(r.self_modulate.a, 0.0), "fully transparent once faded")
	r.free()

func test_readout_holds_before_it_starts_fading() -> void:
	# It should be fully opaque for a brief hold right after the tap (readable), not
	# start vanishing on frame one — assert it's still full alpha a few frames in.
	var r := TierReadout.new()
	r.display(SitWindow.Tier.MISS)
	r.advance(0.05)
	assert_true(is_equal_approx(r.self_modulate.a, 1.0),
		"still fully opaque during the initial hold")
	r.free()
