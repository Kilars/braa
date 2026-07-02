extends "res://tests/test_case.gd"
## Unit tests for the post-BRA joyful celebration beat (077, PO Note 7). The positive twin of
## main.gd's procedural confused beat: a short, damped, FACING-PRESERVING nudge on the dog root after
## a successful mark, so the payoff reads as one coherent happy bounce/wiggle that stays facing the
## player — never the Jump_Place_IP rear-spin the PO caught (seated → rear-to-camera, tail up → side
## profile → facing in ~4 frames). Pure + deterministic (a Transform3D offset from the dog's rest),
## so it is test-first here; the node-driving glue is Visual-Review-gated (the same split as FaceTurn
## and the confused beat).

const EPS := 1.0e-4

# The maximum yaw magnitude the beat may reach anywhere in its span — the facing invariant: the
# celebration can never rotate the dog rear-to-camera (that was the whole bug). Kept small (a gentle
# body waggle), and JoyBeat clamps to it, so this is both the design intent and a hard guard.
func test_joyful_beat_returns_exactly_to_rest() -> void:
	# At/after the end of the beat the offset is identity — the dog settles EXACTLY back to its rest
	# transform, no drift (the same invariant the confused beat holds). Also identity before it starts.
	assert_true(JoyBeat.offset(JoyBeat.DURATION, 1.0).is_equal_approx(Transform3D.IDENTITY),
		"the beat is over at DURATION — offset returns to identity (settles exactly to rest)")
	assert_true(JoyBeat.offset(JoyBeat.DURATION + 0.2, 1.0).is_equal_approx(Transform3D.IDENTITY),
		"past the end the offset stays identity — no lingering nudge or drift")
	assert_true(JoyBeat.offset(-0.1, 1.0).is_equal_approx(Transform3D.IDENTITY),
		"before it starts the offset is identity")

func test_joyful_beat_preserves_facing() -> void:
	# The yaw offset NEVER exceeds MAX_YAW across the whole beat — so the celebration can never spin
	# the dog rear-to-camera (Note 7). Sample densely.
	var steps := 120
	for i in range(steps + 1):
		var age := JoyBeat.DURATION * float(i) / float(steps)
		var yaw: float = JoyBeat.offset(age, 1.0).basis.get_euler().y
		assert_true(absf(yaw) <= JoyBeat.MAX_YAW + EPS,
			"yaw stays within the small facing cap at age %.3f (was %.3f rad) — no rear-spin" % [age, yaw])

func test_joyful_beat_eases_no_snap() -> void:
	# Per-frame (60 fps) the offset changes only a little — no sub-150 ms pose snap. A jump-clip spin
	# would blow past these caps; the eased procedural beat stays well under.
	var dt := 1.0 / 60.0
	var prev := JoyBeat.offset(0.0, 1.0)
	var age := dt
	while age <= JoyBeat.DURATION + EPS:
		var cur := JoyBeat.offset(age, 1.0)
		var d_yaw: float = absf(cur.basis.get_euler().y - prev.basis.get_euler().y)
		var d_pos: float = (cur.origin - prev.origin).length()
		assert_true(d_yaw < 0.05,
			"yaw eases frame-to-frame at age %.3f (Δ %.4f rad) — no snap" % [age, d_yaw])
		assert_true(d_pos < 0.02,
			"the bob eases frame-to-frame at age %.3f (Δ %.4f m) — no snap" % [age, d_pos])
		prev = cur
		age += dt

func test_reduced_motion_zeroes_the_beat() -> void:
	# X-5: under full reduced motion the beat is fully damped to nothing (like the tell / confused
	# beat scale down). No motion at any point in the span.
	for i in range(11):
		var age := JoyBeat.DURATION * float(i) / 10.0
		assert_true(JoyBeat.offset(age, 0.0).is_equal_approx(Transform3D.IDENTITY),
			"reduced motion (scale 0) yields no beat at age %.3f" % age)

func test_beat_is_active_mid_span() -> void:
	# A sanity guard so the test suite can't pass by trivially returning identity everywhere: somewhere
	# in the first half the beat produces a real bob (dog lifts a little) — a genuine celebration.
	var lifted := false
	for i in range(1, 30):
		var age := JoyBeat.DURATION * float(i) / 60.0
		if JoyBeat.offset(age, 1.0).origin.y > 0.005:
			lifted = true
			break
	assert_true(lifted, "the beat actually lifts the dog a little mid-span (a real bounce, not a no-op)")
