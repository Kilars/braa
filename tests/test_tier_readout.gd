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

func test_readout_has_dark_outline_color() -> void:
	# The outline is a dark stroke so every tier pops against the bright Pokémon-GO sky
	# (P1-7). The color override is required for Godot to render the outline.
	var r := TierReadout.new()
	assert_true(r.has_theme_color_override("font_outline_color"),
		"TierReadout has a font_outline_color override")
	var outline_color := r.get_theme_color("font_outline_color")
	assert_eq(outline_color, TierReadout.OUTLINE_COLOR,
		"outline color equals TierReadout.OUTLINE_COLOR")
	r.free()

func test_readout_has_outline_size_at_least_8() -> void:
	# The outline size constant override is required (along with the color) for the
	# stroke to render. Size must be >= 8 px at font_size 88 to be legible.
	var r := TierReadout.new()
	var outline_size := r.get_theme_constant("outline_size")
	assert_true(outline_size >= 8,
		"outline_size is at least 8 (actual: %s)" % outline_size)
	r.free()

func test_emphasis_invariant_perfect_brightest() -> void:
	# The readout's emphasis (via brightness/value) must agree with the reward gate:
	# PERFECT brightest, OK in the middle, MISS dimmest. This locks the invariant
	# so a later contrast tweak can't silently break the emphasis-tracks-reward rule.
	var perfect_v := TierReadout.COLOR_PERFECT.v
	var ok_v := TierReadout.COLOR_OK.v
	var miss_v := TierReadout.COLOR_MISS.v
	assert_true(perfect_v >= ok_v,
		"COLOR_PERFECT.v (%.2f) >= COLOR_OK.v (%.2f)" % [perfect_v, ok_v])
	assert_true(ok_v >= miss_v,
		"COLOR_OK.v (%.2f) >= COLOR_MISS.v (%.2f)" % [ok_v, miss_v])
