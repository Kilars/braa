extends "res://tests/test_case.gd"
## TDD for the bounded-patch wander math (050, P2-8 locomotion). WanderField is the PURE core
## of the ambient roam: no Node, no AnimationPlayer — main.gd drives the dog ROOT from
## position()/heading() each frame while idle and the AnimationPlayer keeps animating the legs.
## Determinism comes from an INJECTED, seeded RandomNumberGenerator (the same idiom as SitLoop),
## so the three contract bullets the task names — target in range · edge turn-back · never leaves
## the patch — are unit-tested headless. The node-driving glue is Visual-Review-gated instead.

# A seeded RNG so the target draws are reproducible run to run.
func _rng(seed_val := 4242) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_val
	return r

func test_every_target_lies_inside_the_patch() -> void:
	# "target in range": a fresh wander target is always inside the bounded disc — the dog can
	# never aim past its patch (the first half of "never leaves the patch").
	var f := WanderField.new(_rng(3), 0.7)
	var all_in := true
	var maxr := 0.0
	for i in 1000:
		var t := f.pick_target()
		if t.length() > 0.7 + 1e-4:
			all_in = false
		maxr = maxf(maxr, t.length())
	assert_true(all_in, "every wander target lies inside the patch radius")
	assert_true(maxr > 0.5, "targets use the whole patch, not a tiny dot at the centre")

func test_clamp_turns_a_point_back_at_the_edge() -> void:
	# "edge turn": the clamp is the turn-back mechanism — a point past the boundary is pulled
	# back ONTO the edge along the same bearing (the dog turns in instead of walking out).
	var f := WanderField.new(_rng(), 0.7)
	var inside := f.clamp_to_patch(Vector2(0.3, 0.0))
	assert_eq(inside, Vector2(0.3, 0.0), "a point already inside the patch is unchanged")
	var out := f.clamp_to_patch(Vector2(2.0, 0.0))
	assert_true(abs(out.length() - 0.7) < 1e-4, "a point past the edge is pulled onto the boundary")
	assert_true(out.x > 0.0, "the clamp keeps the bearing — turns the dog back in along the same line")

func test_the_dog_never_leaves_the_patch_over_a_long_walk() -> void:
	# The headline invariant: across thousands of frames the dog stays inside the patch AND
	# actually roams (it isn't stuck at the centre).
	var f := WanderField.new(_rng(7), 0.7, 0.5, 0.3)
	var maxr := 0.0
	for i in 4000:
		f.advance(0.1)
		maxr = maxf(maxr, f.position().length())
	assert_true(maxr <= 0.7 + 1e-3, "the dog never leaves the bounded patch")
	assert_true(maxr > 0.1, "the dog actually wandered the patch (not frozen at origin)")

func test_heading_faces_the_travel_direction() -> void:
	# So the dog reads as ROAMING, not sliding sideways: the heading points along the line from
	# where it stands to the target it's ambling toward.
	var f := WanderField.new(_rng(11), 1.0, 0.2, 1.0)
	var t := f.target()
	assert_true(t.length() > 0.01, "this seed yields a non-trivial first target")
	f.advance(0.05)  # one small step — heading is set facing the target before the move
	var expected := atan2(t.x, t.y)
	assert_true(abs(f.heading() - expected) < 1e-4, "heading faces the travel direction")

func test_the_dog_pauses_at_a_target_then_ambles_on() -> void:
	# The amble → pause → amble rhythm: is_moving() drives walk-clip vs idle-clip in main, and
	# the pause is what lets the idle clip read between strides (the PO's "ambles, pauses, picks
	# another").
	var f := WanderField.new(_rng(5), 1.0, 100.0, 0.5)  # huge speed: reaches the target in one step
	f.advance(0.1)  # stride onto the target
	f.advance(0.1)  # next frame detects arrival and begins the pause
	assert_false(f.is_moving(), "the dog pauses on reaching a wander target (idle clip reads)")
	var paused_target := f.target()
	f.advance(0.5)  # wait out the pause
	assert_true(f.is_moving(), "after the pause the dog ambles to a fresh target")
	assert_ne(f.target(), paused_target, "a fresh target is drawn after the pause")
