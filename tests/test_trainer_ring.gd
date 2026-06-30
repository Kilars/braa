extends "res://tests/test_case.gd"
## Unit tests for the trainer ring envelope (specs2.md P2-9), task 058.
##
## The trainer ring is the approach-cue that shrinks onto the BRA button and lands
## exactly at the apex, fading as the learned bar fills and gone at mastery. TrainerRing
## is the pure envelope (radius scale and opacity in [0,1] over seconds-into-the-sit);
## the visual marker just renders whatever these return. Keeping it pure is what makes
## "shrinks exactly onto the button" and "gone at mastery" test-first, not eyeballed.

# A representative trainer ring over the same shape test_sit_window and test_apex_tell use:
# markable [0,2]s, apex (fully seated) at 1.2s, window half-width 0.30s (the OK window).
func _trainer(teach: float = 1.0) -> TrainerRing:
	var w := SitWindow.from_sit_clips(1.2, 0.80, 0.08, 0.20)
	return TrainerRing.from_window(w, teach)

func test_teach_strength_is_1_at_brand_new_trick() -> void:
	# The fade law: at a brand-new trick (value == 0), the teach strength is full (1.0).
	# The player gets the boldest cue on their first attempt.
	var strength := TrainerRing.teach_strength(0.0, false)
	assert_true(is_equal_approx(strength, 1.0), "teach_strength(0, false) == 1.0 at brand-new")

func test_teach_strength_is_0_at_mastery() -> void:
	# At mastery the cue is gone (teach strength 0). The experienced player is weaned
	# off the guidance.
	var strength := TrainerRing.teach_strength(0.5, true)
	assert_true(is_equal_approx(strength, 0.0), "teach_strength(any, mastered=true) == 0 at mastery")

func test_teach_strength_decreases_monotonically_as_bar_fills() -> void:
	# The cue fades smoothly as the bar fills — each step toward mastery is dimmer
	# than the last.
	var s0 := TrainerRing.teach_strength(0.0, false)
	var s2 := TrainerRing.teach_strength(0.2, false)
	var s5 := TrainerRing.teach_strength(0.5, false)
	var s8 := TrainerRing.teach_strength(0.8, false)
	assert_true(s0 > s2, "teach_strength decreases: 0.0 > 0.2")
	assert_true(s2 > s5, "teach_strength decreases: 0.2 > 0.5")
	assert_true(s5 > s8, "teach_strength decreases: 0.5 > 0.8")

func test_teach_strength_reaches_0_at_full_bar() -> void:
	# When the bar is full (value == 1.0) and not yet latched mastered, the strength
	# is already 0 (ready to latch on next apply).
	var strength := TrainerRing.teach_strength(1.0, false)
	assert_true(is_equal_approx(strength, 0.0), "teach_strength(1.0, false) == 0")

func test_radius_scale_is_1_at_sit_start() -> void:
	# The ring starts fully expanded (far out) at the start of the sit.
	var t := _trainer()
	var r := t.radius_scale(t.sit_start)
	assert_true(is_equal_approx(r, 1.0), "radius_scale at sit_start == 1.0 (fully expanded)")

func test_radius_scale_is_0_at_apex() -> void:
	# The ring has landed on the button at the apex (radius 0).
	var t := _trainer()
	var r := t.radius_scale(t.apex)
	assert_true(is_equal_approx(r, 0.0), "radius_scale at apex == 0.0 (landed on button)")

func test_radius_scale_decreases_monotonically_from_sit_start_to_apex() -> void:
	# The ring shrinks continuously and never grows — each step into the approach
	# is smaller than the last, so the eye sees a smooth contraction.
	var t := _trainer()
	var r_start := t.radius_scale(t.sit_start)
	var r_early := t.radius_scale(t.sit_start + 0.1)
	var r_mid := t.radius_scale(t.sit_start + 0.5)
	var r_late := t.radius_scale(t.apex - 0.1)
	var r_apex := t.radius_scale(t.apex)
	assert_true(r_start > r_early, "shrinks: sit_start > early")
	assert_true(r_early > r_mid, "shrinks: early > mid")
	assert_true(r_mid > r_late, "shrinks: mid > late")
	assert_true(r_late > r_apex, "shrinks: late > apex")

func test_radius_scale_is_0_before_sit_start() -> void:
	# Before the sit opens, the ring does not exist (radius 0).
	var t := _trainer()
	var r := t.radius_scale(t.sit_start - 0.5)
	assert_true(is_equal_approx(r, 0.0), "radius_scale before sit_start == 0")

func test_radius_scale_is_0_after_apex() -> void:
	# After the ring lands at the apex, it has handed off to the apex tell / the
	# tap. The ring radius is 0.
	var t := _trainer()
	var r := t.radius_scale(t.apex + 0.5)
	assert_true(is_equal_approx(r, 0.0), "radius_scale after apex == 0")

func test_radius_scale_is_0_during_idle() -> void:
	# Well before or after the sit, the ring does not exist.
	var t := _trainer()
	var r_idle_before := t.radius_scale(-10.0)
	var r_idle_after := t.radius_scale(100.0)
	assert_true(is_equal_approx(r_idle_before, 0.0), "radius_scale far before == 0")
	assert_true(is_equal_approx(r_idle_after, 0.0), "radius_scale far after == 0")

func test_opacity_is_0_outside_the_approach_span() -> void:
	# The ring is dark during idle, before the sit opens and after it lands.
	var t := _trainer()
	var o_before := t.opacity(t.sit_start - 0.5)
	var o_after := t.opacity(t.apex + 0.5)
	assert_true(is_equal_approx(o_before, 0.0), "opacity before sit_start == 0")
	assert_true(is_equal_approx(o_after, 0.0), "opacity after apex == 0")

func test_opacity_equals_teach_inside_the_approach_span() -> void:
	# Inside the active sit, the ring's opacity is the teach strength (unless teach is 0).
	var teach := 0.7
	var t := _trainer(teach)
	var o_early := t.opacity(t.sit_start + 0.2)
	var o_mid := t.opacity(t.sit_start + 0.5)
	assert_true(is_equal_approx(o_early, teach), "opacity inside span == teach (early)")
	assert_true(is_equal_approx(o_mid, teach), "opacity inside span == teach (mid)")

func test_opacity_is_0_when_teach_is_0_even_inside_the_span() -> void:
	# At mastery (teach == 0), the ring is gone even during the approach — mastered
	# tricks don't show the training cue.
	var t := _trainer(0.0)
	var o_early := t.opacity(t.sit_start + 0.2)
	var o_mid := t.opacity(t.sit_start + 0.5)
	var o_late := t.opacity(t.apex - 0.1)
	assert_true(is_equal_approx(o_early, 0.0), "opacity == 0 at mastery (early)")
	assert_true(is_equal_approx(o_mid, 0.0), "opacity == 0 at mastery (mid)")
	assert_true(is_equal_approx(o_late, 0.0), "opacity == 0 at mastery (late)")

func test_opacity_varies_with_teach_inside_the_span() -> void:
	# Different teach strengths produce different opacities — the fade law is observable.
	var t_brand_new := _trainer(1.0)
	var t_half := _trainer(0.5)
	var t_faint := _trainer(0.1)
	var o_brand_new := t_brand_new.opacity(t_brand_new.sit_start + 0.2)
	var o_half := t_half.opacity(t_half.sit_start + 0.2)
	var o_faint := t_faint.opacity(t_faint.sit_start + 0.2)
	assert_true(o_brand_new > o_half, "brand-new teach (1.0) is brighter than half (0.5)")
	assert_true(o_half > o_faint, "half teach (0.5) is brighter than faint (0.1)")
	assert_true(is_equal_approx(o_brand_new, 1.0), "brand-new opacity == 1.0")
	assert_true(is_equal_approx(o_half, 0.5), "half opacity == 0.5")
	assert_true(is_equal_approx(o_faint, 0.1), "faint opacity == 0.1")

func test_from_window_ties_sit_start_to_the_window() -> void:
	# Single source of truth: the ring's sit_start is the window's sit_start — it opens
	# exactly when the sit becomes scorable.
	var w := SitWindow.from_sit_clips(1.2, 0.80, 0.08, 0.20)
	var t := TrainerRing.from_window(w, 1.0)
	assert_true(is_equal_approx(t.sit_start, w.sit_start),
		"from_window: trainer.sit_start == window.sit_start")

func test_from_window_ties_apex_to_the_window() -> void:
	# Single source of truth: the ring's apex is the window's apex — the ring lands
	# exactly when a tap scores PERFECT.
	var w := SitWindow.from_sit_clips(1.2, 0.80, 0.08, 0.20)
	var t := TrainerRing.from_window(w, 1.0)
	assert_true(is_equal_approx(t.apex, w.apex),
		"from_window: trainer.apex == window.apex")

func test_from_window_preserves_teach() -> void:
	# The teach strength passed in is stored and used for opacity.
	var w := SitWindow.from_sit_clips(1.2, 0.80, 0.08, 0.20)
	var teach := 0.6
	var t := TrainerRing.from_window(w, teach)
	var o := t.opacity(w.sit_start + 0.2)
	assert_true(is_equal_approx(o, teach), "from_window preserves teach for opacity")

func test_radius_scale_matches_window_keyframes() -> void:
	# The ring built from a SitWindow has its radius keyed exactly to that window's
	# sit_start and apex — it can't drift.
	var w := SitWindow.from_sit_clips(1.5, 0.90, 0.10, 0.20)
	var t := TrainerRing.from_window(w, 1.0)
	assert_true(is_equal_approx(t.radius_scale(w.sit_start), 1.0), "ring expands at window.sit_start")
	assert_true(is_equal_approx(t.radius_scale(w.apex), 0.0), "ring lands at window.apex")
