extends "res://tests/test_case.gd"
## TDD for the face-the-camera turn math (061, P2-11). FaceTurn is the PURE core of "turn to face
## the camera on a real trick": no Node, no Camera — main.gd feeds it the current yaw + the
## camera-facing target and reads heading() each frame to yaw the dog ROOT. It eases a heading
## toward a target at a bounded angular speed, always taking the SHORT way around ±π, and reports
## arrival via is_facing(). Retargetable so the same turner eases IN to the camera during the sit
## and OUT to the roam heading after. The node-driving glue is Visual-Review-gated (same split as
## the WanderField locomotion in 050); these pin the contract the story names: smooth (bounded,
## no snap), completes before the apex (finishes within a deadline), reduced motion still resolves.

func test_turns_at_a_bounded_speed_without_overshoot() -> void:
	# "smooth, no snap": each step moves at most speed*delta toward the target — never a jump.
	# (Target 1.5 rad, not an exact PI half-turn, so the short direction is unambiguous.)
	var f := FaceTurn.new(0.0, 1.5, 1.0)  # 1 rad/s toward a target 1.5 rad away
	f.advance(0.1)
	assert_true(abs(f.heading() - 0.1) < 1e-5, "one 0.1s step at 1 rad/s advances exactly 0.1 rad")
	assert_false(f.is_facing(), "a big turn is not done after a single small step")

func test_takes_the_short_way_around_the_wrap() -> void:
	# From 3.0 rad to -3.0 rad the SHORT path crosses +PI (heading increases and wraps), it does
	# NOT sweep back down through 0. So the first small step must move the heading UP, not down.
	var f := FaceTurn.new(3.0, -3.0, 0.1)
	f.advance(0.1)
	assert_true(f.heading() > 3.0, "turns the short way across the +PI wrap, not the long way through 0")

func test_reaches_and_holds_the_target() -> void:
	# It arrives exactly at the target and then holds it (no drift, no oscillation).
	var f := FaceTurn.new(0.0, 1.2, 5.0)
	for i in 60:
		f.advance(0.05)
	assert_true(f.is_facing(), "the turn reaches the target and reports facing")
	assert_true(abs(f.heading() - 1.2) < 1e-4, "it settles exactly on the target, no drift")

func test_completes_within_a_deadline_when_speed_is_sized_to_it() -> void:
	# "completes before the apex": main sizes speed = turn / deadline so a turn of ANY size finishes
	# within the deadline. A worst-case half-turn (PI) with speed PI/0.5 must be facing by t=0.5s.
	var deadline := 0.5
	var target := 3.0  # a near-worst-case turn (just under a half-turn), unambiguous short way
	var f := FaceTurn.new(0.0, target, target / deadline)
	var elapsed := 0.0
	while elapsed < deadline + 1e-6:
		f.advance(1.0 / 60.0)
		elapsed += 1.0 / 60.0
	assert_true(f.is_facing(), "a turn sized to the deadline is facing by the deadline (before the apex)")
	assert_true(abs(f.heading() - target) < 1e-4, "and it lands exactly facing the camera target")

func test_a_very_high_speed_resolves_in_about_one_frame() -> void:
	# Reduced motion (X-5): main hands it a very high speed so the facing RESOLVES near-instantly —
	# a dampened/near-instant turn is fine, the trick is still read head-on.
	var f := FaceTurn.new(0.0, 2.0, 1000.0)
	f.advance(1.0 / 60.0)
	assert_true(f.is_facing(), "a near-instant turn resolves within a single frame (reduced motion)")
	assert_true(abs(f.heading() - 2.0) < 1e-4, "it lands exactly on the target, not past it")

func test_retarget_redirects_the_turn() -> void:
	# The same turner is reused: eases IN to the camera, then main retargets it OUT to the roam
	# heading for the release. Retargeting mid-turn just changes where it eases toward.
	var f := FaceTurn.new(0.0, 1.0, 100.0)
	f.advance(1.0 / 60.0)
	assert_true(f.is_facing(), "reached the first target")
	f.retarget(-0.5)
	assert_false(f.is_facing(), "retargeting away from the current heading is no longer facing")
	f.advance(1.0 / 60.0)
	assert_true(abs(f.heading() - (-0.5)) < 1e-4, "it eases toward the new target after a retarget")
