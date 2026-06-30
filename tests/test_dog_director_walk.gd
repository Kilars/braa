extends "res://tests/test_case.gd"
## TDD for the ambient walk (050, P2-8 locomotion). DogDirector.play_walk() loops the dog's
## real walk clip so the legs move while main.gd glides the ROOT across the grass patch — honest
## locomotion, never a faked gait. On a dog with no walk clip it is a no-op (mirrors play_sit /
## play_feint / play_reaction asset gates). Built on a synthetic AnimationPlayer so the play path
## runs without the licensed asset, the same harness the feint/reaction director tests use.

func _ap_with(clips: Array) -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	for name in clips:
		lib.add_animation(name, Animation.new())
	ap.add_animation_library("", lib)
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(ap)
	return ap

func test_play_walk_loops_the_walk_clip() -> void:
	var ap := _ap_with(["Idle", "Walk_F_IP", "Sitting_start", "Sitting_1"])
	var dir := DogDirector.new(ap)
	assert_true(dir.has_walk(), "a dog with a walk clip can amble")
	dir.play_walk()
	assert_eq(ap.current_animation, "Walk_F_IP", "play_walk plays the walk clip")
	assert_eq(ap.get_animation("Walk_F_IP").loop_mode, Animation.LOOP_LINEAR,
		"the amble loops so the dog keeps stepping across the patch")
	ap.queue_free()

func test_play_walk_is_a_noop_without_a_walk_clip() -> void:
	# A dog with only idle + sit (no locomotion) must not grab some other clip — main then
	# leaves it centred rather than sliding (never a faked gait).
	var ap := _ap_with(["Idle", "Sitting_start", "Sitting_1"])
	var dir := DogDirector.new(ap)
	assert_false(dir.has_walk(), "no walk clip -> can't amble")
	dir.play_walk()
	assert_eq(ap.current_animation, "", "play_walk no-ops cleanly on a dog with no walk clip")
	ap.queue_free()
