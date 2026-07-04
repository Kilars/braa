extends "res://tests/test_case.gd"
## The juicy marker-word burst (P5-3), task 094. WordPop is a dumb renderer that shows
## the effective fired marker word ("Dyktig!" / "Bra!" / "Super!" / "Kjempebra!"), floats
## it up from the BRA button, and fades it out. It mirrors TierReadout's split: main
## decides WHAT word fired, this node just shows it, floats it, and fades. The fade is
## stepped by main each frame via advance(delta), so it's fully deterministic and
## render-free to test — visibility, opacity, and rise offset are read off pure
## predicates (text, self_modulate.a, rise_offset()), no framebuffer needed.

func test_pop_shows_the_word() -> void:
	## After pop("Dyktig!"), the word is shown at full opacity and is visible.
	var w := WordPop.new()
	w.pop("Dyktig!")
	assert_eq(w.text, "Dyktig!", "pop() sets the label text to the word")
	assert_true(w.is_visible_now(), "the word is visible immediately after pop")
	assert_true(is_equal_approx(w.self_modulate.a, 1.0), "alpha is full opacity (1.0)")
	w.free()

func test_pop_empty_clears() -> void:
	## pop("") is a defensive clear — the word is blanked and the pop becomes invisible.
	var w := WordPop.new()
	w.pop("Bra!")
	assert_true(w.is_visible_now(), "word is visible before clear")
	w.pop("")
	assert_false(w.is_visible_now(), "pop(\"\") hides the word (not visible)")
	assert_true(is_equal_approx(w.self_modulate.a, 0.0), "alpha is fully transparent (0.0)")
	w.free()

func test_pop_holds_before_fading() -> void:
	## During the initial HOLD period, the word stays fully opaque — not fading yet.
	var w := WordPop.new()
	w.pop("Super!")
	w.advance(0.05)  # well within the HOLD period
	assert_true(is_equal_approx(w.self_modulate.a, 1.0),
		"still fully opaque during the initial hold (not fading yet)")
	w.free()

func test_pop_fades_fully_out() -> void:
	## After advancing past HOLD + FADE, the word fades fully out and becomes invisible.
	var w := WordPop.new()
	w.pop("Super!")
	assert_true(w.is_visible_now(), "visible right after pop")
	# Step past HOLD + FADE (advance 60 frames at 1/30 fps = 2.0s >> HOLD + FADE).
	for i in 60:
		w.advance(1.0 / 30.0)
	assert_false(w.is_visible_now(), "fully faded out and invisible (never stale)")
	assert_true(is_equal_approx(w.self_modulate.a, 0.0), "alpha is fully transparent (0.0)")
	w.free()

func test_rise_offset_starts_at_zero_and_floats_up() -> void:
	## At age 0, rise_offset() is 0; as time advances, it becomes negative (floats up).
	var w := WordPop.new()
	w.pop("Bra!")
	assert_true(is_equal_approx(w.rise_offset(), 0.0),
		"rise_offset() is 0.0 immediately after pop (age 0)")
	# Advance a few frames.
	for i in 10:
		w.advance(1.0 / 30.0)
	var offset_after := w.rise_offset()
	assert_true(offset_after < 0.0, "rise_offset() becomes negative (floats UP)")
	assert_true(offset_after < -1.0,  # at least some magnitude by frame 10
		"rise_offset() magnitude is significant (at least >1.0px)")
	w.free()

func test_reduced_motion_dampens_float_but_keeps_the_word() -> void:
	## Under reduced motion, the rise_offset() magnitude is STRICTLY between 0 and the
	## full-motion magnitude (X-5: dampen but never remove). The word text/opacity are
	## unaffected by motion scale.
	var w_full := WordPop.new()
	var w_damped := WordPop.new()

	# Full motion (default).
	w_full.pop("Dyktig!")

	# Damped motion.
	w_damped.pop("Dyktig!")
	w_damped.set_motion_scale(ReducedMotion.DAMPED)

	# Advance both by the same delta.
	var delta := 1.0 / 30.0
	for i in 10:
		w_full.advance(delta)
		w_damped.advance(delta)

	# At the same age, compare rise_offset() magnitudes.
	var offset_full := w_full.rise_offset()
	var offset_damped := w_damped.rise_offset()

	# Both should be negative (upward).
	assert_true(offset_full < 0.0, "full motion rise is negative (upward)")
	assert_true(offset_damped < 0.0, "damped motion rise is negative (upward)")

	# Damped magnitude is strictly between 0 and full magnitude.
	var mag_full := -offset_full
	var mag_damped := -offset_damped
	assert_true(mag_damped > 0.0, "damped magnitude is > 0 (never removed)")
	assert_true(mag_damped < mag_full,
		"damped magnitude (%.2f) < full magnitude (%.2f) — dampened" % [mag_damped, mag_full])

	# Word text and opacity are unaffected by motion scale.
	assert_eq(w_full.text, w_damped.text, "word text is identical under both motion scales")
	assert_true(is_equal_approx(w_full.self_modulate.a, w_damped.self_modulate.a),
		"alpha is identical under both motion scales (motion scale does NOT affect word visibility)")

	w_full.free()
	w_damped.free()

func test_set_motion_scale_guards_bad_input() -> void:
	## set_motion_scale() guards non-finite and ≤0 inputs back to 1.0 (full motion),
	## matching the web-marshal guard in ReducedMotion.scale_for().

	# Build a reference WordPop at full motion (1.0).
	var w_ref := WordPop.new()
	w_ref.pop("Bra!")
	for i in 10:
		w_ref.advance(1.0 / 30.0)
	var ref_offset := w_ref.rise_offset()

	# Test zero input — should be guarded back to 1.0.
	var w_zero := WordPop.new()
	w_zero.pop("Bra!")
	w_zero.set_motion_scale(0.0)
	for i in 10:
		w_zero.advance(1.0 / 30.0)
	var offset_zero := w_zero.rise_offset()
	assert_true(is_equal_approx(offset_zero, ref_offset),
		"set_motion_scale(0.0) is guarded back to 1.0 (full motion)")

	# Test negative input — should be guarded back to 1.0.
	var w_neg := WordPop.new()
	w_neg.pop("Bra!")
	w_neg.set_motion_scale(-1.0)
	for i in 10:
		w_neg.advance(1.0 / 30.0)
	var offset_neg := w_neg.rise_offset()
	assert_true(is_equal_approx(offset_neg, ref_offset),
		"set_motion_scale(-1.0) is guarded back to 1.0 (full motion)")

	# Test INF input — should be guarded back to 1.0.
	var w_inf := WordPop.new()
	w_inf.pop("Bra!")
	w_inf.set_motion_scale(INF)
	for i in 10:
		w_inf.advance(1.0 / 30.0)
	var offset_inf := w_inf.rise_offset()
	assert_true(is_equal_approx(offset_inf, ref_offset),
		"set_motion_scale(INF) is guarded back to 1.0 (full motion)")

	w_ref.free()
	w_zero.free()
	w_neg.free()
	w_inf.free()
