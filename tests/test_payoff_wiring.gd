extends "res://tests/test_case.gd"
## Scene-level wiring for the mark payoff (024f, P1-6). The unit tests prove MarkPayoff's
## gate and PayoffPlayer's loudness in isolation; these prove the running scene actually
## mounts the player and routes a scored tap through it — so a wiring regression (player
## missing, or a tap never dispatched) can't read green. On the committed CC0 dog a real
## tap is DEAD → provably silent; forcing a PERFECT through the production dispatch shows
## the wiring carries a success to the player (it lights up for real once 025 ships Sitt).

func _instantiate_main() -> Node:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	# Pin the CC0 dog so this scene-mount test is deterministic whether or not the
	# gitignored licensed Labrador is present locally. (025)
	main.dog_path_override = "res://assets/models/dog.glb"
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(main)
	# The headless runner quits before any process frame, so _ready is deferred —
	# invoke the real _ready path so we assert the production wiring (see test_bra_button).
	if not main.is_node_ready():
		main._ready()
	return main

func _find_payoff(n: Node) -> PayoffPlayer:
	if n is PayoffPlayer:
		return n
	for c in n.get_children():
		var f := _find_payoff(c)
		if f != null:
			return f
	return null

func test_scene_mounts_the_payoff_player() -> void:
	var main := _instantiate_main()
	var payoff := _find_payoff(main)
	assert_true(payoff != null, "the scene must mount the payoff player (P1-6)")
	main.queue_free()

func test_a_real_cc0_tap_is_silent() -> void:
	# The observable acceptance on the deployed CC0 dog: every tap is DEAD, so the real
	# button press must leave the payoff silent — no false reward (P1-6).
	var main := _instantiate_main()
	var payoff := _find_payoff(main)
	assert_true(payoff != null, "payoff present")
	main._on_bra_pressed()
	if payoff != null:
		assert_false(payoff.last_played, "a DEAD CC0 tap plays no payoff")
	main.queue_free()

func test_production_dispatch_carries_a_success_to_the_player() -> void:
	# Force a PERFECT through the SAME dispatch a tap uses (_play_payoff) to prove the
	# wiring routes a successful mark to the player — the path that lights up live once
	# 025 ships the sit-capable dog and real taps start scoring PERFECT/OK.
	var main := _instantiate_main()
	var payoff := _find_payoff(main)
	assert_true(payoff != null, "payoff present")
	main._play_payoff(SitWindow.Tier.PERFECT)
	if payoff != null:
		assert_true(payoff.last_played, "a PERFECT routes through to the payoff player")
		assert_eq(payoff.last_cue, MarkPayoff.VOICE_PERFECT, "it carries the PERFECT cue")
	# And a MISS through the same path stays silent — the gate holds end-to-end.
	main._play_payoff(SitWindow.Tier.MISS)
	if payoff != null:
		assert_false(payoff.last_played, "a MISS through the dispatch stays silent")
	main.queue_free()
